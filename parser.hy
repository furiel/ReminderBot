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
    (if (not (.isdigit (cut timeout-str -1)))
        (setv timeout-str-without-modifier (cut timeout-str 0 -1))
        (setv timeout-str-without-modifier timeout-str))

    (* (int (cut timeout-str-without-modifier 1)) modifier)
    (except [e ValueError]
      (raise (ValueError (.format "Error: {} is invalid for timeout" timeout-str))))))

(defn parse-input [input]
  (try
    (setv [when message] (.split input :maxsplit 1))
    (except [e ValueError]
      (raise (ValueError "Error: not enough arguments"))))

  (setv timeout-type (first when))
  (setv timeout -1)

  (cond [(= timeout-type "+") (setv timeout (timeout-to-sec when))]
        [(= timeout-type "@") (raise (NotImplementedError "@ version for timeout is not supported"))]
        [True (raise (ValueError (.format "{} as timeout is invalid, should be + or @" timeout-type)))])

  (, timeout message))
