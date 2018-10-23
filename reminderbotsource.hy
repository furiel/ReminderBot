(import sys traceback threading)
(import syslogng)
(import parser timerdb telegramfetcher)

(defclass ReminderBotSource [syslogng.LogSource]
  (defn init [self options]
    (setv api-token (get options "api_token"))
    (setv self.event (threading.Event)
          self.exit False
          self.fetcher (telegramfetcher.TelegramFetcher api-token))
    True)

  (defn fetch-logs [self timer-db]
    (while (not self.exit)
      (try
        (setv request (self.fetcher.fetch))
        (self.add-notification timer-db request)
        (except [e Exception]
          (traceback.print_exc)))))

  (defn run [self]
    (setv self.timer-db (timerdb.TimerDB))
    (.start (threading.Thread :target self.fetch-logs :args (, self.timer-db)))
    (self.timer-db.start))

  (defn request-exit [self]
    (self.fetcher.request-exit)
    (setv self.exit True)
    (self.timer-db.stop))

  (defn add-notification [self timer-db request]
    (setv [timeout message] (parser.parse-input request))
    (timer-db.add-timer
      timeout
      (fn []
        (self.post_message
          (syslogng.LogMessage message))))))
