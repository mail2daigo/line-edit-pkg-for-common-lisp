(pushnew :build-as-packages *features*)

(load "~/build-utils.lisp")

#+sbcl (declaim (sb-ext:muffle-conditions sb-ext:compiler-note))
#+sbcl (load (get-pkg-path "support-functions.fasl"))

#+clisp (load (get-pkg-path "support-functions.fas"))

#+gcl (load (get-pkg-path "support-functions.o"))

(compile-file (get-pkg-path "package-util.lisp"))

#+sbcl (exit)
#+clisp (exit)
#+gcl (si::bye)
