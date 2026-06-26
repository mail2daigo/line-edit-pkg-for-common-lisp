;;;
;;; last updated : 2026-06-25 09:28:41(JST)
;;;
;;; history-pkg.lsp: performs 'history', just like csh style.
;;;
;;
;;      for following examples, ">" means top-level prompt.
;;
;;      >!n                     re-do n'th history.
;;                              same as (do-history n).
;;      >!-n                    re-do current minus n'th history.
;;                              same as (do-history -n).
;;      >!!                     re-do last input. same as !-1.
;;                              same as (do-history) or (do-history -1).
;;      >!do m n                do history from m to n.
;;                              same as (do-history m n).
;;      >!history               print all history.
;;                              same as (history).
;;      >!hist n                print last n history.
;;                              same as (history n).
;;      >!h                     print (last-histories) history.
;;                              same as !hist (last-histories).
;;      >!r or !read            read history from file.
;;                              same as (read-history), not (restore-history).
;;      >!w or !write           write history to file.
;;                              same as (write-history).
;;      >!c or !clear           clear current history in memory, not a file.
;;                              same as (clear-history).
;;      >!edit                  edit and re-read history file.
;;                              same as (edit-history).
;;      >!ed n                  edit and eval n'th history.
;;                              same as (edit-history n).
;;      >!ed -n                 edit and eval current minus n'th history.
;;                              same as (edit-history -n).
;;      >!e                     edit and eval last history.
;;                              same as (edit-history -1).
;;      >!help                  print help message.
;;
;; un-keybinded-functions:
;;      (restore-history)               read history's history and history file.
;;      (reset-history)                 reset history # to 0, then read history.
;;      (history-size)                  returns current history buffer size.
;;      (history-size n)                set history buffer size to n.
;;      (history-with-number t)         print history with number (default).
;;      (history-with-number nil)       without number.
;;      (history-with-number)           returns current settings.
;;      (last-histories)                returns current number of prints.
;;      (last-histories n)              set default number of prints. see !h.
;;
;;      *NOTE*: "!edit family" uses function (invoke-favorite-editor ..) to invoke your editor.
;;
;; Copyright (C) 2000,2001-2026 Isao Daigo.
;;
;;              Version 0.1.0 : 2000-12-08 Implement almost all.
;;                      0.1.3 : 2000-12-20 Implement !edit family
;;                      0.2.0 : 2000-12-22 Implement !load
;;                      0.2.1 : 2000-12-23 Bug fix
;;                      0.3.0 : 2001-01-02 Can resize history buffer
;;                      0.4.3 : 2001-01-04 Delete !load & add (do-history m n).
;;                      0.5.0 : 2001-02-06 Add (history-with-number)
;;                      0.6.0 : 2001-05-08 Add !do
;;                      0.7.1 : 2001-05-19 Add (restore-history) & 1 bug fixed.
;;                      0.7.2 : 2001-06-23 1 bug fixed in (write-history).
;;                      0.8.0 : 2001-06-23 Add (last-live-history).
;;                      1.0.0 : 2025-12-25 package version.
;;
;; Licensed under GNU Library General Public License.
;;
;; ヒストリ・パッケージを利用するには処理系のトップレベル・ループ(repl)をhistory-pkg用の
;; replに変更する必要があります。そのための関数[history-repl]を定義してありますので、処理系
;; 起動後に、この[history-repl]を実行してください。処理系起動時のオプションで自動的に実行する
;; ように設定しておくと便利です。clispの場合は機能が衝突するのでreadlineライブラリを停止します。
;;
;; alias sbcl='/usr/local/bin/sbcl --noinform --load load-repl.lisp
;; alias clisp='/usr/bin/clisp -ansi -disable-readline -i load-repl.lisp -repl -on-error abort
;;

#+ :build-as-packages
(defpackage :history-pkg
  (:use :common-lisp)
  (:use :support-functions)
  (:use :print-color-string)
  (:use :package-util)
  (:export
   #:add-str-to-hist
   #:beginning-of-history       ;; M-< 最も古い履歴へ移動。
   #:clear-history
   #:current-history
   #:current-prompt-length
   #:do-history
   #:echo-history
   #:edit-history
   #:end-of-history             ;; M-> 最新の履歴に移動。
   #:invoke-favorite-editor
   #:get-hist
   #:goto-global-mark           ;; M-g x (グローバルマーク'x'に移動)
   #:goto-history               ;; 引数で指定された履歴番号に移動。
   #:incf-history-number
   #:help-history
   #:hist
   #:hist-buf
   #:hist-range-p
   #:history
   #:history-buffer
   #:history-count
   #:history-file
   #:history-functions
   #:history-number ;; = *hist-num*
   #:history-repl
   #:history-search-backward
   #:history-search-forward
   #:history-size
   #:history-version
   #:history-with-number
   #:last-histories
   #:last-live-history
   #:next-line                  ;; C-n 次の履歴に移動。連続移動可能。
   #:read-history
   #:reset-history
   #:restore-history
   #:previous-line              ;; C-p ひとつ前の履歴に移動。連続移動可能。
   #:set-global-mark            ;; C-u [num] M-m x (グローバルマーク'x’をセット)
   #:set-prompt-element
   #:get-prompt-string
   #:set-prompt-attributes
   #:get-prompt-attributes
   #:system-prompt
   #:write-history
   )
  )

