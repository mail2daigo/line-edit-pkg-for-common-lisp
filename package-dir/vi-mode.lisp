;;;; last updated : 2026-05-11 11:57:58(JST)

;;;
;;; vi互換コマンドのキー・バインドを定義するファイル(vi-mode)。
;;;

;;
;; Meta(Alt) + Controlの組み合わせは端末ソフトやOSのショートカット・キーとして定義されている場合がある。
;; その場合、アプリケーション・レイヤで動作している本ソフトよりもOS側ショートカット・キー(第1順位)、端末
;; ソフト側ショートカット・キー(第2順位)にキー・シーケンスを横取りされる。以下で定義されたキー・シーケンス
;; が動作しない場合はまず、端末ソフト、それでもだめならOS側ショートカット・キーの定義を解除する。
;; 具体的なショートカット・キーの設定解除方法はOSと端末ソフトによって異なる。
;;

;;(in-package  :line-edit-pkg)
;;(use-package :support-functions)

(clear-global-set-key)
(clear-key-def-for-complete-symbol)

;;
;; 初期設定用ディレクトリ→カレント・ディレクトリ→ホーム・ディレクトリにviモード用キーバインドに必要な
;; 定義を収めた[vi-mode-function]のオブジェクトファイルがあればオブジェクト・ファイルを、オブジェクト
;; ファイルがなく、ソース・ファイルがあればソース・ファイルを読み込む。
;;
(let ((fname nil))
  ;;(setf fname (support-functions:config-file-abs-path "vi-mode-function"))
  (setf fname (find-current-and-home-dir "vi-mode-function" :ext ".lisp" :dir (config-file-dir)))
  (cond
    ((identity fname)
     (load fname)
     (format t "~s loaded.~%" fname))
    (t (error "vi-mode-function.\{~s,~s\} can not find.~%" *object-extension* *lisp-extension*) )
    ) ;; end cond
  )

;;
;; [define-key]は別名定義。
;;
(define-key "[Backspace]"       "\\C-h") ;; BSキー。
(define-key "[Enter]"           "\\C-j")
(define-key "[Return]"          "\\C-m")
(define-key "[delete]"          "\\C-?")
(define-key "[Tab]"             "\\C-i")
(define-key "\\S-"              "#\^[ #\^[") ;; SuperキーをESC+ESCと定義。

