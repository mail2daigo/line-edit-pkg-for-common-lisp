;;;
;;; last updated : 2026-06-21 10:38:05(JST)
;;;
;;; 機種依存関数とサポート用関数の定義
;;;

#+ :build-as-packages
(defpackage :support-functions
  (:use :common-lisp)
  (:nicknames :external-command :debug-print) ;; [:external-command]は過去の版との互換性確保用。
  (:export
   #:absolute-path
   #:assoc-by-symbol-name
   #:black-cursor               ;; ラッパー関数。(set-cursor-color-by-name 'black)と同じ。
   #:blue-cursor                ;; ラッパー関数。(set-cursor-color-by-name 'blue)と同じ。
   #:can-use-color-cursor       ;; カラー・カーソル機能の有無を[t/nil]で設定する関数。
   #:can-use-color-cursor-p     ;; カラー・カーソル機能の有無を返す関数。
   #:config-file-abs-path
   #:config-file-dir
   #:cooked-mode
   #:current-cursor-color-name  ;; returns one of color name or returns [nil].
   #:current-directory-pathname-string
   #:cursor-info-file-name      ;; カラー・カーソル機能の有無やカーソル色情報を記録するファイル名を返す関数。
   #:cyan-cursor                ;; ラッパー関数。(set-cursor-color-by-name 'cyan)と同じ。
   #:debug-print
   #:debug-print-p
   #:remove-debug-print-string	;; 引数で指定した文字列を[debug-print]の対象から削除する。
   #:elapsed-time
   #:exec-command
   #:exit-runtime
   #:extract-function
   #:find-current-and-home-dir
   #:getenv
   #:green-cursor               ;; ラッパー関数。(set-cursor-color-by-name 'green)と同じ。
   #:helpf                      ;; help function. (documentation 引数 'function)と同じ。
   #:home-directory-pathname-string
   #:iso-639-1-language-list    ;; ISO 639-1で定義されている第1主要言語の2文字略称と正式名のペアのリスト。
   #:iso-date-string            ;; ISO形式の現在日付を表す文字列を返す関数。
   #:iso-time-string            ;; ISO形式の現在時刻を表す文字列を返す関数。
   #:iso-timezone               ;; UTCとの時差。日本の場合UTC+9:00。
   #:less
   #:magenta-cursor             ;; ラッパー関数。(set-cursor-color-by-name 'magenta)と同じ。
   #:member-by-symbol-name
   #:message                    ;; Native-Language Message.
   #:message-list-changed-p     ;; メッセージ・リストが変更されていれば[t]。
   #:ml-message                 ;; MultiLingual Message.
   #:native-language            ;; ユーザの第1使用言語を返す関数。設定は[*native-language*]
   #:parse-dir
   #:print-multiple-value-between ;; 多値関数の戻り値を表示する際に、値と値の間に表示する文字を設定する。
   #:raw-mode
   #:read-registered-message    ;; メッセージ・リストが記録されたファイルを読み込む関数。
   #:record-color-cursor-info   ;; カラー・カーソル機能の有無と、挿入モード時のカー−ソル色の情報を記録する。
   #:red-cursor                 ;; ラッパー関数。(set-cursor-color-by-name 'red)と同じ。
   #:registered-message-file    ;; メッセージ・リストを保存するファイル名。
   #:registered-message-list    ;; メッセージ・リストを保持するリスト。
   #:reset-cursor-color         ;; カーソル色を標準色にリセットする関数。
   #:select-language            ;; 優先言語を設定する関数。
   #:selected-language          ;; 現在の優先言語を返す関数。
   #:set-cursor-color           ;; '(#xrr #xgg #xbb) ;; 全ての状況でカーソル色を即時変更する。
   #:set-cursor-color-by-name   ;; '(black red green yellow blue magenta cyan white) ;; 同上。
   #:set-cursor-color-for-insert-mode ;; 挿入モード時のカーソル色を設定する。
   #:shell
   #:short-current-directory-pathname-string
   #:split-string
   #:string-equal-by-symbol-name
   #:suppress-important-message
   #:test-can-use-color-cursor  ;; ユーザにカーソル色が変化するかを判断してもらう関数。
   #:time12-string              ;; 12時間形式での現在時刻をHH:MM:SS{am/pm}形式の文字列で返す関数。
   #:touch
   #:verbose-message
   #:what-language              ;; ISO 639-1の2文字の短縮言語名シンボルを受け取り、正式言語名シンボルを返す関数。
   #:white-cursor               ;; ラッパー関数。(set-cursor-color-by-name 'white)と同じ。
   #:write-registered-message   ;; メッセージ・リストを[(registered-message-file)]に書き出す関数。
   #:yellow-cursor              ;; ラッパー関数。(set-cursor-color-by-name 'yellow)と同じ。
   ) ;; end export
  ) ;; end defpackage

(declaim (optimize (safety 0) (speed 3) (space 0) (debug 0) (compilation-speed 0))) ;; maximum speed.
;;(declaim (optimize (safety 3) (speed 0) (space 0) (debug 3) (compilation-speed 0))) ;; maximum safety

(declaim (ftype (function (string &key (:ext t) (:dir t)) (values (or null simple-string) &optional))
                find-current-and-home-dir))
(declaim (ftype (function (t t) (or null list)) true-extract-function))
(declaim (ftype (function (symbol symbol (or stream boolean null) string &rest t) t) ml-message))
(declaim (ftype (function (symbol string &rest t) t) message))
;;(declaim (ftype (function (t t) (values list &optional)) support-functions:member-by-symbol-name))
;;(declaim (ftype (function (t t) list) member-by-symbol-name))
;;(declaim (ftype (function (string &key (:ext t) (:dir t)) (values (or null simple-string) &optional))
;;                find-current-and-home-dir))
;;(declaim (ftype (function (t t) (values list &optional)) member-by-symbol-name))
;;(declaim (ftype (function (t t) (values list &optional)) assoc-by-symbol-name))
;;(declaim (ftype (function (t t) (values boolean &optional)) string-equal-by-symbol-name))

#+ :build-as-packages
(in-package :support-functions)

(defconstant +languages-iso-639-1+
  '(
    (ab Abkhazian)
    (aa Afar)
    (af Afrikaans)
    (ak Akan)
    (sq Albanian)
    (am Amharic)
    (ar Arabic)
    (an Aragonese)
    (hy Armenian)
    (as Assamese)
    (av Avaric)
    (ae Avestan)
    (ay Aymara)
    (az Azerbaijani)
    (bm Bambara)
    (ba Bashkir)
    (eu Basque)
    (be Belarusian)
    (bn Bengali)
    (bi Bislama)
    (bs Bosnian)
    (br Breton)
    (bg Bulgarian)
    (my Burmese)
    (ca Catalan)
    (ch Chamorro)
    (ce Chechen)
    (ny Chichewa)
    (zh Chinese)
    (zh-hans Chinese) ;; 中国大陸で使われる簡体字。iso 639-1の規格外の記述。
    (zh-hant Taiwan)  ;; 台湾で使われる繁体字。同上。
    (cv Chuvash)
    (kw Cornish)
    (co Corsican)
    (cr Cree)
    (hr Croatian)
    (cs Czech)
    (da Danish)
    (dv Divehi)
    (nl Dutch)
    (dz Dzongkha)
    (en English)
    (eo Esperanto)
    (et Estonian)
    (ee Ewe)
    (fo Faroese)
    (fj Fijian)
    (fi Finnish)
    (fr French)
    (ff Fulah)
    (gl Galician)
    (ka Georgian)
    (de German)
    (el Greek)
    (Guaraní gn)
    (gu Gujarati)
    (ht Haitian)
    (ha Hausa)
    (he Hebrew)
    (hz Herero)
    (hi Hindi)
    (Hiri Motu ho)
    (hu Hungarian)
    (ia Interlingua)
    (id Indonesian)
    (ie Interlingue)
    (ga Irish)
    (ig Igbo)
    (ik Inupiaq)
    (io Ida)
    (is Icelandic)
    (it Italian)
    (iu Inuktitut)
    (ja Japanese)
    (jv Javanese)
    (kl Kalaallisut)
    (kn Kannada)
    (kr Kanuri)
    (ks Kashmiri)
    (kk Kazakh)
    (km Khmer)
    (ki Kikuyu)
    (rw Kinyarwanda)
    (ky Kirghiz)
    (kv Komi)
    (kg Kongo)
    (ko Korean)
    (ku Kurdish)
    (kj Kwanyama)
    (la Latin)
    (lb Luxembourgish)
    (lg Ganda)
    (li Limburgan)
    (ln Lingala)
    (lo Lao)
    (lt Lithuanian)
    (Luba-Katanga lu)
    (lv Latvian)
    (gv Manx)
    (mk Macedonian)
    (mg Malagasy)
    (ms Malay)
    (ml Malayalam)
    (mt Maltese)
    (mi Maori)
    (mr Marathi)
    (mh Marshallese)
    (mn Mongolian)
    (na Nauru)
    (nv Navajo)
    (ng Ndonga)
    (ne Nepali)
    (Norwegian Bokmål nb)
    (Norwegian Nynorsk nn)
    (no Norwegian)
    (ii Nuosu)
    (oc Occitan)
    (oj Ojibwa)
    (om Oromo)
    (or Oriya)
    (os Ossetian)
    (pa Panjabi)
    (Pāli pi)
    (fa Persian)
    (pl Polish)
    (ps Pashto)
    (pt Portuguese)
    (qu Quechua)
    (rm Romansh)
    (rn Rundi)
    (ro Romanian)
    (ru Russian)
    (sa Sanskrit)
    (sc Sardinian)
    (sd Sindhi)
    (Northern Sami se)
    (sm Samoan)
    (sg Sango)
    (sr Serbian)
    (gd Gaelic)
    (sn Shona)
    (si Sinhala)
    (sk Slovak)
    (sl Slovenian)
    (so Somali)
    (Southern Sotho st)
    (es Spanish)
    (su Sundanese)
    (sw Swahili)
    (ss Swati)
    (sv Swedish)
    (ta Tamil)
    (te Telugu)
    (tg Tajik)
    (th Thai)
    (ti Tigrinya)
    (bo Tibetan)
    (tk Turkmen)
    (tl Tagalog)
    (tn Tswana)
    (to Tonga)
    (tr Turkish)
    (ts Tsonga)
    (tt Tatar)
    (tw Twi)
    (ty Tahitian)
    (ug Uighur)
    (uk Ukrainian)
    (ur Urdu)
    (uz Uzbek)
    (ve Venda)
    (vi Vietnamese)
    (Volapük vo)
    (wa Walloon)
    (cy Welsh)
    (wo Wolof)
    (Western Frisian fy)
    (xh Xhosa)
    (yi Yiddish)
    (yo Yoruba)
    (za Zhuang)
    (zu Zulu)
    )
  )

