(import http.client urllib.parse json os)
(import parser)

(import logging)
(logging.basicConfig)
(setv logger (logging.getLogger))
(.setLevel logger logging.DEBUG)
;; (setv http.client.HTTPConnection.debuglevel 1)

(defclass TelegramFetcher [object]

  (defn connect [self &optional [host "api.telegram.org"] [context None]]
    (setv self.conn (http.client.HTTPSConnection host :context context))
    self.conn)

  (defn disconnect [self]
    (when self.conn
      (.close self.conn))
    (setv self.conn None))

  (defn request-exit [self]
    (self.disconnect))

  (defn getUpdates [self]
    (setv
      params {
              "offset" self.last-id
              "timeout" 60
              }
      params_encoded (urllib.parse.urlencode params)
      url (.format "/bot{}/{}?{}" self.api-token "getUpdates" params_encoded))

    (.request self.conn :method "GET" :url url :body params_encoded)
    (setv response (.getresponse self.conn))

    (if (= 2 (// (int response.status) 100))
        (response.read)
        (raise (Exception response.reason))))

  (defn write-last-id-to-disk [self]
    (os.makedirs self.persist-dir :exist_ok True)

    (try
      (with [f (open (os.path.join self.persist-dir "last_id.dat") "w")]
        (f.write (str self.last-id)))
      (except [e Exception]
        (logger.error
          (.format "Exception while writing last_id: {}"
                   (str e))))))

  (defn update-largest-update-id [self messages]
    (setv update-ids
          (lfor
            message-block messages
            :if (in "update_id" message-block)
            (int (get message-block "update_id"))))

    (when update-ids
      (setv self.last-id (+ 1 (max update-ids)))
      (self.write-last-id-to-disk)))

  (defn get-response [self]
    (json.loads
      (.decode
        (self.getUpdates)
        "utf-8")))

  (defn parse-messages[self messages]
    (setv instant-responses (list)
          timers (list))
    (setv items
          (lfor
            message_block messages
            :setv message (get message_block "message")
            :if (in "text" message)
            {"message" (get message "text")
             "from" (get message "from" "username")
             "chat" (get message "chat" "id")
             "update-id" (get message_block "update_id") }))

    (for [item items]
      (setv chat-id (get item "chat"))
      (try
        (setv [timeout message] (parser.parse-input (get item "message")))
        (timers.append {"timeout" timeout "message" message "CHAT_ID" chat-id})
        (instant-responses.append
          {
           "message" (.format "Reminder scheduled. id={}" (get item "update-id"))
           "CHAT_ID" chat-id
           })

        (except [e Exception]
          (pass)
          (instant-responses.append { "message" (str e) "CHAT_ID" chat-id }))))

    (, instant-responses timers))

  (defn fetch [self]
    (setv instant-responses (list)
          timers (list))
    (try
      (when (not self.conn)
        (self.connect))

      (setv response (self.get-response))
      (setv messages (get response "result"))
      (self.update-largest-update-id messages)
      (setv [instant-responses timers] (self.parse-messages messages))

      (except [e Exception]
        (logger.error (.format "Exception while fetch {}" (str e)))
        (self.disconnect)))
    (, instant-responses timers))

  (defn load-last-id [self]
    (try
      (with [f (open (os.path.join self.persist-dir "last_id.dat"))]
        (setv self.last_id (int (f.read))))
      (except [e Exception]
        (logger.error
          (.format "Exception while reading last_id: {}"
                   (str e)))
        (setv self.last_id 0))))

  (defn --init-- [self api-token &optional [persist-dir "persist-dir"]]
    (setv
      self.conn None
      self.api-token api-token
      self.persist-dir persist-dir)
    (self.load-last-id)))
