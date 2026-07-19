(pushnew :builed-as-packages *features*)
(pushnew :use-history-pkg *features*)

(load "~/build-utils.lisp" :verbose nil :print nil)

(let ((*load-verbose* nil)) ;; ファイル/ロード時のメッセージを抑止する。
  ;; ロード順序は依存関係の下位から上位へ。さもないとエラーとなる。
  #+ sbcl (load (get-src-path "support-functions.fasl") :verbose nil :print nil)
  #+ sbcl (load (get-src-path "package-util.fasl") :verbose nil :print nil)
  #+ sbcl (load (get-src-path "print-color-string.fasl") :verbose nil :print nil)
  #+ sbcl (load (get-src-path "history-pkg.fasl") :verbose nil :print nil)
  #+ sbcl (load (get-src-path "line-edit-pkg.fasl") :verbose nil :print nil)
  #+ sbcl (load (get-src-path "history-repl.fasl") :verbose nil :print nil)
      
  #+ clisp (load (get-src-path "support-functions.fas") :verbose nil :print nil)
  #+ clisp (load (get-src-path "package-util.fas") :verbose nil :print nil)
  #+ clisp (load (get-src-path "print-color-string.fas") :verbose nil :print nil)
  #+ clisp (load (get-src-path "history-pkg.fas") :verbose nil :print nil)
  #+ clisp (load (get-src-path "line-edit-pkg.fas") :verbose nil :print nil)
  #+ clisp (load (get-src-path "history-repl.fas") :verbose nil :print nil)

  #+ gcl (load (get-src-path "support-functions.o") :verbose nil :print nil)
  #+ gcl (load (get-src-path "package-util.o") :verbose nil :print nil)
  #+ gcl (load (get-src-path "print-color-string.o") :verbose nil :print nil)
  #+ gcl (load (get-src-path "history-pkg.o") :verbose nil :print nil)
  #+ gcl (load (get-src-path "line-edit-pkg.o") :verbose nil :print nil)
  #+ gcl (load (get-src-path "history-repl.o") :verbose nil :print nil)
  ) ;; end let

;;(in-package :cl-user)

;;(setf *print-level* 5)
;;(setf *print-length* 5)

;;(debug-print "true-get-candidates")
;;(debug-print "display-line")
;;(debug-print "line-edit-command-loop")
;;(debug-print "set-point")
;;(debug-print "info-list")

(history-repl:history-repl :line-edit-pkg) ;; 第1引数は[history-repl]の初期パッケージの指定。
;;(history-repl:history-repl) ;; = (history-repl:history-repl :cl-user)
