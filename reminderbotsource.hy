(import sys traceback threading)
(import syslogng)
(import parser timerdb)

(defclass ReminderBotSource [syslogng.LogSource]
  (defn init [self options]
    (setv self.event (threading.Event)
          self.exit False)

    (setv self.api-token (get options "api_token"))
    True)

  (defn fetch-logs [self timer-db]
    (while (not self.exit)
      (try
        (setv request (input "waiting for input: "))
        (self.add-notification timer-db request)
        (except [e Exception]
          (traceback.print_exc)))))

  (defn run [self]
    (setv self.timer-db (timerdb.TimerDB))
    (.start (threading.Thread :target self.fetch-logs :args (, self.timer-db)))
    (self.timer-db.start))

  (defn request-exit [self]
    (setv self.exit True)
    (self.timer-db.stop))

  (defn add-notification [self timer-db request]
    (setv [timeout message] (parser.parse-input request))
    (timer-db.add-timer
      timeout
      (fn []
        (self.post_message
          (syslogng.LogMessage message))))))
