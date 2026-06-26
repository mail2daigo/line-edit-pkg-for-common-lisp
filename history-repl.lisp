;;;
;;; last updated : 2026-06-25 09:47:55(JST)
;;;

#+ :build-as-packages
(defpackage :history-repl
  (:use :common-lisp)
  (:use :package-util)
  (:use :support-functions)
  (:use :print-color-string)
  (:use :history-pkg)
  (:use :line-edit-pkg)
  (:export
   #:history-repl
   #:current-default-prompt-color
   #:help
   #:help-help
   )
  )

#+ :build-as-packages
(in-package :history-repl)

(declaim (optimize (safety 0) (speed 3) (space 0) (compilation-speed 0)))
;;(declaim (optimize (safety 3) (speed 0) (space 0) (compilation-speed 0)))

(defparameter *current-default-prompt-color* 'blue)     ;; repl毎のプロンプト全体の既定色。
(defparameter *shadowing-import-functions* ;; パッケージ前置子なしで呼び出したい関数を登録しておく。
  '(
    package-util:cd              ;; change package-directory stack.
    package-util:pwd             ;; print working package-directory.
    package-util:pushd           ;; push package to package-directory.
    package-util:popd            ;; pop package from package-directory.
    package-util:dirs            ;; show package-directory stack.
    package-util:rotate-up-dir   ;; rotate up package-directory stack.
    package-util:rotud           ;; synonym of rotate-up-dir
    package-util:rotd            ;; synonym of rotate-up-dir
    package-util:rotate-down-dir ;; rotate down package-directory stack.
    package-util:rotdd           ;; synonym of rotate-down-dir
    package-util:exchgd          ;; exchange directory top and sencond.
    package-util:ls              ;; list symbols.
    package-util:view-package-dependency-graph ;; パッケージ間の依存(ユース)関係をgraphvizで描画する。
    package-util:view-pkg-dep    ;; [view-package-dependency-graph]のラッパー関数。
    debug-print:debug-print
    debug-print:debug-print-p
    line-edit-pkg:select-language
    line-edit-pkg:selected-language
    line-edit-pkg:native-language
    line-edit-pkg:set-editor-mode
    history-repl:help
    history-repl:help-help
    print-color-string:help-color
    history-pkg:help-history
    support-functions:helpf
    line-edit-pkg:help-edit
    line-edit-pkg:help-complete
    support-functions:message
    )
  ) ;; end defparameter

(defun current-default-prompt-color ()
  *current-default-prompt-color*
  )

(defun help (&optional (item nil))
  (cond
    ((null item)
     (message :history-repl+help-001 "(help-edit) 現在選択されているエディタ用コマンド一覧を表示する。~%")
     (message :history-repl+help-002 "(help-complete) 補完コマンドの解説を表示する。~%")
     (message :history-repl+help-003 "(help-history) csh互換履歴操作コマンドの一覧を表示する。~%")
     (message :history-repl+help-004
              "(help-color) 文字列をカラー出力する関数[print-colored-string]の解説を表示する。~%")
     )
    ((equal item :edit)
     (help-edit)
     )
    ((equal item :complete)
     (help-complete)
     )
    ((equal item :history)
     (help-history)
     )
    ((equal item :color)
     (help-color)
     )
    (t
     (format t "Type (help) or (help :edit), (help :complete), (help :history), (help :color).~%")
     )
    ) ;; end cond
  ) ;; end help

(defun help-help ()
  (help)
  )

(define-condition too-many-input-error (reader-error)
  ((garbage :initarg :garbage :reader error-garbage))
  (:report (lambda (condition stream) (format stream "~a" (error-garbage condition))))
  ) ;; end define-condition

