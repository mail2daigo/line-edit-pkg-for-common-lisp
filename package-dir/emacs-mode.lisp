;;;; last updated : 2026-05-17 09:37:29(JST)

;;;
;;; Emacs互換コマンド用のコマンドを定義(emacs-mode)。
;;;

;;
;; Meta(Alt) + Controlの組み合わせは端末ソフトやOSのショートカット・キーとして定義されている場合がある。
;; その場合、アプリケーション・レイヤで動作している本ソフトよりもOS側ショートカット・キー(第1順位)、端末
;; ソフト側ショートカット・キー(第2順位)にキー・シーケンスを横取りされる。以下で定義されたキー・シーケンス
;; が動作しない場合はまず、端末ソフト、それでもだめならOS側ショートカット・キーの定義を解除する。
;; 具体的なショートカット・キーの設定解除方法はOSと端末ソフトによって異なる。
;;

(clear-global-set-key)
(clear-key-def-for-complete-symbol)

;;(trace global-set-key)

;;
;; [define-key]は別名定義。
;;
(define-key "[Backspace]"       "\\C-h") ;; BSキー。
(define-key "[Enter]"           "\\C-j") ;; C-jとC-mのどちらが#\Newlineかは処理系依存。
(define-key "[Return]"          "\\C-m") ;; 同上。
(define-key "[Delete]"          "\\C-?")
(define-key "[Tab]"             "\\C-i")
(define-key "[ESC]"             "#\^[")
(define-key "\\S-"              "#\^[ #\^[") ;; SuperキーをESC+ESCと定義。

