(import sys traceback threading time math)
(import syslogng)
(import timerdb telegramfetcher persiststate)

(import logging)
(logging.basicConfig)
(setv logger (logging.getLogger))
(.setLevel logger logging.DEBUG)

(defclass ReminderBotSource [syslogng.LogSource]
  (defn init [self options]
    (setv api-token (get options "api_token")
          allowed-users (.get options "allowed_users"))

    (setv self.wait (threading.Event)
          self.exit False
          self.fetcher (telegramfetcher.TelegramFetcher api-token :allowed-users allowed_users)
          self.persist-state (persiststate.PersistState "persist-dir")
          self.unhandled-timers (self.persist-state.load-all))
    True)

  (defn add-to-persist [self timer]
    (assoc timer "creation-time" (math.ceil (time.time)))
    (self.persist-state.save (get timer "id") timer))

  (defn fetch-logs [self timer-db]
    (while (not self.exit)
      (try
        (setv [instant-responses timers] (self.fetcher.fetch))

        (for [timer timers]
          (self.add-to-persist timer)
          (self.add-notification timer-db timer))

        (for [instant instant-responses]
          (self.send-response timer-db instant))

        (except [e Exception]
          (traceback.print_exc)))

      (self.wait.wait 1)))

  (defn re-add-persist-timer [self timer-db timer]
    (setv current-time (math.ceil (time.time))
          creation-time (get timer "creation-time")
          original-timeout (get timer "timeout")
          timeout (- original-timeout (- current-time creation-time)))
    (assoc timer "timeout" timeout)
    (self.add-notification timer-db timer))

  (defn run [self]
    (setv self.timer-db (timerdb.TimerDB))
    (for [timer self.unhandled-timers]
      (self.re-add-persist-timer self.timer-db timer))
    (setv self.unhandled-timers (list))

    (.start (threading.Thread :target self.fetch-logs :args (, self.timer-db)))
    (self.timer-db.start))

  (defn request-exit [self]
    (self.fetcher.request-exit)
    (setv self.exit True)
    (self.timer-db.stop)
    (self.wait.set))

  (defn create-logmessage [self message]
    (setv text (get message "message")
          chat_id (get message "CHAT_ID"))

    (setv logmessage (syslogng.LogMessage text))
    (assoc logmessage "CHAT_ID" (str chat_id))
    logmessage)

  (defn add-notification [self timer-db timer]
    (timer-db.add-timer
      (get timer "timeout")
      (fn []
        (self.post_message
          (self.create-logmessage timer))
        (self.persist-state.remove (get timer "id")))))

  (defn send-response [self timerdb instant]
    (timerdb.call-immediately
      (fn []
      (self.post_message
        (self.create-logmessage instant))))))