;; 起動時にこの関数を呼び出すとヒストリ機能が使えるようになる。
;; > (load "history-pkg.fasl") ;; or (load "history-pkg.lisp")
;; T
;; > (history-pkg:history-repl) ;; or (in-package :history-pkg) -> (history-repl)
;;
;; プロンプトを変更したい場合は関数[set-prompt-element]で設定する。
;;
(defun history-repl (&optional (init-pkg :cl-user))
  "ANSI Common Lispの標準機能に基づいたカスタムREPL。"
  (let (
        (prmpt-color nil)
        (prmpt-attr nil)
	(input "")
        tmp
        )
    (declare (type (or simple-string null) input))

    (load (support-functions:config-file-abs-path "init-repl-prompt")) ;; 各種初期設定。
    (history-pkg:clear-history) ;; 履歴をクリア。
    (history-pkg:read-history) ;; 前回記録した履歴ファイルを読み込む。
    (set-macro-character #\! #'history-pkg:hist) ;; C-shell風履歴コマンドを処理するマクロ。

    ;; [history-repl]のパッケージを引数で指定されたパッケージに設定する。
    (when (packagep (find-package init-pkg))
      (let (last-show-level)
	(setf last-show-level (auto-show-dirs))
	(auto-show-dirs nil)
	(cd init-pkg)
	(last-package (find-package init-pkg))
	(auto-show-dirs last-show-level)
	) ;; end let
      )	  ;; end when

    (unwind-protect
         (loop
	   ;; replごとにパッケージが変化しているかも知れないので、パッケージ前置子なしで呼び出したい関数
	   ;; 群を毎回shadowing-importする。
	   ;; これで常にshadowing-importリストの関数をパッケージ前置子なしで呼び出せる。
	   ;; 同じパッケージに重複してshadowing-importしても規格上も問題ない。
	   (when (not (member (package-name *package*) (packages-exception-list) :test #'string-equal))
	     (shadowing-import *shadowing-import-functions* *package*)
	     ) ;; end when

	   ;; [package-util]内のパッケージ移動関数を使用すると[package-changed-by-package-util-p]
	   ;; が[t]になる。
	   (package-util:package-changed-by-package-util nil)

	   ;; [set-prompt-attributes]で設定された色属性があれば取得する。
           (setf prmpt-attr (history-pkg:get-prompt-attributes))
           (setf tmp (member :color prmpt-attr :test #'equal :key #'car))
           (cond
             ((null tmp)
              (setf prmpt-color *current-default-prompt-color*)
              )
             (t
              (setf prmpt-color (second (first tmp)))
              (setf *current-default-prompt-color* prmpt-color) ;; 次回以降のデフォルトとして記録する。
              (setf tmp (remove ':color prmpt-attr :test #'string-equal-by-symbol-name :key #'car))
              (setf prmpt-attr nil)
              (dolist (s tmp)
                (setf prmpt-attr (append s prmpt-attr))
                ) ;; end dolist
              )   ;; end [t]
             )    ;; end cond

	   ;; プロンプトを表示する。
           ;; (print-colored-string [color] [atom-or-list] &key ...)
           (apply #'print-colored-string prmpt-color (system-prompt) prmpt-attr)
           (finish-output)
       
	   ;; 関数[line-edit]で入力を得て評価する。
           (handler-case ;; 主に[read-from-string]でのエラー捕捉を目的としたhandler-case
               (unwind-protect
                    (progn
                      (raw-mode) ;; OS側でのバッファリングなし、エコーなしの入力モードにする。

                      ;; 端末からの行編集機能付き入力。入出力制御はすべて関数[line-edit]が行う。
                      (setf input (line-edit-pkg:line-edit)) ;; 返す型は文字列型。

                      (when (null input) ;; [nil]の場合のみ。何も入力しない場合は[""]が返る。
                        (if (not (suppress-important-message))
                            (format t "line-edit returned [nil]. exit.~%")
                            )
                        (return-from history-repl t)
                        )

		      ;;
                      ;; (quit-repl)または(quit)と入力されたら[history-repl]を終了。
		      ;; (exit-repl)または(exit)と入力されても[history-repl]を終了。
		      ;; (bye)と入力されても[history-repl]を終了。
		      ;; "quit-repl" "quit" "exit-repl" "exit" の前後に空白文字類があっても許す。
		      ;; "  (  exit ) " などと入力してもOK。大文字・小文字どちらでも可。
		      ;;
		      ;; その他はCommon Lispのreaderに渡すので何もしない。
		      ;;
                      ;; 空文字なら何もしない。
		      (when (not (and (stringp input) (zerop (length input))))
			
			;; (quit), (quit-repl), (exit), (exit-repl)などのrepl終了用疑似関数を正確に
			;; 捕捉するために入力されたS式を整形し、該当する疑似関数ならreplを終了する。
			(let (trimmed-str (white-spaces '(#\Space #\Tab #\Newline #\Return)))
			  ;; 先ず前後の空白文字類を削除。
			  (setf trimmed-str (string-trim white-spaces input))

			  ;; 先頭文字が#\(であれば#\(の右側の空白文字類を削除。
			  (when (char= (char trimmed-str 0) #\()
			    (setf trimmed-str
				  (format nil "(~a"
					  (string-left-trim white-spaces (subseq trimmed-str 1)))
				  ) ;; end setf
			    )	    ;; end when

			  ;; 末尾文字が#\)であれば#\)の左側の空白文字類を削除。
			  (when (char= (char trimmed-str (1- (length trimmed-str))) #\) )
			    (setf trimmed-str
				  (format nil "~a)"
					  (string-right-trim
					   white-spaces
					   (subseq trimmed-str 0 (1- (length trimmed-str)))))
				  ) ;; end setf
			    )	    ;; end when

			  (when (member trimmed-str
					(list "(quit-repl)" "(quit)") :test #'string-equal)
			    (if (not (suppress-important-message))
				(format t "Quited history-repl.")
				) ;; end if
			    ;;(verbose-message nil)
			    (return-from history-repl t)
			    ) ;; end when

			  (when (member trimmed-str
					(list "(exit-repl)" "(exit)" "(bye)") :test #'string-equal)
			    (if (not (suppress-important-message))
				(format t "exited history-repl.")
				) ;; end if
			    ;;(verbose-message nil)
			    (return-from history-repl t)
			    ) ;; end when
			  )   ;; end let

			;; 入力をS式として評価する。
                        (let (
                              (form nil)
                              (vals nil)
                              (len 0)
                              )
                          ;; 不正入力でエラー発生の可能性あり。[handler-case]で捕捉する。
                          (multiple-value-bind (parsed-form idx) (read-from-string input)
			    ;; idx から入力文字列の末尾までの間に空白以外の文字が残っていないかチェック。
			    (setf form parsed-form)
			    (let (trailing-str)
                              (setf trailing-str (string-trim '(#\Space #\Tab #\Newline #\Return)
                                                              (subseq input idx)))
                              (when (plusp (length trailing-str))
                                (error 'too-many-input-error :stream nil :garbage trailing-str)
                                ) ;; end when
                              )   ;; end let
			    )     ;; end multiple-value-bind

                          ;; "!"で始まる履歴操作マクロは展開された内容を文字列に戻して履歴に追加。
                          ;; 展開前が"!"で始まる履歴操作マクロでなければ入力そのままを履歴に追加。
                          (unless
                              (and
                               (listp form)
                               (member (car form) (history-pkg:history-functions)))
			    (if (char= (char input 0) #\!)
                                (history-pkg:add-str-to-hist (format nil "~s" form))
                                (history-pkg:add-str-to-hist input)
                                ) ;; end if
			    )     ;; end unless

                          ;;
                          ;; 評価し、多値の場合を含めて結果を表示する。
                          ;;
                          (setf vals (multiple-value-list (eval form)))
                          ;; (multiple-value-list (values)) return [nil]. (length nil) => 0.
                          ;; (multiple-value-list nil) return [(nil)]. (length '(nil)) => 1.
                          (setf len (length vals))
                          (when (plusp len)
			    (dotimes (i len)
                              (format t "~a" (nth i vals))
                              (if (< i (1- len)) (format t "~a" (print-multiple-value-between)))
                              ) ;; end dotimes
			    (terpri)
			    ) ;; end when

			  ;;
			  ;; (setf *package* (find-package :history-pkg)のように直接パッケージを
			  ;; 移動した際でも、移動先パッケージの外部、内部、継承シンボル情報を得る。
			  ;;
			  ;; [package-util]内のcd, pushd, popdなどを使用していれば
			  ;; [package-changed-by-util-p]は[t]を返す。使用していなければ[nil]のまま。
			  ;;
			  (when (and
				 (not (member (package-name *package*) (packages-exception-list)
					      :test #'string-equal))
				 (not (package-changed-by-package-util-p)) ;; pushd, popdなどで移動？
				 (string-not-equal
				  (package-name (last-package))
				  (package-name *package*) ;; パッケージが変化している。
				  )
				 ) ;; ==> in-packageなどで移動している。

			    (cd *package*) ;; パッケージが変化していれば移動し設定に従って情報を表示。
			    )		   ;; end when

                          ) ;; end let [入力をS式として評価する]

			(last-package *package*)
                        )     ;; end when
                      ) ;; end progn [unwinded-protect protected-form]

                 ;; 以下は、入力処理後、異常終了時にも必ず実行される[unwind-protect]の終了処理コード。
                 (finish-output)
                 (cooked-mode) ;; OS側のバッファリングあり、エコーありの入力モードに戻す。
                 ) ;; end unwind-protect

             ;;
             ;; handler-caseでエラーを補足した場合の処理。
	     ;;
	     ;; handler-caseはプロンプト表示後の入力と入力評価部分を監視している。
             ;;
             ;; 閉じカッコが足りないなど入力が不足している場合。エラーを含む入力も履歴に記録する。
             (end-of-file (c)
               (format *error-output* "~&end of file error(ex. less paren): ~a~%" c)
               (finish-output *error-output*)
               (history-pkg:add-str-to-hist input)
               )

             ;; 入力されたS式の後ろに余分な閉じカッコなどの入力がある。
             (too-many-input-error (c)
               (if (search ")" (the simple-string (error-garbage c)))
                   (format *error-output* "~&too many parenthesis: \'~a\'~%" (error-garbage c))
                   (format *error-output* "~&too many input: \'~a\'~%" (error-garbage c))
                   ) ;; end if
               (finish-output *error-output*)
               (history-pkg:add-str-to-hist input)
               )

             ;; 構文エラー。エラーを含む入力も履歴に記録する。
             (reader-error (c)
               (format *error-output* "~&syntax error: ~a~%" c)
               (finish-output *error-output*)
               (history-pkg:add-str-to-hist input)
               )

             ;; その他のエラーを捕捉し、デバッガを呼び出す。
             (error (c)
               (format *error-output* "~&General Error: ~a~%" c)
               (finish-output *error-output*)
               (break) ;; デバッガへ。
               )

             ) ;; end handler-case
           ) ;; end loop

      ;;=======================================================================================
      ;;
      ;; 以下は[history-repl]最上位のloopを囲む[unwind-protect]に対するエラー時に実行される終了処理。
      ;; すなわちrepl終了時の終了処理。
      ;;
      ;;=======================================================================================
      (history-pkg:write-history)
      (if (not (suppress-important-message))
          (format t "~&History saved to ~a~%" (history-file))
          )

      (record-editor-mode)

      (when (user-keymap-added-p)
        (line-edit-pkg:save-completion-dictionaries) ;; save completion info if added.
        (when (not (suppress-important-message))
          (format t "~&Completion dictionaries saved.~%")
          ) ;; end when
        )   ;; end when

      (exit-runtime)
      ;;====================================================================================
      ) ;; end unwind-protect
    )   ;; end let
  ) ;; end history-repl

#+ :build-as-packages (provide :history-repl)
