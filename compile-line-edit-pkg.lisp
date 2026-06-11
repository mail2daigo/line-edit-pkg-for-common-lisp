(pushnew :build-as-packages *features*)
(pushnew :use-history-pkg   *features*)
(pushnew :use-package-util  *features*)
;;(pushnew :debug *features*)

(load "~/build-utils.lisp")

#+sbcl (load (get-src-path "support-functions.fasl"))
#+sbcl (load (get-src-path "package-util.fasl"))
#+sbcl (load (get-src-path "print-color-string.fasl"))
#+sbcl (load (get-src-path "history-pkg.fasl"))

#+clisp (load (get-src-path "support-functions.fas"))
#+clisp (load (get-src-path "package-util.fas"))
#+clisp (load (get-src-path "print-color-string.fas"))
#+clisp (load (get-src-path "history-pkg.fas"))

#+gcl (load (get-src-path "support-functions.o"))
#+gcl (load (get-src-path "package-util.o"))
#+gcl (load (get-src-path "print-color-string.o"))
#+gcl (load (get-src-path "history-pkg.o"))

#+sbcl (declaim (sb-ext:muffle-conditions sb-ext:compiler-note))

;;#+sbcl (sb-int:clear-info :function :where-from 'support-functions:find-current-and-home-dir)
;;#+sbcl (sb-int:clear-info :function :type 'support-functions:find-current-and-home-dir)
;;#+sbcl (sb-int:clear-info :function :definition 'support-functions:find-current-and-home-dir)
;;(declaim (notinline support-functions:find-current-and-home-dir))
(compile-file (get-src-path "line-edit-pkg.lisp"))

#+sbcl (exit)
#+clisp (exit)
#+gcl (si::bye)
