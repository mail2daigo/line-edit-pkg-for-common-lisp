(pushnew :build-as-packages *features*)
(pushnew :use-history-pkg *features*)

(load "~/build-utils.lisp")

#+sbcl (load (get-pkg-path "support-functions.fasl"))
#+sbcl (load (get-pkg-path "package-util.fasl"))
#+sbcl (load (get-pkg-path "print-color-string.fasl"))

#+clisp (load (get-pkg-path "support-functions.fas"))
#+clisp (load (get-pkg-path "package-util.fas"))
#+clisp (load (get-pkg-path "print-color-string.fas"))

#+gcl (load (get-pkg-path "support-functions.o"))
#+gcl (load (get-pkg-path "package-util.o"))
#+gcl (load (get-pkg-path "print-color-string.o"))

#+sbcl (declaim (sb-ext:muffle-conditions sb-ext:compiler-note))
(compile-file (get-pkg-path "history-pkg.lisp"))

#+sbcl (exit)
#+clisp (exit)
#+gcl (si::bye)
