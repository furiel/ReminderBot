(import os tempfile glob)

(defclass CorruptPersistFile [Exception])

(setv PERSIST-STATE-DIR (+ (os.getcwd) "/persist/"))

(defn init [dir]
  (unless (os.path.exists dir)
    (os.makedirs dir))
  (setv PERSIST-STATE-DIR dir))

(defn get-id [filename]
  (setv basename (os.path.basename filename))
  (setv [id ext] (os.path.splitext basename))
  id)

(defn save [data]
  (setv [fd abspath] (tempfile.mkstemp :dir PERSIST-STATE-DIR :prefix "" :suffix ".persist"))
  (os.write fd (.encode (.format "{:d} {}" (len data) data)))
  (get-id abspath))

(defn active-states []

  (setv states (list))
  (for [filename (glob.glob (os.path.join PERSIST-STATE-DIR "*.persist"))]
    (unless (os.path.isfile filename)
      (continue))

    (with [f (open filename)]
      (setv content (.read f))
      (setv [length data] (.split content :maxsplit 2))

      (unless (= (len data) (int length))
        (raise (CorruptPersistFile filename)))

      (setv id (get-id filename))
      (setv state (dict))
      (assoc state "id" id "data" data)
      (.append states state)))
  states)

(defn forget [id]
  (os.unlink (os.path.join PERSIST-STATE-DIR (+ id ".persist"))))
