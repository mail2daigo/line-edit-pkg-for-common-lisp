(pushnew :build-as-packages *features*)
(pushnew :use-history-pkg *features*)
;;(pushnew :debug *features*)

;; 環境変数[env-var]で指定されたパスを第1引数のファイルに付加した文字列を返す関数[get-src-path]を定義。
(load "~/build-utils.lisp")

#+ sbcl (load (get-src-path "support-functions.fasl"))
#+ sbcl (load (get-src-path "package-util.fasl"))
#+ sbcl (load (get-src-path "print-color-string.fasl"))
#+ sbcl (load (get-src-path "history-pkg.fasl"))
#+ sbcl (load (get-src-path "line-edit-pkg.fasl"))

#+ clisp (load (get-src-path "support-functions.fas"))
#+ clisp (load (get-src-path "package-util.fas"))
#+ clisp (load (get-src-path "print-color-string.fas"))
#+ clisp (load (get-src-path "history-pkg.fas"))
#+ clisp (load (get-src-path "line-edit-pkg.fas"))

#+ gcl (load (get-src-path "support-functions.o"))
#+ gcl (load (get-src-path "package-util.o"))
#+ gcl (load (get-src-path "print-color-string.o"))
#+ gcl (load (get-src-path "history-pkg.o"))
#+ gcl (load (get-src-path "line-edit-pkg.o"))

;;#+sbcl (sb-int:clear-info :function :where-from 'support-functions:find-current-and-home-dir)
;;#+sbcl (sb-int:clear-info :function :type 'support-functions:find-current-and-home-dir)
;;#+sbcl (sb-int:clear-info :function :definition 'support-functions:find-current-and-home-dir)
;;#+sbcl (declaim (sb-ext:muffle-conditions sb-ext:compiler-note))
(compile-file (get-src-path "history-repl.lisp"))

#+sbcl (exit)
#+clisp (exit)
#+gcl (si::bye)
