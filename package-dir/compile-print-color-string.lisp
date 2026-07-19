(pushnew :build-as-packages *features*)
(pushnew :use-history-pkg *features*)

(load "~/build-utils.lisp")

#+sbcl (load (get-pkg-path "support-functions.fasl"))
;;#+sbcl (load (get-src-path "package-util.fasl"))

#+clisp (load (get-pkg-path "support-functions.fas"))
;;#+clisp (load (get-src-path "package-util.fas"))

#+gcl (load (get-pkg-path "support-functions.o"))
;;#+gcl (load (get-src-path "package-util.o"))

#+sbcl (declaim (sb-ext:muffle-conditions sb-ext:compiler-note))
(compile-file (get-pkg-path "print-color-string.lisp"))

#+sbcl (exit)
#+clisp (exit)
#+gcl (si::bye)
