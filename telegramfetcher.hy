(import http.client urllib.parse json os)

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
    (.close self.conn))

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

  (defn update-largest-update-id [self messages]
    (setv update-ids
          (lfor
            message-block messages
            :if (in "update_id" message-block)
            (int (get message-block "update_id"))))

    (when update-ids
        (setv self.last-id (+ 1 (max update-ids)))))

  (defn fetch [self]
    (setv response
          (json.loads
            (.decode
              (self.getUpdates)
              "utf-8")))
    (setv messages (get response "result"))
    (self.update-largest-update-id messages)

    (lfor
      message_block messages
      :setv message (get message_block "message")
      :if (in "text" message)
      {"message" (get message "text")
       "from" (get message "from" "username")
       "chat" (get message "chat" "id")
       "update-id" (get message_block "update_id") }))

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
    (setv self.api-token api-token
          self.persist-dir persist-dir)
    (self.load-last-id)))
