;;
;; replのプロンプト設定例。
;;
(package-util:set-package-name-case :downcase)		;; パッケージ名を小文字で表示。
;;(package-util:set-package-name-case :upcase)		;; パッケージ名を大文字で表示。
;;(package-util:set-package-name-case :capitalize)	;; パッケージ名を先頭のみ大文字で表示。
;;(package-util:set-package-name-case nil)		;; 処理系の設定に従って表示(通常は大文字)。
(history-pkg:set-prompt-attributes :color 'blue :bold t) ;; print-colored-string全体の属性指定。

;;
;; プロンプトを設定する。指定できるプロンプト構成指示子は
;;
;; > (documentation 'history-pkg:set-prompt-element 'function)
;;  指定できるプロンプト構成指示子は以下の通り。
;; 
;;  :current-package		カレント・パッケージ名(ニックネームがあれば、最短のニックネームを返す)。
;;  :original-package-name	カレント・パッケージ名を返す。ニックネームがあってもオリジナル名を返す。
;;  :not-cl-user		cl-userパッケージでない場合のみオリジナル・パッケージ名を返す。
;;  :date			今日のISOフォーマットでの日付(YYYY-MM-DD)。
;;  :time			24時間フォーマットでの現在の時刻(HH:MM:DD)。
;;  :time12			12時間フォーマットでの現在の時刻(HH:MM{am,pm})。
;;  :absolute-dir		カレント・ディレクトリ(絶対パス)。
;;  :working-dir		カレント・ディレクトリ(相対パス)。
;;  :working-dir-name		カレント・ディレクトリ名のみ。
;;  :history-number		履歴番号。
;;  :os-type			OSの種類。
;;  :host-name			ホスト名/マシン名。
;;  :machine-type		CPUタイプ。
;;  :lisp-type			処理系名。
;;  :lisp-version		処理系のバージョン番号。
;;  "string"			文字列。
;;  #'func			関数funcの返す結果。
;;
(history-pkg:set-prompt-element
	"["					;; "["を表示。
        :lisp-type				;; 処理系名。
        ":"					;; ":"を表示。
 #'print-color-string:change-to-green		;; ここ以降は緑色。
	:not-cl-user				;; カレント・パッケージが[:cl-user]でない場合のみ
        					;; パッケージ名を表示。表示色は緑色。
        ;; カレント・パッケージが[:cl-user]以外の場合は外部シンボル数を表示。
	#'(lambda () (format nil "~a" (px:number-of-external-symbols *package* "=" "")))
 #'print-color-string:change-to-blue		;; ここ以降は再び青色。
	#+sbcl "("				;; sbclの場合は"("を表示。
 #+sbcl #'print-color-string:change-to-red	;; ここ以降は赤色。
	#+sbcl :heap-size			;; sbclの場合はヒープ・サイズを表示。
 #+sbcl #'print-color-string:change-to-blue	;; ここ以降は青色。
	#+sbcl ")"				;; sbclの場合は")"を表示。
	#+(not sbcl) " "			;; sbcl以外の場合は空白(" ")を表示。
        :date					;; ISOフォーマットでの日付(YYYY-MM-DD)
        " "					;; 空白(" ")を表示。
	:time					;; 時刻を24時間制で表示。
 " #" :history-number "]> "			;; 文字の色や属性指定はここでリセットされる。
) ;; end history-pkg:set-prompt-element

;; ==> [sbcl:(49.5MB)16:12:35 #2]>	;; 処理系名、":"、カレント・パッケージ名(:cl-userなら非表示)
					;; sbclの場合は括弧内に赤字でヒープサイズ、時刻、" #"
					;; 履歴番号を表示。全体が太字の青色。全体の前後に"["と"]> "。
