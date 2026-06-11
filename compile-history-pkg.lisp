(pushnew :build-as-packages *features*)
(pushnew :use-history-pkg *features*)

(load "~/build-utils.lisp")

#+sbcl (load (get-src-path "support-functions.fasl"))
#+sbcl (load (get-src-path "package-util.fasl"))
#+sbcl (load (get-src-path "print-color-string.fasl"))

#+clisp (load (get-src-path "support-functions.fas"))
#+clisp (load (get-src-path "package-util.fas"))
#+clisp (load (get-src-path "print-color-string.fas"))

#+gcl (load (get-src-path "support-functions.o"))
#+gcl (load (get-src-path "package-util.o"))
#+gcl (load (get-src-path "print-color-string.o"))

#+sbcl (declaim (sb-ext:muffle-conditions sb-ext:compiler-note))
(compile-file (get-src-path "history-pkg.lisp"))

#+sbcl (exit)
#+clisp (exit)
#+gcl (si::bye)
