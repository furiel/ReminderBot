(import sys traceback threading)
(import syslogng)
(import timerdb telegramfetcher)

(import logging)
(logging.basicConfig)
(setv logger (logging.getLogger))
(.setLevel logger logging.DEBUG)

(defclass ReminderBotSource [syslogng.LogSource]
  (defn init [self options]
    (setv api-token (get options "api_token"))
    (setv self.wait (threading.Event)
          self.exit False
          self.fetcher (telegramfetcher.TelegramFetcher api-token))
    True)

  (defn fetch-logs [self timer-db]
    (while (not self.exit)
      (try
        (setv [instant-responses timers] (self.fetcher.fetch))

        (for [timer timers]
          (self.add-notification timer-db timer))

        (for [instant instant-responses]
          (self.send-response timer-db (get instant "message")))

        (except [e Exception]
          (traceback.print_exc)))

      (self.wait.wait 1)))

  (defn run [self]
    (setv self.timer-db (timerdb.TimerDB))
    (.start (threading.Thread :target self.fetch-logs :args (, self.timer-db)))
    (self.timer-db.start))

  (defn request-exit [self]
    (self.fetcher.request-exit)
    (setv self.exit True)
    (self.timer-db.stop)
    (self.wait.set))

  (defn add-notification [self timer-db timer]
    (timer-db.add-timer
      (get timer "timeout")
      (fn []
        (self.post_message
          (syslogng.LogMessage (get timer "message"))))))

  (defn send-response [self timerdb message]
    (timerdb.call-immediately
      (fn []
      (self.post_message
        (syslogng.LogMessage message))))))
