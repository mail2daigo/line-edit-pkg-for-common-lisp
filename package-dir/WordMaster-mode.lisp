;;;; last updated : 2026-05-11 12:02:15(JST)

;;;
;;; WordMasterのビデオ・モードのコマンドを定義。
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
;; カレント・ディレクトリ→ホーム・ディレクトリにWordMasterモード用キーバインドに必要な定義を収めた
;; [WordMaster-mode-function]のオブジェクトファイルがあればオブジェクト・ファイルを、オブジェクト
;; ファイルがなく、ソース・ファイルがあればソース・ファイルを読み込む。
;;
(let ((fname nil))
  ;;(setf fname (support-functions:config-file-abs-path "WordMaster-mode-function"))
  (setf fname (find-current-and-home-dir "WordMaster-mode-function" :ext ".lisp" :dir (config-file-dir)))
  (cond
    ((identity fname)
     (load fname)
     (format t "~s loaded.~%" fname))
    (t (error "WordMaster-mode-function.~s can not find.~%" *lisp-extension*) )
    ) ;; end cond
  )

;;
;; [define-key]は別名定義。
;;
(define-key "[Backspace]"       "\\C-h") ;; BSキー。
(define-key "[Enter]"           "\\C-j") ;; 処理系依存。
(define-key "[Return]"          "\\C-m")
(define-key "[Delete]"          "\\C-?")
(define-key "[Tab]"             "\\C-i")
(define-key "\\S-"              "#\^[ #\^[") ;; SuperキーをESC+ESCと定義。

