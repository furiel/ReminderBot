(defclass TelegramFetcher [object]

  (defn fetch [self]
    (setv request (input "waiting for input: "))
    request)

  (defn --init-- [self api-token]
    (setv self.api-token api-token)))