(global-set-key "[0xa0]"        #'just-one-space)       ;M-[Space] generates 0xa0.
(global-set-key "[Space]"       #'forward-char)

(global-set-key "\\C-@"         #'set-mark-command) 
(global-set-key "\\C-a"         #'beginning-of-line)
(global-set-key "\\C-b"         #'backward-char) 
(global-set-key "\\C-d"         #'delete-char) 
(global-set-key "\\C-e"         #'scroll-up) 
(global-set-key "\\C-f"         #'forward-char) 
(global-set-key "\\C-g"         #'what-cursor-position) 
(global-set-key "[Backspace]"   #'delete-backward-char)
(global-set-key "[Tab]"         #'complete-symbol)
(global-set-key "[Enter]"       #'end-input)
(global-set-key "\\C-k"         #'kill-line) 
(global-set-key "\\C-l"         #'redraw) 
(global-set-key "[Return]"      #'end-input)
(global-set-key "\\C-n"         #'next-line)
(global-set-key "\\C-o"         #'set-mark-command)
(global-set-key "\\C-q"         #'quoted-insert) 
(global-set-key "\\C-r"         #'redraw) ;; same as C-l
(global-set-key "\\C-s"         #'isearch-forward) 
(global-set-key "\\C-t"         #'transpose-chars) 
(global-set-key "\\C-u"         #'universal-argument) 
(global-set-key "\\C-v"         #'scroll-up) 
(global-set-key "\\C-w"         #'kill-region) 
(global-set-key "\\C-x ("       #'start-kbd-macro) 
(global-set-key "\\C-x )"       #'end-kbd-macro) 
;;(global-set-key "\\C-x <"       #'scroll-left) 
(global-set-key "\\C-x ="       #'what-cursor-position) 
;;(global-set-key "\\C-x >"       #'scroll-right)
(global-set-key "\\C-x u"       #'advertised-undo) 
(global-set-key "\\C-x U"       #'advertised-redo) 
(global-set-key "\\C-x \\C-f"   #'find-file) 
(global-set-key "\\C-x \\C-k"   #'edit-kbd-macro) 
(global-set-key "\\C-x \\C-s"   #'save-buffer) 
(global-set-key "\\C-x \\C-u"   #'up-list) 
(global-set-key "\\C-x \\C-w"   #'write-file) 
(global-set-key "\\C-x \\C-x"   #'exchange-point-and-mark) 
(global-set-key "\\C-x e"       #'call-last-kbd-macro)
(global-set-key "\\C-x \\C-e"   #'call-last-kbd-macro)  ;; [Ctrl]キーを押したまま[e]をタイプする場合のガード。
(global-set-key "\\C-x i"       #'insert-file)
(global-set-key "\\C-x \\C-i"   #'insert-file)          ;; 同上。
(global-set-key "\\C-x q"       #'kbd-macro-query) 
(global-set-key "\\C-x \\C-q"   #'kbd-macro-query)      ;; 同上。
(global-set-key "\\C-x r R"     #'restore-registers) 
(global-set-key "\\C-x \\C-r R" #'restore-registers)    ;; 同上。
(global-set-key "\\C-x r S"     #'save-registers) 
(global-set-key "\\C-x \\C-r S" #'save-registers)       ;; 同上。
(global-set-key "\\C-x r i"     #'insert-register) 
(global-set-key "\\C-x \\C-r i" #'insert-register)      ;; 同上。
(global-set-key "\\C-x r s"     #'copy-to-register) 
(global-set-key "\\C-x \\C-r s" #'copy-to-register)     ;; 同上。
(global-set-key "\\C-y"         #'scroll-down) 
(global-set-key "\\M-("         #'insert-parenthesis) 
(global-set-key "\\M-@"         #'mark-word) 
(global-set-key "\\M-O\C"       #'forward-char)
(global-set-key "\\M-O\D"       #'backward-char)
(global-set-key "\\M-\\\\"      #'delete-horizontal-space) 
(global-set-key "\\M-\\C-@"     #'mark-sexp) 
(global-set-key "\\M-\\C-b"     #'backward-sexp) 
(global-set-key "\\M-\\C-c"     #'line-edit-break) ;for debug. 
(global-set-key "\\M-\\C-d"     #'down-list) 
(global-set-key "\\M-\\C-e"     #'end-command-trace) ;for debug. 
(global-set-key "\\M-\\C-f"     #'forward-sexp) 
(global-set-key "\\M-\\C-h"     #'backward-kill-word) 
(global-set-key "\\M-\\C-k"     #'kill-sexp) 
(global-set-key "\\M-\\C-n"     #'forward-list) 
(global-set-key "\\M-\\C-o"     #'mark-sexp) 
(global-set-key "\\M-\\C-p"     #'backward-list) 
(global-set-key "\\M-\\C-s"     #'start-command-trace) ;for debug. 
(global-set-key "\\M-\\C-t"     #'transpose-sexps) 
(global-set-key "\\M-\\C-u"     #'backward-up-list) 
(global-set-key "\\M-\\C-w"     #'append-next-kill) 
(global-set-key "\\M-\\[\C"     #'forward-char)
(global-set-key "\\M-\\[\D"     #'backward-char)
(global-set-key "\\M-a"         #'beginning-of-text) 
(global-set-key "\\M-b"         #'backward-word) 
(global-set-key "\\M-c"         #'capitalize-word) 
(global-set-key "\\M-d"         #'kill-word) 
(global-set-key "\\M-e"         #'end-of-text) 
(global-set-key "\\M-f"         #'forward-word) 
(global-set-key "\\M-k"         #'kill-text) 
(global-set-key "\\M-l"         #'downcase-word) 
(global-set-key "\\M-n"         #'next-word) 
(global-set-key "\\M-o"         #'mark-word) 
(global-set-key "\\M-p"         #'move-to-matching-paren) 
(global-set-key "\\M-s"         #'just-one-space) 
(global-set-key "\\M-t"         #'transpose-words) 
(global-set-key "\\M-u"         #'upcase-word) 
(global-set-key "\\M-v"         #'scroll-down) 
(global-set-key "\\M-w"         #'kill-ring-save) 
(global-set-key "\\M-y"         #'yank-pop) 
(global-set-key "\\M-z"         #'zap-to-char) 

(global-set-key "\\: r"         #'insert-file)
(global-set-key "\\: w"         #'write-file)

(global-set-key "i"             #'start-insert-mode) 
(global-set-key "I"             #'insert-from-beginning-of-line) 
(global-set-key "a"             #'append-char) 
(global-set-key "A"             #'append-to-end-of-line) 
(global-set-key "o"             #'append-to-end-of-text) 
(global-set-key "O"             #'insert-from-beginning-of-text) 
(global-set-key "p"             #'append-region) 
(global-set-key "P"             #'insert-region) 
(global-set-key "y l"           #'vi-yank-char) 
(global-set-key "y h"           #'vi-yank-backward-char) 
(global-set-key "y w"           #'vi-yank-word) 
(global-set-key "y b"           #'vi-yank-backward-word) 
(global-set-key "y W"           #'vi-yank-xword) 
(global-set-key "y B"           #'vi-yank-backward-xword) 
(global-set-key "y 0"           #'vi-yank-from-beginning-of-line)       ;zero
(global-set-key "y $"           #'vi-yank-to-end-of-line) 
(global-set-key "y y"           #'vi-yank-line) 
(global-set-key "Y"             #'vi-yank-line) 

(global-set-key "c l"           #'change-character) 
(global-set-key "s"             #'change-character) 
(global-set-key "c h"           #'change-backward-character) 
(global-set-key "c w"           #'change-word) 
(global-set-key "c b"           #'change-word) 
(global-set-key "c W"           #'change-xword) 
(global-set-key "c B"           #'change-xword) 
(global-set-key "c 0"           #'change-from-beginning-of-line) 
(global-set-key "c $"           #'change-to-end-of-line) 
(global-set-key "c c"           #'change-line) 
(global-set-key "S"             #'change-line) 
(global-set-key "\\~"           #'exchange-case) 

(global-set-key "d l"           #'delete-char) 
(global-set-key "x"             #'delete-char) 
(global-set-key "d h"           #'delete-backward-char) 
(global-set-key "X"             #'delete-backward-char) 
(global-set-key "d w"           #'delete-word) 
(global-set-key "d b"           #'delete-backward-word) 
(global-set-key "d W"           #'delete-xword) 
(global-set-key "d B"           #'delete-backward-xword) 
(global-set-key "d 0"           #'delete-line-from-beginning-of-line) 
(global-set-key "d $"           #'delete-line) 
(global-set-key "D"             #'delete-line) 
(global-set-key "d d"           #'delete-text) 
(global-set-key "J"             #'join-next-line) 

(global-set-key "r"             #'replace-character) 
(global-set-key "R"             #'replace-characters) 

(global-set-key "m"             #'set-global-mark)
(global-set-key "\\#'"          #'goto-global-mark)

(global-set-key "u"             #'advertised-undo) 
(global-set-key "U"             #'advertised-redo) 

(global-set-key "\%"            #'move-to-matching-paren) 

(global-set-key "\\|"           #'nth-char-of-line) 
(global-set-key "\\^"           #'first-char-of-line) 
(global-set-key "0"             #'beginning-of-line) ;zero 
(global-set-key "H"             #'beginning-of-text) 
(global-set-key "k"             #'previous-line) 

(global-set-key "\$"            #'end-of-line) 
(global-set-key "L"             #'end-of-text) 

(global-set-key "l"             #'forward-char) 
(global-set-key "w"             #'next-word) 
(global-set-key "W"             #'next-xword) 
(global-set-key "e"             #'end-of-word) 
(global-set-key "E"             #'end-of-xword) 

(global-set-key "h"             #'backward-char) 
(global-set-key "b"             #'backward-word) 
(global-set-key "B"             #'backward-xword) 
(global-set-key "\\)"           #'backward-sexp) 

(global-set-key "\\("           #'insert-symbolic-expression)
(global-set-key "\\."           #'vi-redo) 
(global-set-key "\\/"           #'isearch-forward) 

(global-set-key "1"             #'digit-argument) 
(global-set-key "2"             #'digit-argument) 
(global-set-key "3"             #'digit-argument) 
(global-set-key "4"             #'digit-argument) 
(global-set-key "5"             #'digit-argument) 
(global-set-key "6"             #'digit-argument) 
(global-set-key "7"             #'digit-argument) 
(global-set-key "8"             #'digit-argument) 
(global-set-key "9"             #'digit-argument) 

;; 拡張エスケープ・シーケンスモード1が有効な端末で機能するキー。
(global-set-key "\\M-\\[\D"     #'backward-char)        ;; left-arrow  (HHKB=Fn + ;)
(global-set-key "\\M-\\[\C"     #'forward-char)         ;; right-arrow (HHKB=Fn + ')
(global-set-key "\\S-\\[\D"     #'backward-word)        ;; M-left-arrow  = ESC + Fn + [
(global-set-key "\\S-\\[\C"     #'forward-word)         ;; M-right-arrow = ESC + Fn + '

#+ :use-history-pkg
  (progn
    ;;(format t "history-pkg commands available.~%")
    (global-set-key "\\C-p"             #'previous-line)
    (global-set-key "\\M-\\[A"          #'previous-line) ;; モード1が有効な場合。up-arrow. [Fn]+[
    (global-set-key "j"                 #'next-line) 
    (global-set-key "\\M-\\[\B"         #'next-line) ;; モード1が有効な場合。down-arrow. [Fn]+/
    (global-set-key "\\< \\<"           #'beginning-of-history)
    (global-set-key "\\M-<"             #'beginning-of-history)
    (global-set-key "\\> \\>"           #'end-of-history) 
    (global-set-key "\\M->"             #'end-of-history)
    (global-set-key "m"                 #'set-global-mark)
    (global-set-key "\\#'"              #'goto-global-mark)
    ) ;; end progn

(global-set-key nil #'vi-warning)

;;
;; 関数[complete-symbol]内で使用する[*complete-symbol-keymap*]に保管するキー列の定義。
;; [(get-key-def-complete-symbol)]により入力されたキー列に応じたキーワードを返す。
;; キーワード部分は文字列型以外であること。
;;
(complete-symbol-set-key "\\C-p"     :previous-candidate)       ;; 前の候補に移動する。
(complete-symbol-set-key "\\M-\\[A"  :previous-candidate)       ;; (↑) up arrow (HHKB=Fn + [).
(complete-symbol-set-key "j"         :previous-candidate)

(complete-symbol-set-key "\\C-n"     :next-candidate)           ;; 次の候補に移動する。
(complete-symbol-set-key "\\M-\\[B"  :next-candidate)           ;; (↓) down arrow (HHKB=Fn + /).
(complete-symbol-set-key "\\C-i"     :next-candidate)           ;; Tab.
(complete-symbol-set-key "k"         :next-candidate)

(complete-symbol-set-key "\\C-j"     :current-candidate)        ;; 現在の候補に確定。
(complete-symbol-set-key "."         :current-candidate)        ;; [,][.][/]=[短][標準][長]

(complete-symbol-set-key "\\C-s"     :short-candidate)          ;; 短い候補に確定。
(complete-symbol-set-key "s"         :short-candidate)          ;; "s" for Short.
(complete-symbol-set-key ","         :short-candidate)          ;; [,][.][/]

(complete-symbol-set-key "\\C-l"     :long-candidate)           ;; 長い候補に確定。
(complete-symbol-set-key "l"         :long-candidate)           ;; "l" for Long.
(complete-symbol-set-key "/"         :long-candidate)           ;; [,][.][/]
 
(complete-symbol-set-key "r"         :redraw)                   ;; 現在の行を再描画し
(complete-symbol-set-key "\\C-r"     :redraw)                   ;; #\Newline以外の制御文字を削除する。
(complete-symbol-set-key "\\M-r"     :redraw)

(complete-symbol-set-key "q"         :cancel)                   ;; 補完をキャンセル。
(complete-symbol-set-key "\\C-q"     :cancel)
(complete-symbol-set-key "\\M-q"     :cancel)

;; '(:previous-candidate :next-candidate :current-candidate :short-candidate :long-candidate :redraw :cancel)
(setf *complete-symbol-used-key-def* '("j" "k" "." "," "/" "C-r" "q")) 

;;
;; 挿入モード時にカーソルの色を変える機能の有無を記述したファイルを確認する。
;; 機能があると記載されていれば、挿入モード時のカーソル色も記載されている。
;;
(let ((fname nil))
  (setf fname (external-command:config-file-abs-path (cursor-info-file-name)))
  (when (identity fname)
    (load fname :verbose nil)
    (format t "~s loaded.~%" fname)
    ) ;; end when
  ) ;; end let

;;(in-package :cl-user)