(global-set-key "\\M-/"         #'universal-argument)
(global-set-key "\\C-d"         #'forward-char)
(global-set-key "\\C-f"         #'forward-word)
(global-set-key "\\C-q d"       #'end-of-line)
(global-set-key "\\C-q\\C-d"    #'end-of-line)
(global-set-key "\\C-s"         #'backward-char)
(global-set-key "\\C-a"         #'backward-word)
(global-set-key "\\C-q s"       #'beginning-of-line)
(global-set-key "\\C-q\\C-s"    #'beginning-of-line)
(global-set-key "\\C-w"         #'scroll-up)
(global-set-key "\\C-z"         #'scroll-down)
(global-set-key "[Backspace]"   #'delete-backward-char)
(global-set-key "\\C-g"         #'delete-char)
(global-set-key "[delete]"      #'delete-char)
(global-set-key "\\C-t"         #'kill-word)
(global-set-key "\\C-u"         #'delete-line-from-beginning-of-line) ;; ポイント位置から行頭までを削除。
(global-set-key "\\C-y"         #'delete-text) ;; 行全体を削除。
(global-set-key "\\C-q y"       #'kill-line) ;; ポイント位置から行末までを削除。
(global-set-key "\\C-q\\C-y"    #'kill-line) ;; [Ctrl]キー押しっぱなしによるご操作のガード。
(global-set-key "[Tab]"         #'complete-symbol) ;; [Tab]挿入はQuoted insertで行う。
(global-set-key "\\C-p"         #'quoted-insert)
(global-set-key "\\C-v"         #'wm-start-overwrite-mode)
(global-set-key "\\C-l"         #'redraw)
(global-set-key "[Enter]"       #'end-input)
(global-set-key "[Return]"      #'end-input)

(global-set-key "\\M-\\C-w"     #'append-next-kill)
(global-set-key "\\M-\\C-d"     #'down-list)
(global-set-key "\\M-\\C-n"     #'forward-list)
(global-set-key "\\M-\\C-f"     #'forward-sexp)

(global-set-key "\\M-\\C-u"     #'backward-up-list)
(global-set-key "\\M-\\C-p"     #'backward-list)

(global-set-key "\\M-\\C-b"     #'backward-sexp)
(global-set-key "\\M-\\C-p"     #'backward-list)

;;(global-set-key "\\C-x <"       #'scroll-left)
;;(global-set-key "\\C-x >"       #'scroll-right)

(global-set-key "\\C-s"         #'isearch-forward)

(global-set-key "\\M-\\C-k"     #'kill-sexp)

(global-set-key "\\M-z"         #'zap-to-char)
(global-set-key "\\M-\\\\"      #'delete-horizontal-space)
(global-set-key "\\M-s"         #'just-one-space)

(global-set-key "\\M-t"         #'transpose-words)
(global-set-key "\\M-\\C-t"     #'transpose-sexps)

(global-set-key "\\C-@"         #'set-mark-command)
(global-set-key "\\C-_"         #'set-mark-command)
(global-set-key "\\M-/"         #'mark-word)
(global-set-key "\\M-@"         #'mark-word)
(global-set-key "\\M-\\C-@"     #'mark-sexp)
(global-set-key "\\M-\\C-_"     #'mark-sexp)
(global-set-key "\\M-\\C-o"     #'mark-sexp)
(global-set-key "\\C-x\\C-x"    #'exchange-point-and-mark)

(global-set-key "\\C-w"         #'kill-region)
(global-set-key "\\M-w"         #'kill-ring-save)
(global-set-key "\\M-\\C-w"     #'append-next-kill)

(global-set-key "\\C-y"         #'yank)
(global-set-key "\\M-y"         #'yank-pop)

(global-set-key "\\C-x r s"     #'copy-to-register)
(global-set-key "\\C-x\\C-r s"  #'copy-to-register)
(global-set-key "\\C-x r S"     #'save-registers)
(global-set-key "\\C-x\\C-r S"  #'save-registers)
(global-set-key "\\C-x r R"     #'restore-registers)
(global-set-key "\\C-x\\C-r R"  #'restore-registers)
(global-set-key "\\C-x r i"     #'insert-register)
(global-set-key "\\C-x\\C-r i"  #'insert-register)

(global-set-key "\\C-x u"       #'advertised-undo)
(global-set-key "\\C-x U"       #'advertised-redo)

(global-set-key "\\C-x ("       #'start-kbd-macro)
(global-set-key "\\C-x )"       #'end-kbd-macro)
(global-set-key "\\C-x e"       #'call-last-kbd-macro)
(global-set-key "\\C-x q"       #'kbd-macro-query)
(global-set-key "\\C-x\\C-k"    #'edit-kbd-macro)

(global-set-key "\\M-i"         #'inspect-keycode)

(global-set-key "\\M-l"         #'downcase-word)
(global-set-key "\\M-u"         #'upcase-word)
(global-set-key "\\M-p"         #'move-to-matching-paren)
(global-set-key "\\C-x ="       #'what-cursor-position)

;; 拡張エスケープ・シーケンスモード1が有効な端末で機能するキー。
(global-set-key "\\M-\\[\C"     #'forward-char)         ;;right-arrow
(global-set-key "\\M-\\[\D"     #'backward-char)        ;;left-arrow
(global-set-key "\\S-\\[\C"     #'forward-word)         ;; M-right-arrow = ESC + Fn + '
(global-set-key "\\S-\\[\D"     #'backward-word)        ;; M-left-arrow = ESC + Fn + [

#+ :use-history-pkg
  (progn
    ;;(format t "history-pkg commands available.~%")
    (global-set-key "\\C-e"             #'previous-line)        ;; history-pkg使用時。
    (global-set-key "\\M-\\[A"          #'previous-line)        ;; モード1が有効な場合。up-arrow. [Fn]+[
    (global-set-key "\\C-x"             #'next-line)            ;; history-pkg使用時。
    (global-set-key "\\M-\\[\B"         #'next-line)            ;; モード1が有効な場合。down-arrow. [Fn]+/
    (global-set-key "\\M-<"             #'beginning-of-history) ;; 拡張機能。
    (global-set-key "\\M->"             #'end-of-history)       ;; 拡張機能。
    ) ;; end progn

(global-set-key nil             #'self-insert)

;;
;; 関数[complete-symbol]内で使用する[*complete-symbol-keymap*]に保管するキー列の定義。
;; [(get-key-def-for-complete-symbol)]により入力されたキー列に応じたキーワードを返す。
;; キーワード部分は文字列型以外であること。
;;
(complete-symbol-set-key "\\C-e"     :previous-candidate)       ;; 前の候補に移動する。
(complete-symbol-set-key "\\M-\\[A"  :previous-candidate)       ;; (↑) up arrow (Fn + [).
(complete-symbol-set-key "\\C-p"     :previous-candidate)

(complete-symbol-set-key "\\C-x"     :next-candidate)           ;; 次の候補に移動する。
(complete-symbol-set-key "\\M-\\[B"  :next-candidate)           ;; (↓) down arrow (Fn + /).
(complete-symbol-set-key "\\C-n"     :next-candidate)
(complete-symbol-set-key "\\C-i"     :next-candidate)           ;; Tab.

(complete-symbol-set-key "\\C-j"     :current-candidate)
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
(setf *complete-symbol-used-key-def* '("C-e" "C-x" "." "," "/" "C-r" "q")) 

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
