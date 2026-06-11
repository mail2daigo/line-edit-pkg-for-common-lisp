(pushnew :build-as-packages *features*)

(load "~/build-utils.lisp")

#+sbcl (declaim (sb-ext:muffle-conditions sb-ext:compiler-note))
#+sbcl (load (get-src-path "support-functions.fasl"))

#+clisp (load (get-src-path "support-functions.fas"))

#+gcl (load (get-src-path "support-functions.o"))

(compile-file (get-src-path "package-util.lisp"))

#+sbcl (exit)
#+clisp (exit)
#+gcl (si::bye)
