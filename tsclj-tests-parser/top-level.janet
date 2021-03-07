(import ./grammar)

(def top-level
  # grammar/clojure is a struct, need something mutable
  (let [ca (table ;(kvs grammar/clojure))]
    # override things that need to be captured
    (put ca
         :main ~(sequence (capture :input) (position)))
    # tried using a table with a peg but had a problem, so use a struct
    (table/to-struct ca)))