(global-set-key "\\C-@"         #'set-mark-command)
(global-set-key "\\C-_"         #'set-mark-command)
(global-set-key "\\C-^"         #'scroll-down)
(global-set-key "\\C-a"         #'beginning-of-line)
(global-set-key "\\C-b"         #'backward-char)
(global-set-key "\\C-d"         #'delete-char)
(global-set-key "[Delete]"      #'delete-char)
(global-set-key "\\C-e"         #'end-of-line)
(global-set-key "\\C-f"         #'forward-char)
(global-set-key "[Backspace]"   #'delete-backward-char)
(global-set-key "[Tab]"         #'complete-symbol)
(global-set-key "[Enter]"       #'end-input)
(global-set-key "\\C-k"         #'kill-line)
(global-set-key "\\C-l"         #'redraw)
(global-set-key "[Return]"      #'end-input)
(global-set-key "\\C-o"         #'set-mark-command)
(global-set-key "\\C-q"         #'quoted-insert)
(global-set-key "\\C-s"         #'isearch-forward)
(global-set-key "\\C-t"         #'transpose-chars)
(global-set-key "\\C-u"         #'universal-argument)
(global-set-key "\\C-v"         #'scroll-up)
(global-set-key "\\C-w"         #'kill-region)
(global-set-key "\\C-y"         #'yank)
(global-set-key "\\M-("         #'insert-parenthesis)
(global-set-key "\\M-,"         #'advertised-undo)
(global-set-key "\\M-."         #'advertised-redo)
(global-set-key "\\M-/"         #'mark-word)
(global-set-key "\\M-@"         #'mark-word)
(global-set-key "\\M-\\\\"      #'delete-horizontal-space)
(global-set-key "\\M-a"         #'beginning-of-text)
(global-set-key "\\M-b"         #'backward-word)
(global-set-key "\\M-c"         #'capitalize-word)
(global-set-key "\\M-d"         #'kill-word)
(global-set-key "\\M-e"         #'end-of-text)
(global-set-key "\\M-f"         #'forward-word)
(global-set-key "\\M-i"         #'inspect-keycode)
(global-set-key "\\M-k"         #'kill-text)
(global-set-key "\\M-l"         #'downcase-word)
(global-set-key "\\M-n"         #'next-word)
(global-set-key "\\M-o"         #'mark-sexp)
(global-set-key "\\M-p"         #'move-to-matching-paren)
(global-set-key "\\M-s"         #'just-one-space)
(global-set-key "\\M-t"         #'transpose-words)
(global-set-key "\\M-u"         #'upcase-word)
(global-set-key "\\M-v"         #'scroll-down)
(global-set-key "\\M-w"         #'kill-ring-save)
(global-set-key "\\M-y"         #'yank-pop)
(global-set-key "\\M-z"         #'zap-to-char)
(global-set-key "\\M-\\C-@"     #'mark-sexp)
(global-set-key "\\M-\\C-_"     #'mark-sexp)
(global-set-key "\\M-\\C-o"     #'mark-sexp)
(global-set-key "\\M-\\C-b"     #'backward-sexp)
(global-set-key "\\M-\\C-c"     #'line-edit-break)
(global-set-key "\\M-\\C-d"     #'down-list)
(global-set-key "\\M-\\C-e"     #'end-command-trace)
(global-set-key "\\M-\\C-f"     #'forward-sexp)
(global-set-key "\\M-\\C-h"     #'backward-kill-word)
(global-set-key "\\M-\\C-k"     #'kill-sexp)
(global-set-key "\\M-\\C-n"     #'forward-list)
(global-set-key "\\M-\\C-p"     #'backward-list)
(global-set-key "\\M-\\C-s"     #'start-command-trace)
(global-set-key "\\M-\\C-t"     #'transpose-sexps)
(global-set-key "\\M-\\C-u"     #'backward-up-list)
(global-set-key "\\M-\\C-w"     #'append-next-kill)
(global-set-key "\\C-x ("       #'start-kbd-macro)
(global-set-key "\\C-x )"       #'end-kbd-macro)
;;(global-set-key "\\C-x <"       #'scroll-left)
(global-set-key "\\C-x ="       #'what-cursor-position)
;;(global-set-key "\\C-x >"       #'scroll-right)
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
(global-set-key "\\C-x u"       #'advertised-undo)
(global-set-key "\\C-x U"       #'advertised-redo)
(global-set-key "\\C-x r R"     #'restore-registers)
(global-set-key "\\C-x \\C-r R" #'restore-registers)    ;; 同上。
(global-set-key "\\C-x r S"     #'save-registers)
(global-set-key "\\C-x \\C-r S" #'save-registers)       ;; 同上。
(global-set-key "\\C-x r i"     #'insert-register)
(global-set-key "\\C-x \\C-r i" #'insert-register)      ;; 同上。
(global-set-key "\\C-x r s"     #'copy-to-register)
(global-set-key "\\C-x \\C-r s" #'copy-to-register)     ;; 同上。

;; 拡張エスケープ・シーケンスモード1が有効な端末で機能するキー。
(global-set-key "\\M-\\[\D"     #'backward-char)        ;; left-arrow  (HHKB=Fn + ;)
(global-set-key "\\M-\\[\C"     #'forward-char)         ;; right-arrow (HHKB=Fn + ')
(global-set-key "\\S-\\[\D"     #'backward-word)        ;; M-left-arrow  = ESC + Fn + [
(global-set-key "\\S-\\[\C"     #'forward-word)         ;; M-right-arrow = ESC + Fn + '
;;(global-set-key (shift :right-arrow) #'forward-word)  ;; gnomeターミナルでは機能しない。
;;(global-set-key (alt :right-arrow) #'forward-sexp)

#+ :use-history-pkg
  (progn
    ;;(format t "history-pkg commands available.~%")
    (global-set-key "\\C-p"             #'previous-line)
    (global-set-key "\\M-\\[A"          #'previous-line)        ;; モード1が有効な場合。up-arrow. [Fn]+[
    (global-set-key "\\C-n"             #'next-line)
    (global-set-key "\\M-\\[\B"         #'next-line)            ;; モード1が有効な場合。down-arrow. [Fn]+/
    (global-set-key "\\M-<"             #'beginning-of-history)
    (global-set-key "\\M->"             #'end-of-history) ;; 履歴テキストをキルし履歴検索開始位置をリセット。
    (global-set-key "\\M-m"             #'set-global-mark)
    (global-set-key "\\M-g"             #'goto-global-mark)
    ) ;; end progn

(global-set-key "\\S-t" #'transpose-sexps)

(global-set-key nil #'self-insert)      ;otherwise self-insert it.

;;
;; 関数[complete-symbol]内で使用する[*complete-symbol-keymap*]に保管するキー列の定義。
;;
;; [global-set-key]が遷移表を[*global-keymap*]に作成するのに対して、遷移表を[*complete-symbol-keymap*]
;; に作成するのが唯一の違い。ひとつのキーワードに対して他種類のキー列を定義でき、キー列は複数の文字の列で良い。
;;
;; [(get-key-def-for-complete-symbol)]により[define-key-sequence-for-complete-symbol]で定義された
;; 入力キー列に応じたキーワードを返す(C-pに対して:previous-candidateを返すなど)。
;;
;; 定義中の空白文字は無視しているのでスペース・キーは定義できないが、未定義キー列の場合は定義済みキー列
;; と一致しなかった最初の文字を返すのでスペース・キー単体の入力は#\Spaceを返す。
;;
;; キーワード部分は文字列型以外であること。
;;
(complete-symbol-set-key "\\C-p"        :previous-candidate)    ;; ひとつ前の候補に戻る。
(complete-symbol-set-key "\\M-\\[A"     :previous-candidate)    ;; (↑) up arrow (HHKB=Fn + [).

(complete-symbol-set-key "\\C-n"        :next-candidate)        ;; 次の候補に移動する。
(complete-symbol-set-key "\\M-\\[B"     :next-candidate)        ;; (↓) down arrow (HHKB=Fn + /).
(complete-symbol-set-key "\\C-i"        :next-candidate)        ;; Tab.

(complete-symbol-set-key "\\C-j"        :current-candidate)     ;; 現在の候補に確定。
(complete-symbol-set-key "."            :current-candidate)     ;; [,][.][/]=[短][標準][長]
(complete-symbol-set-key "\\C-."        :current-candidate)     ;; [,][.][/]
(complete-symbol-set-key "\\M-."        :current-candidate)     ;; [,][.][/]

(complete-symbol-set-key "\\C-s"        :short-candidate)       ;; 短い候補に確定。
(complete-symbol-set-key ","            :short-candidate)       ;; [,][.][/]
(complete-symbol-set-key "\\C-,"        :short-candidate)       ;; [,][.][/]
(complete-symbol-set-key "\\M-,"        :short-candidate)       ;; [,][.][/]

(complete-symbol-set-key "\\C-l"        :long-candidate)        ;; 長い候補に確定。
(complete-symbol-set-key "/"            :long-candidate)        ;; [,][.][/]
(complete-symbol-set-key "\\C-/"        :long-candidate)        ;; [,][.][/]
(complete-symbol-set-key "\\M-/"        :long-candidate)        ;; [,][.][/]

(complete-symbol-set-key "r"            :redraw)                ;; 現在の行を再描画し
(complete-symbol-set-key "\\C-r"        :redraw)                ;; #\Newline以外の制御文字を削除する。
(complete-symbol-set-key "\\M-r"        :redraw)

(complete-symbol-set-key "q"            :cancel)                ;; 補完をキャンセル。
(complete-symbol-set-key "\\C-q"        :cancel)
(complete-symbol-set-key "\\M-q"        :cancel)

;; '(:previous-candidate :next-candidate :current-candidate :short-candidate :long-candidate :redraw :cancel)
;;(setf *complete-symbol-used-key-def* '("C-p" "C-n" "." "," "/" "C-r" "q")) 
(setf *complete-symbol-used-key-def* '("C-p" "C-n" "C-j" "C-s" "C-l" "C-r" "C-q")) 
