(import http.client urllib.parse json)

;; (import logging)
;; (logging.basicConfig)
;; (.setLevel (logging.getLogger) logging.DEBUG)
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
;              "offset" 123456
              "timeout" 60
              }
      params_encoded (urllib.parse.urlencode params)
      url (.format "/bot{}/{}?{}" self.api-token "getUpdates" params_encoded))

    (.request self.conn :method "GET" :url url :body params_encoded)
    (setv response (.getresponse self.conn))

    (if (= 2 (// (int response.status) 100))
        (response.read)
        (raise (Exception response.reason))))

  (defn fetch [self]
    (setv response
          (json.loads
            (.decode
              (self.getUpdates)
              "utf-8")))
    (setv messages (get response "result"))

    (lfor
      message_block messages
      :setv message (get message_block "message")
      :if (in "text" message)
      {"message" (get message "text")
       "from" (get message "from" "username")
       "chat" (get message "chat" "id")
       "update-id" (get message_block "update_id") }))

  (defn --init-- [self api-token]
    (setv self.api-token api-token)))