(defparameter *shell* "bash") ;; or "csh" "zsh" ...
(defparameter *config-file-dir*
  (concatenate 'string (namestring (user-homedir-pathname)) ".config/line-edit/"))
(defparameter *config-file-dir-exist* nil)
(defparameter *config-file-ext* ".lisp")
(defparameter *cursor-info-file-name* "cursor-info")
(defparameter *registered-message-list* nil)
(defparameter *message-list-changed-p* nil)
(defparameter *registered-message-file* "registered-message-file.lisp")
(defparameter *selected-language* :ja)
(defparameter *native-language* :ja) ;; (message)関数に人間が書くメッセージ言語の設定。
(defparameter *debug-print* nil)
(defparameter *print-multiple-value-between* #\space)


(defun exit-runtime ()
  #+sbcl  (sb-ext:exit) ;; (sb-ext:quit)
  #+clisp (ext:exit)    ;; (ext:quit)
  #+gcl   (system:bye)  ;; (system:quit)
  (error "この処理系での終了方法が定義されていません。")
  )

(defun debug-print (&optional (arg t))
  "デバッグ・プリントを表示させるキーワード文字列を登録する関数。
引数に文字列または文字列のリストを指定すると、指定された文字列をデバッグ対象文字列に追加する。
結果として現在のデバッグ対象文字列のリストを返す。
引数に[nil]を指定するとキーワード文字列をリセットする。
引数を省略すると現在登録されているキーワード文字列を返す。
"
  (cond
    ((null arg)
     (setf *debug-print* nil)
     )
    ((and
      (stringp arg)
      (stringp *debug-print*)
      )
     (setf *debug-print* (list arg *debug-print*))
     )
    ((and
      (stringp arg)
      (listp *debug-print*)
      )
     (push arg *debug-print*)
     )
    ((and
      (listp arg)
      (every #'stringp arg)
      (listp *debug-print*)
      )
     (setf *debug-print* (append arg *debug-print*))
     )
    (t
     *debug-print*
     )
    )
  ) ;; end debug-print

;; デバッグ・プリント対象文字列として登録されているキーワード文字列から引数で指定された文字列を削除する。
(defun remove-debug-print-string (str)
  (if (null (find str *debug-print* :test #'string-equal))
      (return-from remove-debug-print-string nil)
      )
  (setf *debug-print* (remove str *debug-print* :test #'string-equal))
  ) ;; end remove-debug-print-string

(defun debug-print-p (&optional (args t))
  "引数として文字列、または文字列のリストを与える。
指定された文字列がスペシャル変数[*debug-print*]に設定されている文字列と等しいか、
または文字列のリストの要素の一部と等しければ[t]を返す。
引数を指定しない[=nil]と常に[t]を返す。
文字列または[nil]以外の値を指定すると常に[t]を返す。
"
  (cond
    ((null args)
     t)
    ((null *debug-print*)
     nil)
    ((and
      (stringp args)
      (stringp *debug-print*)
      )
     (string-equal args *debug-print*)
     )
    ((and
      (stringp args)
      (listp *debug-print*)
      (every #'stringp *debug-print*)
      )
     (member args *debug-print* :test #'string-equal)
     )
    ((and
      (listp args)
      (stringp *debug-print*)
      )
     (member *debug-print* args :test #'string-equal)
     )
    ((and
      (listp args)
      (every #'stringp args)
      (listp *debug-print*)
      (every #'stringp *debug-print*)
      )
     (intersection args *debug-print* :test #'string-equal)
     )
    ((identity args)
     t
     )
    ) ;; end cond
  ) ;; end debug-print-p

;; ラッパー関数
(defun helpf (function-name)
  (documentation function-name 'function)
  )

;; time-1 → time-2の経過時間(秒)
(defun elapsed-time (time-1 time-2)
  (/ (- time-2 time-1) internal-time-units-per-second)
  )

;;
;; 多値を出力する際に値と値の区切り文字を指定する。デフォルトは空白文字。良くあるのは#\Newline。
;; 引数が指定されていない場合は、現在の設定を返す。
;;
(defun print-multiple-value-between (&optional (ch #\Space sw))
  (cond
    ((null sw)
     *print-multiple-value-between*
     )
    ((characterp ch)
     (setf *print-multiple-value-between* ch)
     )
    (t
     (warn "print-multiple-value-between: Argument must be character.~%")
     *print-multiple-value-between*
     )
    ) ;; end cond
  ) ;; end print-multiple-value-between

(defun alist-p (list)
  "リストのすべての要素がコンスセルであり、連想リストの形式を満たしているか判定する。

(alist-p '((a . b) (c . d))) ; => T
(alist-p '(a b c))           ; => NIL (要素がシンボルであり、コンスセルではない)
(alist-p '((a . b) c))       ; => NIL (最後の要素 c がコンスセルではない)
(alist-p nil)                ; => T (空リストは有効なAlistであるため)
"
  (and (listp list)             ;; 引数がリストであり
       (every #'consp list)     ;; リスト内のすべての要素がコンスセルであること
       )
  )

;;
;; シンボルのパッケージが異なる場合でもシンボル名が一致するかどうかで判定する。
;;
(defun member-by-symbol-name (item lst)
  "ITEM（シンボル）がLISTの要素（シンボル）と名前が一致するかどうかを判定する。"
  ;;(declare (inline symbol-name string-equal))
  (if (not (symbolp item)) (return-from member-by-symbol-name nil))
  (member (symbol-name item) lst :key #'symbol-name :test #'string-equal)
  )

;;
;; シンボルのパッケージが異なる場合でもシンボル名が一致するかどうかで判定する。
;;
(defun assoc-by-symbol-name (item a-list)
  ;;(declare (inline symbol-name string-equal))
  (when (or (not (symbolp item)) (not (alist-p a-list)))
    (return-from assoc-by-symbol-name nil)
    ) ;; end when

  (assoc (symbol-name item) a-list :test #'string-equal :key #'symbol-name)
  )

;;
;; シンボルのパッケージが異なる場合でもシンボル名が一致するかどうかで判定する。
;;
(defun string-equal-by-symbol-name (sym-1 sym-2)
  (string-equal (symbol-name sym-1) (symbol-name sym-2))
  )

(defun find-by-symbol-name (arg seq)
  (let (p q)
    (setf p (symbol-name (car arg)))
    (setf q (symbol-name (cdr arg)))
    (find (cons p q) seq
          :key #'car :test #'(lambda (x y) (equal x (cons (symbol-name (car y)) (symbol-name (cdr y))))))
    ) ;; end let
  )

;;
;; (split-string "/bin:/usr/bin" #\:)   =>      ("bin" "/usr/bin")
;; (split-string "/usr/local/bin::/usr/bin" #\:) => ("/usr/local/bin" "" "/usr/bin")
;; (split-string "/usr/local/bin::/usr/bin" #\: :remove-empty-p t) => ("/usr/local/bin" "/usr/bin")
;;
(defun split-string (str delimiter &key (remove-empty-p nil))
  "strを指定された単一の文字delimiterで分割し、文字列のリストを返す。
   :remove-empty-p が t の場合、空文字列は結果から除外する。"
  (declare (type string str)
           (type character delimiter))
  (let (start pos result)
    (setf start 0)
    (setf result nil)
    (loop
      (setf pos (position delimiter str :start start)) ; デリミタの位置を検索
      (push (subseq str start (or pos (length str))) result) ;; 部分文字列をリストに追加。
      (if (null pos) (return result)) ; デリミタが見つからなければループを終了
      (setf start (1+ pos)) ; 次の検索開始位置をデリミタの次の文字に設定
      )                     ;; end loop
    ;; 収集した結果を post-process
    (return-from split-string
      (reverse
       (if (identity remove-empty-p)
           ;; :remove-empty-p が T の場合は、空文字列を除外
           (remove-if #'(lambda (s) (string= s "")) result)
           ;; そうでなければそのまま返す
           result)
       ) ;; end reverse
      )  ;; end return-from
    )    ;; end let
  ) ;; end split-string

;;
;; 指定された実行可能ファイルが[PATH]環境変数内に存在するなら絶対パスを加えたファイル名を返す。
;; [:exec-p t]を加えて呼び出すと実行可能性もチェックする。
;;
(defun absolute-path (fname &key (pathname-object nil) (current-dir-first nil) (exec-p t))
  "PATH環境変数を使用してファイルの絶対パスを検索して返す。ファイルが存在しなければ[nil]を返す。
キーワード[pathname-object]に[t]を与えて呼び出すとパス名オブジェクト形式で返す。
そうでないならパス名文字列を返す。

キーワード[current-dir-first]に[t]を与えて呼び出すと、PATH環境変数に登録されたディレクトリを
探す前にカレント・ディレクトリからプログラムを探す。

キーワード[exec-p]に[nil]を与えて呼び出すと実行可能かどうかのチェックを行わない。デフォルトは[t]。
\"/usr/bin/less\"
[2] (absolute-path \"less\" :pathname-object t)
#P\"/usr/bin/less\"
[3] (absolute-path \"less\" :current-dir-first t)
nil
"
  (let* ((path-string (getenv "PATH"))
         ;; PATHをコロンで分割してディレクトリのリストを作成
         (directories (when path-string (split-string path-string #\:)))
         )
    (when current-dir-first
      (push (current-directory-pathname-string) directories)
      )
    (dolist (dir directories)
      (let* ((full-path
               (merge-pathnames
                (make-pathname :name fname)
                (parse-dir (concatenate 'string dir "/"))
                )
               )
             (full-path-string (namestring full-path))
             )
        ;; ファイルが存在するかを確認
        (when
            (and ;; ファイルが存在し、かつ実行可能形式かを調べる。
             (probe-file full-path)
             (when exec-p
               #+sbcl (sb-unix:unix-access (sb-ext:native-namestring full-path) sb-unix:x_ok)
               #+clisp (null (ext:shell (format nil "test -x ~A" full-path-string)))
               #+gcl (system::file-test 1 full-path)
               ) ;; end when
             ) ;; end and
          (return-from absolute-path
            (cond
              ((identity pathname-object)
               full-path ;; [pathname-object]が[nil]ならパス名オブジェクト形式で返す。
               )
              (t
               full-path-string) ;; そうでないならパス名文字列を返す。
              )                  ;; end cond
            )
          ) ;; end when
        )   ;; end let*
      )     ;; end dolist
    (return-from absolute-path nil)
    ) ;; end let*
  ) ;; end absolute-path

;; Linuxのコマンドを呼び出す。
(defun exec-command (command &rest params)
  (let (cmd)
    (declare (type string command))
    (setf cmd (absolute-path command :exec-p t))
    (when (null cmd) ;; 存在し実行可能か？
      (message :support-functions+exec-command-001 "実行可能なコマンド(~a)は存在しませんでした。~%" command)
      (return-from exec-command nil)
      )
    ;;#+ clisp (ext:run-program cmd :arguments params :wait t)
    #+ clisp (if (string= command "sh")
                 ;; sh -c が呼ばれた場合は、引数をそのまま渡す
                 (ext:run-program "sh" :arguments params :wait t)
                 ;; それ以外の通常のコマンド呼び出し（dotなど）の場合
                 (ext:run-program cmd :arguments params :wait t))
    #+ sbcl  (sb-ext:run-program cmd params :input t :output t :error nil :wait t) 
    #+ gcl   (system (concatenate 'string cmd " " (string-list-to-string params)))
    )
  )

;;;
;;; バッファリングなし、エコーなしの入力モードにする。
;;;
(defun raw-mode ()
  (exec-command "stty" "-echo" "raw")
  )

;;;
;;; バッファリングあり、エコーありの入力モードに戻す。
;;;
(defun cooked-mode ()
  (exec-command "stty" "sane")
  )

;; 環境変数[env-var]の値を取得する。
#+ clisp (defun getenv (env-var) (ext:getenv env-var))
#+ sbcl  (defun getenv (env-var) (sb-ext:posix-getenv env-var))
#+ gcl   (defun getenv (env-var) (si:getenv env-var))

;; パス名文字列を受け取りCommon Lispのpathnameオブジェクトに変換する。
#+ sbcl  (defun parse-dir (dir) (parse-namestring dir))
#+ clisp (defun parse-dir (dir) (parse-namestring dir))
#+ gcl   (defun parse-dir (dir) (pathname dir)) ;; GCLはpathnameで対応可能

;; ホーム・ディレクトリ文字列を返す。
(defun home-directory-pathname-string ()
  "returns such as /home/daigo/"
  #+ clisp (namestring (user-homedir-pathname))
  #+ sbcl  (namestring (user-homedir-pathname))
  #+ gcl   (namestring (user-homedir-pathname))
  ;;#+ gcl   (si::getenv "HOME")
  )

;; カレント・ディレクトリ文字列を返す。
(defun current-directory-pathname-string ()
  "returns such as /home/daigo/Lisp/"
  #+ clisp (namestring (ext:default-directory))
  #+ sbcl  (namestring (truename "."))
  #+ gcl   (si::get-working-directory)
  )

(defun short-current-directory-pathname-string ()
  "
(split-string (current-directory-pathname-string) #\/ :remove-empty-p t)
        ==> (\"home\" \"daigo\" \"Lisp\" \"support-functions\")
(split-string (namestring (user-homedir-pathname)) #\/ :remove-empty-p t)
        ==> (\"home\" \"daigo\")

(short-current-directory-pathname-string)
        ==> \"~/Lisp/support-functions/\"
"

  (let (current-dir-path-list home-dir-path-list (result nil))
    (setf current-dir-path-list (split-string (current-directory-pathname-string) #\/ :remove-empty-p t))
    (setf home-dir-path-list (split-string (namestring (user-homedir-pathname)) #\/ :remove-empty-p t))

    (when (not (string-equal (first current-dir-path-list) (first home-dir-path-list)))
      (return-from short-current-directory-pathname-string (current-directory-pathname-string))
      ) ;; end when

    (loop
      (if (string-equal (first current-dir-path-list) (first home-dir-path-list))
          (progn
            (pop current-dir-path-list)
            (pop home-dir-path-list)
            ) ;; end progn
          (progn
            (dolist (s (reverse current-dir-path-list)) ;; (reverse '("Lisp" "ext"))
              (push "/" result) ;; ("/") => ("/" "ext" "/")
              (push s result)   ;; ("ext" "/") => ("Lisp" "/" "ext" "/")
              )
              (push "~/" result) ;; ("~/" "Lisp" "/" "ext" "/")
            (return-from short-current-directory-pathname-string
              (format nil "~{~a~}" result))
            )   ;; end progn
          )     ;; end if
      )         ;; end loop
    )           ;; end let
  ) ;; end short-current-directory-pathname-string

(defun ends-with-slash-p (path-string)
  "文字列path-stringがスラッシュで終わるか判定する。"
  (declare (type string path-string))
  (let ((len (length path-string)))
    (and (> len 0)                     ; 文字列が空でないことを確認
         (char= #\/ (char path-string (1- len)))))) ; 末尾の文字が #\/ かをチェック

;;
;; UNIXのtouchコマンドと同じ。指定したファイルが存在しなければ作成し、存在すればタイム・スタンプだけを更新する。
;;
(defun touch (path)
  (with-open-file (stream path :direction :output :if-exists :append :if-does-not-exist :create)
    (declare (ignore stream))
    ) ;; 何も書き込まない
  path
  ) ;; end touch

;;
;; 引数で指定したパスのディレクトリが存在するか否かを返す。
;;
(defun directory-exists-p (path)
  (let (abs-path)
    (cond
      ((string= path ".")
       (setf abs-path (current-directory-pathname-string))
       )
      ((string= path "~")
       (setf abs-path (home-directory-pathname-string))
       )
      (t
       (setf abs-path path)
       )
      ) ;; end cond
    #+clisp (ignore-errors (ext:probe-directory abs-path))
    #+sbcl  (and (probe-file abs-path)
                 (null (pathname-name (probe-file abs-path))))
    #+gcl   (not (null (si:stat abs-path)))
    #-(or clisp sbcl gcl) (ignore-errors (probe-file abs-path))
    ) ;; end let
  )

(defun find-current-and-home-dir (fname &key ((:ext extension) nil) ((:dir directory) nil))
  "[extension]が文字列のときは、指定されたファイル名に[extension]で指定された拡張子を付加して
カレント・ディレクトリ→ホーム・ディレクトリの順に指定されたファイルを探し絶対パス名を返す。

[:dir]が指定されていた場合は、まず[:dir]で指定されたディレクトリを探し、次にカレント・ディレクトリ
→ホーム・ディレクトリの順に指定されたファイルを探し、絶対パスを返す。

[extension]が文字列のリストのときはリストに指定された順序に拡張子を付加してファイルを
探して絶対パス名を返す。存在しなければ[nil]を返す。

[3]> (find-current-and-home-dir \"test\" :ext (list \".fasl\" \".lisp\"))

カレント・ディレクトリの\"test.fasl\" --> ホーム・ディレクトリの\"test.fasl\"の順に探し、
見つからなければ次に、カレント・ディレクトリの\"test.lisp\" --> ホーム・ディレクトリの\"test.lisp\"
の順に探す。つまり、指定された拡張子の順にカレント・ディレクトリ --> ホーム・ディレクトリの順に探す。
"
  (let ((current-dir nil) (home-dir nil) (user-dir nil))

    (cond
      ((not (stringp fname))
       (return-from find-current-and-home-dir nil) ;; [nil]を返して終わり。
       )
      ((stringp extension)
       nil ;; 継続処理。
       )
      ((not ;; [extension]が全てが文字列からなるリストでないなら[nil]。
        (and
         (listp extension)
         (every #'stringp extension)
         )
        )
       (return-from find-current-and-home-dir nil) ;; [nil]を返して終わり。
       )
      ) ;; end cond

    ;; 指定されたディレクトリの末尾が"/"で終わっていなければ付加する。
    (when (and directory (stringp directory) (not (ends-with-slash-p directory)))
      (setf directory (concatenate 'string directory "/"))
      )

    ;; 指定されたディレクトリ[directory]が存在するなら、最初に探すべきディレクトリとして設定。
    (when (and (identity directory) (stringp directory)
               ;;(ignore-errors (probe-file (parse-namestring directory)))
               (directory-exists-p directory)
               )
      (setf user-dir directory)
      ) ;; end when

    (setf current-dir (current-directory-pathname-string))
    (setf home-dir    (namestring (user-homedir-pathname)))
    ;;(format t "current-dir=~s~%home-dir=~s~%" current-dir home-dir)

    ;; 拡張子指定がない場合（extensionがnil）の処理
    ;; extensionがない場合、ファイル名そのままを指定ディレクトリ→カレント→ホームの順に探す
    (when (null extension)
      (dolist (s (list user-dir current-dir home-dir))
        ;;(when (identity s) ;; [user-dir], [home-dir]は[nil]の場合があり得る。
        (when s ;; [user-dir], [home-dir]は[nil]の場合があり得る。
          (let ((full-path (concatenate 'string s fname)))
            (when (probe-file full-path)
              ;;(return-from find-current-and-home-dir (namestring (probe-file full-path)))
              (return-from find-current-and-home-dir full-path)
              )                                   ;; end when
            )                                     ;; end let
          )                                       ;; end when
        )                                         ;; end dolist
      (return-from find-current-and-home-dir nil) ;;指定されたファイルが存在しなかった。
      )

    ;; 単一の拡張子だけが指定された(文字列のみ)場合の処理。
    (when (stringp extension)
      (dolist (s (list user-dir current-dir home-dir)) ;; [user-dir], [home-dir]は[nil]の場合があり得る。
        ;;(when (and (identity s) (probe-file (concatenate 'string s fname extension)))
        (when (and s (probe-file (concatenate 'string s fname extension)))
          (return-from find-current-and-home-dir
            ;;(namestring (probe-file (concatenate 'string s fname extension))))
            (concatenate 'string s fname extension))
          )                                       ;; end when
        )                                         ;; end dolist
      (return-from find-current-and-home-dir nil) ;;指定されたファイルが存在しなかった。
      )

    ;; 複数の拡張子が文字列のリストで指定されていた場合の処理。
    ;; 指定された拡張子から順に、カレント・ディレクトリ→ホーム・ディレクトリの順に探す。
    (when (listp extension)
      (dolist (ext extension) ;; 全てのリストの要素が文字列からなることは確認済み。
        (dolist (s (list user-dir current-dir home-dir))
          ;;(when (and (identity s) (probe-file (concatenate 'string s fname ext)))
          (when (and s (probe-file (concatenate 'string s fname ext)))
            (return-from find-current-and-home-dir
              ;;(namestring (probe-file (concatenate 'string s fname ext))))
              (concatenate 'string s fname ext))
            )
          ) ;; end dolist
        )   ;; end dolist
      )
    ;;(return-from find-current-and-home-dir nil) ;; 指定されたファイルが存在しなかった。
    ) ;; end let
  (return-from find-current-and-home-dir nil)
  ) ;; end find-current-and-home-dir

(defun config-file-dir ()
  *config-file-dir*
  )

;;
;; ファイル名[fname]に拡張子があるかどうかを調べる。
;;
(defun with-file-ext-p (fname)
  (find "." fname :from-end t :test #'string=)
  ) ;; end with-file-ext-p

;;
;; 設定用ディレクトリが存在しなければ作成し、[fname]で指定された設定用ファイルの絶対パス名を返す。
;; [fname]の拡張子がなければ、[*config-file-ext*]で定義された値を付加する。
;;
(defun config-file-abs-path (fname)
  (let ((abs-fname ""))
    (if (with-file-ext-p fname) ;; 拡張子があるかチェック。
        (setf abs-fname (concatenate 'string *config-file-dir* fname))
        (setf abs-fname (concatenate 'string *config-file-dir* fname *config-file-ext*))
        ) ;; end if
    (when (null *config-file-dir-exist*)
      (ensure-directories-exist abs-fname)
      (setf *config-file-dir-exist* t)
      ) ;; end when
    abs-fname
    ) ;; end let
  ) ;; end config-file-abs-path

(defun shell (&optional (shell-name nil) (keep-new-shell t))
  "指定されたシェルを起動する。指定がなければ現在のシェルを起動する。
指定されたシェルが実行可能な場合は起動するシェルを指定されたシェルに切り替える。
第２引数に[nil]を指定すると起動シェルの切り替えを記憶しない。
[3]> (shell)
 指定されたシェルが実行可能なパスに存在しなければエラー・メッセージを表示して[nil]を返す。"
  (let (result is-exist)
    (when shell-name ;; 起動するシェルが指定されていた場合は実行可能かチェック。
      (setf is-exist (absolute-path shell-name))
      )
    (cond
      ((and ;; 起動シェルが指定されていて実行可能で、起動シェルの変更を記憶する。
        shell-name
        is-exist
        keep-new-shell
        )
       (setf result (change-shell shell-name))
       (if (null result) (return-from shell nil))
       (pure-shell result)
       )
      ((and ;; 起動シェルが指定されていて実行可能で、起動シェルの変更を記憶しない。
        shell-name
        is-exist
        (null keep-new-shell)
        )
       (pure-shell shell-name)
       )
      ((and ;; 起動シェルが指定されておらず現在の起動シェルが実行可能で、それを記憶する。
        (null shell-name)
        (absolute-path *shell*)
        keep-new-shell
        )
       (pure-shell *shell*)
       )
      ((and ;; 起動シェルが指定されておらず現在の起動シェルが実行可能で、それを記憶しない。
        (null shell-name)
        (absolute-path *shell*)
        (null keep-new-shell)
        )
       (format t "warning: 新たな起動シェルが指定されていないため現在の起動シェルを変更しません。~%")
       (pure-shell *shell*)
       )
      ) ;; end cond
    )   ;; end let
  )

(defun pure-shell (shell-name)
  #+clisp (ext:shell (absolute-path shell-name))
  #+sbcl (sb-ext:run-program (absolute-path shell-name) nil :input t :output t :error t :wait t) 
  #+ gcl (system shell-name)
  )

(defun change-shell (&optional (shell-name nil))
"関数[shell]で起動するシェルを引数で指定されたシェルに切り替える。
[3]> (change-shell \"bash\")
引数が指定されなければ現在設定されているシェル名を返す。
指定されたシェルが実行可能なパスに存在していなければメッセージを表示して[nil]を返す。"
  (let (shell)
    (when (null shell-name) (return-from change-shell *shell*)) ;; 引数なしで呼び出すと現在のシェル名を返す。

    (setf shell (absolute-path shell-name)) ;; 実行可能なパスに存在するかチェック。
    (cond
      ((null shell)
       (format t "指定されたシェル(~a)は実行可能なパスに存在しませんでした。~%" shell-name)
       (format t "現在のシェル設定(~a) は変更されていません。~%" (absolute-path *shell*))
       (return-from change-shell nil)
       )
      (t
       (setf *shell* shell-name)
       )
      ) ;; end cond
    )   ;; end let
  )

#|
(defun less (&rest fname)
  (format t "(less ~s)~%" fname)
  #+ gcl (system (concatenate 'string "less" (string-list-to-string fname)))
  ;;#+ clisp (ext:run-program (absolute-path "less") :arguments fname :input t :output t :wait t)
  #+ clisp
  (ext:run-program (absolute-path "less") :arguments fname :input :terminal :output :terminal :wait t)
  #+ sbcl (sb-ext:run-program (absolute-path "less") fname :input t :output t :error t :wait t) 
  )
|#

(defun less (fname)
  (format t "(less ~s)~%" fname)
  (exec-command "less" fname)
  )

(defun string-list-to-string (lst)
  (let (result)
    (setf result nil)
    (dolist (s lst)
      (push s result)
      )
    (reverse result)
    )
  )

(defun cursor-info-file-name ()
  *cursor-info-file-name*
  )

(defun iso-date-string ()
  (let (tmp)
    (setf tmp (multiple-value-list (get-decoded-time)))
    (format nil "~4d-~2,'0d-~2,'0d" (sixth tmp) (fifth tmp) (fourth tmp))
    )
  )

(defun iso-time-string ()
  (let (tmp)
    (setf tmp (multiple-value-list (get-decoded-time)))
    (format nil "~2,'0d:~2,'0d:~2,'0d" (third tmp) (second tmp) (truncate (first tmp)))
    )
  )

;; UTCとの時差
(defun iso-timezone ()
  (- (nth 8 (multiple-value-list (get-decoded-time))))
  )   ;; end iso-timezone

(defun time12-string ()
  (let (tmp (am-pm nil))
    (setf tmp (multiple-value-list (get-decoded-time)))
    (if (> (third tmp) 12)
      (setf am-pm 'pm)
      (setf am-pm 'am)
      )
    (if (equal am-pm 'am)
        (format nil "~2,'0d:~2,'0dam" (third tmp) (second tmp))
        (format nil "~2,'0d:~2,'0dpm" (- (third tmp) 12) (second tmp))
        )
    )
  )

;;;
;;; カーソルの色を変えるための関数群の定義。
;;;
;;;     使用できるとは限らない機能なので用意したテスト用関数(test-osc-rgb)
;;;     を実行して可否を判断してから使用する。
;;;
(let* (
       ;;(tmp 0)
       (can-use-color-cursor t)
       (cursor-color-for-insert-mode nil)
       (black '(#x00 #x00 #x00))
       (red '(#xff #x00 #x00))
       (green '(#x00 #xff #x00))
       (yellow '(#xff #xff #x00))
       (blue '(#x00 #x00 #xff))
       (magenta '(#xff #x00 #xff))
       (cyan '(#x00 #xff #xff))
       (white '(#xff #xff #xff))
       (color-list
         (list
          (list 'black black)
          (list 'red red)
          (list 'green green)
          (list 'yellow yellow)
          (list 'blue blue)
          (list 'magenta magenta)
          (list 'cyan cyan)
          (list 'white white)
          )
         )
       (rgb-color-list
         (list
          (list 'red red)
          (list 'green green)
          (list 'blue blue)
          )
         )
       )

  (defun test-can-use-color-cursor ()
    (let (
          (result nil)
          (tmp nil)
          )
      ;; 設定ファイルが存在していなければ作成する。存在していれば何もせずに終了する。
      ;;(setf tmp (config-file-abs-path (cursor-info-file-name)))
      ;;(if (probe-file tmp)
      ;;    (return-from test-can-use-color-cursor nil) ;; ファイルが存在しているならチェック済み。
      ;;    (touch tmp)
      ;;    )   ;; end if

      (message :support-functions+test-can-use-color-cursor-007
"Operationg System Command(OSC)が有効な場合にカーソルの色を変えることができます。

しかし、OSCは規格ではないので確実に機能の有無を調べる方法はなく、機械的な検査では推測の域を出ません。

そのため、ユーザ自身に機能の有無を確認してもらうために端末上のカーソル色を変えるテストを行います。
標準的な方法でカーソルの色を変える操作を行いますので

        *** 色が変化しているのを認めたら[yes]と回答して下さい。***

端末の表示が乱れたり、クラッシュした場合は端末ソフトを終了して、端末ソフトを起動し直して下さい。
その場合は設定用ディレクトリ[~~/.config/line-edit/]に中身のない[cursor-info.lisp]という
ファイルを用意して下さい。
        $ touch ~~/.config/line-edit/cursor-info.lisp
で作れます。このファイルがあると以後、カーソルをカラーで表示する機能に関する質問は行いません。

※ カーソルをカラー指定する機能なども無視されます。有効にするにはLispセッション内で
        > (can-use-color-cursor t)
としますが、カーソルをカラー化する機能がない端末では画面表示が乱れる可能性があります。")

      (message :support-functions+test-can-use-color-cursor-008
               "...ではカーソルの色が変更できるかどうか赤・緑・青の3原色についてテストを行います。~%")

      (setf result nil)
      (dolist (p rgb-color-list)
        (set-cursor-color (second p))
        (setf tmp (ml-message :support-functions+test-can-use-color-cursor-001 :ja nil
                              "カーソル色は ~a です。変化を認めますか？"
                              (string-downcase (symbol-name (first p)))))
        (push (yes-or-no-p tmp) result)
        ) ;; end dolist

      (reset-cursor-color)

      ;;(format t "result=~s~%" result)

      (when (some #'identity result)
        (terpri)
        (message :support-functions+test-can-use-color-cursor-002
                 "#\Tab*** カーソルをカラー表示する機能が使えます。 ***~%")
        (can-use-color-cursor t)
        ) ;; end when


      (message :support-functions+test-can-use-color-cursor-003
               "~%関数[set-cursor-color]を使えば (set-cursor-color '(#xff #x00 #x00))のようにRGBの要素それぞれを最大16ビットで指定できます(表現できる色数は端末の表示能力の範囲内です)。

本ソフトでは利便性を考えて black, red, green, yellow, blue, magenta, cyan, white の8色をシンボル名で指定できます。

        (set-cursor-color-by-name 'green)
は
        (set-cusor-color '(#x00 #xff #x00))

と同じです。~%")

      (loop
        (message :support-functions+test-can-use-color-cursor-004
                "~%挿入モード時のカーソル色を以下から番号で選んで下さい。~%")

        (dotimes (i (length color-list))
          (format t "~02d) ~a~%" (1+ i) (string-capitalize (symbol-name (first (nth i color-list)))))
          ) ;; dotimes

        (format t "Enter : ")
        (finish-output)
        (setf tmp (read))

        (if (and (<= 0 tmp) (<= tmp (1+ (length color-list))))
            (return) ;; exit loop.
            (message :support-functions+test-can-use-color-cursor-005
                "1-~dの範囲の番号を入力して下さい。~%" (1+ (length color-list)))
            ) ;; end if
        )     ;; end loop

      (set-cursor-color-for-insert-mode (first (nth (1- tmp) color-list)))

      (record-color-cursor-info
       :fname (cursor-info-file-name) :verbose nil :can-use t :cursor-color (current-cursor-color-name))

      (message :support-functions+test-can-use-color-cursor-006
                "設定ファイル(~a)に情報を記録しました。~%" (cursor-info-file-name)) 

      ) ;; end let
    )   ;; end test-can-use-color-cursor

  ;;
  ;; カラー・カーソル機能の有無と、機能する場合のカーソル色をファイルに設定する関数。
  ;;
  (defun record-color-cursor-info
      (&key
         (fname (cursor-info-file-name))
         (verbose nil) ;; メッセージを表示するか？
         (can-use t)   ;; カーソルのカラー表示機能は使えるか？
         (cursor-color (current-cursor-color-name)) ;; 挿入モード時のカーソルの表示色。
         )
    (let (msg-1 msg-2 msg-3 abs-fname)
      (setf abs-fname (config-file-abs-path fname))
      (with-open-file (s abs-fname :direction :output :if-does-not-exist :create :if-exists :supersede)
        (setf msg-1 (format nil ";; ~a ~a JST(~2,0@d\:00)"
                            (iso-date-string) (iso-time-string) (iso-timezone)))
        (setf msg-2 (format nil "(support-functions:can-use-color-cursor ~a)"
                            (string-downcase (symbol-name can-use)))) ;; 小文字は単なる趣味。
        (setf msg-3 (format nil "(support-functions:set-cursor-color-for-insert-mode \'~a)"
                            (string-downcase (symbol-name cursor-color)))) ;; 同上。
        (format s "~a~%" msg-1)
        (format s "~a~%" msg-2)
        (format s "~a~%" msg-3)

        (can-use-color-cursor can-use)
        (set-cursor-color-for-insert-mode cursor-color)
        ) ;; end with-open-file
      (when verbose
        (message :support-functions+record-color-cursor-info-001
                 "~a を作成し、以下のカラー・カーソル表示情報を書き込みました。~%"
                (cursor-info-file-name))
        (format t "~a~%" msg-1)
        (format t "~a~%" msg-2)
        (format t "~a~%" msg-3)
        (if (can-use-color-cursor-p)
            (progn
              (message :support-functions+record-color-cursor-info-002
                  "...この端末はカラー・カーソル表示が有効です。~%")
              (message :support-functions+record-color-cursor-info-003
                  "...挿入モード時のカーソル色(~a)を書き込みました。~%"
                      (string-downcase (symbol-name (current-cursor-color-name))))
              ) ;; end progn
            (message :support-functions+record-color-cursor-info-004
                  "...この端末はカラー・カーソル機能無効です。~%")
            ) ;; end if
        )     ;; end when
      )       ;; end let
    )         ;; end record-color-cursor-info

  (defun can-use-color-cursor-p ()
    can-use-color-cursor
    )

  (defun can-use-color-cursor (p)
    (setf can-use-color-cursor p)
    )

  ;;
  ;; Operationg System Command(OSC)が有効な場合にカーソルの色を変える。
  ;; OSCはANSI規格ではないので全ての端末に機能が備わっているとは限らず、
  ;; 備わっていても同じ規格とは限らない。
  ;;
  ;; 引数にはrgb各最大16ビットの数値リストを渡す。例:赤='(#xff #x00 #x00)
  ;; この関数を実行するとカーソルの色が即座に変わる。
  ;;
  (defun set-cursor-color (rgb-color-list)
    "端末上のカーソルの色を変える。r, g, bはそれぞれ最大16ビット。
ただし表示できる色数は端末依存。"
    ;;(format t "set-cursor-color:rgb-color-list=~s~%" rgb-color-list)
    (when (can-use-color-cursor-p)
      (let (r g b)
        (setf r (first rgb-color-list))
        (setf g (second rgb-color-list))
        (setf b (third rgb-color-list))
        (when (can-use-color-cursor-p)
          ;;(format t "~C]12;rgb:~2,'0X/~2,'0X/~2,'0X~C" #\Esc r g b #\Bel)
          (format t "~C]12;rgb:~2,'0X/~2,'0X/~2,'0X~C" (code-char 27) r g b (code-char 7)) ;; for GCL.
          (finish-output)))
      ) ;; end when
    )   ;; end set-cursor-color

  ;; 
  ;; vi-modeでの挿入モード時のカーソル色を設定する。
  ;; この関数を実行してもカーソルの色は即座には変わらない。
  ;; カーソルの色が変わるのは挿入モード時のみ。
  ;;
  (defun set-cursor-color-for-insert-mode (color-name)
    (when (can-use-color-cursor-p)
      (setf cursor-color-for-insert-mode color-name)
      ) ;; end when
    )   ;; end set-cursor-color-for-insert-mode

;;;
;;; カーソルの色を(black red green yellow blue magenta cyan white)からシンボル名で指定する。
;;;
  (defun set-cursor-color-by-name (color-name)
    (when (and
           (can-use-color-cursor-p)
           (member (symbol-name color-name) '(black red green yellow blue magenta cyan white)
                   :key #'symbol-name :test #'string-equal)
           ) ;; end and
      (set-cursor-color (second (find (symbol-name color-name) color-list
                                      :key #'(lambda (x) (symbol-name (first x))) :test #'equal)))
      (set-cursor-color-for-insert-mode color-name) 
      ) ;; end when
    (return-from set-cursor-color-by-name cursor-color-for-insert-mode)
    ) ;; end cursor-color-by-name

  ;;
  ;; wrapper functions
  ;;
  (defun black-cursor ()
    (set-cursor-color-for-insert-mode 'black)
    )

  (defun red-cursor ()
    (set-cursor-color-for-insert-mode 'red)
    )

  (defun green-cursor ()
    (set-cursor-color-for-insert-mode 'green)
    )

  (defun yellow-cursor ()
    (set-cursor-color-for-insert-mode 'yellow)
    )

  (defun blue-cursor ()
    (set-cursor-color-for-insert-mode 'blue)
    )

  (defun magenta-cursor ()
    (set-cursor-color-for-insert-mode 'magenta)
    )

  (defun cyan-cursor ()
    (set-cursor-color-for-insert-mode 'cyan)
    )

  (defun white-cursor ()
    (set-cursor-color-for-insert-mode 'white)
    )

  (defun current-cursor-color-name ()
    (return-from current-cursor-color-name cursor-color-for-insert-mode)
    )

  (defun reset-cursor-color ()
    (when (can-use-color-cursor-p)
      ;;(format t "~C]112~C" #\Esc #\Bel)
      (format t "~C]112~C" (code-char 27) (code-char 7) )
      (finish-output)))

  ) ;; end let

;; 現在のシェル名を起動シェルの初期値として取得しておく。
(setf *shell* (getenv "SHELL"))

;;
;; iso-639-1で定義された2文字の短縮言語名シンボルを受け取り、正式言語名シンボルを返す関数。
;;
(defun what-language (&optional (abbrev *selected-language*))
  (find (symbol-name abbrev) +languages-iso-639-1+
        :test #'string-equal :key #'(lambda (x) (symbol-name (car x))))
  )

;;(format t "(what-language :ja)=~s~%" (what-language :ja)) ==> (ja japanese)
;;(format t "(what-language :en)=~s~%" (what-language :en)) ==> (en english)

(defun select-language (&optional (abbrev nil) (verbose (verbose-message)))
  (if (null abbrev)
      (return-from select-language (selected-language))
      ) ;; end if

  (when (what-language abbrev)
    (setf *selected-language* abbrev)
    (when verbose
      (format t "~a language(\:~a) selected.~%"
              (string-capitalize (symbol-name (second (what-language))))
              (string-downcase (symbol-name (first (what-language))))
              ) ;; end format
      ) ;; end when
    ) ;; end when
  (what-language abbrev)
  ) ;; end select-language

(defun selected-language ()
  (values *selected-language* (second (what-language *selected-language*)))
  )

(defun native-language ()
  *native-language*
  )

;;
;; message関数のメッセージに使用する母語を設定する。
;; 設定できる言語はISO 639-1で規定された約180言語。
;; 設定できた場合は、設定した言語コードそのままを返す。そうでない場合は[nil]を返す。
;;
(defun select-native-language (abbrev)
  (when (what-language abbrev)
    (setf *native-language* abbrev)
    )
  )

(defun iso-639-1-list ()
  +languages-iso-639-1+
  )

(defun registered-message-list ()
  *registered-message-list*
  )

(defun registered-message-file ()
  *registered-message-file*
  )

(defun message-list-changed-p ()
  *message-list-changed-p*
  )

(defun read-registered-message (&optional (fname (registered-message-file)))
  (let (
        (eos (cons nil nil))
        (form nil)
        )
    (setf *registered-message-list* nil)
    (with-open-file (stream (config-file-abs-path fname) :direction :input :if-does-not-exist nil)
      (loop
        (setf form (read stream nil eos))
        (when (eq form eos) (return-from read-registered-message *registered-message-list*))
        (push form *registered-message-list*)
        ) ;; end loop
      )   ;; end with-open-file
    (return-from read-registered-message *registered-message-list*)
    )     ;; end let
  ) ;; end read-registered-message

(defun first-second-order (p q)
  (let ((first-element nil) (second-element nil))
    (setf first-element (symbol-name (car (first p))))
    (setf second-element (symbol-name (car (first q))))
    (cond
      ((string< first-element second-element) t)
      ((string= first-element second-element)
       (string< (symbol-name (cdr (first p))) (symbol-name (cdr (first q)))))
      ) ;; end cond
    ) ;; end let
  ) ;; end first-second-order

(defun second-first-order (p q)
  (let ((first-element nil) (second-element nil))
    (setf first-element (symbol-name (cdr (first p))))
    (setf second-element (symbol-name (cdr (first q))))
    (cond
      ((string< first-element second-element) t)
      ((string= first-element second-element)
       (string< (symbol-name (car (first p))) (symbol-name (car (first q)))))
      ) ;; end cond
    ) ;; end let
  ) ;; end second-first-order

(let (
      (verbose-message-p t)
      (suppress-important-message-p nil)
      )
  ;;
  ;; 冗長なメッセージを表示するかどうかを設定する。
  ;; 引数なしで実行すると現在の設定を返す。
  ;;
  (defun verbose-message (&optional (arg nil sw))
    (cond
      ((null sw)
       verbose-message-p
       )
      (t
       (setf verbose-message-p arg)
       )
      ) ;; end cond
    )   ;; end verbose-message

  (defun suppress-important-message (&optional (arg nil sw))
    (cond
      ((null sw)
       suppress-important-message-p
       )
      (t
       (setf suppress-important-message-p arg)
       )
      ) ;; end cond
    )   ;; end suppress-important-message

  ) ;; end let

;;
;; メッセージ・リストを[msg-id]か[lang]の順にソートする関数。
;;
;; メッセージ・リストは下記の形式。
;;
;;
;; <message-list>       ::= ( <message>+ ) ;;
;; <message>            ::= ( (<msg-id> . <language>) <stream> <format-string> <parameter>*) ;;
;;
;; <message-list>       ::= ( <message>+ ) ;;
;; <message>            ::= ( (<msg-id> . <language>) <stream> <format-string> <parameter>*) ;;
;;
(defun sort-registered-message (msg-list &key (order :language))
  (cond
    ((eql order :msg-id)
     (sort (copy-seq msg-list) #'first-second-order)
     )
    ((eql order :language)
     (sort (copy-seq msg-list) #'second-first-order)
     )
    (t
     (warn "指定できるソート順は[:msg-id]か[:language]の2種類です。~%")
     )
    ) ;; end cond
  ) ;; end sort-registered-message

;;
;; [(registered-message-lit)]を[(registered-message-file)]に書き出す。
;;
;; (write-registered-message (registered-message-file) (registered-message-list))
;;
(defun write-registered-message
    (&optional (fname (registered-message-file)) (msg-list (registered-message-list)))
  (let
      (
       (original-file nil)
       (backup-file nil)
       (original-file-exist nil)
       (backup-file-exist nil)
       (sorted-msg-list nil)
       )

    (setf sorted-msg-list (sort-registered-message msg-list :order :language)) ;; 言語順+メッセージ識別子順。

    (setf original-file (config-file-abs-path fname))
    (setf backup-file   (concatenate 'string original-file ".backup"))

    (setf original-file-exist (probe-file original-file))
    (setf backup-file-exist   (probe-file backup-file))

    (when original-file-exist
      (when backup-file-exist
        (delete-file backup-file))
      (rename-file original-file backup-file))

    (with-open-file (stream original-file :direction :output :if-does-not-exist :create)
      (dolist (p sorted-msg-list)
        (format stream "~s~%" p)
        )
      ) ;; end with-open-file
    (return-from write-registered-message original-file)
    ) ;; end let
  ) ;; end write-registered-message

(defun make-index-list (n)
  "0からn-1までの整数のリストを返す。"
  (let ((result nil))
    (dotimes (i n (nreverse result))
      (push i result))))

(defun make-indexed-permutation (list-a list-b)
  "Bの各要素が、元々Aのどのインデックスにあったかを返す。"
  (let*
      (
       (n (length list-a))
       ;; [list-a]内に同じ要素が存在する場合に備えてインデックスを紐つける。
       ;; [list-a]の要素とインデックスのペアリスト: ((a . 0) (a . 1) (b . 2))を作る。
       (indexed-a (map 'list #'cons list-a (make-index-list n)))
       (result nil)
       (match nil)
       )
    (dolist (p list-b)
      (setf match (find p indexed-a :key #'car :test #'equal))
      (if (identity match)
          (progn
            (setf indexed-a (remove match indexed-a :count 1 :test #'equal))
            (push (cdr match) result)
            )
          (error "要素 ~a が一致しません。" p)
          ) ;; end if
      )     ;; end dolist
    (return-from make-indexed-permutation (reverse result))
    ) ;; end let*
  ) ;; end make-indexed-permutation

(defun get-transpose-map (p-indices)
  "順変換のインデックス対応から、逆変換（転置）用の対応を作成する。"
  (let* ((n (length p-indices))
         (transpose-map (make-array n)))
    (dotimes (b-idx n)
      (setf (aref transpose-map (aref p-indices b-idx)) b-idx))
    transpose-map))

(defun valid-message-p (msg)
  (or (null msg) (>= (length msg) 3))
  )

#|
(let* (
       (result (make-array 3))
       (a #(a a b))
       (b #(b a a))
       ;; 1. BがAのどの位置から来たか特定
       (p-map (make-indexed-permutation a b)) ; => #(2 0 1)
       ;; 2. AがBのどの位置に行ったか（転置）特定
       (t-map (get-transpose-map p-map))) ; => #(1 2 0)

  (format t "a=~s~%" a)
  (format t "b=~s~%" b)
  (format t "BがAのどの位置から来たか特定:p-map=~s~%" p-map)
  (format t "AがBのどの位置に行ったか（転置）特定:t-map=~s~%" t-map)

  (dotimes (i (length t-map))
    (setf (aref result (elt t-map i)) (elt a i))
    )
  (format t "~s -> ~s -> ~s~%" a result (coerce result 'list))
  )
> 上記を実行すると
a=#(A A B)
b=#(B A A)
BがAのどの位置から来たか特定:p-map=#(2 0 1)
AがBのどの位置に行ったか（転置）特定:t-map=#(1 2 0)
#(A A B) -> #(B A A) -> (B A A)
T
|#

;;
;; 多言語対応のメッセージ出力用関数(MultiLingual-message)。
;;
;; 指定された[msg-id]と[lang]が一致するリストが[*registered-message-list*]に存在するか調べ、
;; 後半の[stream],[msg],[parm]も含めて一致していれば、[msg-id]と[lang]に一致するリストの
;; データを[stream]に出力する。
;;
;; 後半が異なっていれば引数で指定されたデータに入れ替えて[*registered-message-list*]に登録した上で、
;; 入れ替えたデータに従って出力する。
;;
;; [msg-id]と[lang]に一致するリストが[*registered-message-list*]に存在しなければ登録して
;; から出力する。
;;
;; 優先順位:
;; [(selected-language)]と[lang]が異なる場合。
;;      (1-1) [msg-id]と[(selected-language)]で指定された言語のメッセージが存在すれば表示。
;;      (2-1) 存在しなければ、引数で指定された[msg-id]と[lang]に一致するメッセージを表示。
;;      (3-1) それも存在しなければ、引数で指定されたメッセージ本体を登録して表示。
;;      (4-1) 存在するが、メッセージ本体が引数部分と異なれば引数で指定されたメッセージに差し替えてから表示。
;;
;; [(selected-language)]と[lang]が同じ場合。
;;      (1-2) [msg-id]と[lang]で指定された言語のメッセージが存在すれば表示。
;;      (2-2) 存在しなければ引数で指定されたメッセージ本体を登録してから表示。
;;      (3-2) 存在するが、メッセージ本体が引数部分と異なれば引数で指定されたメッセージに差し替えてから表示。
;;
;; *** 注意 ***
;; ソースコード内に関数[ml-message]および関数[message]を使って書かれているメッセージ言語は
;; [(native-language)]という前提でプログラムしている。
;;
;; *** 運用 ***
;; format関数で出力しているメッセージを、このml-message関数に置き換える。先頭2つの引数が増える以外は
;; 元のformat関数の引数はそのままでよい。
;;
;; <message-list>       ::= ( <message>+ ) ;;
;; <message>            ::= ( (<msg-id> . <lang>) <stream> <format-string> <parameter>*) ;;
;;
;; ファイルからmessage関数、ml-message関数を抽出するにはextract-function関数を使う。
;;      (extract-function "~/Lisp/line-edit/print-color-string.lisp")
;; のように指定するとmessage関数とml-message関数のリストを返す。
;;
;; このリストを以下のプロンプトでclaudeに渡すと翻訳されたリストが得られる。
;;
#| ;; ----以下、AIに渡すプロンプト。メッセージ部分を直接渡す場合などは適宜、必要部分を書き換える。
別途アップロードしたcommon lispのプログラム・ファイルから (message msg-id “書式文字列” parm1 parm2 …)
という形式のS式を抜き出して書式文字列内の日本語を英語、ドイツ語、フランス語、中国語簡体字、中国語繁体字、韓国語、
ズールー語に翻訳して以下の形式のリストに変換して、このリストのみをファイルに書き出して下さい。

((msg-id . lang) t “書式文字列” parm…)

日本語の場合はlangを:ja、英語の場合はlangを:en、ドイツ語は:de、フランス語は:fr、中国語簡体字は:zh-hans、
中国語繁体字は:zh-hant、韓国語は:ko、ズールー語は:zu。

日本語の場合は元の”書式文字列”をそのまま使い、日本語以外は”書式文字列”内の日本語を各言語に翻訳します。
翻訳の際、”書式文字列”内の書式指定子とパラメータの対応順を守ると翻訳先言語での表現が不自然になる場合は、
パラメータの順序を変更しても副作用がないことを確認できる場合のみ順序の入れ替えを行います。
対応するパラメータの順序入れ替えも忘れずに行って下さい。
|# ;; -----プロンプト、ここまで。
;;
(defun ml-message (msg-id lang stream msg &rest parm)
  (declare (type string msg))
  (let (
        (runtime-message nil)
        (original-message nil)
        (selected-message nil) ;; 表示用メッセージはどちらか。
        )

    ;; オリジナル・メッセージを記述した基準言語の登録データを取得する。必ず存在する。
    (setf original-message (find-by-symbol-name (cons msg-id lang) *registered-message-list*))


    ;; 実行時設定の言語データを取得する。なければ[nil]。
    (setf runtime-message (find-by-symbol-name (cons msg-id (selected-language)) *registered-message-list*))

    (when (not (valid-message-p original-message))
      (error "Error at ml-message: Illegal format of runtime-message(~s).~%" runtime-message)
      )
    
    (when (debug-print-p "ml-message")
      (format t "msg-id=~s, lang=~s~%" msg-id lang)
      (format t "msg=~s, parm=~s~%" msg parm)
      (format t "--------------------~%")
      (format t "original-message=~s~%" original-message)
      (format t "--------------------~%")
      (format t "runtime-message=~s~%" runtime-message)
      (format t "--------------------~%")
      (format t "selected-message=~s~%" selected-message)
      (format t "--------------------~%")
      )

    (cond
      ;;-----------------------------------------------------------------------------------
      ((and ;; (1-1) [msg-id]と[(selected-language]で指定された言語でのメッセージが登録されている。
        (not (equal lang (selected-language)))
        (identity runtime-message)
        )
       (setf *message-list-changed-p* nil)
       (setf selected-message runtime-message)
       )
      ((and ;; (2-1) ;; [msg-id]と[lang]で指定された言語のメッセージが登録されている。
        (not (equal lang (selected-language)))
        (null runtime-message)
        (identity original-message)
        )
       (cond                                         ;; (2-1)/(4-1)
         ((not (equal msg (third original-message))) ;; (4-1) メッセージ本体が異なる → 差し替え
          (setf *registered-message-list*
                (remove original-message *registered-message-list* :test #'equal))
          (setf original-message (append (list (cons msg-id lang) stream msg) (cdddr original-message)))
          (setf *message-list-changed-p* t)
          (pushnew original-message *registered-message-list* :test #'equal)
          (setf selected-message original-message))
         (t ;; (2-1) 一致 → そのまま使う
          (setf *message-list-changed-p* nil)
          (setf selected-message original-message)
          ) ;; end [t]
         )  ;; end cond ;; (2-1)/(4-1)
       )
      ((and ;; (3-1) [(selected-language)]で言語を指定されたが、その言語ではメッセージが登録されていない。
        (not (equal lang (selected-language)))
        (null runtime-message)
        (null original-message)
        )
       (setf original-message (append (list (cons msg-id lang) stream msg) parm))
       (setf selected-message original-message) ;; 引数に指定されているメッセージを表示する。
       (setf *message-list-changed-p* nil)
       )
      ;;-----------------------------------------------------------------------------------
      ((and
        (equal lang (selected-language))
        (identity original-message) ;; [msg-id]と[lang]で指定されたメッセージが登録されている。
        )
       (cond
         ((not (equal msg (third original-message))) ;; (3-2) 後半が異なる。
          (setf *registered-message-list*
                (remove original-message *registered-message-list* :test #'equal)) ;; 古い定義を削除。
          (setf original-message (append (list (cons msg-id lang) stream msg) (cdddr original-message)))
          (setf *message-list-changed-p* t)
          ;; 新しく指定された定義に差し替える。
          (pushnew original-message  *registered-message-list* :test #'equal)
          (setf selected-message original-message)
          )
         (t ;; (1-2) 後半も含めて同じ。
          (setf *message-list-changed-p* nil)
          (setf selected-message original-message)
          )
         )
       )
      ;;-----------------------------------------------------------------------------------
      (t ;; (4-1)&(2-2) [msg-id]と[lang]のペアは登録されていなかった → 登録してから表示。
       (setf *message-list-changed-p* t)
       (setf selected-message (append (list (cons msg-id lang) stream msg) parm))
       (pushnew selected-message *registered-message-list* :test #'equal)
       )
      ) ;; end cond

    ;; 引数で指定された言語データと実行時指定の言語データの引数の順序が異なる場合。
    ;; 引数の順序を正しく入れ替える。
    (when (not (equal (cdddr runtime-message) (cdddr original-message)))
      (let*
          (
           (org-parm (cdddr original-message))
           (new-parm (cdddr runtime-message)) ;; [new-parm]が元々のパラメータ[parm]のどの位置から来たか得る。
           (tmp-vec (make-array (length new-parm)))
           (p-map nil)
           (t-map nil)
           )

        (when (debug-print-p "ml-message")
          (format t "------------------------------------~%")
          (format t "(2) ml-message:org-parm=~s~%" org-parm)
          (format t "(2) ml-message:new-parm=~s~%" new-parm)
          (format t "(2) ml-message:evaled parm=~s~%" parm)
          (finish-output)
          )

        (setf p-map (make-indexed-permutation org-parm new-parm)) ;; [parm]が[new-parm]の移動位置を特定する。
        ;;(format t "ml-message:p-map=~s~%" p-map)
        (setf t-map (get-transpose-map (coerce p-map 'vector))) ;; #(1 2 0)など。0→1, 1→2, 2→0という意味。
        ;;(format t "ml-message:t-map=~s~%" t-map)

        (dotimes (i (length t-map))
          (setf (aref tmp-vec (elt t-map i)) (elt parm i))
          )
        ;;(format t "before:parm=~s~%" parm)
        (setf parm (coerce tmp-vec 'list))
        ;;(format t "after:parm=~s~%" parm)
        ) ;; let*
      )   ;; end when

    (when (debug-print-p "ml-message")
      (format t "(2)msg-id=~s, (selected-language)=~s, lang=~s~%" msg-id (selected-language) lang)
      (format t "(2)msg=~s~%" msg)
      (format t "--------------------~%")
      (format t "(2)original-message=~s~%" original-message)
      (format t "--------------------~%")
      (format t "(2)runtime-message=~s~%" runtime-message)
      (format t "--------------------~%")
      (format t "(2)selected-message=~s~%" selected-message)
      (format t "--------------------~%")
      (format t "(2)ml-message:parm=~s~%" parm)
      )
    (apply #'format (second selected-message) (third selected-message) parm)

    (when (debug-print-p "ml-message")
      (format t "(3)ml-message finished.~%")
      )
    
    ) ;; end let
  ) ;; end defun ml-message

;;
;; Native-language Message.
;; 関数[ml-message]に対するラッパー関数。
;;
(defun message (msg-id msg &rest parm)
  "第1引数に「メッセージID」が入る以外は[format]関数と同じ。出力先は標準出力。
標準出力以外を指定したい場合は関数[ml-message]を使う。"
  ;;(format t "message:parm=~s~%" parm)
  (apply #'ml-message msg-id (native-language) t msg parm)
  )

;;
;; 引数で指定したファイルから[func-list]で指定した関数呼び出しを抽出して、そのリストを返す。
;;
;; 注意:関数呼び出し形式にのみ対応。マクロやスペシャル・フォームは誤認識する可能性あり。
;;
(defun extract-function (fname &optional (func-list '(message ml-message)))
  (let ((abs-fname (probe-file fname)))
    (when abs-fname
      (with-open-file (stream abs-fname :direction :input)
        (let ((eos (cons nil nil)))
          (labels (
                   (read-all ()
                     (let ((s-exp (read stream nil eos)))
                       ;;(format t "s-exp=~s~%" s-exp)
                       (unless (equal s-exp eos)
                         (append (true-extract-function s-exp func-list) (read-all))))
                     ) ;; end definition of read-all.
                   )   ;; end definition part of labels.
            (read-all)
            ) ;; end labels
          )   ;; end let
        )     ;; end with-open-file
      )       ;; end when
    )         ;; end let
  )    ;; end extract-function

;;
;; [s-exp]内のリストの先頭シンボルが[func-list]のいずれかである、すべてのリストのリストを返す。
;;
(defun true-extract-function (s-exp &optional (func-list '(message ml-message)))
  (cond
    ((null s-exp) nil)
    ((atom s-exp) nil)
    ((and ;; dotted pairは除外する。
      (consp s-exp)
      (not (listp (cdr s-exp)))
      )
     nil)
    ((and
      (listp s-exp)
      (symbolp (car s-exp))
      (member-by-symbol-name (car s-exp) func-list)
      )
     ;;(format t "~~true-extract-function: s-exp=~s~%" s-exp)
     (list s-exp)
     )
    ((and
      (listp s-exp)
      (listp (car s-exp))
      )
     (append (true-extract-function (car s-exp)) (true-extract-function (cdr s-exp)))
     )
    (t
     (true-extract-function (cdr s-exp))
     )
    ) ;; end cond
  )  ;; end true-extract-function

;;(eval-when (:load-toplevel :execute)
  ;;(read-registered-message) ;; → line-edit-pkg.lisp内での初期化に移動。
;;  )

#+ :build-as-packages
(provide :support-functions)
