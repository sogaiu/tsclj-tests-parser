(import ./top-level)

(def ts-test-grammar
  ~{:main (some :section)
    :section (sequence :header :code-strs :trees)
    :header (sequence :equalses "\n"
                      (capture (to "\n")) "\n"
                      :equalses "\n")
    :equalses (at-least 8 "=")
    :code-strs (sequence (capture (to "\n---\n"))
                         "\n---\n")
    :trees (choice (to :equalses)
                   (to -1))})

(comment

  (def sample
    ``
    =====================================
    List - ()
    =====================================

    ()
    ("a" "b" "c")
    (:a {:a "a"})

    ---

    (program
      (list)
      (list (string) (string) (string))
      (list (keyword)
            (hash_map (keyword) (string))))

    =====================================
    Vector - []
    =====================================

    []
    [true]
    ["a" :b 3]

    ---

    (program
      (vector)
      (vector (boolean (true)))
      (vector (string) (keyword) (number (number_long))))

    =====================================
    Hash Map - {}
    =====================================

    {}
    {:a "a"}
    {"x" :x, "y" :y, "z" :z}

    ---

    (program
      (hash_map)
      (hash_map (keyword) (string))
      (hash_map (string) (keyword)
                (string) (keyword)
                (string) (keyword))
      )

    ``)

  (deep=
    #
    (peg/match ts-test-grammar sample)
    #
    '@["List - ()"
       "\n()\n(\"a\" \"b\" \"c\")\n(:a {:a \"a\"})\n"
       "Vector - []"
       "\n[]\n[true]\n[\"a\" :b 3]\n"
       "Hash Map - {}"
       "\n{}\n{:a \"a\"}\n{\"x\" :x, \"y\" :y, \"z\" :z}\n"]
    )
  # => true

  )

(defn parse-test-file
  [content]
  (when-let [parsed (peg/match ts-test-grammar content)]
    (struct ;parsed)))

(defn collect-tests
  [dir]
  (def tests @[])
  (each item (os/dir dir)
    (when-let [parsed (parse-test-file
                        (slurp (string dir "/" item)))]
      (eachp [seg-name forms-str] parsed
        (var from 0)
        (loop [[tl pos]
               :iterate (peg/match top-level/top-level
                                   forms-str from)]
          (unless (peg/match ~(sequence (any :s) -1) tl)
            (array/push tests tl))
          (set from pos)))))
  tests)

# traverse the corpus files for oakmac and Tavistock, creating for each one
# a single file that contains all forms
#
# these files can be fed to tree-sitter's parse command to check for errors,
# e.g.
#
#   npx tree-sitter parse test-files/corpus.oakmac.txt
#   npx tree-sitter parse test-files/corpus.Tavistock.txt
#
# the hope is that there are no instances of ERROR in the output :)
(defn main
  [& args]
  #
  (def out-dir "test-files")
  #
  (os/mkdir out-dir)
  #
  (each name ["tsclj-oakmac"
              "tsclj-Tavistock"]
    # this path works when the script is run from the project directory
    (with [f (file/open (string out-dir "/" name ".txt") :w)]
      (let [corpus-path (string name "/corpus")]
        (unless (os/stat corpus-path)
          (eprint "non-existant corpus: " name)
          (os/exit 1))
        (each form (collect-tests corpus-path)
          (file/write f form)
          (file/write f "\n\n"))))))
