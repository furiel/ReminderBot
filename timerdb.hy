(import threading os select logging)

(setv POLL-NONE 0)

(defclass TimerDB [object]
  (defn --init-- [self]
    (setv self.timers (dict))
    (setv [self.shutdown-event-listener self.shutdown-event] (os.pipe))
    (setv self.shutdown-finished (threading.Event))
    (setv [self.wakeup-listener self.wakeup-event] (os.pipe)))

  (defn acknowledge-restart-poll-request [self]
    (os.read self.wakeup-listener 1))

  (defn start [self]
    (setv self.poll (select.poll))
    (.register self.poll self.shutdown-event-listener POLL-NONE)
    (.register self.poll self.wakeup-listener select.POLLIN)

    (logging.info (.format "TimerDB started : shutdown-fd {} wakeup-fd {}"
                           self.shutdown-event-listener
                           self.wakeup-listener))
    (while 1
      (setv poll-result (.poll self.poll))

      (for [single-event poll-result]
        (setv [fd event] single-event)
        (logging.info (.format "event happened fd {}, event {}" fd event))

        (cond
          [(= fd self.shutdown-event-listener)
           (for [key self.timers]
             (.cancel (get self.timers key)))

           (.set self.shutdown-finished)
           (logging.info "TimerDB shut down")
           (return)]

          [(= fd self.wakeup-listener)
           (.acknowledge-restart-poll-request self)
           (continue)]

          [True
           (.pop self.timers fd)
           (.unregister self.poll fd)]))))

  (defn shutdown [self]
    (os.close self.shutdown-event)
    (.wait self.shutdown-finished))

  (defn restart-poll [self]
    (os.write self.wakeup-event b"."))

  (defn add-fd-to-poll [self fd]
    (.register self.poll fd POLL-NONE)
    (.restart-poll self))

  (defn add-timer [self when action]
    (setv [finished-listener finished-event] (os.pipe))

    (setv handler (fn [action finished-event]
                    (action)
                    (os.close finished-event)))

    (.add-fd-to-poll self finished-listener)
    (setv timer (threading.Timer when handler :args (, action finished-event)))
    (assoc self.timers finished-listener timer)
    (.start timer)))
