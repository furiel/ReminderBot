(import os glob json)

(defclass CorruptPersistFile [Exception])

(defclass PersistState [object]
  (defn --init-- [self persist-dir]
    (os.makedirs persist-dir :exist_ok True)
    (setv self.persist-dir persist-dir))

  (defn save [self id data]
    (setv payload (json.dumps data))
    (setv filename (os.path.join self.persist-dir (.format "{}.persist" id)))
    (with [f (open filename "w")]
      (f.write payload)))

  (defn load-all [self]
    (setv persist-files (glob.glob (os.path.join self.persist-dir "*.persist")))

    (lfor
      filename persist-files
      :if (os.path.isfile filename)
      (with [f (open filename)]
        (json.loads (.read f)))))

    (defn remove [self id]
      (setv filename (os.path.join self.persist-dir (.format "{}.persist" id)))
      (os.unlink filename)))