#+ :build-as-packages
(in-package :history-pkg)

(declaim (optimize (safety 0) (speed 3) (space 0) (compilation-speed 0)))
;;(declaim (optimize (safety 3) (speed 0) (space 0) (compilation-speed 0)))

(defconstant +ESC+ #\^[)
(defconstant +str-space+ " ")
(defconstant +history-functions+
  '(do-history history read-history write-history clear-history edit-history))

;;
;; editable INITIAL values.
;;

(defparameter *hist-size* 1024  "history's ring buffer size")
(defparameter *number-of-prints* (min 25 *hist-size*))
(defparameter *history-version* "2025-10-25 Version 0.9.0")
(defparameter *favorite-editor* "vi")
;;(defparameter *history-file*   "~/.history.file") ;; [~]を正しく展開できるかは実装依存。
(defparameter *history-file* (concatenate 'string (home-directory-pathname-string) ".history.file"))
;;(defparameter *history-buffer* "~/.history.buffer")
(defparameter *history-buffer* (concatenate 'string (home-directory-pathname-string) ".history.buffer"))
(defparameter *echo-history* t "normaly t, then echo history")
(defparameter *no-echo* '(history ~edit-history help-history))
(defparameter *history-with-number* t)
(defparameter *prompt-elements* nil)
(defparameter *prompt-attributes* nil)

(defvar *hist-num* 0 "number of forms from Lisp system invoked")
(defvar *hist-pointer* 0 "buffer pointer: 0..(1- *hist-size*)")
(defvar *hist-buf* (make-array *hist-size* :initial-element nil))
(defvar *read-history* nil "already read history buffer?")
(defvar *count* 0)
(defvar *standard-readtable* (copy-readtable nil))
(defvar *last-prompt* nil)

(defun history-functions ()
  +history-functions+
  )

(defun all-element-p (item-list reference-list)
  "[item-list]の全ての要素が[reference-list]の要素であるかを調べる。"
  (dolist (s item-list)
    (when (not (print-color-string::member-by-symbol-name s reference-list))
      (return-from all-element-p nil)
      )
    )
  (return-from all-element-p t)
  ) ;; end all-element-p

(defun make-prompt (args)
  "Common Lispの対話ループで表示するプロンプト用のアトムとリストのリストを作って返す関数。

引数にはプロンプト構成指示子のリストを渡す。[set-prompt-element]関数でスペシャル変数
[*prompt-elements*]にプロンプト構成指示子のリストをセットしておき、対話ループで
関数[system-prompt]が都度、内容を評価することで、[:time24]や[:current-package]などの
最新状態が表示される。

最終的に指定したキーワード、文字列、文字列関数の返す文字列を結合して、ひとつの文字列として返す。

        :current-package
        :original-package-name
        :not-cl-user

の結果文字列は関数

        [px:set-package-name-case]

での設定に従う。
        > (px:set-package-name-case :downcase)
        > (px:set-package-name-case :upcase)
        > (px:set-package-name-case :capitalize)
        > (px:set-package-name-case nil)

それぞれ小文字化(:downcase)、大文字化(:upcase)、先頭のみ大文字(:capitalize)を意味する。[nil]は
処理系の設定に従うことを意味する(通常は大文字)。

 :current-package       カレント・パッケージ名(ニックネームがあれば、ニックネームを返す)。
 :original-package-name カレント・パッケージ名を返す。ニックネームがあってもオリジナル名を返す。
 :not-cl-user           cl-userパッケージでない場合のみパッケージ名を返す。
 :date                  今日のISOフォーマットでの日付(YYYY-MM-DD)。
 :time                  24時間フォーマットでの現在の時刻(HH:MM:DD)。
 :time12                12時間フォーマットでの現在の時刻(HH:MM{am,pm})。
 :absolute-dir          カレント・ディレクトリ(絶対パス)。
 :working-dir           カレント・ディレクトリ(相対パス)。
 :working-dir-name      カレント・ディレクトリ名のみ。
 :history-number        履歴番号。
 :os-type               OSの種類。
 :host-name             ホスト名/マシン名。
 :machine-type          CPUタイプ。
 :lisp-type             処理系名。
 :lisp-version          処理系のバージョン番号。
 :heap-size             使用しているヒープ領域のサイズ(MB)。sbclのみ。
 \"string\"             文字列。
 #'func                 関数funcの返す結果。
                        #'(lambda () print-color-string:chg-attr :color 'blue :bold t ...)を使うと
                        プロンプトの途中で文字色や文字属性を変更可能。

* (make-prompt :current-package)
\"cl-user\"
* (make-prompt :original-package-name)
\"common-lisp-user\"
* (make-prompt :not-cl-user)
\"\" <== カレント・パッケージが[cl-user]だった場合は空文字列。
* (make-prompt :date \" \" :time12)
\"2025-12-01 09:08pm\"
* (make-prompt :current-package)
\"COMMON-LISP-USER\"
* (make-prompt :date \" \" :time12)
\"2025-12-01 09:08pm\"
* (make-prompt :working-dir \" \" :working-dir-name)
\"~/Lisp/ Lisp\"
* (make-prompt :absolute-dir)
\"/home/daigo/Lisp/\"
* (make-prompt (format nil \"~a=~d\" \"(+ 2 3)\" (+ 2 3)))
\"(+ 2 3)=5\"
"
  (let ((result nil))

    (when (null args)
      (return-from make-prompt "")
      ) ;; end when

    (dolist (arg args)
      (cond ;; [package-name-case-convert]は関数[px:set-package-name-case]の設定に従って文字種を変換する。
        ((equal arg :original-package-name) ;; オリジナルのパッケージ名を返す。
         (push (package-name-case-convert (package-name *package*)) result)
         )
        ((equal arg :current-package) ;; カレント・パッケージの場合。
         (if (package-nicknames *package*) ;; ニックネームがあれば最短文字数のニックネーム。
             (push (package-name-case-convert (shortest-nickname *package*)) result)
             (push (package-name-case-convert (package-name *package*)) result)
             ) ;; end if
         )
        ;; カレント・パッケージが[common-lisp-user]でない場合のみパッケージ名を返す。
        ((equal arg :not-cl-user)
         (when (not (string-equal (package-name *package*) "common-lisp-user"))
           (push (package-name-case-convert (package-name *package*)) result)
           )     ;; end when
         )
        ((equal arg :date) ;; ISOフォーマットの日付文字列を返す。
         (push (iso-date-string) result)
         )
        ((equal arg :time) ;; ISOフォーマットの時刻文字列を返す(24時間制)。
         (push (iso-time-string) result)
         )
        ((equal arg :time12) ;; 12時間制の時刻文字列を返す。
         (push (time12-string) result)
         )
        ((equal arg :absolute-dir) ;; カレント・ディレクトリ名文字列を絶対パス形式で返す。
         (push (current-directory-pathname-string) result)
         )
        ((equal arg :working-dir) ;; カレント・ディレクトリ名文字列を相対パス形式で返す。
         (push (short-current-directory-pathname-string) result)
         )
        ((equal arg :working-dir-name) ;; カレント・ディレクトリ名文字列のみを返す。
         (push (first (last (split-string (current-directory-pathname-string) #\/ :remove-empty-p t)))
               result)
         )
        ((equal arg :history-number) ;; 履歴番号を返す。
         (push (history-pkg:history-number) result)
         )
        ((equal arg :os-type) ;; OSの種類を返す。
          (push (software-type) result)
         )
        ((equal arg :host-name) ;; ホスト名/マシン名を返す。
         (push (machine-instance) result)
         )
        ((equal arg :machine-type) ;; CPUタイプを返す。
         (push (machine-type) result)
         )
        ((equal arg :lisp-type) ;; Lisp処理系名を返す。
         (if (not (stringp (lisp-implementation-type)))
             (push (name-case-convert (string (lisp-implementation-type))) result)
             (push (name-case-convert (lisp-implementation-type)) result)
             ) ;; end if
         )
        ((equal arg :lisp-version) ;; Lisp処理系のバージョン番号を返す。
         (push (lisp-implementation-version) result)
         )
        #+ sbcl
        ((equal arg :heap-size)
         (push (format nil "~,1fMB" (/ (sb-kernel:dynamic-usage) 1024 1024)) result)
         )
        ((functionp arg) ;; 指定された関数を評価した結果を返す。結果の文字種変換の対象とはしない。
         (push (funcall arg) result)
         )
        ((stringp arg) ;; 指定された文字列をそのまま返す。
         (push arg result)
         )
        ) ;; end cond
      ) ;; end dolist
    (return-from make-prompt (reverse result))
    ) ;; end let
  ) ;; end make-prompt

(defun set-prompt-element (&rest args)
 " 指定できるプロンプト構成指示子は以下の通り。

 :current-package       カレント・パッケージ名(ニックネームがあれば、ニックネームを返す)。
 :original-package-name カレント・パッケージ名を返す。ニックネームがあってもオリジナル名を返す。
 :not-cl-user           cl-userパッケージでない場合のみパッケージ名を返す。ニックネームがあればニックネーム。
 :date                  今日のISOフォーマットでの日付(YYYY-MM-DD)。
 :time                  24時間フォーマットでの現在の時刻(HH:MM:DD)。
 :time12                12時間フォーマットでの現在の時刻(HH:MM{am,pm})。
 :absolute-dir          カレント・ディレクトリ(絶対パス)。
 :working-dir           カレント・ディレクトリ(相対パス)。
 :working-dir-name      カレント・ディレクトリ名のみ。
 :history-number        履歴番号。
 :os-type               OSの種類。
 :host-name             ホスト名/マシン名。
 :machine-type          CPUタイプ。
 :lisp-type             処理系名。
 :lisp-version          処理系のバージョン番号。
 \"string\"             文字列。
 #'func                 関数funcの返す結果。ただし引数なしの関数であること。
"
  (setf *prompt-elements* args)
  )

(defun get-prompt-string ()
  (return-from get-prompt-string *prompt-elements*)
  )

(defun set-prompt-attributes (&key (color 'blue color-sw) (bold nil bold-sw)
                                (italic nil italic-sw) (underline nil underline-sw)
                                (invert nil invert-sw) (strike nil strike-sw))
  (setf *prompt-attributes* nil)
  (when color-sw
    (pushnew (list :color color) *prompt-attributes*)
    )
  (when bold-sw
    (pushnew (list :bold bold) *prompt-attributes*)
    )
  (when italic-sw
    (pushnew (list :italic italic) *prompt-attributes*)
    )
  (when underline-sw
    (pushnew (list :underline underline) *prompt-attributes*)
    )
  (when invert-sw
    (pushnew (list :invert invert) *prompt-attributes*)
    )
  (when strike-sw
    (pushnew (list :strike strike) *prompt-attributes*)
    )

  (return-from set-prompt-attributes (reverse *prompt-attributes*))

  ) ;; end set-prompt-attributes

(defun get-prompt-attributes ()
  (return-from get-prompt-attributes *prompt-attributes*)
  )

(defun system-prompt ()
  (setf *last-prompt* (make-prompt *prompt-elements*))
  )

;;
;; Clear current history in memory, not a file.
;;
(defun clear-history ()
  (prog1
   (dotimes (i *hist-size* t)
            ;;(setf (aref *hist-buf* i) +eos+))
            (setf (aref *hist-buf* i) nil))
   (setf *count* 0)
   (setf *hist-num* 0)
   (setf *hist-pointer* 0)))

(defun history-version () *history-version*)

(defun current-prompt-length ()
  (setf *last-prompt* (system-prompt))
  (when (debug-print-p "current-prompt-length")
    (format t "current-prompt-length:*last-prompt*=~s~%" *last-prompt*)
    ) ;; end if
  (let ((total 0))
    (when (listp *last-prompt*)
      (dolist (p *last-prompt*)
        (cond
          ((stringp p)
           (incf total (length p)))
          ((numberp p)
           (incf total (length (write-to-string p))))
          ((characterp p)
           (incf total 1))
          (t nil)
          ) ;; end cond
        )   ;; end dolist
      )     ;; end when
    total
    ) ;; end let
  ) ;; end current-prompt-length

(defun add-str-to-hist (str)
  (setf (aref *hist-buf* (set-hist-pointer)) str))

(defmacro strcat (&rest str)
  (declare (string str))
  (cons 'concatenate (cons ''string str)))

(defun history (&optional m n) "print history"
  (cond
   ((null m)                            ;; all history
    (prt-hist (- *hist-num* *hist-size*) (1- *hist-num*)))
   ((null n)                            ;; Last m history
    (if (not (integerp m)) (history-error "Argument must be integer."))
    (prt-hist (- *hist-num* m) (1- *hist-num*)))
   ((not (and (integerp m) (integerp n)))
    (history-error "Argument must be integer."))
   (t (prt-hist m n))))                 ;; history from m to n

(defun prt-hist (m n)
  (declare (fixnum m n))
  (cond
   ((minusp m) (prt-hist2 0 n))
   (t (prt-hist2 m n))))

(defun prt-hist2 (m n &aux (fmt "") tmp) "print history m to n"
  (declare (fixnum m n) (string fmt))
  ;;(setf fmt (strcat "\~" (format nil "~d" (columns (1- *hist-size*))) ",\'0d:"))
  (setf fmt (concatenate 'string "\~" (format nil "~d" (columns (1- *hist-size*))) "d:"))
  (dolist (i (buf-index m n) t)
    (setf tmp (aref *hist-buf* (cdr i)))
    ;;(when (not (eq tmp +eos+))
    (when (not (eq tmp nil))
      (if (history-with-number) (format t fmt (car i)))
      (princ tmp)
      (terpri))))

(defun hist (stream char)
  (echo-hist (read-hist-exp stream char)))

;;(set-macro-character #\! #'hist)

(defun read-token-as-string (stream)
  (with-output-to-string (out)
    (do ((char (peek-char nil stream nil nil t) 
               (peek-char nil stream nil nil t)))
        ;; 終了条件: 文字がない、または空白文字である
        ((or (null char) 
             (member char '(#\Space #\Tab #\Newline #\Return)))
         nil) ; 戻り値（with-output-to-string が結果を返すので nil でよい）
      (write-char (read-char stream) out)
      ) ;; end do
    ) ;; end with-output-to-string
  ) ;; end read-token-as-string

(defun read-hist-exp (stream char &aux tmp i)
  (declare (ignore char))

  (if (eql (peek-char nil stream) #\!)  ;; 1文字先読み。
      (setf tmp (read-char stream))     ;; [tmp]は文字 #\!
      (setf tmp (read stream))          ;; [tmp]はシンボル/数値/文字列のいずれか。
      ) ;; end if

  ;; シンボルの場合は小文字の文字列に統一。
  (when (symbolp tmp) ;; 数値/文字/文字列は[nil]を返す。
    (setf tmp (string-downcase (symbol-name tmp)))
    )

  (cond
    ((eql tmp #\!)                      ;!!
     (~do-history -1)
     )
    ;; tmp が数値の場合の処理
    ((and
      (integerp tmp)
      (minusp tmp)
      )
     (~do-history tmp)                  ;!-n
     )
    ((and
      (integerp tmp)
      (hist-range-p tmp)
      )
     (~do-history tmp)                  ;!n
     )

    ;; 以下、文字列コマンドの処理。
    ((not (stringp tmp))
     (history-error "Invalid history command.~%")
     )
    ((string-equal tmp "do")            ;;!do m n
     `(do-history ,(read stream t nil t) ,(read stream t nil t))
     )
    ((string-equal tmp "history")       ;; !history
     '(history)
     )
    ((string-equal tmp "hist")          ;; !hist n
     `(history ,(read stream t nil t))
     )
    ((string-equal tmp "h")             ;; !h
     `(history ,*number-of-prints*)
     )
    ((or                                ;; !read or !r
      (string-equal tmp "read")
      (string-equal tmp "r")
      )
     '(read-history)
     )
    ((or                                ;; !write or !w
      (string-equal tmp "write")
      (string-equal tmp "w")
      )
     '(write-history)
     )
    ((or                                ;; !clear or !c
      (string-equal tmp "clear")
      (string-equal tmp "c")
      )
     '(clear-history)
     )
    ((string-equal tmp "edit")          ;; !edit
     '(edit-history)
     )
    ((string-equal tmp "ed")            ;; !ed n or !ed -n
     (setf i (read stream t nil t))
     (if (minusp i)
         (~edit-history (- *hist-num* (- i)))
         (~edit-history i)
         ) ;; end if
     )
    ((string-equal tmp "e")             ;; !e
     (~edit-history (1- *hist-num*))
     )
    ((string-equal tmp "help")          ;; !help
     '(help-history)
     )
    ((string-equal tmp "do")            ;; !do m n
     `(do-history ,(read stream t nil t) ,(read stream t nil t))
     )
    (t
     (history-error (format nil "Don't support \'\!~a\'." tmp))
     )
    )    ;; end cond
  ) ;; end read-hist-exp

(defun do-history (&optional m n &aux val)
  (cond
   ((null m)
    (eval (echo (~do-history -2))))
   ((not (integerp m))
    (history-error "Argument must be integer."))
   ((and (null n) (minusp m))
    (eval (echo (~do-history (1- m)))))
   ((and (null n) (>= m 0))
    (eval (echo (~do-history m))))
   (t (do ((i m (incf i))) ((> i n) t)
        (setf val (multiple-value-list (eval (echo (~do-history i)))))
        (dolist (i val)
          (princ #\space)
          (prin1 i))
        (terpri)))))

(defun ~do-history (n)
  (declare (fixnum n))
  (cond
    ((>= n 0)
     (string-to-form (aref *hist-buf* (get-hist n)))
     )
    ((minusp n)
     ;;(string-to-form (aref *hist-buf* (get-hist (- *hist-num* (- n)))))
     (string-to-form (aref *hist-buf* (get-hist (+ *hist-num* n))))
     )
    ) ;; end cond
  ) ;; end ~do-history

(defun invoke-favorite-editor (fname)
  (let ((absolute-fname (namestring (truename fname))))
    ;;(format t "absolute-fname=~s~%" absolute-fname)
    (support-functions:exec-command *favorite-editor* absolute-fname)
    ) ;; end let
  ) ;; end invoke-favorite-editor

(defun edit-history (&optional arg)
  (eval (echo (~edit-history arg))))

(defun ~edit-history (&optional arg)
  (cond
   ((null arg)
    (edit-history-file))
   ((integerp arg)
    (edit-nth-history arg))))

(defun edit-history-file ()
  (write-history)
  (invoke-favorite-editor *history-file*)
  (clear-history)
  (restore-history))

(defun edit-nth-history (n) "edit n'th history"
  (declare (fixnum n))
  (if (minusp n) (setf n (- *hist-num* (- n) 1)))
  (cond
   ((hist-range-p n)
    (write-to-buffer n)
    (invoke-favorite-editor *history-buffer*)
    (read-from-buffer))))

(defun string-to-form (str)
  (let ((*readtable* *standard-readtable*))
    (unless (stringp str) (return-from string-to-form nil))
    ;;(with-input-from-string (stream str) (read stream))
    (read-from-string str) ;; 「読み込んだオブジェクト」と「読み終えた位置」を返す多値関数。
    ) ;; end let
  ) ;; end string-to-form

(defun hist-range-p (n)
  (declare (fixnum n))
  (cond
    ((not (integerp n)) nil)
    ((minusp n) nil)
    ((and
      (< n *hist-num*)
      (>= n (- *hist-num* *hist-size*)))
     t)
    ) ;; end cond
  )

(defun history-number () *hist-num*)

(defun incf-history-number () (incf *hist-num*))

(defun set-hist-pointer ()
  (prog1
   (setf *hist-pointer* (mod *hist-num* *hist-size*))
   (history-count t)
   (incf-history-number)))

(defun history-count (&optional inc-p)
  (cond
   ((null inc-p) *count*)
   (t (setf *count* (min *hist-size* (1+ *count*))))))

(defun get-hist (num &aux tmp)
  (declare (fixnum num))
  (setf tmp (cdr (assoc num (current-buf))))
  (if (null tmp) (history-error "Bad history number.")
    (return-from get-hist tmp)
    ) ;; end if
  ) ;; end get-hist

(defun last-hist ()
  (the string (aref *hist-buf* (get-hist (1- *hist-num*)))))

#|
;;
;; here is sample data
;;
(add-to-history '(car '(a b)))
(add-to-history '(princ 'a))
(add-to-history '*hist-pointer*)
(add-to-history '*hist-buf*)
(add-to-history '(add-to-history '(cdr '(a b))))
(add-to-history '(floor 9 4))
(add-to-history '(history))

for example: (assume *hist-size* == 30)

 > (buf-index 25 35)
 ((25 . 25) (26 . 26) (27 . 27) (28 . 28) (29 . 29)
  (30 . 0) (31 . 1) (32 . 2) (33 . 3) (34 . 4) (35 . 5))
 > (buf-index2 25 35)
 (25 26 27 28 29 0 1 2 3 4 5)
 > (index-list 25 7)
 (25 26 27 28 29 0 1)
 >

|#

;;
;; Pentium III-700MHz/GCL 2.3.8-Beta
;;
;; > (time (dotimes (i 1000) (current-buf)))
;; real time : 4.580 secs
;; run time  : 4.560 secs
;;
;; (current-buf) == 4.580/1000 secs
;;
(defun current-buf ()
  (buf-index (- *hist-num* *hist-size*) (1- *hist-num*)))

(defun buf-index (m n)
  (declare (fixnum m n))
  (if (minusp m) (setf m 0))
  (mapcar 'cons (make-num-list m n) (buf-index2 m n)))

(defun make-num-list (m n &aux tmp)
  (declare (fixnum m n))
  ;(if (minusp m) (make-num-list 0 n))
  (do ((i n (decf i))) ((< i m) tmp)
      (push i tmp)))

(defun index-list (from n &aux tmp)
  (declare (fixnum from n))
  (dotimes (i n (reverse tmp))
           (push (mod (+ from i) *hist-size*) tmp)))

#|
where { m , n } should satisfy
        { 0 <= m <= n < *hist-num* } and { (n - m) < *hist-size* }
|#

(defun out-of-index (m n)
  (declare (fixnum m n))
  (cond ((or
          (minusp m)
          (> m n)
          (>= n *hist-num*)
          (>= (- n m) *hist-size*))
         t)
        ) ;; end cond
  )

(defun buf-index2 (m n)
  (declare (fixnum m n))
  (cond ;((minusp m) (buf-index2 0 n))
        ((out-of-index m n) nil)
        (t (index-list
            (- *hist-pointer* (- *hist-num* m 1))
            (1+ (- n m))))))

(defun hist-buf (n)
  (aref *hist-buf* n))

(defun history-file (&optional fname)
  (cond
   ((null fname)
    *history-file*)
   ((stringp fname)
    (setf *history-file* fname))
   ((pathnamep fname)
    (setf *history-file* (namestring fname)))))

;;
;; Read history from (history-file)
;;
(defun read-history ()
  (when (probe-file (history-file))
    (with-open-file (stream (history-file) :direction :input :if-does-not-exist nil)
      (let (tmp count eof)
        (setf *read-history* t)
        (setf count 0)
        (setf eof (cons nil nil))
        (loop
          (handler-case
              (progn
                (setf tmp (read stream nil eof))
                (when (eq tmp eof) (return count))
                (incf count)
                (add-str-to-hist tmp)
                ) ;; end progn
            (error (c)
              (message :history-pkg+read-history-001
                       "履歴ファイル~aの読み込み中にエラーが発生しました。~%" (history-file))
              (message :history-pkg+read-history-002
                       "履歴ファイルが壊れている可能性があります。カッコの対応などを確認してください。~%")
              (format t "~a~%" c)
              (support-functions:exit-runtime)
              )
            ) ;; end handler-case
          )   ;; end loop
        )     ;; end let
      )       ;; end with-open-file
    )         ;; end when
  ) ;; end read-history

(defun history-buffer (&optional fname)
  (cond
   ((null fname)
    *history-buffer*)
   ((stringp fname)
    (setf *history-buffer* fname))
   ((pathnamep fname)
    (setf *history-buffer* (namestring fname)))))

(defun read-from-buffer ()
  (when (probe-file *history-buffer*)
    (with-open-file (stream (history-buffer) :direction :input)
      (let (tmp eos)
        (setf eos (cons nil nil))
        (setf tmp (read stream nil eos))
        (if (eq tmp eos) nil tmp)))))

;;
;; Returns date & time in "YYYY/MM/DD HH:MM:SS"
;;
(defun simple-date ()
  (let (tmp)
    (setf tmp (multiple-value-list (get-decoded-time)))
    (format nil "~4d-~2,'0d-~2,'0d ~2,'0d:~2,'0d:~2,'0d"
            (sixth tmp) (fifth tmp) (fourth tmp)
            (third tmp) (second tmp) (truncate (first tmp)))))

(defun history-history ()       ;History's history
  (concatenate 'string (history-file) ".history"))

;;
;; Record history's history
;;      put *hist-num* and (history-count) with commented date & time
;;      such as "(2506 . 976) ;2001/05/19 16:59:27".
;;
(defun record-history ()
  (delete-file (history-buffer))
  (rename-file (history-history) (history-buffer))
  (with-open-file (out (history-history) :direction :output :if-does-not-exist :create :if-exists :supersede)
    (prin1 (cons *hist-num* (history-count)) out)
    (princ " ; " out)
    (princ (simple-date) out)
    (terpri out)
    (with-open-file (in (history-buffer) :direction :input :if-does-not-exist nil)
      (let (tmp eof)
        (setf eof (cons nil nil))
        (loop
          (setf tmp (read-line in nil eof))
          (when (eq tmp eof) (return t))
          (write-line tmp out)
          ) ;; end loop
        ) ;; end let
      ) ;; end with-open-file
    ) ;; end with-open-file
  ) ;; end record-history

(defun prinx (form &optional (stream *standard-output*))
  (write form :stream stream :escape t :pretty t))

;;
;; Write current on-memory history to (history-file)
;;
(defun write-history ()
  (record-history)
  (with-open-file
      (stream (history-file) :direction :output :if-exists :supersede :if-does-not-exist :create)
    (let (tmp num)
      (setf num 0)
      (dolist (i (current-buf) num)
        (setf tmp (aref *hist-buf* (cdr i)))
        ;;(when (not (eq tmp +eos+))
        (when (not (eq tmp nil))
          (incf num)
          (prinx tmp stream)
          (terpri stream))))))

(defun write-to-buffer (n) "write n'th history to buffer"
  (declare (fixnum n))
  (with-open-file (stream (history-buffer)
                          :direction :output :if-does-not-exist :create :if-exists :supersede)
    (let (tmp i)
      (setf i (assoc n (current-buf)))
      (setf tmp (aref *hist-buf* (cdr i)))
      (princ tmp stream)
      (terpri stream))))

(defun discardable (fname)
  (cond
   ((not (probe-file fname)) t) ;Is it there?
   (*read-history* t)           ;exist, and already read
   ((yes-or-no-p "Do not read history file yet, discard it?") t)))

(defun history-size (&optional size)
  "returns current history-size, or set to it"
  (cond
    ((null size)
     *hist-size*)
    ((or
      (not (integerp size))
      (zerop size))
     nil)
    ((discardable *history-file*)
     (write-history)
     (setf *hist-size* size)
     (setf *hist-buf* (make-array *hist-size*))
     (clear-history)
     (read-history))
    ) ;; end cond
  )

(defun restore-history ()
  (when (probe-file (history-history))
    (with-open-file (stream (history-history) :direction :input)
      (let (tmp)
        (setf tmp (read stream nil))
        (setf *hist-num* (- (car tmp) (cdr tmp)))
        (setf *hist-pointer* 0)
        ) ;; end let
      )   ;; end with-open-file
    )
  (read-history)
  )

;;
;; Reset history and read history file again.
;;
(defun reset-history ()
  (clear-history)
  (read-history))

(defun last-histories (&optional num)
  "set or return current default number of prints"
  (if (and (integerp num) (plusp num))
      (setf *number-of-prints* num)
      *number-of-prints*))

;;
;; 数値[num]を印字するのに必要な桁数を返す。
;;
(defun columns (num &aux col)
  (declare (fixnum num))
  (setf col 1)
  (loop
   (setf num (truncate num 10))
   (if (zerop num) (return col))
   (incf col)))

(defun echo (form &optional (is-echo *echo-history*))
  (when is-echo
    (write form :escape t :pretty t)
    (terpri))
  (return-from echo form))

(defun echo-hist (arg)
  (cond
    ((atom arg)
     (prog1 arg (echo arg))
     )
    ((member (car arg) *no-echo*)
     arg
     )
    (t
     (prog1 arg (echo arg))
     )
    ) ;; end cond
  ) ;; end echo-hist

(defun echo-history (&optional (arg nil s))
  "echo history if (echo-history t). (echo-history) returns current setting"
  (cond
   ((and (null arg) (null s)) *echo-history*)
   (t (setf *echo-history* arg))))
;;  (declare (ignore arg s))
;;  (format t "--- debug: echo-history called ---~%")
;;  t
;;  )

(defun history-error (msg)
  (cooked-mode)
  (princ (format nil "~%~a~%Type \'\!help\' for help.~%" msg))
  (break))

(defun history-with-number (&optional (n t sw))
  (cond
   ((null sw) *history-with-number*)
   (t (setf *history-with-number* n))))

;;
;; 引数には 探索する文字列とヒストリ番号を与える。与えられたヒストリ番号
;; より若い番号のヒストリを探索し、文字列が見つからなければ nil を、見つ
;; かれば((ヒストリ番号 . 配列番号) ポイント位置) を返す。
;;
(defun history-search-backward (str &optional hist-num)
  (declare (string str))
  (prog (nlist idx rev-lst pos (first-search nil))
     (when (null hist-num) ;; 履歴番号が[nil]ならば最新の履歴番号。
       (setf first-search t)
       (setf hist-num (1- *hist-num*)))
     (setf rev-lst (reverse (current-buf)))
     (setf pos (position hist-num rev-lst :test #'(lambda (x y) (= x (car y)))))
     (when (null pos) (return nil))
     (if first-search
         (setf nlist (nthcdr pos rev-lst))
         (setf nlist (nthcdr (1+ pos) rev-lst))
         ) ;; end if
     (if (null nlist)
         (return nil)
         ) ;; end if
     (dolist (i nlist nil)
       (setf idx (search str (aref *hist-buf* (cdr i))))
       (if (and (numberp idx) (zerop idx))
           (return-from history-search-backward (list i idx))
           ) ;; end if
       )     ;; end dolist
     )       ;; end prog
  ) ;; end history-search-backward

;;
;; 引数には 探索する文字列とヒストリ番号を与える。与えられたヒストリ番号
;; より古い番号のヒストリを探索し、文字列が見つからなければ nil を、見つ
;; かれば((ヒストリ番号 . 配列番号) ポイント位置) を返す。
;;
(defun history-search-forward (str &optional hist-num)
  (declare (string str))
  (prog (nlist idx lst pos)
     (if (null hist-num)
         (setf hist-num (1- *hist-num*))
         ) ;; end if
     (setf lst (current-buf))
     (setf pos (position hist-num lst :test #'(lambda (x y) (= x (car y)))))
     (when (null pos)
       (return nil)
       ) ;; end when
     (setf nlist (nthcdr (1+ pos) lst))
     (if (null nlist)
         (return nil)
         ) ;; end if
     (dolist (i nlist nil)
       (setf idx (search str (aref *hist-buf* (cdr i))))
       (if (and (numberp idx) (zerop idx))
           (return-from history-search-forward (list i idx))
           ) ;; end if
       )     ;; end dolist
     )       ;; end prog
  ) ;; end history-search-forward

;;
;; 現在のヒストリ番号と履歴が格納されている配列番号を
;; (ヒストリ番号 . 配列番号) の形式で返す。
;;
(defun current-history () (cons (1- *hist-num*) *hist-pointer*))

;;
;; ヒストリに記録されている最も古い有効なヒストリ番号と履歴が格納されて
;; いる配列番号を (ヒストリ番号 . 配列番号) の形式で返す。
;;
(defun last-live-history ()
  (prog (n pos lst)
    (setf n (- (car (current-history)) (1- (history-count))))
    (setf lst (current-buf))
    (setf pos (position n lst :test #'(lambda (x y) (= x (car y)))))
    (if (null pos) (error "cann't happen."))
    (return (car (nthcdr pos lst)))))

;;
;; へルプ・メッセージを表示する。
;;
(defun help-history () (princ
"
!n                      re-do n'th history.
                        same as (do-history n).
!-n                     re-do current minus n'th history.
                        same as (do-history -n).
!!                      re-do last input. same as !-1.
                        same as (do-history).
!do m n                 do history from m to n.
                        same as (do-history m n).
!history                print all history.
                        same as (history).
!hist n                 print last n history.
                        same as (history n).
!h                      print last histories.
                        same as (last-histories).
!r or !read             read history from file.
                        same as (read-history).
!w or !write            write history to file.
                        same as (write-history).
!c or !clear            clear current history, not a file.
                        same as (clear-history).
!edit                   edit and re-read history file.
                        same as (edit-history).
!ed n                   edit and eval n'th history.
                        same as (edit-history n).
!ed -n                  edit and eval current minus n'th history.
                        same as (edit-history -n).
!e                      edit and eval last history.
                        same as (edit-history -1).

un-keybinded-functions:
        (restore-history)       read history's history and history file.
        (reset-history)         reset history # to 0, then read history.
        (history-size)          returns current history buffer size.
        (history-size n)        set history buffer size to n.
        (last-histories)        returns current default number of prints.
        (last-histories n)      set default number of prints. see !h.
        (history-with-number t) print history with number (default).
        (history-with-number nil) without number.
        (history-file fname)    set history file to 'fname'.
        (history-file)          returns current history-file's name.
        (history-buffer fname)  set history's buffer to 'fname'.
        (history-buffer)        returns current history buffer's name.

        (help-edit)             show current editor mode commands.
")
 (return-from help-history t)
  ) ;; end defun

(eval-when (:load-toplevel :execute)
  (touch (history-history))
  (touch (history-buffer))
  (touch (history-file))
  )

#+ :build-as-packages (provide :history-pkg)
