(defclass InvalidInputException [Exception])

(defn timeout-to-sec [timeout-str]
  (assert (> (len timeout-str 1)))
  (setv modifier-symb (cut timeout-str -1))

  (cond [(.isdigit modifier-symb) (setv modifier 1)]
        [(= "s" modifier-symb) (setv modifier 1)]
        [(= "m" modifier-symb) (setv modifier 60)]
        [(= "h" modifier-symb) (setv modifier (* 60 60))]
        [(= "d" modifier-symb) (setv modifier (* 24 60 60))]
        [True (raise (ValueError (.format "Error: invalid modifier in {}: {}" timeout-str modifier-symb)))])

  (try
    (if (not (.isdigit modifier-symb))
        (setv timeout-str-without-modifier (cut timeout-str 0 -1))
        (setv timeout-str-without-modifier timeout-str))

    (* (int timeout-str-without-modifier) modifier)
    (except [e ValueError]
      (raise (ValueError (.format "Error: {} is invalid for timeout" timeout-str))))))

(defn parse-input [input]
  (setv example "/later 1h message")
  ;; todo: /at 2018 12 24 10 15 00 text or something similar

  (setv tokens (.split input :maxsplit 3))
  (when (< (len tokens) 3)
    (raise (ValueError (.format "Error: not enough arguments. Example: {}" example))))
  (setv [command when message] tokens)

  (when (not (in command ["/later"]))
    (raise (ValueError (.format "Unknown command: {}. Example: {}" command example))))

  (try
    (setv timeout (timeout-to-sec when))
    (except [e Exception]
      (raise (ValueError (.format "Error while parsing: {}" (str e))))))

  (, timeout message))
