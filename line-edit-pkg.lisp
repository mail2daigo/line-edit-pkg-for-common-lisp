;;;
;;; last updated : 2026-06-20 16:43:37(JST)
;;;
;;; line-edit-pkg : Read line with customizable editor command, like Emacs, vi and WordMaster.
;;;     Licenced under GNU Library General Public Licence.
;;;     Copyright (C) 2001-2026 Isao Daigo (mail2daigo@gmail.com).
;;;
;;;     (line-edit)                     read and edit characters interactively.
;;;
;;; Emacs/vi/WordMaster互換コマンドを備えた行編集入力関数[line-edit]を提供するパッケージ。
;;;     ・Emacs/vi/WordMaster互換コマンドによる編集操作。
;;;     ・約800種類の全Common Lisp関数に対する補完入力(関数名のみ/引数情報付き)。
;;;     ・パッケージ移動ごとに全外部シンボル、内部シンボル、継承シンボルを補完入力対象とする機能。
;;;     ・ヒストリ・パッケージとの連携(bash/csh方式同時対応)。
;;;     ・日本語,英語,ドイツ語,フランス語,中国語(簡体字,繁体字),韓国語,ズールー語での動的メッセージ切り替え。
;;; に対応している。Common Lispで書かれたCommon Lisp用readlineライブラリとして機能する。
;;;
;;; rlwrapと比較するとヒストリ機能利用時のプロンプト定義が直感的で自作関数の評価結果を表示できるなど
;;; 自由度が高い。
;;;
;;; SBCL版とCLISP版の現状での唯一の違いは端末ソフトの画面幅を変更したときに自動的に変化を補足できるか否か。
;;;   SBCL版は自動的に端末幅の変化を補足して対応できるが、
;;;   CLISP版は端末幅変化を補足する手段がないので[C-l](redraw)コマンドで手動で対応する。
;;; セッション実行中に端末幅を変えなければ、それ以外はまったく同じ。
;;;
;;; 入力できる文字数は無制限。文字入力用ウインドウ幅を超えて文字を入力すると自動的に文字が左スクロールする。
;;; 特殊文字の文字コード定義は7 bit範囲なので、ASCII、UTF-8、SHIFT-JISで共通。UTF-16、EBCDICは未対応。
;;;
;;; 2026-06-20 [package-util.lisp]にパッケージの依存(ユース)関係をGraphvizで表示する関数[view-dot-graph]を追加。
;;; 2026-06-09 [package-util.lisp]内のpushdとpopdのバグを修正。
;;; 2026-06-07 [package-util.lisp]に用意されたパッケージ移動関数以外の方法で移動した場合の捕捉方法を修正。
;;; 2026-06-06 関数[history-repl]にrepl初期状態のパッケージを指定するオプショナル引数を追加した。
;;; 2026-06-05 [history-repl]の終了コマンドの記法を頑健にした("  ( exit  )"などの不要な空白文字類を許す)。
;;; 2026-06-04 動作に影響のない細かな修正。
;;; 2026-06-03 関数[history-repl]内で不正入力があった場合でも入力文字列を履歴に保存するようにした。
;;; 2026-05-16 関数[xterm-p]を実装。端末自体から端末名称番号を得るようにした。
;;; 2026-05-08 undo/redoを修正。バッチモードのサポートを廃止(コードは残してある)。
;;; 2026-05-07 [universal-argument]関連関数のバグを修正。
;;; 2026-05-02 [most-simple-condense]で特殊な条件下で発生するバグを修正→[define-key]を頑健化。
;;; 2026-05-01 初期設定ファイルの内容を整理した。
;;; 2026-04-27 関数[complete-symbol]内の候補選択用キーを自由に定義できるようにした。
;;; 2025-12-24 Control, Metaに加えてSuperキーも定義できるようにした。
;;;     Superキーはコマンド・キー(⌘)やWindowsキーに割り当てるのが自然だが端末ソフトやOSに
;;;     横取りされる場合が多く、文字コードとして受け取ることが困難な場合が多い。
;;;
;;;     本プログラムではESC+ESCをSuperキーとして解釈している。
;;;     altキーをMetaキーとして使う場合が多いが、端末ソフトはalt+[key]をタイプすると
;;;     ESC+[key]を返す。従ってESC+[key]としてもalt+[key]と同じである。
;;;
;;;     Meta+[key]がESC+[key]なので、Super+[key]はESC+ESC+[key]とした。
;;;     Super + Meta + Control + [key]などの3重修飾キーの定義も可能。Super, Meta, Control
;;;     の入力順は入力受け取り時に Super→Meta→Controlに正規化している。コマンド登録用の
;;;     関数global-set-keyの修飾子も同じ順序に正規化しているので、修飾子のタイプ順、定義順は自由。
;;;
;;; *NOTE*
;;;     compile or load with (push 'disable-hook *features*)
;;;     when DO NOT USE WITH history-pkg (C-n & C-p set to do nothing).
;;;

;; ヒストリ・パッケージを併用する場合はコンパイル前に以下を実行しておく。
;; コンパイル用ファイルに記述することを推奨(ソースコード内だとコンパイル時に有効にならない場合がある)。
;;
;;    (pushnew :use-history-pkg *features*)
;;

#+ :build-as-packages
(defpackage :line-edit-pkg
  (:use :common-lisp)
  (:use :support-functions)
  #+ :use-history-pkg  (:use :history-pkg)
  #+ :use-package-util (:use :package-util)
  (:nicknames :cl-rl :cl-readline)
  (:export
   #:absolute-path
   #:add-allow-yank-pop-commands
   #:add-kill-commands
   #:add-prefix-commands
   #:add-this-keyword
   #:add-this-keyword
   #:add-to-current-completion-keymap
   #:advertised-redo
   #:advertised-redo-command-p
   #:advertised-undo
   #:advertised-undo-command-p
   #:align-mark
   #:allow-yank-pop-commands-p
   #:append-break-char
   #:append-next-kill
   #:append-to-kill-ring
   #:ascii-printable-char-p
   #:assoc-by-symbol-name
   #:audio-bell
   #:auto-scroll-offset
   #:backward-char
   #:backward-down-list
   #:backward-kill-commands
   #:backward-kill-sexp
   #:backward-kill-white-space
   #:backward-kill-word
   #:backward-list
   #:backward-sexp
   #:backward-skip-to-normal-char
   #:backward-skip-white-space
   #:backward-up-list
   #:backward-word
   #:batch-str
   #:beginning-of-line
   #:beginning-of-line-p
   #:beginning-of-text
   #:beginning-of-text-p
   #:black-cursor ;; ラッパー関数。(set-cursor-color-by-name 'black)と同じ。
   #:blink-paren
   #:blink-paren-deley
   #:blink-paren-just-inserted
   #:blink-paren-p
   #:blue-cursor ;; ラッパー関数。(set-cursor-color-by-name 'blue)と同じ。
   #:break-char-p
   #:call-by-keyboard-p
   #:call-last-kbd-macro
   #:call-last-kbd-macro-forever
   #:can-use-color-cursor ;; カラー・カーソル機能の有無を[t/nil]で設定する関数。
   #:can-use-color-cursor-p ;; カラー・カーソル機能の有無を返す関数。
   #:capitalize-word
   #:case-sensitive-read
   #:change-interval-second
   #:char-to-digit
   #:clear-global-set-key
   #:clear-key-def-for-complete-symbol
   #:clear-kill-ring
   #:clear-line
   #:command-trace
   #:command-trace-list
   #:command-undo-info
   #:complete-symbol
   #:complete-symbol-start-char
   #:complex-do-command
   #:condense
   #:condense-keymaps
   #:config-file-abs-path
   #:config-file-dir
   #:control-code
   #:control-prefix-p
   #:control-to-char
   #:cooked-mode
   #:cooked-mode
   #:copy-to-register
   #:corres-paren
   #:current-char
   #:current-completion-keymap
   #:current-cursor-color-name ;; returns one of color name or returns [nil].
   #:current-directory-pathname-string
   #:current-directory-pathname-string
   #:current-line
   #:current-line-base
   #:current-physical-column-size
   #:current-word-length
   #:cursor-info-file-name ;; カラー・カーソル機能の有無やカーソル色情報を記録するファイル名を返す関数。
   #:cyan-cursor           ;; ラッパー関数。(set-cursor-color-by-name 'cyan)と同じ。
   #:debug-level
   #:debug-print
   #:debug-print-p
   #:default-completion-keymap ;; = (condense (user-completion-keymap) (syntax-completion-keymap))
   #:define-key
   #:define-key-sequence-for-complete-symbol
   ;;#:define-keymap
   #:defined-key-list
   #:delete-backward-char
   #:delete-char
   #:delete-horizontal-space
   #:digit-to-char
   #:display-line
   #:display-range
   #:distill-line
   #:do-command
   #:do-nothing
   #:do-write-file
   #:down-list
   #:downcase-word
   #:dprt
   #:edit-kbd-macro
   #:editor-mode
   #:editor-mode-file
   #:empty-text-p
   #:enable-audio-bell
   #:end-command-trace
   #:end-input
   #:end-input-p
   #:end-kbd-macro
   #:end-kbd-macro-p
   #:end-of-line
   #:end-of-line-p
   #:end-of-text
   #:end-of-text-p
   #:exactly-matched
   #:exchange-point-and-mark
   #:exec-command
   #:exit-runtime
   #:extract-function
   #:find-current-and-home-dir
   #:find-file
   #:forward-char
   #:forward-list
   #:forward-sexp
   #:forward-word
   #:get-candidates
   #:get-command
   #:get-def
   #:get-key-def-for-complete-symbol
   #:getch
   #:getchar
   #:getenv
   #:getsym
   #:global-keymap
   #:global-set-key
   #:goto-history           ;; (goto-history [num])
   #:goto-history-by-string ;; (goto-history-by-string [str]) backward search.
   #:green-cursor           ;; ラッパー関数。(set-cursor-color-by-name 'green)と同じ。
   #:gryph-to-description
   #:half-life-sec          ;; 補完候補優先順位を決める計算式内の指数減衰スコア時間(秒数)。初期値は2週間。
   #:half-life-hour         ;; 同上(時間単位)。中長期での安定なら14日程度。短期に敏感に反映させるなら数時間。
   #:head
   #:help-complete
   #:help-edit
   #:highlight-mode
   #:highlight-mode-putc
   #:home-directory-pathname-string
   #:home-directory-pathname-string
   #:hscroll-unit
   #:ignore-invalid-command-p
   #:in-string-or-literal-p
   #:in-word-p
   #:insert
   #:insert-file
   #:insert-parenthesis
   #:insert-register
   #:inspect-keycode
   #:inverse-off
   #:inverse-on
   #:invert-list
   #:isearch-forward
   #:iso-639-1-language-list ;; ISO 639-1で定義されている第1主要言語の2文字略称と正式名のペアのリスト。
   #:iso-date-string ;; ISO形式の現在日付を表す文字列を返す関数。
   #:iso-time-string ;; ISO形式の現在時刻を表す文字列を返す関数。
   #:iso-timezone    ;; UTCとの時差。日本の場合UTC+9:00。
   #:jump-and-return-balanced-paren
   #:just-one-space
   #:kbd-macro-query
   #:kbd-macro-query-time
   #:key-seq-to-normalized-symbol-seq
   #:key-seq-to-symbol-seq
   #:kill-commands-p
   #:kill-line
   #:kill-region
   #:kill-ring-max
   #:kill-ring-save
   #:kill-ring-suspend
   #:kill-sexp
   #:kill-text
   #:kill-white-space
   #:kill-word
   #:last-char
   #:last-command
   #:last-kbd-macro
   #:less
   #:less
   #:line-edit
   #:line-edit-break
   #:line-edit-command-loop
   #:line-edit-put-newline
   #:line-edit-version
   #:line-length
   #:lisp-extension
   #:load-macro
   #:macro-file
   #:macro-mode-p
   #:magenta-cursor ;; ラッパー関数。(set-cursor-color-by-name 'magenta)と同じ。
   #:make-completion-keymap
   #:make-date-and-time-string
   #:make-description
   #:make-info-list
   #:make-info-list-for-package
   #:make-package-symbol-completion-keymap
   #:make-parenthesis-list
   #:make-trans-table
   #:mark
   #:mark-sexp
   #:mark-word
   #:max-column
   #:member-by-symbol-name
   #:message                ;; multi-lingual-Message.
   #:message-list-changed-p ;; メッセージ・リストが変更されていれば[t]。
   #:meta-prefix-p
   #:meta-string-to-number
   #:ml-message ;; MultiLingual Message.
   #:move-logical-cursor-left
   #:move-logical-cursor-right
   #:move-logical-cursor-to
   #:move-point-left
   #:move-point-right
   #:move-point-to
   #:move-to-matching-paren
   #:multiply-repeat-count
   #:narrow-break-char
   #:native-language ;; ユーザの第1使用言語を返す関数。設定は[*native-language*]
   #:need-refresh-line
   #:need-refresh-line-p
   #:newline-symbol
   #:next-newline-position
   #:next-word
   #:normal-char-p
   #:normalize-symbol-seq
   #:pack
   #:packed-line
   #:packed-text
   #:parenthesis-list
   #:parse-dir
   #:parse-request-modify-other-key-response
   #:paste
   #:peek-ahead
   #:physical-line-window-size
   #:point
   #:pop-kill-ring
   #:post-do-command
   #:postlude-input
   #:pre-do-command
   ;;#:prefix-commands-p
   #:previous-newline-position
   #:push-command-trace-list
   #:push-keyboard-macro
   #:push-kill-ring
   #:push-redo-info
   #:push-undo-info
   #:putc
   #:putch
   #:putnum-as-char
   #:quoted-insert
   #:raw-mode
   #:raw-mode
   #:read-keyword-file
   #:read-number
   #:read-registered-message ;; メッセージ・リストが記録されたファイルを読み込む関数。
   #:record-color-cursor-info ;; カラー・カーソル機能の有無と、挿入モード時のカー−ソル色の情報を記録する。
   #:record-editor-mode ;; エディタ・モード用の初期設定がない場合に備えて前回のエディタ・モードを記録しておく。
   #:red-cursor ;; ラッパー関数。(set-cursor-color-by-name 'red)と同じ。
   #:redo
   #:redo-info
   #:redraw
   #:refresh-prompt-and-get-start
   #:register
   ;;#:registered-message-file ;; メッセージ・リストを保存するファイル名。
   ;;#:registered-message-list ;; メッセージ・リストを保持するリスト。
   #:registers-file
   #:remove-break-char
   #:remove-preceding-white-spaces
   #:repeat-count
   #:reset-cursor-color         ;; カーソル色を標準色にリセットする関数。
   #:reset-parenthesis-list
   #:reset-repeat-count
   #:reset-scroll
   #:reset-undo-info
   #:restore-line
   #:restore-registers
   #:reverse-do
   #:save-backward-delete-undo-info
   #:save-backward-kill-undo-info
   #:save-buffer
   #:save-completion-dictionaries
   #:save-delete-undo-info
   #:save-insert-undo-info
   #:save-kill-undo-info
   #:save-line
   #:save-macro
   #:save-mark-info
   #:save-registers
   #:save-self-insert-undo-info
   #:save-undo-info
   #:scroll-down
   #:scroll-left
   #:scroll-right
   #:scroll-up
   #:select-language            ;; 優先言語を設定する関数。
   #:select-repeat-count
   #:selected-language          ;; 現在の優先言語を返す関数。
   #:self-insert
   #:self-insert-newline
   #:self-insert-space
   #:self-insert-string
   #:set-balanced-paren
   #:set-break-code
   #:set-command-trace
   #:set-command-trace-list
   #:set-command-undo-info
   #:set-current-completion-keymap
   #:set-cursor-color           ;; '(#xrr #xgg #xbb) ;; 全ての状況でカーソル色を即時変更する。
   #:set-cursor-color-by-name   ;; '(black red green yellow blue magenta cyan white) ;; 同上。
   #:set-cursor-color-for-insert-mode ;; 挿入モード時のカーソル色を設定する。
   #:set-editor-mode
   #:set-global-keymap
   #:set-keymap
   #:set-last-command
   #:set-last-command-inhibit-list
   #:set-mark-command
   #:set-redo-info
   #:set-register
   ;;#:set-repeat-count
   #:set-undo-control
   #:set-undo-info
   #:shell
   #:short-current-directory-pathname-string
   #:skip-bar-string
   #:skip-double-quoted-string
   #:skip-quoted-string
   #:skip-sharp-backslash-string
   #:skip-string-or-literal
   #:skip-to-normal-char
   #:skip-white-space
   #:split-string
   #:start-command-trace
   #:start-kbd-macro
   #:start-kbd-macro-p
   #:string-equal-by-symbol-name
   #:sync-line
   #:syntax-completion-keymap   ;; returns Common Lisp's syntax info.
   #:test-can-use-color-cursor  ;; ユーザにカーソル色が変化するかを判断してもらう関数。
   #:text-length
   #:time12-string              ;; 12時間形式での現在時刻をHH:MM:SS{am/pm}形式の文字列で返す関数。
   #:to-circumflex-accent-char
   #:touch
   #:trace-list
   #:transpose-chars
   #:transpose-sexps
   #:transpose-words
   #:undo
   #:undo-control
   #:undo-info
   #:undo-limit
   #:universal-argument
   #:universal-argument-command-p
   #:universal-argument-digit-separater
   #:unpack
   #:unset-balanced-paren
   #:up-list
   #:upcase-word
   #:user-completion-keymap     ;; returns user defined info.
   #:user-keymap-added-p
   #:view-all-registers
   #:view-register
   #:what-cursor-position
   #:what-language              ;; ISO 639-1の2文字の短縮言語名シンボルから正式言語名シンボルを返す関数。
   #:white-cursor               ;; ラッパー関数。(set-cursor-color-by-name 'white)と同じ。
   #:white-space-p
   #:wide-break-char
   #:write-file
   #:write-file-to
   #:write-keyword-file-with-backup
   #:write-registered-message   ;; メッセージ・リストを[(registered-message-file)]に書き出す関数。
   #:writeln
   #:xsleep
   #:xterm-p                    ;; xterm(互換)端末か否かを返す関数。(互換)端末なら該当端末名を返す。
   #:yank
   #:yank-pop
   #:yellow-cursor              ;; ラッパー関数。(set-cursor-color-by-name 'yellow)と同じ。
   #:zap-to-char
   #:zero-base-physical-cursor-position
   ) ;; end :export
  )  ;; end defpackage

#+ build-as-packages (in-package :line-edit-pkg)

(declaim (optimize (safety 0) (speed 3) (space 0) (debug 0) (compilation-speed 0))) ;; maximum speed.
;;(declaim (optimize (safety 3) (speed 0) (space 0) (debug 3) (compilation-speed 0))) ;; maximum safety.

(declaim (ftype (function (t) t) need-refresh-line))
(declaim (ftype (function () t)  need-refresh-line-p))
(declaim (ftype (function () integer) current-physical-column-size))
(declaim (ftype (function () integer) update-physical-column-size))
(declaim (ftype (function (t t t) t) set-key))
(declaim (ftype (function () t) clear-symbol-buffer))
(declaim (ftype (function (&optional t t) t) true-getsym))
(declaim (ftype (function (&optional t t) t) getsym))

(defconstant +line-edit-version+ "line-edit-pkg: Version 2026-06-20 16:41:02")

(defconstant +small-a+                  "small-a")
(defconstant +small-b+                  "small-b")
(defconstant +small-c+                  "small-c")
(defconstant +small-d+                  "small-d")
(defconstant +small-e+                  "small-e")
(defconstant +small-f+                  "small-f")
(defconstant +small-g+                  "small-g")
(defconstant +small-h+                  "small-h")
(defconstant +small-i+                  "small-i")
(defconstant +small-j+                  "small-j")
(defconstant +small-k+                  "small-k")
(defconstant +small-l+                  "small-l")
(defconstant +small-m+                  "small-m")
(defconstant +small-n+                  "small-n")
(defconstant +small-o+                  "small-o")
(defconstant +small-p+                  "small-p")
(defconstant +small-q+                  "small-q")
(defconstant +small-r+                  "small-r")
(defconstant +small-s+                  "small-s")
(defconstant +small-t+                  "small-t")
(defconstant +small-u+                  "small-u")
(defconstant +small-v+                  "small-v")
(defconstant +small-w+                  "small-w")
(defconstant +small-x+                  "small-x")
(defconstant +small-y+                  "small-y")
(defconstant +small-z+                  "small-z")
(defconstant +capital-A+                "capital-A")
(defconstant +capital-B+                "capital-B")
(defconstant +capital-C+                "capital-C")
(defconstant +capital-D+                "capital-D")
(defconstant +capital-E+                "capital-E")
(defconstant +capital-F+                "capital-F")
(defconstant +capital-G+                "capital-G")
(defconstant +capital-H+                "capital-H")
(defconstant +capital-I+                "capital-I")
(defconstant +capital-J+                "capital-J")
(defconstant +capital-K+                "capital-K")
(defconstant +capital-L+                "capital-L")
(defconstant +capital-M+                "capital-M")
(defconstant +capital-N+                "capital-N")
(defconstant +capital-O+                "capital-O")
(defconstant +capital-P+                "capital-P")
(defconstant +capital-Q+                "capital-Q")
(defconstant +capital-R+                "capital-R")
(defconstant +capital-S+                "capital-S")
(defconstant +capital-T+                "capital-T")
(defconstant +capital-U+                "capital-U")
(defconstant +capital-V+                "capital-V")
(defconstant +capital-W+                "capital-W")
(defconstant +capital-X+                "capital-X")
(defconstant +capital-Y+                "capital-Y")
(defconstant +capital-Z+                "capital-Z")
(defconstant +digit-0+                  "digit-0")
(defconstant +digit-1+                  "digit-1")
(defconstant +digit-2+                  "digit-2")
(defconstant +digit-3+                  "digit-3")
(defconstant +digit-4+                  "digit-4")
(defconstant +digit-5+                  "digit-5")
(defconstant +digit-6+                  "digit-6")
(defconstant +digit-7+                  "digit-7")
(defconstant +digit-8+                  "digit-8")
(defconstant +digit-9+                  "digit-9")
(defconstant +plus-sign+                "plus-sign")
(defconstant +less-than-sign+           "less-than-sign")
(defconstant +equals-sign+              "equals-sign")
(defconstant +greater-than-sign+        "greater-than-sign")
(defconstant +dollar-sign+              "dollar-sign")
(defconstant +backquote+                "backquote")
(defconstant +circumflex-accent+        "circumflex-accent")
(defconstant +tilde+                    "tilde")
(defconstant +sharp-sign+               "sharp-sign")
(defconstant +percent-sign+             "percent-sign")
(defconstant +ampersand+                "ampersand")
(defconstant +asterisk+                 "asterisk")
(defconstant +at-sign+                  "at-sign")
(defconstant +left-square-bracket+      "left-square-bracket")
(defconstant +backslash+                "backslash")
(defconstant +right-square-bracket+     "right-square-bracket")
(defconstant +left-brace+               "left-brace")
(defconstant +vertical-bar+             "vertical-bar")
(defconstant +right-brace+              "right-brace")
(defconstant +exclamation-mark+         "exclamation-mark")
(defconstant +double-quote+             "double-quote")
(defconstant +single-quote+             "single-quote")
(defconstant +left-parenthesis+         "left-parenthesis")
(defconstant +right-parenthesis+        "right-parenthesis")
(defconstant +comma+                    "comma")
(defconstant +underscore+               "underscore")
(defconstant +minus-sign+               "minus-sign")
(defconstant +period+                   "period")
(defconstant +slash+                    "slash")
(defconstant +colon+                    "colon")
(defconstant +semicolon+                "semicolon")
(defconstant +question-mark+            "question-mark")
(defconstant +control-string+           "control")
(defconstant +meta-string+              "meta")         ;; Meta key. Usually assigned to alt key.
(defconstant +super-string+             "super")        ;; Super key. Usally assigned to command key.

(defconstant +modifier-priority+        (list +super-string+ +meta-string+ +control-string+))

(defconstant +letter-a+                 "letter-a")
(defconstant +letter-b+                 "letter-b")
(defconstant +letter-c+                 "letter-c")
(defconstant +letter-d+                 "letter-d")
(defconstant +letter-e+                 "letter-e")
(defconstant +letter-f+                 "letter-f")
(defconstant +letter-g+                 "letter-g")
(defconstant +letter-h+                 "letter-h")
(defconstant +letter-i+                 "letter-i")
(defconstant +letter-j+                 "letter-j")
(defconstant +letter-k+                 "letter-k")
(defconstant +letter-l+                 "letter-l")
(defconstant +letter-m+                 "letter-m")
(defconstant +letter-n+                 "letter-n")
(defconstant +letter-o+                 "letter-o")
(defconstant +letter-p+                 "letter-p")
(defconstant +letter-q+                 "letter-q")
(defconstant +letter-r+                 "letter-r")
(defconstant +letter-s+                 "letter-s")
(defconstant +letter-t+                 "letter-t")
(defconstant +letter-u+                 "letter-u")
(defconstant +letter-v+                 "letter-v")
(defconstant +letter-w+                 "letter-w")
(defconstant +letter-x+                 "letter-x")
(defconstant +letter-y+                 "letter-y")
(defconstant +letter-z+                 "letter-z")

;; 特殊文字の文字コード定義。7 bit範囲なので、ascii、UTF-8、SHIFT-JISで共通。
(defconstant +ctrl-@+                 (code-char  0)) ;;#\^@ ;; #\^Xという表記は処理系独自の拡張機能。
(defconstant +ctrl-a+                 (code-char  1)) ;;#\^A
(defconstant +ctrl-b+                 (code-char  2)) ;;#\^B
(defconstant +ctrl-c+                 (code-char  3)) ;;#\^C
(defconstant +ctrl-d+                 (code-char  4)) ;;#\^D
(defconstant +ctrl-e+                 (code-char  5)) ;;#\^E
(defconstant +ctrl-f+                 (code-char  6)) ;;#\^F
(defconstant +ctrl-g+                 (code-char  7)) ;;#\^G
(defconstant +ctrl-h+                 (code-char  8)) ;;#\^H
(defconstant +ctrl-i+                 (code-char  9)) ;;#\^I
(defconstant +ctrl-j+                 (code-char 10)) ;;#\^J
(defconstant +ctrl-k+                 (code-char 11)) ;;#\^K
(defconstant +ctrl-l+                 (code-char 12)) ;;#\^L
(defconstant +ctrl-m+                 (code-char 13)) ;;#\^M
(defconstant +ctrl-n+                 (code-char 14)) ;;#\^N
(defconstant +ctrl-o+                 (code-char 15)) ;;#\^O
(defconstant +ctrl-p+                 (code-char 16)) ;;#\^P
(defconstant +ctrl-q+                 (code-char 17)) ;;#\^Q
(defconstant +ctrl-r+                 (code-char 18)) ;;#\^R
(defconstant +ctrl-s+                 (code-char 19)) ;;#\^S
(defconstant +ctrl-t+                 (code-char 20)) ;;#\^T
(defconstant +ctrl-u+                 (code-char 21)) ;;#\^U
(defconstant +ctrl-v+                 (code-char 22)) ;;#\^V
(defconstant +ctrl-w+                 (code-char 23)) ;;#\^W
(defconstant +ctrl-x+                 (code-char 24)) ;;#\^X
(defconstant +ctrl-y+                 (code-char 25)) ;;#\^Y
(defconstant +ctrl-z+                 (code-char 26)) ;;#\^Z
(defconstant +ctrl-[+                 (code-char 27)) ;;#\^[
(defconstant +ctrl-\+                 (code-char 28)) ;;#\^\\
(defconstant +ctrl-]+                 (code-char 29)) ;;#\^]
(defconstant +ctrl-^+                 (code-char 30)) ;;#\^^
(defconstant +ctrl-_+                 (code-char 31)) ;;#\^_
(defconstant +ctrl-?+                 (code-char 127)) ;;#\Rubout ;; [Delete]
(defconstant +meta-code+              (code-char 27)) ;;#\^[ ;; key-code for Meta key.
(defconstant +alt-code+               (code-char 27)) ;;#\^[ ;; key-code for Alt key.
(defconstant +eos+                    (cons nil nil))
(defconstant +ESC+                    (code-char 27))
(defconstant +Tab+                    (code-char 9))
(defconstant +delete-char+            (code-char 127))

#+ sbcl  (defconstant +compiled-ext+ ".fasl") ;; コンパイル済みファイルの拡張子。
#+ clisp (defconstant +compiled-ext+ ".fas")
#+ gcl   (defconstant +compiled-ext+ ".o")

;; xterm拡張エスケープ・シーケンスのモード1における基数(1)とshiftキーの加算値(1)を加味した加算値。
;;
;;      基数:    1
;;      shift:  +1
;;      alt:    +2
;;      ctrl:   +4
;;
;; ==>  shift+alt       = 1+1+2   = 4
;;      shift+ctrl      = 1+1+4   = 6
;;      shift+alt+ctrl  = 1+1+2+4 = 8
;;
(defconstant +base+              1)
(defconstant +shift+            +1)
(defconstant +alt+              +2)
(defconstant +shift+alt+        +3)
(defconstant +ctrl+             +4)
(defconstant +shift+ctrl+       +5)
(defconstant +alt+ctrl+         +6)
(defconstant +shift+alt+ctrl+   +7)

(defconstant +rubout+                   "[Rubout]")
(defconstant +space+                    "[Space]")
(defconstant +backspace+                "[Backspace]")
(defconstant +newline+                  "[Newline]")
(defconstant +return+                   "[Return]")
(defconstant +linefeed+                 "[Linefeed]")
(defconstant +delete+                   "[Delete]")

(defconstant +control-prefix+           '(#\C #\-))
(defconstant +meta-prefix+              '(#\M #\-))
(defconstant +super-prefix+             '(#\S #\-))
(defconstant +backslash-ch+             #\\)
(defconstant +left-square-bracket-ch+   #\[)
(defconstant +right-square-bracket-ch+  #\])
(defconstant +vertical-bar-ch+          #\|)
(defconstant +underscore-ch+            #\_)

;;; 通常は[global-set-key]で[#'complete-symbol]と関連付けたキーに揃える。1文字のみ。一般的には共に[Tab]。
(defconstant +complete-symbol-start-char+ +Tab+)

(defconstant +number-char+ '(#\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9))
(defconstant +digit-symbol+ (list +digit-0+ +digit-1+ +digit-2+ +digit-3+ +digit-4+ +digit-5+
                                  +digit-6+ +digit-7+ +digit-8+ +digit-9+))
(defconstant +white-space-char+ (list #\Space #\Newline +Tab+))
(defconstant +narrow-break-char+
  '(#\" #\# #\' #\= #\| #\\ #\` #\; #\, #\. #\< #\> #\( #\) #\[ #\] #\{ #\} #\? #\+ #\~))
(defconstant +wide-break-char+ (append +narrow-break-char+ '(#\- #\* #\: #\/ #\$ #\@)))
(defconstant +common-lisp-break-char+ (append '(#\( #\) #\' #\` #\, #\; #\: #\") +white-space-char+))
(defconstant +priority-half-life-init+ (* 14 24 60 60)) ;; 補完候補の優先順位計算用指数減衰スコア初期値(14日)。
(defconstant +complete-symbol-used-key-def-init+ '("C-p" "C-n" "." "," "/" "C-r" "q")) ;; emacs-mode.
;;(defconstant +complete-symbol-used-key-def-init+ '("j" "k" "." "," "/" "C-r" "q"))     ;; vi-mode.
;;(defconstant +complete-symbol-used-key-def-init+ '("C-e" "C-x" "." "," "/" "C-r" "q")) ;; WordMaster-mode. 
(defconstant +xterm-color-terminals+ '(:vt340 :vt382 :vt420 :vt510 :vt520 :vt525))
(defparameter *left-parenthesis-list*  '( #\( ) )       ;; 左カッコ類の定義。
;;(defparameter *left-parenthesis-list*  '(#\( #\< #\{ #\[) )
(defparameter *right-parenthesis-list* '( #\) ) )       ;; 右カッコ類の定義。
;;(defparameter *right-parenthesis-list* '(#\) #\> #\} #\]) )
(defparameter *parenthesis-list* (append *left-parenthesis-list* *right-parenthesis-list*))
(defparameter *last-command-inhibit-list* nil)
(defparameter *otherwise-function* '#'self-insert)      ;; コマンドが定義されていない場合に実行する関数。
(defparameter *kill-commands*                           ;; 削除系コマンドのリスト。
  '(#'kill-line #'kill-region #'kill-word #'kill-sexp
    #'zap-to-char #'backward-kill-word
    #'kill-ring-save #'kill-text #'append-next-kill)
  )
(defparameter *prefix-commands* '(#'universal-argument)) ;; 前置引数用関数の定義。
;;(defparameter *prefix-commands* '(universal-argument))
(defparameter *allow-yank-pop-commands*                 ;; yank類関数の定義。
  (append '(#'yank #'yank-pop) *prefix-commands*))
;;(defparameter *allow-yank-pop-commands*
;;  (append '(yank yank-pop) *prefix-commands*))
(defparameter *editor-mode-file* "set-editor-mode")     ;; エディタ・モードの初期値を定めるファイル名。
(defparameter *syntax-info-file* "syntax-info-list.lisp") ;; 標準関数の引数情報を格納したファイル名。
(defparameter *user-info-file* "user-info-list.lisp")   ;; ユーザが追加する補完候補を格納したファイル名。
(defparameter *syntax-info-list* nil)                   ;; 標準関数の引数情報を備えた補完候補リスト。
(defparameter *syntax-completion-keymap* nil)           ;; 標準関数に対する遷移表。
(defparameter *syntax-target-words* nil)                ;; 標準関数の名前一覧。
(defparameter *user-info-list* nil)                     ;; ユーザが追加する補完候補リスト。
(defparameter *user-completion-keymap* nil)             ;; ユーザが追加した補完候補に対する遷移表。
(defparameter *user-target-words* nil)                  ;; ユーザが追加した補完候補名の名前一覧。
(defparameter *default-completion-keymap* nil)          ;; [*syntax-completion-keymap*]と
                                                        ;; [*user-completion-keymap*]を合成した遷移表。
(defparameter *current-completion-keymap* nil)          ;; [*default-completion-keymap*]とパッケージ
                                                        ;; ごとの遷移表を合成した遷移表。保存しない。
(defparameter *default-editor-mode* "emacs-mode")       ;; default editor mode.
(defparameter *terminal-resized-p* t)                   ;; 端末の文字幅が変わったら[t]にする。
(defparameter *last-terminal-size* 80)                  ;; 前回の端末幅を記録しておく。正整数(>0)。
(defparameter *user-keymap-added-p* nil)                ;; [*user-info-list*]に補完対象を追加したか。
(defparameter *sleep-time* 0.3)                         ;; [complete-symbol]内での確認メッセージ表示秒数。
(defparameter *long-sleep-time* 1.5)                    ;; 長めの確認メッセージ表示秒数。
(defparameter *line-edit-init* "line-edit-init.lisp")   ;; このパッケージ用の初期設定ファイル名。
(defparameter *ignore-invalid-command* t)               ;; コマンドとして未定義の制御文字を無視するか？
(defparameter *complete-symbol-keymap* nil)             ;; 関数[complete-symbol]内で使用するキー列を保管。
(defparameter *complete-symbol-used-key-def* nil)       ;; 関数[complete-symbol]内で使用するキー。
(defparameter *default-repeat-count* 4)                 ;; 繰り返し回数のデフォルト。
(defparameter *repeat-count* 1)
(defparameter *universal-argument-digit-separater* #\/) ;; ユニバーサル引数指定での数値指定区切り文字。
(defparameter *time-out-time* 1/50)                     ;; xterm端末へ入力データ存在問い合わせ待ち時間。秒。
(defparameter *sleep-for-wait* 1/10000)                 ;; 待機なし先読みでの入力文字存在問い合わせ待ち時間。
(defparameter *long-sleep-for-wait* 1/50)               ;; listenでの問い合わせ待ち時間。

#|
(defparameter *package-exclusion-list*                  ;; パッケージ名補完の対象外とするパッケージ。
  #+sbcl
  '(
    "asdf/action"
    "asdf/backward-interface"
    "asdf/backward-internals"
    "asdf/bundle"
    "asdf/component"
    "asdf/concatenate-source"
    "asdf/find-component"
    "asdf/find-system"
    "asdf/footer"
    "asdf/forcing"
    "asdf/interface"
    "asdf/lisp-action"
    "asdf/operate"
    "asdf/operation"
    "asdf/output-translations"
    "asdf/package-inferred-system"
    "asdf/parse-defsystem"
    "asdf/plan"
    "asdf/session"
    "asdf/source-registry"
    "asdf/system"
    "asdf/system-registry"
    "asdf/upgrade"
    "asdf/user"
    ;; "common-lisp"
    ;; "common-lisp-user"
    ;; "keyword"
    "ql-abcl"
    "ql-allegro"
    "ql-bundle"
    "ql-ccl"
    "ql-cdb"
    "ql-clasp"
    "ql-clisp"
    "ql-cmucl"
    "ql-config"
    "ql-dist"
    "ql-dist-user"
    "ql-ecl"
    "ql-gunzipper"
    "ql-http"
    "ql-impl"
    "ql-impl-util"
    "ql-info"
    "ql-lispworks"
    "ql-mezzano"
    "ql-minitar"
    "ql-mkcl"
    "ql-network"
    "ql-progress"
    "ql-sbcl"
    "ql-scl"
    "ql-setup"
    "ql-util"
    "quicklisp-client"
    "sb-alien"
    "sb-alien-internals"
    "sb-aprof"
    "sb-assem"
    "sb-bignum"
    "sb-brothertree"
    "sb-bsd-sockets"
    "sb-bsd-sockets-internal"
    "sb-c"
    "sb-debug"
    "sb-di"
    "sb-disassem"
    "sb-eval"
    "sb-ext"
    "sb-fasl"
    "sb-format"
    "sb-gray"
    "sb-impl"
    "sb-int"
    "sb-kernel"
    "sb-lockless"
    "sb-loop"
    "sb-mop"
    "sb-pcl"
    "sb-posix"
    "sb-pretty"
    "sb-profile"
    "sb-regalloc"
    "sb-sequence"
    "sb-sys"
    "sb-thread"
    "sb-unicode"
    "sb-unix"
    "sb-vm"
    "sb-walker"
    "sb-x86-64-asm"
    "uiop/backward-driver" 
    "uiop/common-lisp"
    "uiop/configuration" 
    "uiop/driver" 
    "uiop/filesystem" 
    "uiop/image"
    "uiop/launch-program" 
    "uiop/lisp-build" 
    "uiop/os" 
    "uiop/package"
    "uiop/pathname" 
    "uiop/run-program" 
    "uiop/stream" 
    "uiop/utility" 
    "uiop/version")
  #+ clisp
  '(
    "charset"
    "clos"
    ;;"common-lisp"
    ;;"common-lisp-user"
    ;; "keyword"
    "cs-common-lisp"
    "cs-common-lisp-user"
    "custom"
    "exporting"
    "ext"
    "ffi"
    "gray"
    "gstream"
    "i18n"
    "posix"
    "readline"
    "regexp"
    "screen"
    "socket"
    "system"
    "wildcard")
  )
|#

;;;
;;; システムとしての各種初期値。
;;;
(defvar *ctrl-g* +ctrl-g+)              ;break code for C-g.
(defvar *kill-ring-max* 30)             ;kill-ring stack size.
(defvar *blink-paren-deley* 3/10)       ;how many sec. for BLINKING paren ?
(defvar *blink-paren-just-inserted* t)  ;Is blink paren only inserted ?
(defvar *undo-limit* 300)               ;undo limit. nil means unlimited.
(defvar *auto-scroll-offset* t)         ;auto scroll offset. t means auto.
(defvar *newline-symbol* #\$)           ;display character for #\Newline.
(defvar *kbd-macro-query-time* 1)       ;How many sec. waiting for C-x q ?
(defvar *audio-bell* t)                 ;enable audio bell ?
(defvar *break-char* +wide-break-char+) ;default definition.

(defvar *registers-file*                ".line-edit.registers")
(defvar *global-mark-file*              ".line-edit.global-mark")
(defvar *macro-file*                    ".line-edit.last-kbd-macro")
(defvar *lisp-extension*                ".lisp")    ;default source file extension.
(defvar *object-extension*
                #+clisp ".fas"
                #+sbcl  ".fasl"
                #+gcl   ".o"
  )
(defvar *case-sensitive-readtable* (copy-readtable nil))
(setf (readtable-case *case-sensitive-readtable*) :preserve) ;; 大文字小文字を区別して読み込む設定に変更。

;;;
;;; このパッケージに対するローカル変数。
;;;
(declaim (type list *text*))
(defvar *text* nil)                     ;; current text (=list of characters). unlimited length.
(declaim (type fixnum *point* *ncl*))
(defvar *point* 0)                      ;; point position (just before cursor).
(defvar *last-text* nil)
(defvar *last-point* 0)
(defvar *ncl* 0)                        ;; Number of Characters in Line.
(defvar *mark* nil)                     ;; Mark of beginning or end of region.
(defvar *kill-ring* nil)                ;; kill-ring buffer.
(defvar *hscroll-unit* nil)             ;; horizontal scrolling unit.
(defvar *hscroll-size* 0)
(defvar *suspend-switch* t)
(defvar *line-stack* nil)
(defvar *echo* t)
(defvar *last-yank* 0)
(defvar *search-from* nil)
(defvar *registers* nil)
(defvar *line-edit-put-newline* t)
(defvar *allow-yank-pop* nil)
(defvar *backward-kill-commands* nil)
(defvar *save-mark-info* nil)
(defvar *command-undo-info* nil)
(defvar *undo-control* nil)
(defvar *undo-info* nil)
(defvar *last-undo-info* nil)
(defvar *exec-undo* nil)
(defvar *redo-info* nil)
(defvar *exec-redo* nil)
(defvar *max-undo-length* 0)            ;; for statistics information.
(defvar *zero-base-physical-cursor-position* 0)
(defvar *newline-position* nil)
(defvar *last-newline-position* nil)
(defvar *keyboard-macro* nil)
(defvar *record-macro* nil)
(defvar *macro-mode* nil)
(defvar *last-command* nil)
(defvar *command-trace* nil)
(defvar *command-trace-list* nil)
(defvar *debug-level* 0)
(defvar *last-char* nil)
(defvar *global-keymap* nil)
(defvar *defined-key-list* nil)
(defvar *call-by-keyboard* nil)
(defvar *global-mark* nil)
(defvar *display-start* 0)              ;; 画面の左端に表示される文字の[*text*]内のインデックス
(defvar *display-end* 0)                ;; 画面の右端に表示される文字の[*text*]内のインデックス。
(defvar *logical-cursor-position* 0)    ;; 論理測位系でのカーソル位置記録用。
(defvar *physical-start* 0)             ;; カーソル位置。左端が[0]。 
(defvar *physical-line-window-size* 0)  ;; プロンプトを除いた端末の文字幅。端末幅の変更に追随。

;;; ==============================================================
;;;
;;; MACRO DEFINITION PART.
;;;
;;; ==============================================================
;;; 行頭からプロンプト "prompt" を表示し、残余引数 "body" を評価した後
;;; プロンプトで消された行の内容を復元する。関数[line-edit]の行内で使用する。
;;;
;;; (例) 何か文字が入力されるまで"Are you OK?"と表示し、文字が入力されたら元の行を表示する。
;;;   ==> (with-prompt "Are you OK?" (getchar))
;;;
(defmacro with-prompt (prompt &rest body) ;; 2026-04-28
  `(let ((txt (pack *text*)) (pos *point*))
     (beginning-of-line 1)
     (kill-line)
     (move-logical-cursor-to 0)
     (pure-delete-line 0) ;; 表示を消す。
     (self-insert-string ,prompt)
     (display-line)
     ,@body ;; この[body]の評価が終わるまで[prompt]の表示を維持する。通常はユーザの入力を待つ関数。
     (beginning-of-line 1)
     (kill-line) ;; 表示していたメッセージを行バッファから消去。
     (move-logical-cursor-to 0)
     (pure-delete-line 0) ;; 表示を消す。
     (self-insert-string txt) ;; 元々表示されていたテキストを行バッファに入力。
     (move-point-to pos)
     (display-line)
     )
  )

;;;
;;; バッファリングなし、エコーなしの入力モードで引数を評価する。
;;;
(defmacro with-raw-input-mode (&rest body)
  `(progn
     (raw-mode)
     (unwind-protect
         ,@body
       (cooked-mode)))) 
;;; ==============================================================

;;;
;;; 実際のカーソルを右にn文字移動する。移動範囲のチェックは行わない。
;;;
(defun move-raw-cursor-right (n)
  (declare (type fixnum n)) ;; GCL 2.4.0では(declare ...)があるとコンパイルできない。
  (when (> n 0) ;; 2.3.8 beta,2.4.4,2.5.2では問題ないことを確認している。
    (putc +ESC+) ;; 2.4.0だけの問題。
    (putc #\[)
    (putnum-as-char n)
    (putc #\C)
    (incf *zero-base-physical-cursor-position*)
    (setf *logical-cursor-position* (- *zero-base-physical-cursor-position* (view-area-start)))
    (finish-output)
    ) ;; end when
  )

;;;
;;; 実際のカーソルを左にn文字移動する。移動範囲のチェックは行わない。
;;;
(defun move-raw-cursor-left (n)
  (declare (type fixnum n))
  (when (> n 0)
    (putc +ESC+)
    (putc #\[)
    (putnum-as-char n)
    (putc #\D)
    (decf *zero-base-physical-cursor-position*)
    (setf *logical-cursor-position* (- *zero-base-physical-cursor-position* (view-area-start)))
    (finish-output)
    )
  )

;;;
;;; 実際のカーソルをゼロ・ベース物理測位系カーソル位置の[n]カラム目に移動する。ポイントは変化しない。
;;; ANSI端末側の認識では画面の左端が1カラム目。[*text*]用ポインタの先頭がゼロなので同じ測位系に揃えた。
;;; したがって、ゼロ・ベース物理測位系カーソルの位置[0]は実際には物理カーソル位置の[1]。
;;;
(defun move-raw-cursor-to (n)
  (declare (type fixnum n))
  (when (or (minusp n) (> n (current-physical-column-size)))
    (return-from move-raw-cursor-to nil)
    ) ;; end when
  (putc +ESC+)
  (putc #\[)
  (putnum-as-char (1+ n))
  (putc #\G)
  (finish-output)
  (setf *zero-base-physical-cursor-position* n)
  (setf *logical-cursor-position* (- *zero-base-physical-cursor-position* (view-area-start)))
  )

;;;
;;; カーソル位置の1文字を消去して、以降の文字を1字分づつ前につめる。
;;; 表示のみを消す。
;;;
(defun pure-delete-char ()
  (putc +ESC+)
  (putc #\[)
  (putc #\P)
  (finish-output)
  )

;;;
;;; raw-modeでの(terpri)。改行し、次の行の先頭にカーソルを移動する。
;;;
(defun writeln ()
  (putc +ctrl-m+)
  (putc +ctrl-j+))

;;;
;;; カーソル位置から行末までの文字を消去する。
;;; 対応するエスケープ・シーケンスがサポートされていない場合は
;;; コメント・アウトしてある定義と入れ替える。
#|
;Pentium III 700MHz/Linux 2.4.0-test8 GNU Common Lisp 2.3.8 Beta - Interpreted.
;
;> (time (dotimes (i 1000) (line-edit-pkg::pure-delete-line)))
;real time : 1.250 secs
;run time  : 1.150 secs
;
(defun pure-delete-line ()
  (dotimes (i (- (physical-line-window-size) (zero-base-physical-cursor-position))) (pure-delete-char)))
|#
;;;
;> (time (dotimes (i 1000) (line-edit-pkg::pure-delete-line)))
;
;real time : 0.020 secs
;run time  : 0.020 secs
;

;;;
;;; n=0 カーソル位置から行末まで消去。
;;; n=1 行頭からカーソル位置までを消去。
;;; n=2 行全体を消去。
;;;
(defun pure-delete-line (&optional (n 0))
  (putc +ESC+)
  (putc #\[)
  (putnum-as-char n)
  (putc #\K))

(defun pure-delete-line-from-here ()
  (pure-delete-line 0)
  )

;;;
;;; 「強調表示」のオン／オフを制御する。
;;;
(defun highlight-mode (mode)
  (cond
   ((null mode) (inverse-off))
   (t (inverse-on))))

;;;
;;; 反転表示モードにする。
;;;
(defun inverse-on ()
  (putc +ESC+)
  (putc #\[)
  (putnum-as-char 7)
  (putc #\m))

;;;
;;; 反転表示モードを終了する。
;;;
(defun inverse-off ()
  (putc +ESC+)
  (putc #\[)
  (putc #\m))


;;;
;;; 文字コード体系に依存する関数。ASCIIコードの表示可能文字か否かを返す。
;;; GCL 2.4.4の graphic-char-pの定義にミスがあり、(char-code ch) >= 32
;;; であるような文字 chに対して (graphic-char-p ch)は、すべて t を返し
;;; てしまう。これはファイル character.dの655行目
;;;
;;;        if (' ' <= i && ' ' < '\177')
;;; を
;;;        if (' ' <= i && i < '\177')
;;;
;;; と修正して再コンパイルすればよいが、バグのあるシステムでも正しく動
;;; 作するように念のために以下の関数を定義して使用している。
;;;
;;; このバグは GCL 2.5.1で修正された。
;;;
(defun ascii-printable-char-p (ch)
  (declare (type character ch))
  (<= 32 (char-code ch) 126)
  ;;(graphic-char-p ch)
  )

(defun ascii-control-char-p (ch)
  (declare (type character ch))
  (or (<= 0 (char-code ch) 31) (= (char-code ch) 127))
  )

;;; MACHINE INDEPENDENT FUNCTIONS.

;;;
;;; このパッケージのバージョンと現在のエディタ・モード名を表す文字列を返す。
;;;
(defun line-edit-version ()
  (format nil "~a" +line-edit-version+)
  )

;;;
;;; エディタ・モードを設定する。引数なしで実行すると現在の
;;; モード名を返す。モード名は文字列であり、
;;;     "emacs-mode"
;;;     "vi-mode"
;;;     "WordMaster-mode"
;;; など任意に設定できるが、
;;;
;;; 定義設定ファイル名は
;;;     emacs-mode.lisp
;;;     vi-mode.lisp
;;;     WordMaste-moder.lisp
;;; ヘルプ・ファイル名は
;;;     emacs-mode.help
;;;     vi-mode.help
;;;     WordMaster-mode.help
;;;
;;; と関連付けされる。モード名の大・小文字は区別する。モード名の末尾が["-mode"]である必要はない。
;;; ファイルは設定用ディレクトリ(初期設定では~/.config/line-edit/)→カレント→ホーム・ディレクトリの順に探す。
;;;
;;; 初期設定情報は[support-functions.lisp]内のパラメータ[*config-file-dir*]で定義している。
;;;
;;; 引数なしで呼び出すと現在のエディタ・モードを返す。
;;;
(defun set-editor-mode (&optional (ed-mode "" sw) (verbose (verbose-message)))
  (let ((fname nil))
    (cond
      ((or
        (null sw)
        (string= ed-mode "")
        )
       (editor-mode)
       )
      ((stringp ed-mode)
       ;;(setf fname (config-file-abs-path ed-mode))
       (setf fname
             (find-current-and-home-dir ed-mode :ext (list +compiled-ext+ ".lisp") :dir (config-file-dir)))
       (cond
         ((identity fname)
          (let ((*package* (find-package :line-edit-pkg)))
              (load fname :verbose nil) ;; 指定されたエディタ用のキー・バインド設定ファイルを読み込む。
            )
          (setf *default-editor-mode* ed-mode)
          )
         (t
          (message :line-edit-pkg+set-editor-mode-001
                   "エディタ・モードに応じた定義ファイル(~a)が存在しません。~%"
                   (concatenate 'string ed-mode *lisp-extension*))
          )
         ) ;; end inner cond
       )
      (t (message :line-edit-pkg+set-editor-mode-002 "エディタ・モードは文字列で指定します。~%"))
      ) ;; end cond
    (when verbose
      (format t "Loading editor mode file... ~a~%" fname)
      (message :line-edit-pkg+set-editor-mode-003 "現在のエディタ・モードは ~a です。~%"
               *default-editor-mode*)
      (finish-output)
      ) ;; end when

    (return-from set-editor-mode *default-editor-mode*)
    ) ;; end let
  ) ;; end defun

;;;
;;; 現在のエディタ・モード名を返す。(set-editor-mode)と同じ。
;;;
(defun editor-mode ()
  (return-from editor-mode *default-editor-mode*)
  )

(defun editor-mode-file ()
  *editor-mode-file*
  )

(defun record-editor-mode (&optional (ed-mode *default-editor-mode*))
  (let ((fname ""))
    (when (not (stringp ed-mode))
      (message :line-edit-pkg+record-editor-mode-001 "記録するエディタ・モードは文字列で指定します。~%")
      (return-from record-editor-mode nil)
      ) ;; end when

    (setf fname (config-file-abs-path *editor-mode-file*))
    (with-open-file (s fname :direction :output :if-does-not-exist :create :if-exists :supersede)
      (format s ";; ~a ~a JST(~2,0@d\:00)~%" (iso-date-string) (iso-time-string) (iso-timezone))
      (format s "(line-edit-pkg:set-editor-mode ~s nil)~%" ed-mode)
      ) ;; end with-open-file
    ed-mode
    )   ;; end let
  ) ;; end record-editor-mode

;;;
;;; 補完機能を起動する場合にタイプする文字を返す。通常は[Tab]。
;;;
(defun complete-symbol-start-char ()
  +complete-symbol-start-char+
  )

;;;
;;; 現在のエディタ・モード用のヘルプ・ファイルを表示する。
;;; 第２引数としてヘルプ・ファイルをロードするパス名も指定
;;; できる。指定されなかった場合はカレント・ディレクトリ
;;; →ホーム・ディレクトリの順に探す。
;;;
(defun help-edit (&optional (mode (editor-mode)) load-path)
  (let (fname)
    (cond
      ((null load-path) ;; Help fileのパスが指定されていなければ[(config-file-dir)]->カレント->ホーム。
       (setf fname (find-current-and-home-dir mode :ext ".help" :dir (config-file-dir)))
       )
      (t ;; Help fileのパスが指定されていれば、そのディレクトリのエディタモード名+".help"ファイル。
       (setf fname (concatenate 'string load-path mode ".help"))
       )
      ) ;; end cond
    (less fname) ;; 外部コマンドの"less"を使って表示する。
    ) ;; end let
  ) ;; end help-edit

(defun help-complete ()
  (let (key-help-list)
    (setf key-help-list (get-key-help-for-complete-symbol))
    (message :line-edit-pkg+help-complete-001
             "入力中の単語と先頭部分が一致する単語を順次表示する。
デフォルトでは[Tab]キーをタイプすると起動し、複数の候補が存在するときは[Tab]キーをタイプするごとに次の候補の表示に切り替わる。[Ctrl-p]をタイプするとひとつ前の候補の表示に戻る。
デフォルトでCommon Lispの約800種の関数、マクロ名などを登録したファイル(デフォルトはsyntax-info.lisp)を備えている。別途、ユーザ独自の単語を登録するファイル(デフォルトはuser-info-list.lisp)もある。いずれも[~~/.config/line-edit/]ディレクトリから読み込む。

合計採用回数、最終採用時刻を自動的に記録しており、複数の補完候補がある場合は採用回数と最終採用時刻を加味した指数減衰法による優先順位に従って表示する。セッションを終了するとファイルに最新情報が記録され、次回のセッションに引き継がれる。ただしパッケージ移動に伴って取得したシンボル情報は記録しない。

文字入力が何もない状態、およびCommon Lispの区切り文字の直後で[Tab]キーをタイプすると登録されている全ての候補が優先順位に従って順次表示される。

[~a] キー     補完候補が複数ある場合、次の補完候補を表示。最後の補完候補の「次」は最初の補完候補。
[~a] キー     ひとつ前の補完候補の表示に戻る。一番最初の補完候補の「前」は最後の補完候補。
[SPC] キー    タイプする毎に短い補完候補と長い補完候補で表示を切り替える。
[~a] キー     表示されている補完候補に確定。
[~a] キー     常に短い補完候補で確定。
[~a] キー     常に長い補完候補で確定。
[~a] キー     Redraw. 端末表示幅に表示しきれない補完候補の行頭・行末を遷移表示する。
[~a] キー     キャンセル。

を選択できる。候補数が多いときは一旦キャンセル後に文字を追加すると絞り込める。~%"
             (nth 1 key-help-list) ;; :next-candidate
             (nth 0 key-help-list) ;; :previous-candidate
             (nth 2 key-help-list) ;; :current-candidate
             (nth 3 key-help-list) ;; :short-candidate
             (nth 4 key-help-list) ;; :long-candidate
             (nth 5 key-help-list) ;; :redraw
             (nth 6 key-help-list) ;; :cancel
             ) ;; end message
    (values)
    ) ;; end let
  ) ;; end help-complete

;;;
;;; キーボードから呼び出されたか否かによって、繰り返し回数
;;; として選択すべき値を返す。
;;;
;;; キーボードから呼び出されたときはC-uで設定された繰り返し回数、
;;; そうでないときは引数[n]をそのまま返す。
;;;
;;; 特殊な関数を除き、この関数を使用することで繰り返し回数を設定できる。
;;;
(defun select-repeat-count (n)
  (let ((i nil))
    (if (null n) (setf n 1))
    (if (call-by-keyboard-p) (setf i (repeat-count)))
    (setf *call-by-keyboard* nil)
    (if (null i) (setf i n))
    (return-from select-repeat-count i)))

;;;
;;; 何もしない関数。
;;;
(defun do-nothing () nil)

;;;
;;; 入力終了時に返される関数。単なるマークなので定義本体は不要。
;;;
(defun end-input () nil)

;;;
;;; 入力途中のコマンドを中断するための文字コードを表示・設定する。
;;; デフォルトは[Ctrl-g]。
;;;
(defun set-break-code (&optional (code nil sw))
  (cond
   ((null sw) *ctrl-g*)
   ((characterp code)
    (setf *ctrl-g* code))
   (t (format nil "set-break-code: single character expected.~%"))))

;;;
;;; debug情報の表示を制御する関数。
;;;
(defun debug-level (&optional (level nil exist-p))
  (cond
   ((null exist-p) *debug-level*)
   (t (setf *debug-level* level))))

;;;
;;; M-i 'ch'
;;; キーボードから入力した文字の文字コードを8進数、10進数、16進数として表示する。
;;;
;;; M-i C-q と入力すると
;;; Char=[^Q] (#o021, 017, #x11)
;;; と表示される。任意の文字をタイプすると元の表示に戻る。
;;;
(defun inspect-keycode ()
  (let (ch n fmt str tm)
    (setf fmt "Char=[~a] (\#\o~3,'0o, ~3,'0d, \#\x~2,'0x)")
    (setf ch (getchar))
    (setf n (char-code ch))
    (setf ch (to-circumflex-accent-char ch))
    (setf str (format nil fmt ch n n n))
    (setf tm (blink-paren-deley))
    (blink-paren-deley 0)
    (with-prompt str (getchar))
    (blink-paren-deley tm)
    ) ;; end let
  ) ;; end inspect-keycode

;;;
;;; 端末左端の位置をゼロとする測位系での現在のカーソル位置を返す。
;;;
(defun zero-base-physical-cursor-position ()
  *zero-base-physical-cursor-position*
  )

;;;
;;; マーク位置を返す。
;;;
(defun mark () *mark*)

;;;
;;; ポイントの直後の文字を返す。
;;;
(defun current-char ()
  (nth *point* *text*) ;; リストの場合、汎用的な[elt]よりリスト専用の[nth]の方が僅かに高速。
  )

;;;
;;; ポイントの直前の文字を返す。ポイントがゼロであればゼロ文字目の文字を返す。
;;;
(defun previous-char ()
  (if (plusp *point*)
      (nth (1- *point*) *text*)
      (nth 0 *text*)
      )
  ) ;; end previous-char

;;;
;;; 指定した位置の文字を返す。
;;;
(defun character-at (n)
  (nth n *text*)
  )

;;;
;;; ポイントがテキストの先頭にあるか否かを返す。
;;;
(defun beginning-of-text-p ()
  (= *point* 0))

;;; M-a
;;; ポイントをテキストの先頭に移動する。
;;;
(defun beginning-of-text ()
  (move-point-to 0))

;;;
;;; ポイントがテキストの終端にあるか否かを返す。
;;;
(defun end-of-text-p ()
  (= *point* *ncl*))

;;; M-e
;;; ポイントをテキストの終端に移動する。
;;;
(defun end-of-text ()
  (move-point-to *ncl*))

;;;
;;; 空行か否かを返す。
;;;
(defun empty-text-p ()
  (= *ncl* 0))

;;;
;;; 最終桁の桁番号を返す。
;;;
(defun max-column ()
  (1- (line-length)) )

;;;
;;; ベルを鳴らす。
;;;
(defun audio-bell ()
  (when (enable-audio-bell) (putc *ctrl-g*))
  (return-from audio-bell nil))

;;;
;;; ポイントが行頭にあるか否かを返す。
;;;
(defun beginning-of-line-p ()
  (cond
   ((beginning-of-text-p) t)
   ((char= (nth (1- *point*) *text*) #\Newline) t)))

;;; C-a
;;; ポイントを指定された行数分前の行の先頭に移動する。
;;;
(defun beginning-of-line (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
   ((zerop n) nil)
   ((> n 0)
    (dotimes (i n)
      (true-beginning-of-line)
      (if (< i (1- n)) (backward-char))))
   ((< n 0)
    (dotimes (i (- n))
      (true-end-of-line)
      (if (< i (1- (- n))) (forward-char))))))

(defun true-beginning-of-line ()
  (loop
    (if (beginning-of-line-p) (return))
    (backward-char)))

;;;
;;; ポイントが行末にあるか否かを返す。
;;;
(defun end-of-line-p ()
  (cond
   ((end-of-text-p) t)
   ((char= (current-char) #\Newline) t)))

;;; C-e
;;; ポイントを指定された行数分後ろの行末に移動する。
;;;
(defun end-of-line (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
   ((zerop n) nil)
   ((> n 0)
    (dotimes (i n)
      (true-end-of-line)
      (if (< i (1- n)) (forward-char 1))))
   ((< n 0)
    (dotimes (i (- n))
      (true-beginning-of-line)
      (if (< i (1- (- n))) (backward-char 1))))))

(defun true-end-of-line ()
  (loop
    (if (end-of-line-p) (return))
    (forward-char 1)))

;;;
;;; テキスト全体の文字数を返す。
;;;
(defun text-length () (length *text*))

;;;
;;; 文字列にパックしたテキスト全体を返す。
;;;
(defun packed-text () (pack *text*))

;;;
;;; ポイントが存在する行の文字数を返す。
(defun line-length ()
  (let (p n)
    (setf p (previous-newline-position))
    (setf n (next-newline-position))
    (cond
     ((and (null p) (null n))
      (text-length))
     ((null p)
      (1+ n))
     ((null n)
      (1- (- (text-length) p)))
     (t (- n p)))))

;;;
;;; ポイントが存在する行全体を文字列にパックして返す。
;;;
(defun packed-line () (pack (current-line)))

;;;
;;; ポイントの存在する行全体を返す。
;;;
(defun current-line (&optional (text *text*) (pt *point*))
  (let (p n)
    (setf p (previous-newline-position text pt))
    (setf n (next-newline-position text pt))
    (cond
     ((and
       (null p)
       (null n))
      text)
     ((null p)
      (subseq text 0 (1+ n)))
     ((null n)
      (subseq text (1+ p)))
     (t (subseq text (1+ p) (1+ n))))))

;;;
;;; ポイントを含む行の開始位置を返す。
;;
(defun current-line-base ()
  (let (pos base)
    (setf pos (previous-newline-position)) ;; [*text*]内の現在のポイント位置よりひとつ前の#Newlineの位置。
    (if (null pos)
        (setf base 0)
        (setf base (1+ pos))
        )
    (return-from current-line-base base)))

;;;
;;; カーソルを左に[n]カラム移動する。ポイントは変化しない。
;;; カーソルが[(current-prompt-length)]を越えて左に動くことはない。
;;;
(defun move-logical-cursor-left (n)
  (declare (type fixnum n))
  (if (minusp n) (return-from move-logical-cursor-left nil))
  (setf n (min n (- (zero-base-physical-cursor-position) (current-prompt-length))))
  (move-raw-cursor-left n)
  ) ;; end move-logical-cursor-left

;;;
;;; カーソルを右に[n]カラム移動する。ポイントは変化しない。
;;; カーソルが[(current-physical-column-size)]を越えて右に動くことはない。
;;;
(defun move-logical-cursor-right (n)
  (declare (type fixnum n))
  (if (minusp n) (return-from move-logical-cursor-right nil))
  (setf n (min n (- (current-physical-column-size) (zero-base-physical-cursor-position))))
  (move-raw-cursor-right n)
  ) ;; move-logical-cursor-right

;;;
;;; 現在のプロンプト(可変長)の直後をゼロ位置とする位置にカーソルを移動する。
;;; 表示範囲外を指定した場合は[nil]を返す。
;;;
(defun move-logical-cursor-to (n)
  (cond
    ((minusp n)
     nil
     )
    ((> n (physical-line-window-size))
     nil
     )
    (t
     (move-raw-cursor-to (+ (view-area-start) n))
     )
    ) ;; end cond
  ) ;; end move-logical-cursor-to

;;;
;;; プロンプト直後をゼロ位置とする測位系での現在のカーソル位置を返す。
;;; 負の値が返された場合はカーソルはプロンプト終端より前にある。
;;; 0----+----1----+-c--2--|-+----3----+----4-c--+----5--
;;;                        ↑=(view-area-start)
;;;
(defun logical-cursor-position ()
  (- (zero-base-physical-cursor-position) (view-area-start))
  ) ;; end logical-cursor-position

;;;
;;; ゼロ・ベース物理測位系カーソル位置の[n]カラム目に移動する。ポイントは変化しない。
;;; 移動後のカーソル位置を返す。
;;;
(defun move-cursor-to-physical (n)
  (declare (type fixnum n))
  (move-raw-cursor-to n)
  )

;;;
;;; ポイント位置を返す。
;;; 呼び出しオーバ・ヘッドが問題となる箇所では inline展開を想定。
;;;
(defun point () *point*)

;;;
;;; ポイントを左に n文字分移動する。
;;; ポイントがすでにテキストの先頭にある場合は何もせず、nilを返す。
;;; 移動できた場合は、移動後のポイントを返す。
;;;
(defun move-point-left (&optional (n 1))
  (declare (type fixnum n))
  (if (<= n 0) (return-from move-point-left nil))
  (setf n (min n *point*))
  (decf *point* n)
  )

;;;
;;; ポイントを右に n文字分移動する。
;;; ポイントがすでにテキストの終端にある場合は何もせず、nilを返す。
;;; 移動できた場合は、移動後のポイントを返す。
;;;
(defun move-point-right (&optional (n 1))
  (declare (type fixnum n))
  (if (minusp n) (return-from move-point-right nil))
  (if (end-of-text-p) (return-from move-point-right nil))
  (setf n (min n (- *ncl* *point*)))
  (incf *point* n)
  )

;;;
;;; ポイントを引数で指定された位置に移動する。
;;; 移動後のポイントを返す。
;;;
(defun move-point-to (&optional (n 1))
  (declare (type fixnum n))
  (if (not (<= 0 n (text-length)))
      (return-from move-point-to nil)
      )
  (setf *point* n)
  )

;;; C-f
;;; 指定された回数分、ポイントを進める。
;;; 移動後のポイントを返す。
;;;
(defun forward-char (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
    ((zerop n) *point*)
    ((> n 0)
     (move-point-right n))
    ((< n 0)
     (move-point-left (- n)))))

;;; C-b
;;; 指定された回数分、ポイントを後ろ向きに進める。
;;; 移動後のポイントを返す。
;;;
(defun backward-char (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
   ((zerop n) *point*)
   ((> n 0)
    (move-point-left n))
   ((< n 0)
    (move-point-right (- n)))))

;;; C-d
;;; ポイント位置から指定された文字数を削除／キルする。
;;;
;;; 文字数が指定された場合は(1文字でも)削除ではなく、キルする。
;;; 負数が指定された場合はポイント位置より前の文字が対象となる。
;;;
;;; 文字の削除／キルが行われなかったときは nilを返す。そうでな
;;; いときは残りの文字数を返す。
;;;
(defun delete-char (&optional (n nil))
  (let (result)
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (cond
     ((empty-text-p) nil)
     ((end-of-text-p) nil)
     ;;((null n)
     ((or
       (null n)
       (and (numberp n) (= n 1))
       )
      (save-mark-info)
      (save-delete-undo-info (current-char))
      (setf result (true-delete-char))
      (align-mark)
      (return-from delete-char result))
     ((zerop n) nil)
     ((< n 0)
      (delete-backward-char (- n)))
     ((> n 0)
      (save-mark-info)
      (set-mark-command)
      (forward-char n)
      (exchange-point-and-mark)
      (kill-region)
      (align-mark)
      (return-from delete-char *ncl*)))))

;;; C-h (BS)
;;; ポイント位置から指定された文字数を逆向きに削除／キルする。
;;;
;;; 文字数が指定された場合は(1文字でも)削除ではなく、キルする。
;;; 負数が指定された場合はポイント位置より後ろの文字が対象となる。
;;;
;;; 文字の削除／キルが行われなかったときは nilを返す。そうでな
;;; いときは残りの文字数を返す。
;;;
(defun delete-backward-char (&optional (n nil))
  (let (result)
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (cond
     ((beginning-of-text-p) nil)
     ((or
       (null n)
       (and (numberp n) (= n 1))
       )
      (save-mark-info)
      (backward-char 1)
      (save-backward-delete-undo-info (current-char))
      (setf result (true-delete-char))
      (align-mark)
      (return-from delete-backward-char result))
     ((zerop n) nil)
     ((< n 0)
      (delete-char (- n)))
     ((> n 0)
      (save-mark-info)
      (set-mark-command)
      (backward-char n)
      (exchange-point-and-mark)
      (setf result (kill-region))
      (pop-kill-ring)
      (align-mark)
      (return-from delete-backward-char result)))))

;;;
;;; ポイント位置の1文字を削除する。
;;;
;;; In GCL 2.3.8-Beta on Pentium-III 700MHz/Linux 2.4.0-test8 (Interpreted).
;;;
;;; > (setq x (unpack "(compile-file \"line-edit-pkg.lsp\")"))
;;;
;;; > (time (dotimes (i 10000) (remove-if #'identity x :start 1 :count 1)))
;;; real time : 0.060 secs
;;; run time  : 0.050 secs
;;;
;;; > (time (dotimes (i 10000) (append (subseq x 0 1) (cdr (subseq x 1)))))
;;; real time : 0.170 secs
;;; run time  : 0.170 secs
;;;
(defun true-delete-char ()
  (if (or (empty-text-p) (end-of-text-p)) (return-from true-delete-char nil))
  (setf *text* (remove-if #'identity *text* :start *point* :count 1))
  ;;(need-refresh-line t)
  (decf *ncl*)
  (return-from true-delete-char *ncl*))

;;; M-\
;;; ポイントの周りの空白文字類をすべて削除する。
;;;
(defun delete-horizontal-space ()
  (save-mark-info)
  (backward-kill-white-space)
  (kill-white-space)
  (align-mark))

;;; M-s
;;; ポイントの周りの空白文字類を削除し、今ある空白の数に関係なく
;;; (たとえゼロ個でも)ポイントの直前に空白を1個だけ残す。
;;;
(defun just-one-space ()
  (save-mark-info)
  (delete-horizontal-space)
  (self-insert #\Space 1)
  (align-mark))

;;; C-k
;;; ポイント位置から行末までの文字をキルする。
;;; ポイント位置を返す。
;;;
;;; 0または負数が指定された場合はポイント位置より前のテキストをキルする。
;;;
(defun kill-line (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (save-mark-info)
  (set-mark-command)
  (cond
   ((null n)
    (if (end-of-line-p) (forward-char 1)
      (end-of-line 1)))
   ((zerop n)
    (beginning-of-line 1))
   ((< n 0)
    (beginning-of-line (- n)))
   ((> n 0)
    (end-of-line n)))
  (exchange-point-and-mark)
  (kill-region)
  (align-mark)
  (return-from kill-line *ncl*))

;;; M-f
;;; 次の単語の直後にポイントを移動する。次の単語の先頭への移動ではない。
;;; ポイントが「GNU Emacs」というテキストの先頭（=Gの直前）にあるとき
;;; forward-wordするとポイントは'U'の直後に移動する。
;;;
;;; 移動しなかったときは nilを返しポイントは変化しない。そうでないときは移動後のポイントを
;;; 返す。
;;;
(defun forward-word (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
    ((zerop n)
     (return-from forward-word nil)
     )
    ((end-of-text-p)
     (audio-bell) ;; returns nil.
     (return-from forward-word nil)
     )
    ((> n 0)
     (dotimes (i n) (true-forward-word))
     )
    (t
     (backward-word (- n))
     )
    ) ;; end cond
  (return-from forward-word *point*)
  ) ;; end defun

(defun true-forward-word ()
  (loop
    (if (end-of-text-p) (return-from true-forward-word *point*))
    (if (normal-char-p (current-char)) (return nil))
    (forward-char 1))
  (loop
    (if (end-of-text-p) (return-from true-forward-word *point*))
    (if (not (normal-char-p (current-char)))
        (return-from true-forward-word *point*))
    (forward-char 1)))

;;; M-n
;;; 次の単語の先頭にポイントを移動する。保守的な移動コマンドに慣れてい
;;; るユーザ用に定義してある。負数が与えられたときは直前の単語の先頭へ
;;; の移動となる。
;;;
(defun next-word (&optional (n nil))
  (let (result)
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (cond
      ((zerop n) nil)
      ((end-of-text-p) (audio-bell))
      ((> n 0) (dotimes (i n result) (setf result (true-next-word))))
      (t (backward-word (- n))))))

(defun true-next-word ()
  (loop
    (if (end-of-text-p) (return-from true-next-word nil))
    (if (not (normal-char-p (current-char))) (return))
    (forward-char 1))
  (loop
    (if (end-of-text-p) (return-from true-next-word nil))
    (if (normal-char-p (current-char)) (return-from true-next-word *point*))
    (forward-char 1)))

;;;
;;; 空白文字類を読み飛ばす。空白文字類は +white-space-char+ の要素として
;;; 定義している。
;;;
;;; 移動しなかったときは nilを返し、そうでないときは移動後のポイントを返す。
;;;
(defun skip-white-space ()
  (let (moved)
    (setf moved nil)
    (loop
      (if (end-of-text-p) (return-from skip-white-space moved))
      (if (not (white-space-p (current-char)))
          (return-from skip-white-space moved))
      (forward-char 1)
      (setf moved *point*))))

;;;
;;; *break-char*でも、+white-space-char+でもない文字までポイントを移動する。
;;; 常にポイント位置を返す。
;;;
(defun skip-to-normal-char ()
  (loop
    (if (end-of-text-p) (return-from skip-to-normal-char *point*))
    (if (normal-char-p (current-char)) (return-from skip-to-normal-char *point*))
    (forward-char 1)))

;;; M-b
;;; 後向きに１単語分移動する。ポイントは単語の直前に移動する。
;;;
;;; 移動しなかったときは nilを返し、そうでないときは移動後のポイントを返す。
;;;
(defun backward-word (&optional (n nil) &aux result)
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
    ((zerop n)
     (return-from backward-word nil)
     )
    ((beginning-of-text-p)
     (audio-bell)
     (return-from backward-word nil)
     )
    ((> n 0)
     (dotimes (i n result) (setf result (true-backward-word))))
    (t (forward-word (- n)))))

(defun true-backward-word ()
  (loop
    (when (beginning-of-text-p) (return-from true-backward-word *point*))
    (backward-char 1)
    (when (normal-char-p (current-char)) (return)))
  (loop
    (if (beginning-of-text-p) (return-from true-backward-word *point*))
    (backward-char 1)
    (when (not (normal-char-p (current-char)))
      (forward-char 1)
      (return-from true-backward-word *point*))))

;;;
;;; 逆向きに空白文字類を読み飛ばす。空白文字類は +white-space-char+
;;; の要素として定義されている。
;;;
;;; 移動しなかったときは nilを返し、そうでないときは移動後のポイントを返す。
;;;
(defun backward-skip-white-space ()
  (let (pos)
    (setf pos *point*)
    (loop
      (if (beginning-of-text-p) (return))
      (backward-char 1)
      (when (not (white-space-p (current-char)))
        (forward-char 1)
        (return)))
    (if (/= pos *point*) *point* nil)))

;;;
;;; *break-char*でも、+white-space-char+でもない文字まで逆向きに
;;; ポイントを移動する。常にポイント位置を返す。
;;;
(defun backward-skip-to-normal-char ()
  (loop
    (if (beginning-of-text-p) (return *point*))
    (if (normal-char-p (current-char)) (return *point*))
    (backward-char 1)))

;;; M-d
;;; 指定された個数分の単語をキルする。
;;; 負数が指定されたときは後ろ向きにキルする。
;;;
;;; キルが行われなかったときは nilを返し、そうでないときはポイント位置を返す。
;;;
(defun kill-word (&optional (n nil) &aux result)
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
    ((zerop n) nil)
    ((> n 0)
     (dotimes (i n result) (setf result (true-kill-word))))
    (t (backward-kill-word (- n)))))

;;;
;;; 次の単語の末尾までを前向きにキルする。
;;;
;;; キルが行われなかったときは nilを返し、そうでないときはポイント位置を返す。
;;;
(defun true-kill-word ()
  (let (result)
    (save-mark-info)
    (set-mark-command)
    (forward-word 1)
    (exchange-point-and-mark)           ;force forward kill.
    (setf result (kill-region))
    (align-mark)
    (return-from true-kill-word result)))

;;;
;;; 空白文字類をキルする。
;;; キルが行われなかったときは nilを返し、そうでないときはポイント位置を返す。
;;;
(defun kill-white-space ()
  (let (result)
    (save-mark-info)
    (set-mark-command)
    (skip-white-space)
    (exchange-point-and-mark)           ;force forward kill.
    (setf result (kill-region))
    (align-mark)
    (return-from kill-white-space result)))

;;; M-C-h
;;; 指定された個数分の単語を後ろ向きにキルする。
;;; 負数が指定されたときは前向きにキルする。
;;;
;;; キルが行われなかったときは nilを返し、そうでないときはポイント位置を返す。

(defun backward-kill-word (&optional (n nil) &aux result)
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
    ((zerop n) nil)
    ((> n 0)
     (dotimes (i n result) (setf result (true-backward-kill-word))))
    (t (kill-word (- n)))))

;;;
;;; 前の単語の先頭までを後向きにキルする。
;;;
;;; キルが行われなかったときは nilを返し、そうでないときはポイント位置を返す。
;;;
(defun true-backward-kill-word ()
  (let (result)
    (save-mark-info)
    (set-mark-command)
    (backward-word 1)
    (exchange-point-and-mark)           ;force backward kill.
    (setf result (kill-region))
    (align-mark)
    (return-from true-backward-kill-word result)))

;;;
;;; 逆向きに空白文字類をキルする。
;;;
;;; キルが行われなかったときは nilを返し、そうでないときはポイント位置を返す。
;;;
(defun backward-kill-white-space ()
  (let (result)
    (save-mark-info)
    (set-mark-command)
    (backward-skip-white-space)
    (exchange-point-and-mark)           ;force backward kill.
    (setf result (kill-region))
    (align-mark)
    (return-from backward-kill-white-space result)))

;;; M-@
;;; ポイントを移動せずに、指定された回数分 M-fによって移動した位置に
;;; マークを設定する。負数が指定されたときは M-bによって移動した位置
;;; にマークを設定する。マーク位置を返す。
;;;
(defun mark-word (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (set-mark-command)
  (cond
   ((zerop n) nil)
   ((> n 0) (forward-word n))
   (t (backward-word (- n))))
  (exchange-point-and-mark))

;;;
;;; kill-ringへの保存回数の最大値を設定する。引数を指定しないと現在の
;;; 最大保存回数を返す。最大保存回数は初期値で 30としてあるが、プログ
;;; ラム上の上限はない。
;;;
;;; kill-ringを削除したテキストを蓄えるスタックと考えると、この関数は
;;; kill-ringスタックの段数を設定／取得する関数である。
;;;
(defun kill-ring-max (&optional n)
  (cond
   ((null n) *kill-ring-max*)
   (t (setf *kill-ring-max* n))))

;;;
;;; kill-ringの先頭へテキストを追加する。
;;;
(defun push-kill-ring (lst)
  (declare (type list lst))
  (push lst *kill-ring*))

;;;
;;; kill-ringの先頭からテキストを取り出し、kill-ringの先頭を捨てる。
;;;
(defun pop-kill-ring ()
  (pop *kill-ring*))

;;;
;;; kill-ringをクリアする。
;;;
(defun clear-kill-ring ()
  (setf *kill-ring* nil)
  )

;;; C-y
;;; kill-ringからテキストをヤンクする。数引数 (nとする)を指定した場合は
;;; 最終ヤンク・ポインタから数えて n番目のテキストをヤンクする。
;;;
;;; ヤンクしたテキストの先頭にマークが設定され、ポイントはヤンクしたテキ
;;; ストの直後に移動する。
;;;
;;; ヤンクされたときはポイント位置が返る。そうでないときは nilが返る。
;;;
(defun yank (&optional (n nil) &aux result)
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
    ((zerop n) nil)
    ((= n 1)
     (true-yank))
    ((> n 1)
     (true-yank)
     (dotimes (i (1- n) result) (if (true-yank-pop) (setf result *point*))))))

;;;
;;; 最後にキルしたテキストをヤンク（kill-ringの先頭のテキストを、ポイント位置
;;; へ挿入）する。
;;;
(defun true-yank ()
  (let (result)
    (setf *last-yank* 0)
    (setf *allow-yank-pop* t)
    (set-mark-command)
    (setf result (insert (car *kill-ring*)))
    ; check and cut *kill-ring*, if its length is over the (kill-ring-max)
    (if (> (length *kill-ring*) (kill-ring-max))
        (setf *kill-ring*
              (butlast *kill-ring* (- (length *kill-ring*) (kill-ring-max)))))
    (return-from true-yank result)))

;;; M-y
;;; 直前にヤンクしたテキストを、それ以前にキルしたテキストに置き換える。
;;;
;;; ヤンクしたテキストの先頭にマークが設定され、ポイントはヤンクしたテキ
;;; ストの直後に移動する。
;;;
;;; ヤンクされたときはポイント位置が返る。そうでないときは nilが返る。
;;;
(defun yank-pop (&optional (n nil) &aux result)
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
    ((zerop n) nil)
    ((> n 0)
     (dotimes (i n result) (if (true-yank-pop) (setf result *point*))))))

;;;
;;; 直前にヤンクしたテキストを、それ以前にキルしたテキストに置き換える。
;;; kill-ringをスタックと考えると、ヤンクしたテキストを実行のたびに
;;; kill-ringスタックの２段目、３段目、．．．の内容で置き換える操作で
;;; ある。kill-ringの最後に到達すると、再びkill-ringの最初に戻る。
;;;
(defun true-yank-pop ()
  (let (result)
    (when (not *allow-yank-pop*) (return-from true-yank-pop nil))
    (when (> *point* *mark*) (exchange-point-and-mark))
    (when (equal
           (car (nthcdr *last-yank* *kill-ring*))
           (subseq *text* *point* *mark*))
      (incf *last-yank*)
      (setf *last-yank* (mod *last-yank* (length *kill-ring*)))
      (kill-ring-suspend t)
      (kill-region)
      (pop-kill-ring)
      (set-mark-command)
      (setf result (insert (car (nthcdr *last-yank* *kill-ring*)))))
    (return-from true-yank-pop result)))

;;; C-@
;;; 現在のポイント位置をリージョンの先頭または末尾として記憶する。
;;;
(defun set-mark-command ()
  (setf *mark* *point*))

;;; C-x C-x
;;; 現在のポイント位置とマーク位置を入れ替える。
;;; マークが存在していなかった場合は、何もせず nilを返す。
;;; そうでないときは入れ替わったマーク位置を返す。
;;;
(defun exchange-point-and-mark ()
  (let (pos)
    (when (null *mark*)
      (audio-bell)
      (return-from exchange-point-and-mark nil))
    (setf pos *point*)
    (move-point-to *mark*)
    (setf *mark* pos)))

;;; M-w
;;; ポイントとマークで囲まれたリージョンをキル・リングにコピー
;;; する。ポイントとマークは変化しない。
;;;
;;; 実際にリージョンをコピーすればnilでない値を返し、そうでなけ
;;; ればnilを返す。
;;;
;;; 前向きにキルする場合は(backward-kill-commands nil)を、
;;; 後ろ向きにキルする場合は(backward-kill-commands t)を
;;; 実行して記録を残す。
;;;
(defun kill-ring-save ()
  (cond
   ((empty-text-p) nil)
   ((null *mark*)
    (audio-bell))
   ((= *mark* *point*) nil)
   ((< *point* *mark*)
    (backward-kill-commands nil)
    (append-to-kill-ring (subseq *text* *point* *mark*)))
   (t (backward-kill-commands t)
      (append-to-kill-ring (subseq *text* *mark* *point*)))))

;;; C-w
;;; ポイント位置からマーク位置までのテキストをキルする（カット）。
;;; リージョンが一部でもキルされたときは、キル後のポイント位置を返す。
;;; そうでないときは nilを返す。
;;;
(defun kill-region ()
  (let (str)
    (when (kill-ring-save)
      (if (> *point* *mark*) (exchange-point-and-mark))
      (setf str (copy-seq (subseq *text* *point* *mark*)))
      (save-mark-info)
      (dotimes (i (- *mark* *point*) *point*) (true-delete-char))
      (align-mark)
      (if (backward-kill-commands)
          (save-backward-kill-undo-info str)
        (save-kill-undo-info str)))))

;;;
;;; kill-ringへテキストを蓄積、または新規項目として保存する。
;;;
(defun append-to-kill-ring (lst)
  (if (characterp lst) (setf lst (list lst)))
  (cond
   ((kill-ring-suspend)
    (setf *suspend-switch* nil)
    (setf *kill-ring* (cons lst *kill-ring*)))
   ((backward-kill-commands)
    (setf *kill-ring*
          (cons (append lst (car *kill-ring*)) (cdr *kill-ring*))))
   (t (setf *kill-ring*
            (cons (append (car *kill-ring*) lst) (cdr *kill-ring*))))))

;;;
;;; 前向きにキルするコマンドでは nilを、後ろ向きにキルするコマンド
;;; では tを記録する。引数を指定しないと、その時点での設定を返す。
;;;
(defun backward-kill-commands (&optional (flag nil sw))
  (cond
   ((null sw) *backward-kill-commands*)
   (t (setf *backward-kill-commands* flag))))

;;;
;;; kill-ring先頭へのテキスト蓄積の可否を制御する。
;;;
(defun kill-ring-suspend (&optional (set-to nil sw))
  (cond
   ((null sw) *suspend-switch*)
   ((null set-to) nil)
   (t (setf *suspend-switch* t))))

;;; M-C-w
;;; 直後のキルを、最後にキルしたテキストに(必ず)付け加える。
;;;
(defun append-next-kill ()
  (setf *suspend-switch* nil))

;;; M-c
;;; 指定された個数の単語の1文字目だけを大文字に変換し、残りを
;;; 小文字に変換する。
;;;
(defun capitalize-word (&optional (n nil))
  (let (pos)
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (cond
      ((zerop n) nil)
      ((> n 0)
       (dotimes (i n *point*) (true-capitalize-word)))
      ((< n 0)
       (setf pos *point*)
       (self-insert #\Space 1)          ;this is a trick.
       (backward-word 1)
       (true-capitalize-word)
       (delete-char nil)                ;cancel trick here.
       (backward-word 1)
       (dotimes (i (- (- n) 1))
         (backward-word 1)
         (true-capitalize-word)
         (backward-word 1))
       (move-point-to pos)))))

;;;
;;; 後続の単語の1文字目だけを大文字に変換し、残りを小文字に変換する。
;;; ポイントが単語の途中にある場合は、ポイントの後ろにある部分だけを
;;; 変換する。
;;;
(defun true-capitalize-word ()
  (let (word)
    (if (empty-text-p) (return-from true-capitalize-word nil))
    (loop
      (when (end-of-text-p) (return-from true-capitalize-word nil))
      (when (normal-char-p (current-char)) (return))
      (forward-char 1))
    (kill-ring-suspend t)
    (kill-word 1)
    (setf word (pop-kill-ring))
    (setf word (unpack (string-capitalize (pack word))))
    (insert word)))

;;; M-u
;;; 指定された個数の単語を大文字に変換する。
;;; 負数が指定されたときは後ろ向きに指定個の単語を大文字化する。
;;;
(defun upcase-word (&optional (n nil))
  (let (pos)
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (cond
      ((zerop n) nil)
      ((> n 0)
       (dotimes (i n *point*) (true-upcase-word)))
      ((< n 0)
       (setf pos *point*)
       (self-insert #\Space 1)          ;this is a trick.
       (backward-word 1)
       (true-upcase-word)
       (delete-char nil)                ;cancel trick here.
       (backward-word 1)
       (dotimes (i (- (- n) 1))
         (backward-word 1)
         (true-upcase-word)
         (backward-word 1))
       (move-point-to pos)))))

;;;
;;; 後続の単語を大文字に変換する。
;;; ポイントが単語の途中にある場合は、ポイントの後ろにある部分だけを
;;; 変換する。
;;;
(defun true-upcase-word ()
  (let (word)
    (if (empty-text-p) (return-from true-upcase-word nil))
    (save-mark-info)
    (set-mark-command)
    (forward-word 1)
    (exchange-point-and-mark)
    (kill-ring-suspend t)
    (kill-word 1)
    (setf word (pop-kill-ring))
    (setf word (unpack (string-upcase (pack word))))
    (insert word)
    (align-mark)
    (return-from true-upcase-word *point*)))

;;; M-l
;;; 指定された個数の単語を小文字に変換する。
;;; 負数が指定されたときは後ろ向きに指定個の単語を小文字化する。
;;;
(defun downcase-word (&optional (n nil))
  (let (pos)
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (cond
      ((zerop n) nil)
      ((> n 0)
       (dotimes (i n *point*) (true-downcase-word)))
      ((< n 0)
       (setf pos *point*)
       (self-insert #\Space 1)          ;this is a trick.
       (backward-word 1)
       (true-downcase-word)
       (delete-char nil)                ;cancel trick here.
       (backward-word 1)
       (dotimes (i (- (- n) 1))
         (backward-word 1)
         (true-downcase-word)
         (backward-word 1))
       (move-point-to pos)))))
;;;
;;; 後続の単語を小文字に変換する。
;;; ポイントが単語の途中にある場合は、ポイントの後ろにある部分だけを
;;; 変換する。
;;;
(defun true-downcase-word ()
  (let (word)
    (if (empty-text-p) (return-from true-downcase-word nil))
    (save-mark-info)
    (set-mark-command)
    (forward-word 1)
    (exchange-point-and-mark)
    (kill-ring-suspend t)
    (kill-word 1)
    (setf word (pop-kill-ring))
    (setf word (unpack (string-downcase (pack word))))
    (insert word)
    (align-mark)
    (return-from true-downcase-word *point*)))

;;; M-z
;;; ポイント位置から入力された文字が指定回数回目に現れる位置までを、
;;; その文字を含めてキルする。キルできなければ nilを返し、キルでき
;;; たときはポイント位置を返す。
;;;
(defun zap-to-char (&optional (n nil) &aux result)
  (let (ch)
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (setf ch (getchar))
    (cond
      ((zerop n) nil)
      ((> n 0)
       (dotimes (i n result) (setf result (true-zap-to-char ch))))
      (t
       (dotimes (i (- n) result) (setf result (true-backward-zap-to-char ch)))))))

(defun true-zap-to-char (ch)
  (declare (type character ch))
  (let (rest-line pos result)
    (declare (type list rest-line))
    (setf rest-line (subseq *text* *point*))
    (setf pos (position ch rest-line))
    (when (null pos)
      (audio-bell)
      (return-from true-zap-to-char nil))
    (save-mark-info)
    (set-mark-command)
    (forward-char (1+ pos))
    (exchange-point-and-mark)   ;force forward kill.
    (setf result (kill-region))
    (align-mark)
    (return-from true-zap-to-char result)))

(defun true-backward-zap-to-char (ch)
  (declare (type character ch))
  (let (prev-line pos result)
    (declare (type list prev-line))
    (setf prev-line (subseq *text* 0 *point*))
    (setf pos (position ch (reverse prev-line)))
    (when (null pos)
      (audio-bell)
      (return-from true-backward-zap-to-char nil))
    (save-mark-info)
    (set-mark-command)
    (backward-char (1+ pos))
    (exchange-point-and-mark)   ;force backward kill.
    (setf result (kill-region))
    (align-mark)
    (return-from true-backward-zap-to-char result)))

;;; C-t
;;; ポイントの前後の文字を入れ替える。
;;;
;;; 012354 というテキストでポイントが4の直前（カーソルが4の位置）に
;;; あるときに transpose-charを行うと 012345 に置き換わりポイントは
;;; 5の直後に移動する。移動後のポイント位置を返す。
;;;
;;; 指定回数が 0のときはポイントの直後の文字とマークの直後の文字を
;;; 入れ替える。ポイント位置とマーク位置は入れ替わる。マークが設定
;;; されていなかったときは何もせず nilを返す。
;;;
(defun transpose-chars (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
   ((> n 0)
    (dotimes (i n *point*) (true-transpose-chars)))
   ((< n 0)
    (dotimes (i (- n) *point*)
      (backward-char 1)
      (true-transpose-chars)
      (backward-char 1)))
   ((zerop n)
    (cond
     ((null *mark*) (audio-bell))
     (t
      (kill-ring-suspend t)
      (delete-char 1)                   ;KILL one character.
      (exchange-point-and-mark)
      (yank 1)
      (pop-kill-ring)
      (kill-ring-suspend t)
      (delete-char 1)                   ;KILL one character.
      (exchange-point-and-mark)
      (yank 1)
      (pop-kill-ring)
      (backward-char 1)
      (exchange-point-and-mark)
      (backward-char 1)
      (return-from transpose-chars *point*))))))

(defun true-transpose-chars ()
  (let (ch)
    (when (beginning-of-text-p)
      (audio-bell)
      (return-from true-transpose-chars nil))
    (if (end-of-text-p) (backward-char 1))
    (setf ch (current-char))
    (delete-char nil)
    (backward-char 1)
    (self-insert ch 1)
    (forward-char 1)))

;;; M-t
;;; ポイントの前後の単語を入れ替える。
;;;
;;; 指定回数が 0のときはポイントの直後の単語とマークの直後の単語を
;;; 入れ替える。ポイント位置とマーク位置は入れ替わる。マークが設定
;;; されていなかったときは何もせず nilを返す。
;;;
(defun transpose-words (&optional (n nil))
  (let (pos pos2)
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (cond
      ((> n 0)
       (dotimes (i n *point*) (true-transpose-words)))
      ((< n 0)
       (dotimes (i (- n) *point*)
         (backward-word 1)
         (true-transpose-words)
         (backward-word 1)))
      ((zerop n)
       (cond
         ((null *mark*) (audio-bell))
         (*mark*
          (kill-ring-suspend t)
          (setf pos *point*)
          (kill-word 1)
          (exchange-point-and-mark)
          (yank 1)
          (pop-kill-ring)
          (kill-ring-suspend t)
          (setf pos2 *point*)
          (kill-word 1)
          (move-point-to pos)
          (yank 1)
          (pop-kill-ring)
          (move-point-to pos)
          (set-mark-command)
          (move-point-to pos2)
          (return-from transpose-words *point*)))))))


(defun true-transpose-words ()
  (let (pos)
    (if (or (empty-text-p) (beginning-of-text-p) (end-of-text-p))
        (return-from true-transpose-words nil))
    (save-mark-info)
    (set-mark-command)
    ;;Already in a word ?
    (when (in-word-p)
      (forward-word 1)
      (set-mark-command))
    ;; Is there word backward ?
    (backward-word 1)
    (when (not (normal-char-p (current-char)))
      (exchange-point-and-mark)
      (align-mark)
      (audio-bell)
      (return-from true-transpose-words nil))
    ;; Is there word forward ?
    (exchange-point-and-mark)
    (set-mark-command)
    (loop
      (if (end-of-text-p) (return))
      (if (normal-char-p (current-char)) (return))
      (forward-char 1))
    (when (end-of-text-p) 
      (exchange-point-and-mark)
      (align-mark)
      (audio-bell)
      (return-from true-transpose-words nil))
    ;; Main block
    (exchange-point-and-mark)
    (backward-word 1)
    (kill-ring-suspend t)
    (kill-word 1)
    (setf pos *point*)
    (skip-to-normal-char)
    (yank 1)
    (pop-kill-ring)
    (kill-ring-suspend t)
    (kill-word 1)
    (move-point-to pos)
    (yank 1)
    (pop-kill-ring)
    (forward-word 1)
    (align-mark)))

;;;
;;; ポイントが単語中にあるか否かを調べる。
;;;
(defun in-word-p ()
  (let (ch)
    (cond
     ((empty-text-p) nil)
     ((beginning-of-text-p)
      (normal-char-p (current-char)))
     ((end-of-text-p) nil)
     ((not (normal-char-p (current-char))) nil)
     (t (backward-char 1)
        (setf ch (current-char))
        (forward-char 1)
        (normal-char-p ch)))))

;;;
;;; ポイントが単語の中にあれば、その単語の文字数を返す。
;;; 単語は「(normal-char-p ch)」を満たす文字の列。
;;; 文字が存在しないか、ポイントが(normal-char-p ch)を満たさない文字を指している場合は[nil]を返す。
;;;
(defun current-word-length ()
  (let (len last-point)
    (setf last-point *point*)
    (cond
      ((empty-text-p)
       nil)
      ((in-word-p)
       (loop
         (backward-char)
         (if (not (normal-char-p (current-char))) (return))
         )
       (forward-char)
       (setf len (- last-point *point*))
       (return-from current-word-length len)
       )
      (t nil)
      )
    ) ;; end let
  ) ;; end defun

;;; M-C-f
;;; Ｓ式を単位として指定回数分、前向きに移動する。
;;; 引数が負の場合は指定回数分後ろ向きに移動する。
;;;
;;; 指定回数分移動できたときはポイント位置を返す。
;;; そうでないときは nilを返す。
;;;
(defun forward-sexp (&optional (n nil) &aux result)
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
    ((zerop n) nil)
    ((> n 0)
     (dotimes (i n result) (setf result (true-forward-sexp))))
    (t (backward-sexp (- n)))))

;;;
;;; ポイントを LispのＳ式ひとつ分、前向きに移動する。
;;; 移動対象のＳ式がなければポイントは移動せず、nilを返す。
;;; 移動できればポイント位置を返す。
;;;
(defun true-forward-sexp ()
  (let (depth in-string pos)
    (setf depth 0)
    (setf pos *point*)
    (setf in-string (in-string-or-literal-p))
    (when in-string
      (move-point-to in-string)
      (skip-string-or-literal)
      (return-from true-forward-sexp *point*))
    (loop
      (skip-white-space)
      (cond
        ((end-of-text-p)
         (move-point-to pos)
         (return-from true-forward-sexp nil))
        ((member (current-char) *left-parenthesis-list* :test #'char=)
         (decf depth)
         (forward-char 1))
        ((member (current-char) *right-parenthesis-list* :test #'char=)
         (incf depth)
         (forward-char 1)
         (if (= depth 0) (return-from true-forward-sexp *point*)))
        ((char= (current-char) #\#)
         (forward-char 1)
         (cond
           ((member (current-char) '(#\\ #\'))
            (forward-char 1)
            (forward-word 1))
           (t (forward-word 1)))
         (if (= depth 0) (return-from true-forward-sexp *point*)))
        ((member (current-char) '(#\' #\` #\, #\@))
         (forward-char 1))
        ((member (current-char) '(#\" #\|))
         (skip-string-or-literal)
         (if (= depth 0) (return-from true-forward-sexp *point*)))
        ((char= (current-char) #\\)
         (forward-char 2)
         (if (= depth 0) (return-from true-forward-sexp *point*)))
        ((normal-char-p (current-char))
         (forward-word 1)
         (if (= depth 0) (return-from true-forward-sexp *point*)))
        (t (forward-char 1))))))

;;; M-C-b
;;; Ｓ式を単位として指定回数分、後ろ向きに移動する。
;;; 引数が負の場合は、指定回数分前向きに移動する。
;;;
;;; 指定回数分移動できたときはポイント位置を返す。
;;; そうでないときは nilを返す。
;;;
(defun backward-sexp (&optional (n nil) &aux result)
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
   ((zerop n) nil)
   ((> n 0)
    (dotimes (i n result) (setf result (true-backward-sexp))))
   (t (forward-sexp (- n)))))

;;;
;;; ポイントをLispのＳ式ひとつ分、後向きに移動する。
;;; 移動対象のＳ式がなければポイントは移動せず、nilを返す。
;;; 移動できればポイント位置を返す。
;;;
(defun true-backward-sexp ()
  (let (line pos len result)
    (setf pos *point*)
    (setf line (copy-seq *text*))
    (setf len (length *text*))
    (setf *text* (invert-list line))
    (move-point-to (- len pos))
    (setf result (forward-sexp 1))
    (setf pos (- len *point*))
    (setf *text* line)
    (move-point-to pos)
    (return-from true-backward-sexp result)))

;;; M-C-d
;;; 順方向に指定回数分、下のかっこレベルに移動する。
;;;
;;; 指定回数分移動できたときはポイント位置を返す。
;;; そうでないときは nilを返す。
;;;
(defun down-list (&optional (n nil) &aux result)
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
   ((zerop n) nil)
   ((> n 0)
    (dotimes (i n result) (setf result (true-down-list))))
   (t (backward-down-list (- n)))))

;;;
;;; 順方向にひとつ下のかっこレベルに移動する。
;;; 移動対象のＳ式がなければポイントは移動せず、nilを返す。
;;; 移動できればポイント位置を返す。
;;;
(defun true-down-list ()
  (let (in-string pos)
    (setf pos *point*)
    (setf in-string (in-string-or-literal-p))
    (when in-string
      (move-point-to in-string)
      (skip-string-or-literal))
    (loop
      (skip-white-space)
      (cond
       ((end-of-text-p)
        (move-point-to pos)
        (return-from true-down-list nil))
       ((member (current-char) *left-parenthesis-list* :test #'char=)
        (forward-char 1)
        (return-from true-down-list *point*))
       ((member (current-char) *right-parenthesis-list* :test #'char=)
        (move-point-to pos)
        (return-from true-down-list nil))
       ((member (current-char) '(#\" #\|))
        (skip-string-or-literal))
       ((char= (current-char) #\\)
        (forward-char 2))
       ((normal-char-p (current-char))
        (forward-word 1))
       (t (forward-char 1))))))

;;;
;;; 逆方向に指定回数分、下のかっこレベルに移動する。
;;;
;;; 指定回数分移動できたときはポイント位置を返す。
;;; そうでないときは nilを返す。
;;;
(defun backward-down-list (&optional n &aux result)
  (if (null n) (setf n (repeat-count)))
  (if (null n) (setf n 1))
  (cond
   ((zerop n) nil)
   ((> n 0)
    (dotimes (i n result) (setf result (true-backward-down-list))))
   (t (down-list (- n)))))

;;;
;;; 逆方向に1つ下のかっこレベルに移動する。
;;;
;;; 指定回数分移動できたときはポイント位置を返す。
;;; そうでないときは nilを返す。
;;;
(defun true-backward-down-list ()
  (let (line pos len result)
    (setf pos *point*)
    (setf line (copy-seq *text*))
    (setf len (length *text*))
    (setf *text* (invert-list line))
    (move-point-to (- len pos))
    (setf result (down-list 1))
    (setf pos (- len *point*))
    (setf *text* line)
    (move-point-to pos)
    (return-from true-backward-down-list result)))

;;; C-x u (for debug binding)
;;; 順方向に指定回数分、上のかっこレベルに移動する。
;;;
;;; 指定回数分移動できたときはポイント位置を返す。
;;; そうでないときは nilを返す。
;;;
(defun up-list (&optional (n nil) &aux result)
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
   ((zerop n) nil)
   ((> n 0)
    (dotimes (i n result) (setf result (true-up-list))))
   (t (backward-up-list (- n)))))

;;;
;;; 順方向にひとつ上のかっこレベルに移動する。
;;; 移動対象のＳ式がなければポイントは移動せず、nilを返す。
;;; 移動できればポイント位置を返す。
;;;
(defun true-up-list ()
  (let (in-string pos level)
    (setf level 0)
    (setf pos *point*)
    (setf in-string (in-string-or-literal-p))
    (when in-string
      (move-point-to in-string)
      (skip-string-or-literal))
    (loop
      (skip-white-space)
      (cond
       ((end-of-text-p)
        (move-point-to pos)
        (return-from true-up-list nil))
       ((member (current-char) *left-parenthesis-list* :test #'char=)
        (decf level)
        (forward-char 1))
       ((member (current-char) *right-parenthesis-list* :test #'char=)
        (incf level)
        (forward-char 1)
        (if (= level 1) (return-from true-up-list *point*)))
       ((member (current-char) '(#\" #\|))
        (skip-string-or-literal))
       ((char= (current-char) #\\)
        (forward-char 2))
       ((normal-char-p (current-char))
        (forward-word 1))
       (t (forward-char 1))))))

;;; M-C-u
;;; 逆方向に指定回数分、上のかっこレベルに移動する。
;;;
;;; 指定回数分移動できたときはポイント位置を返す。
;;; そうでないときは nilを返す。
;;;
(defun backward-up-list (&optional (n nil) &aux result)
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
   ((zerop n) nil)
   ((> n 0)
    (dotimes (i n result) (setf result (true-backward-up-list))))
   (t (up-list (- n)))))

;;;
;;; 逆方向にひとつ上のかっこレベルに移動する。
;;; 移動対象のＳ式がなければポイントは移動せず、nilを返す。
;;; 移動できればポイント位置を返す。
;;;
(defun true-backward-up-list ()
  (let (pos line len level in-string result)
    (setf result t)
    (setf pos *point*)
    (setf line (copy-seq *text*))
    (setf len (length line))
    (setf *text* (invert-list line))
    (move-point-to (- len pos))
    (block main
      (setf level 0)
      (setf in-string (in-string-or-literal-p))
      (when in-string
        (move-point-to in-string)
        (skip-string-or-literal))
      (loop
        (skip-white-space)
        (cond
         ((end-of-text-p)
          (if (= level 0) (setf result nil))
          (return result))
         ((member (current-char) *left-parenthesis-list* :test #'char=)
          (decf level)
          (forward-char 1))
         ((member (current-char) *right-parenthesis-list* :test #'char=)
          (incf level)
          (forward-char 1)
          (if (= level 1) (setf result *point*))
          (return result))
         ((member (current-char) '(#\" #\|))
          (skip-string-or-literal))
         ((char= (current-char) #\\)
          (forward-char 2))
         ((normal-char-p (current-char))
          (forward-word 1))
         (t (forward-char 1)))))
    (when result (setf pos (- len *point*)))
    (setf *text* line)
    (move-point-to pos)
    (return-from true-backward-up-list result)))

;;; M-C-n (move to Next list)
;;; 指定回数分、リスト単位で進む。
;;; 負の引数が指定されたときは、逆向きに進む。
;;;
;;; 指定回数分移動できたときはポイント位置を返す。
;;; そうでないときは nilを返す。
;;;
(defun forward-list (&optional (n nil) &aux result)
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
   ((zerop n) nil)
   ((> n 0)
    (dotimes (i n result) (setf result (true-forward-list))))
   (t (backward-list (- n)))))

;;;
;;; リストひとつ分進む
;;; 移動対象のＳ式がなければポイントは移動せず、nilを返す。
;;; 移動できればポイント位置を返す。
;;;
(defun true-forward-list ()
  (when (down-list 1) (up-list 1)))

;;; M-C-p (move to Previous list)
;;; 指定回数分、リスト単位で逆向きに進む。
;;; 負の引数が指定されたときは、前向きに進む。
;;;
;;; 指定回数分移動できたときはポイント位置を返す。
;;; そうでないときは nilを返す。
;;;
(defun backward-list (&optional (n nil) &aux result)
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
   ((zerop n) nil)
   ((> n 0)
    (dotimes (i n result) (setf result (true-backward-list))))
   (t (forward-list (- n)))))

;;;
;;; リストひとつ分戻る
;;; 移動対象のＳ式がなければポイントは移動せず、nilを返す。
;;; 移動できればポイント位置を返す。
;;;
(defun true-backward-list ()
  (let (pos line len result)
    (setf pos *point*)
    (setf line (copy-seq *text*))
    (setf len (length line))
    (setf *text* (invert-list line))
    (move-point-to (- len pos))
    (setf result (forward-list 1))
    (when result (setf pos (- len *point*)))
    (setf *text* line)
    (move-point-to pos)
    (return-from true-backward-list result)))

;;;
;;; 引数の文字列リストを逆順にする。ただし、逆向きの走査に対して順方向
;;; 走査関数を適用できるようにするために、以下の変換を行う。
;;;
;;;     '('             --> ')'
;;;     ')'             --> '('
;;;     '\x'            --> '\x'
;;;     '#\\word'       --> '#\\word'
;;;     'xyz            --> 'xyz
;;;
;;; たとえば、
;;;     "(load \"line-edit-pkg.lsp\")"  ==> "(\"psl.gkp-tide-enil\" daol)"
;;;     "(list #\\a #\\Space #\\b)"     ==> "(#\\b #\\Space #\\a tsil)"
;;; となる。
;;;     
(defun invert-list (lst)
  (declare (type list lst))
  (let (inv-lst rest buf ch)
    (if (not (listp lst)) (return-from invert-list nil))
    (setf inv-lst nil)
    (setf rest (length lst))
    (loop
      (if (null lst) (return inv-lst))
      (setf ch (pop lst))
      (decf rest)
      (cond
        ((< rest 0) inv-lst)
        ((member ch *left-parenthesis-list* :test #'char=)
         (push (corres-paren ch) inv-lst))
        ((member ch *right-parenthesis-list* :test #'char=)
         (push (corres-paren ch) inv-lst))
        ((char= ch #\\)
         (when lst
           (setf ch (pop lst))
           (decf rest)
           (push ch inv-lst))
         (push #\\ inv-lst))
        ((char= ch #\') ;; 'xyz --> 'xyz
         (loop
           (if (null lst) (return))
           (if (end-of-line-p) (return))
           (if (break-char-p (first lst)) (return))
           (if (white-space-p (first lst)) (return))
           (setf ch (pop lst))
           (decf rest)
           (push ch inv-lst)
           ) ;; end loop
         (push #\' inv-lst)
         )
        ((char= ch #\#)
         (setf buf nil)
         (push #\# buf)
         (setf ch (pop lst))
         (decf rest)
         (cond
           ((null lst)
            (push ch buf)
            (setf inv-lst (append (reverse buf) inv-lst)))
           ((member ch '(#\\ #\') :test #'char=)
            (push ch buf)
            (push (pop lst) buf)
            (decf rest)
            (cond
              ((null lst)
               (setf inv-lst (append (reverse buf) inv-lst)))
              (t
               (loop
                 (setf ch (pop lst))
                 (decf rest)
                 (cond
                   ((null lst)
                    (cond
                      ((normal-char-p ch)
                       (push ch buf)
                       (setf inv-lst (append (reverse buf) inv-lst))
                       (return))
                      (t (push ch lst)
                         (incf rest)
                         (setf inv-lst (append (reverse buf) inv-lst))
                         (return))))
                   ((not (normal-char-p ch))
                    (push ch lst)
                    (incf rest)
                    (setf inv-lst (append (reverse buf) inv-lst))
                    (return))
                   (t (push ch buf)))))))
           (t (setf inv-lst (append (reverse buf) inv-lst))
              (push ch lst)
              (incf rest))))
        (t (push ch inv-lst))))))

;;;
;;; 同種類の対応するかっこを返す。
;;;
(defun corres-paren (paren)
  (let (n)
    (cond
     ((setf n (search (list paren) *left-parenthesis-list* :test #'char=))
      (nth n *right-parenthesis-list*))
     ((setf n (search (list paren) *right-parenthesis-list* :test #'char=))
      (nth n *left-parenthesis-list*)))))

;;;
;;; かっこ類と指定されたものの一覧を返す。
;;;
(defun parenthesis-list ()
  (pairlis *left-parenthesis-list* *right-parenthesis-list*))

;;;
;;; かっこ類の定義をリセットする。
;;;
(defun reset-parenthesis-list ()
  (setf *left-parenthesis-list* nil)
  (setf *right-parenthesis-list* nil))

;;;
;;; 対のかっこを１組、リストの先頭に追加する。
;;;     (set-balanced-paren #\( #\))
;;; 最新のかっこ類の定義一覧を返す。
;;;
(defun set-balanced-paren (left right)
  (when (and (characterp left) (characterp right))
    (push left *left-parenthesis-list*)
    (push right *right-parenthesis-list*)
    (parenthesis-list)))

;;;
;;; 指定されたペアになるかっこをかっこ類の定義から削除する。
;;;
;;; もし、引数がひとつしか指定されていなければリストを左か
;;; から検索し、最初に見つかった左かっこと、対になる右かっ
;;; こを削除する。
;;;
;;; もし、引数が２つ指定されていれば、一致する対のかっこを
;;; 削除する。
(defun unset-balanced-paren (left &optional right)
  (cond
   ((not (characterp left)) nil)
   ((or
     (null right)
     (characterp right))
    (make-parenthesis-list (true-unset-balanced-paren left right (parenthesis-list))))
   (t nil)))

(defun true-unset-balanced-paren (left right alst)
  (cond
   ((null alst) nil)
   ((char= left (caar alst))
    (cond
     ((null right) (cdr alst))
     ((char= right (cdar alst)) (cdr alst))
     (t (cons (car alst) (true-unset-balanced-paren left right (cdr alst))))))
   (t (cons (car alst) (true-unset-balanced-paren left right (cdr alst))))))

;;;
;;; dotted listで表わされた対になるかっこのリストからかっこ
;;; 類の定義リストを作成する。
;;;
(defun make-parenthesis-list (alst)
  (reset-parenthesis-list)
  (loop
    (when (null alst) (return))
    (when (not (and (characterp (caar alst)) (characterp (cdar alst)))) (return))
    (setf *left-parenthesis-list* (append *left-parenthesis-list* (list (caar alst))))
    (setf *right-parenthesis-list* (append *right-parenthesis-list* (list (cdar alst))))
    (pop alst))
  (parenthesis-list))

;;; M-C-@
;;; 指定された個数のＳ式を含むリージョンを設定する。
;;;
(defun mark-sexp (&optional (n 1))
  (declare (type fixnum n))
  (setf n (select-repeat-count n))
  (forward-sexp n)
  (set-mark-command)
  (backward-sexp n))

;;; M-(
;;; 指定された個数分のＳ式をかっこで囲み、ポイントを開きかっこの直後に
;;; 移動する。Ｓ式が存在しなければ１対のかっこを挿入する。
;;;
(defun insert-parenthesis (&optional (n nil))
  (let (deley)
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (setf deley (blink-paren-deley))
    (blink-paren-deley 0)
    (save-mark-info)
    (cond
      ((zerop n) nil)
      ((> n 0)
       (self-insert (first *left-parenthesis-list*) 1)
       (set-mark-command)
       (forward-sexp n)
       (self-insert (first *right-parenthesis-list*) 1)
       (exchange-point-and-mark))
      ((< n 0)
       (self-insert (first *left-parenthesis-list*) 1)
       (backward-sexp (- n))
       (self-insert (first *right-parenthesis-list*) 1)))
    (align-mark)
    (blink-paren-deley deley)))

;;; M-C-k
;;; 現在のポイントから指定回数分のＳ式の終りまでをキルする。
;;;
(defun kill-sexp (&optional (n nil))
  (let (result)
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (cond
      ((zerop n) nil)
      ((< n 0)
       (backward-kill-sexp (- n)))
      ((> n 0)
       (save-mark-info)
       (set-mark-command)
       (forward-sexp n)
       (exchange-point-and-mark)        ;force forward kill.
       (setf result (kill-region))
       (align-mark)
       (return-from kill-sexp result)))))

;;;
;;; 現在のポイントから指定回数分のＳ式の開始位置までをキルする。
;;;
(defun backward-kill-sexp (&optional (n nil))
  (let (result)
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (cond
      ((zerop n) nil)
      ((< n 0)
       (kill-sexp (- n)))
      ((> n 0)
       (save-mark-info)
       (set-mark-command)
       (backward-sexp n)
       (exchange-point-and-mark)        ;force backward kill.
       (setf result (kill-region))
       (align-mark)
       (return-from backward-kill-sexp result)))))

;;; M-C-t
;;; ポイントの前後のＳ式を入れ替える。Ｓ式とＳ式の間の空白文字類は、
;;; そのまま存在する。ポイントは入れ替えたＳ式の直後に移動する。
;;;
;;; 指定回数が 0のときはポイントの直後のＳ式とマークの直後のＳ式を
;;; 入れ替える。ポイント位置とマーク位置は入れ替わる。
;;;
(defun transpose-sexps (&optional (n nil)) ;transpose Symbolic EXPressionS
  (let (pos pos2 tm)
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (setf tm (blink-paren-deley))
    (blink-paren-deley 0)
    (cond
      ((> n 0)
       (dotimes (i n) (true-transpose-sexps)))
      ((< n 0)
       (dotimes (i (- n))
         (true-backward-sexp)
         (true-transpose-sexps)
         (true-backward-sexp)))
      ((zerop n)
       (cond
         ((null *mark*) nil)
         (*mark*
          (kill-ring-suspend t)
          (setf pos *point*)
          (kill-sexp 1)
          (exchange-point-and-mark)
          (yank 1)
          (pop-kill-ring)
          (kill-ring-suspend t)
          (setf pos2 *point*)
          (kill-sexp 1)
          (move-point-to pos)
          (yank 1)
          (pop-kill-ring)
          (move-point-to pos)
          (set-mark-command)
          (move-point-to pos2)))))
    (blink-paren-deley tm)))

(defun true-transpose-sexps ()
  (if (empty-text-p) (return-from true-transpose-sexps nil))
  (if (beginning-of-text-p) (return-from true-transpose-sexps nil))
  (if (end-of-text-p) (return-from true-transpose-sexps nil))
  (save-mark-info)
  (set-mark-command)
  ;; Is previous sexp exists ?
  (backward-skip-white-space)
  ;; Ignore quote character, if exists. 2001/08/12
  (when (not (beginning-of-text-p))
    (backward-char 1)
    (if (char= (current-char) #\')
        (backward-skip-white-space)
        (forward-char 1)))
  (when (beginning-of-text-p)
    (exchange-point-and-mark)
    (align-mark)
    (audio-bell)
    (return-from true-transpose-sexps nil))
  ;; Is next sexp exists ?
  (exchange-point-and-mark)
  (set-mark-command)
  (skip-white-space)
  (when (in-word-p) (forward-word 1))
  (when (not (forward-sexp 1))
    (exchange-point-and-mark)
    (align-mark)
    (audio-bell)
    (return-from true-transpose-sexps nil))
  ;; Main block
  (exchange-point-and-mark)
  (backward-sexp 1)
  (kill-ring-suspend t)
  (kill-sexp 1)
  (kill-ring-suspend t)
  (kill-white-space)
  (forward-sexp 1)
  (yank 1)
  (yank 1) (yank-pop 1)
  (pop-kill-ring)
  (pop-kill-ring)
  (align-mark))

;;; M-p
;;; カーソル位置の文字がかっこであれば、対応するかっこに移動する。
;;; 対応するかっこが存在しなければポイントは移動しない。
;;; カーソル位置の文字がかっこ以外であれば、次のかっこに移動する。
;;;
(defun move-to-matching-paren (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
   ((zerop n) nil)
   ((< n 0) nil)
   ((= (mod n 2) 1) (true-move-to-matching-paren))))

(defun true-move-to-matching-paren ()
  (cond
   ((end-of-text-p) nil)
   (t (pure-move-to-matching-paren))))

(defun pure-move-to-matching-paren ()
  (let (pos)
    (cond
     ((member (current-char) *left-parenthesis-list* :test #'char=)
      (when (forward-list 1) (backward-char 1)))
     ((member (current-char) *right-parenthesis-list* :test #'char=)
      (forward-char 1)
      (when (backward-list 1) (return-from pure-move-to-matching-paren t))
      (backward-char 1)
      (return-from pure-move-to-matching-paren nil))
     (t
      (setf pos *point*)
      (loop
        (forward-char 1)
        (when (end-of-text-p)
          (move-point-to pos)
          (return))
        (if (member (current-char) *parenthesis-list* :test #'char=)
            (return)))))))

;;;
;;; 対応するかっこに設定秒数だけ移動する。
;;;
(defun blink-paren ()
  (if (blink-paren-p) (jump-and-return-balanced-paren)))

;;; 過去の版との互換性のための定義
;;(defun highlight-paren ()
;;  (blink-paren)
;;  )

;;;
;;; 対応するかっこに移動する条件を満たしているか否かを返す。
;;;
(defun blink-paren-p ()
  (and
   (numberp (blink-paren-deley))
   (plusp (blink-paren-deley))
   (not (in-string-or-literal-p)) ;; 文字列内のカッコとリテラル指定されたカッコは除外。
   )
  )

;;;
;;; 対応するかっこに移動する秒数を設定する。
;;; 引数がなければ設定されている秒数を返す。
;;; 対応するかっこへの移動をオフにするには 0または数値以外の値を設定する。
;;;
(defun blink-paren-deley (&optional (sec 0 sw))
  (cond
   ((null sw) *blink-paren-deley*)
   (t (setf *blink-paren-deley* sec))))

;;; 過去の版との互換性のための定義
;;(defun highlight-paren-deley (&optional (sec 0 sw))
;;  (cond
;;   ((null sw) (blink-paren-deley))
;;   (t (blink-paren-deley sec))))

;;;
;;; 対応するかっこに (blink-paren-deley)秒だけ移動する。
;;; ポイントだけでなく、カーソル移動も行う。
;;;
(defun jump-and-return-balanced-paren ()
  (let (pos)
    (setf pos *point*)
    (when (move-to-matching-paren 1)
      (display-line)
      (move-logical-cursor-to (third (display-range)))
      (xsleep (blink-paren-deley))
      (move-point-to pos)
      (display-line)
      (return-from jump-and-return-balanced-paren t))
    (return-from jump-and-return-balanced-paren nil)))

;;;
;;; (sleep sec)と同じ。ただし "sleep is permitted to use approximate timing."
;;; なので、どの程度正確かは処理系に依存する。GCL 2.3.8-Betaでは
;;;
;;;     > (time (sleep 0.5))
;;;     real time : 0.000 secs
;;;     run time  : 0.000 secs
;;;     
;;;     > (time (sleep 0.6))
;;;     real time : 1.000 secs
;;;     run time  : 0.000 secs
;;;
;;; であった。以下のxsleepの精度も処理系と実行マシンの速度依存であるが、
;;; 0.1秒単位の精度を期待して定義している。
;;; Pentium III 700MHz + GCL 2.3.8-Beta/Linux 2.4.0-test8では、期待どお
;;; りの精度であった。

(defun xsleep (sec)
  (let (ctime second)
    (setf second (* sec internal-time-units-per-second))
    (setf ctime (get-internal-real-time))
    (loop
      (when (>= (- (get-internal-real-time) ctime) second)
        (return-from xsleep sec)))))

;;;
;;; 文字入力時のみ、対応するかっこを光らせるかどうかを設定する。
;;; 引数を指定しないと現在の設定を返す。
;;;
(defun blink-paren-just-inserted (&optional (blink-p nil sw))
  (cond
   ((null sw) *blink-paren-just-inserted*)
   (t (setf *blink-paren-just-inserted* blink-p))))

;;; 過去の版との互換性のための定義
;;(defun highlight-paren-just-inserted (&optional (highlight-p nil sw))
;;  (cond
;;   ((null sw) (blink-paren-just-inserted))
;;   (t (blink-paren-just-inserted highlight-p))))

;;;
;;; ポイントが Common Lisp の定義による文字列の途中にあるかどうかを
;;; 調べる。もし、そうであれば、その文字列の先頭位置を返す。
;;;
;;; Is pointer in string (defined by Common Lisp) ?
;;; returns start position of its string, or nil.
;;;
(defun in-string-or-literal-p ()
  (prog (pos start in-string-or-literal)
    (save-mark-info)
    (set-mark-command)
    (setf pos *point*)
    (setf in-string-or-literal nil)
    (setf start nil)
    (beginning-of-line 1)
    (loop
      (if (end-of-text-p) (return))
      (loop
        (if (end-of-text-p) (return))
        (when (member (current-char) '(#\" #\|))
          (setf start *point*)
          (return))
        (if (char= (current-char) #\\) (forward-char 2))
        (forward-char 1))
      (when (or (null start) (>= *point* pos))
        (return))
      (skip-string-or-literal)
      (when (<= start pos *point*)
        (setf in-string-or-literal t)
        (return))
      (forward-char 1))
    (move-point-to pos)
    (align-mark)
    (if in-string-or-literal (return start) (return nil))))

;;;
;;; quoteされた記号を読み飛ばす。
;;;
(defun skip-quoted-string ()
  (if (end-of-text-p) (return-from skip-quoted-string *point*))
  (when (char= (current-char) #\')
    (forward-word 1)
    (return-from skip-quoted-string *point*)
    ) ;; end when
  )

;;;
;;; 「#\」でエスケープされた記号を読み飛ばす。
;;;
(defun skip-sharp-backslash-string ()
  (if (end-of-text-p) (return-from skip-sharp-backslash-string *point*))
  ;;(forward-char 1)
  (cond
    ;;((end-of-text-p)
    ;; (backward-char 1)
    ;; (return-from skip-sharp-backslash-string *point*))
    ((char= (current-char) #\#)
     (forward-word 1)
     (return-from skip-sharp-backslash-string *point*))
    (t
     (backward-char 1)
     (return-from skip-sharp-backslash-string *point*)
     )
    ) ;; end cond
  ) ;; end skip-sharp-back-slash-string

;;;
;;; 文字列を読み飛ばす("....")。
;;;
(defun skip-double-quoted-string ()
  (if (end-of-text-p)
      (return-from skip-double-quoted-string *point*)
      )
  ;;(forward-char 1)
  (cond
    ;;((end-of-text-p)
    ;; (return-from skip-double-quoted-string *point*)
    ;; )
    ((char= (current-char) #\")
     (loop
       (forward-char 1)
       (if (end-of-text-p) (return-from skip-double-quoted-string *point*))
       (cond
         ((char= (current-char) #\")
          (forward-char 1)
          (return-from skip-double-quoted-string *point*))
         ((char= (current-char) #\\) ;; "\
          (forward-char 2)
          (return-from skip-double-quoted-string *point*)
          )
         (t
          (forward-char 1)
          (return-from skip-double-quoted-string *point*))
         ) ;; end cond
       )   ;; end loop
     )
    (t
     (backward-char 1)
     (return-from skip-double-quoted-string *point*)
     )
    )   ;; end cond
  ) ;; end skip-double-quoted-string

;;;
;;; 縦棒リテラルを読み飛ばす。
;;;
(defun skip-bar-string ()
  (if (end-of-text-p)
      (return-from skip-bar-string *point*)
      )
  ;;(forward-char 1)
  (cond
    ;;((end-of-text-p)
    ;; (return-from skip-bar-string *point*)
    ;; )
    ((char= (current-char) #\|)
     (loop
       (cond
         ((end-of-text-p)
          (return-from skip-bar-string *point*))
         ((char= (current-char) #\|)
          (forward-char 1)
          (return-from skip-bar-string *point*))
         ((char= (current-char) #\\)
          (forward-char 2)
          (return-from skip-bar-string *point*)
          )
         (t
          (forward-char 1)
          (return-from skip-bar-string *point*)
          )
         ) ;; end cond
       )   ;; end loop
     )
    (t
     (backward-char 1)
     (return-from skip-bar-string *point*)
     )
    ) ;; end cond
  ) ;; end skip-bar-string

;;;
;;; 文字列またはリテラルを読み飛ばす。
;;;
(defun skip-string-or-literal ()
  ;;(break)
  (cond
   ((end-of-text-p) nil)
   ((char= (current-char) #\')
    (skip-quoted-string))
   ((char= (current-char) #\#)
    (skip-sharp-backslash-string))
   ((char= (current-char) #\")
    (skip-double-quoted-string))
   ((char= (current-char) #\|)
    (skip-bar-string))))

;;;
;;; ポイント位置に引数で指定される文字を挿入する。
;;; 文字が挿入されればポイント位置を返す。そうでなければ nilを返す。
;;;
;;;     In GCL-2.3.8 on Linux 2.4.0/Pentium III-700MHz
;;;
;;;     > (setf x (concatenate 'list "This is a sample code."))
;;;     > (setf y (concatenate 'list " and this is trailing code."))
;;;     > (time (dotimes (i 100000) (append x (list #\&) y)))
;;;     real time : 0.940 secs
;;;     run time  : 0.930 secs
;;;
;;;     > (time (dotimes (i 100000) (concatenate 'list x (list #\&) y)))
;;;     real time : 4.060 secs
;;;     run time  : 4.030 secs
;;;
;;;     So, I use append in this case.
;;;
(defun self-insert (ch &optional (n nil))
  (declare (type character ch))
  (let (char-lst)
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (if (not (characterp ch)) (return-from self-insert nil))
    (cond
      ((zerop n) nil)
      ((= n 1)
       (save-self-insert-undo-info ch)
       (true-self-insert ch))
      ((> n 1)
       (setf char-lst nil)
       (dotimes (i n) (push ch char-lst))
       (insert char-lst))
      ((< n 0)
       (setf char-lst nil)
       (dotimes (i (- n)) (push ch char-lst))
       (insert char-lst)
       (backward-char (length char-lst)))
      ) ;; end cond
    )   ;; end let
  ) ;; end self-insert

(defun true-self-insert (ch)
  (declare (type character ch))
  (if (not (characterp ch))
      (return-from true-self-insert nil)
      )
  (if (end-of-text-p)
      (setf *text* (append *text* (list ch)))
      (setf *text* (pure-self-insert *text* *point* ch))
      ) ;; end if
  (if (and (numberp *mark*) (> *mark* *point*))
      (incf *mark*)
      )
  (incf *ncl*)
  (move-point-to (1+ *point*))
  (when
      (or
       (member ch *right-parenthesis-list* :test #'char=)
       (and
        (not (end-of-text-p))
        (member ch *left-parenthesis-list* :test #'char=)
        ) ;; end and
       )  ;; end or
    (when (blink-paren-p)
      (backward-char 1)
      (if (jump-and-return-balanced-paren)
          (forward-char 1)
          ) ;; end if
      )     ;; end when
    )       ;; end outer when
  (return-from true-self-insert *point*)
  )

;;;
;;; [txt]の[p]位置に[ch]を挿入する。
;;;
;;; (setf *text* '(#\a #\b #\c))
;;; (pure-self-insert *text* 1 #\x) ==> (#\a #\x #\b #\c)
;;;
(defun pure-self-insert (txt p ch)
  (append (subseq txt 0 p) (list ch) (subseq txt p)))

;;;
;;; 内部表現の「文字列」をポイント位置に挿入する。
;;; 常にポイント位置を返す。
;;;
(defun insert (char-lst)
  (save-insert-undo-info char-lst)
  (dolist (ch char-lst *point*) (true-self-insert ch)))

;;;
;;; 文字列をポイント位置に挿入する。
;;;
(defun self-insert-string (str)
  (if (not (stringp str)) (return-from self-insert-string nil))
  (insert (unpack str))
  (return-from self-insert-string str)
  ) ;; end self-insert-string

;;; C-q
;;; 数引数で指定された個数分、クオートした文字を挿入する。
;;;
(defun quoted-insert (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (self-insert (getch) n))

;;;
;;; #\Newlineを挿入する。
;;;
(defun self-insert-newline (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (self-insert #\Newline n))

;;;
;;; #\Spaceを挿入する。
;;;
(defun self-insert-space (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (self-insert #\Space n))

;;; C-l
;;; 現在の行全体を書き直す。
;;; #\Newline 以外のすべての制御文字を削除し行を表示し直す。
(defun redraw ()
  (kill-ring-suspend t)
  (distill-line nil)
  (update-physical-column-size)
  (display-line)
  ) ;; end redraw

(let ((next-need-refresh-line nil))
  ;; 次回描画時に行全体の書き直しが必要となるか否かを記録する。
  (defun need-refresh-line (is-set)
    (setf next-need-refresh-line is-set)
    )

  ;; 書き直しが必要か否かを返す。
  (defun need-refresh-line-p ()
    next-need-refresh-line
    )
  ) ;; end let

;;;
;;; 引数が nilなら行内の#\Newline以外の全ての非図形文字を削除する。
;;; 引数が nil以外なら#\Newlineを含めて全ての非図形文字を削除する。
;;;
(defun distill-line (&optional del-all-p)
  (set-mark-command)
  (beginning-of-text)
  (loop
    (if (end-of-text-p) (return))
    (cond
     ((and (not del-all-p) (char= (current-char) #\Newline))
      (forward-char 1))
     ((not (graphic-char-p (current-char)))
      (delete-char nil))
     (t (forward-char 1))))
  (exchange-point-and-mark))

;;; M-k
;;; 現在の履歴テキストをキルし、履歴検索開始位置をリセットする。
;;; undo情報も捨てる。
;;;
(defun kill-text ()
  (beginning-of-text)
  (set-mark-command)
  (end-of-text)
  (kill-ring-suspend t)
  (kill-region)
  (pop-kill-ring)
  (reset-scroll)
  (reset-undo-info)
  (search-from nil))

;;; C-x r s x
;;; レジスタ 'x'にリージョンをコピーする。
;;; 前置引数が設定されていた場合は、前置引数回
;;; リージョンを複写してコピーする。
;;;
(defun copy-to-register (&optional (n nil))
  (let (r lst tmp)
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (kill-ring-suspend t)
    (kill-ring-save)
    (setf r (getchar))
    (setf lst (pop-kill-ring))
    (setf tmp nil)
    (dotimes (i n)
      (setf tmp (append tmp lst)))
    (set-register r tmp)))

;;; C-x r i x
;;; レジスタ 'x'からポイント位置にテキストを挿入する。
;;; 前置引数が設定されていた場合は、前置引数回レジス
;;; タ 'x'の内容を繰り返し挿入する。
;;;
(defun insert-register (&optional (n nil))
  (let (lst)
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (setf lst (cdr (register (getchar))))
    (dotimes (i n) (insert lst))))

;;;
;;; レジスタ 'r'にテキストを保存する。
;;; 第２引数がnilなら、レジスタ 'r'そのものを削除する。
;;;
(defun set-register (r lst)
  (declare (type character r))
  (declare (type list lst))
  (cond
   ((null r) nil)
   ((null (assoc r *registers*))
      (push (cons r lst) *registers*))
   (t (setf (cdr (assoc r *registers*)) lst)))
  (setf *registers* (remove-if #'(lambda (x) (null (cdr x))) *registers*)))

;;;
;;; レジスタ 'r'の内容を返す。
;;;
(defun register (r)
  (declare (type character r))
  (assoc r *registers*))

;;;
;;; 全レジスタの内容をファイルに保存する。
;;;
(defun save-registers ()
  (with-open-file (stream (registers-file) :direction :output)
    (dolist (i *registers* t)
      (prin1 (cons (car i) (pack (cdr i))) stream)
      (terpri stream))))

;;;
;;; ファイルに保存されている全レジスタの内容を読み込む。
;;;
(defun restore-registers ()
  (let (form)
    (when (probe-file (registers-file))
      (with-open-file (stream (registers-file) :direction :input)
        (loop
          (setf form (read stream nil +eos+))
          (when (eq form +eos+) (return-from restore-registers t))
          (set-register (car form) (unpack (cdr form))))))))

;;;
;;; レジスタの内容を保存するファイル名を設定する。引数なしの場合は
;;; 設定されているファイル名を返す。
;;;
(defun registers-file (&optional fname)
  (cond
   ((null fname) *registers-file*)
   (t (setf *registers-file* fname))))

;;;
;;; 引数で指定されたレジスタ名と、その内容を表示する。
;;; 引数が指定されていない場合は使用されているすべて
;;; のレジスタ名と、その内容を表示する。
;;;
(defun view-register (&optional ch)
  (cond
   ((null ch)
    (view-all-registers))
   (t (pure-view-register ch))))

(defun pure-view-register (ch)
  (let (reg)
;   (declare (list reg))
    (setf reg (register ch))
    (when (null reg) (return-from pure-view-register nil))
    (prin1 (car reg))
    (princ +ctrl-i+)
    (princ (pack (cdr reg)))
    (terpri)
    (return-from pure-view-register t)))

(defun view-all-registers ()
  (if (null *registers*) (return-from view-all-registers nil))
  (setf *registers* (sort *registers* #'(lambda (x y) (char< (car x) (car y)))))
  (dolist (i *registers* t) (pure-view-register (car i))))

;;; C-s
;;; ポイント位置以降の行内を対象にインクリメンタル・サーチを行う。
;;; ・探索文字に大文字を指定すると大文字と小文字を区別して探索する。
;;; ・探索文字を間違えた場合はC-hで取り消せる。
;;; ・探索文字列から(すべての)大文字を取り消すと、探索に対する大文字・
;;;   小文字の区別を行わない。
;;; ・C-hによって探索開始位置までポイントが戻った場合、インクリメンタル
;;;   サーチも終了する。
;;; ・C-gは探索全体を取り消し、ポイントを探索開始時の位置に戻す。
;;; ・探索文字の代わりにC-sをタイプすると探索文字列の次の出現個所を探索する。
;;; ・Enter, Linefeed, または Escをタイプすると検索を終了する。
;;;
(defun isearch-forward ()
  (let (str ch line idx pos first-pos case-sensitive)
    (setf case-sensitive nil)
    (setf first-pos *point*)
    (setf pos first-pos)
    (setf str "")
    (setf line (pack (nthcdr *point* *text*)))
    (loop
      (setf ch (getch)) ;; MUST be 'getch', NOT 'getchar'
      (cond
        ;;((member ch '(#\Return #\Linefeed #\^[))
        ((member ch '(+ctrl-m+ +ctrl-j+ +ESC+))
         (return t))
        ((char= ch +ctrl-h+)
         (when (= (length str) 0)
           (move-point-to first-pos)
           ;;(sync-point-and-cursor)
           (return nil))
         (setf str (subseq str 0 (1- (length str)))))
        ((char= ch *ctrl-g*)
         (move-point-to first-pos)
         ;;(sync-point-and-cursor)
         (return nil))
        ((char= ch #\^S)
         (setf pos *point*)
         (setf line (pack (nthcdr *point* *text*))))
        ((not (graphic-char-p ch))
         (unread-char ch)
         (return nil))
        (t (setf str (concatenate 'string str (list ch)))))
      (if (string= str (string-downcase str))
          (setf case-sensitive nil)
          (setf case-sensitive t))
      (if case-sensitive
          (setf idx (search str line :test #'(lambda (x y) (char= x y))))
          (setf idx (search str line :test #'(lambda (x y) (char-equal x y)))))
      (when idx
        (move-point-to (+ pos idx (length str)))
        ;;(sync-point-and-cursor)
        ) ;; end when
      ) ;; end loop
    ) ;; end let
  ) ;; end isearch-forward

;;;
;;; 対話的置換を行う。
;;;
;;(defun query-replace ()
;;  )

;;; C-x i
;;; ポイント位置にファイルを挿入する。
;;; ヒストリに表示されていたコマンド行、(insert-file)の実行記録
;;; の両方を残すために最後に(throw...)を実行する。
;;;
(defun insert-file ()
  (let (from line result)
    (setf result "")
    (save-line)
    (writeln)
    (format t "Insert file from: ")
    (setf from (line-edit))
    (when (string/= from "")
      (setf from (merge-pathnames from))
      (with-open-file (s from :direction :input :if-does-not-exist nil)
        (loop
          (setf line (read-line s nil +eos+))
          (when (eq line +eos+) (return result))
          (setf result (concatenate 'string result line (list #\Newline))))))
    (restore-line)
    (save-mark-info)
    (insert (unpack (string-right-trim '(#\Newline) result)))
    (align-mark)
    ;;(sync-point-and-cursor)
    (throw :exit-line-edit (line-edit-command-loop))))

;;; C-x C-f
;;; 現在の行を指定したファイルの内容で置き換える。
;;;
(defun find-file ()
  (beginning-of-line 1)
  (kill-ring-suspend t)
  (kill-line 1)
  (pop-kill-ring)
  (insert-file))

;;; C-x C-w
;;; 現在の行を指定したファイルに保存する。
;;;
(defun write-file ()
  (let (save-to path line message)
    (save-line)
    (writeln)
    (format t "Save line to: ")
    (setf save-to (line-edit))
    (when (string= save-to "")
      (return-from write-file nil))
    (setf path (merge-pathnames save-to))
    (restore-line)
    (setf line (pack *text*))
    (do-write-file line path)
    (setf message (concatenate 'string "(write-file-to \"" save-to "\")" ))
    (throw :exit-line-edit message)))

(defun do-write-file (line path)
  (with-open-file (s path :direction :output)
    (write line :stream s :escape nil :pretty t)
    (terpri s)))

(defun write-file-to (fname) fname)

;;; C-x C-s
;;; 現在の行をファイルに保存する。
;;; 保存するファイル名は日時を元に自動的に作成する。
;;;     yyyymmdd-hhmmss.lsp
;;;
(defun save-buffer ()
  (let (save-to path message)
    (setf save-to
          (concatenate 'string (make-date-and-time-string) *lisp-extension*))
    (setf path (merge-pathnames save-to))
    (do-write-file (pack *text*) path)
    (setf message (concatenate 'string "(write-file-to \"" save-to "\")" ))
    (writeln)
    (throw :exit-line-edit message)))

;;;
;;; C-x C-sで書き出すファイルの拡張子を設定する。
;;; 引数なしで呼び出すと現在の設定値を返す。
;;; デフォルトは ".lsp" か ".lisp"
;;;
(defun lisp-extension (&optional ext)
  (cond
   ((or
     (null ext)
     (not (stringp ext)))
    *lisp-extension*)
   (t (setf *lisp-extension* ext))))

;;;
;;; 現在の時刻をyyyymmdd-hhmmssという形式の文字列として返す。
;;;
;;; (get-decoded-time)はシステムのタイムゾーンに従った時刻を
;;; 返す。タイムゾーンの既定値の設定方法はLispシステムに依存
;;; する。(decode-universal-time (get-universal-time) timezone)
;;; で明示的にタイムゾーンを指定することもできるが、その場合
;;; は夏時間情報が無視されるので互換性上問題がある。
;;;
;;; GCLでタイムゾーンの既定値を設定するには
;;;     (setf si::*default-time-zone* -9)
;;; とする(日本の場合)。Common Lispにおけるタイムゾーン値は
;;; 「GMTの西の時間数として表される正数」と規定されているの
;;; でGMTとは符号が逆になる。GMT+0900であれば -9。
;;;
(defun make-date-and-time-string ()
  (let (tm)
    (setf tm (multiple-value-list (get-decoded-time)))
    (format nil "~4,'0d~2,'0d~2,'0d-~2,'0d~2,'0d~2,'0d"
            (nth 5 tm) (nth 4 tm) (nth 3 tm)
            (nth 2 tm) (nth 1 tm) (truncate (nth 0 tm)))))

;;;
;;; ストリームから１文字読み込む。
;;; 処理中断文字の *ctrl-g* も文字として返す。
;;;
(defun getch (&optional (stream *standard-input*))
  (let (ch)
    (setf ch (read-char stream nil +eos+))
    (cond
      ((eq ch +eos+)
       (warn "EOF detected. Exiting line-edit.~%") 
       (throw :exit-line-edit nil)
       +eos+
       )
      (t
       ch
       )
      ) ;; end cond
    )   ;; end let
  ) ;; end getch

;;;
;;; peek-ahead
;;;
(defun peek-ahead (&optional (stream *standard-input*))
  (let (ch)
    ;;(setf ch (peek-char nil *standard-input* nil +eos+))
    (setf ch (peek-char nil stream nil +eos+))
    (if (eq ch +eos+) (throw :control-g nil) ch)))

;;;
;;; 1文字読み込む。*ctrl-g*が入力されたらタグ「control-g」に制御を移す。
;;; つまり、文字 *ctrl-g* が結果として返されることはない。

(defun getchar (&optional (stream *standard-input*))
  (let (ch)
    (setf ch (getch stream))
    (if (char/= ch *ctrl-g*)
        ch
        (throw :control-g nil)
        ) ;; end if
    )     ;; end let
  ) ;; end getchar

;;;
;;; カーソル位置に文字[ch]を表示し、カーソル位置を1字分進める。
;;;
;;; ただし、文字[ch]が#\^Aから#\^Zの場合、
;;;     *print-case* が :downcaseなら        大文字のAからZ
;;;                     :upcase  なら 小文字のaからz
;;;                     :capitalizeなら       大文字のAからZ
;;; を「反転表示」(機種依存関数の定義部を参照)する。
;;;
;;; 文字[ch]が、それ以外の非図形文字の場合は(to-circumflex-accent-char)
;;; が返す文字列の2文字目を反転表示する。
;;;
;;; 反転表示がサポートされていない場合でも制御文字の位置と種類を
;;; 知ることができる。
;;;
;;; C-lを実行すると行内のすべての非図形文字を削除する。したがって
;;; C-lを実行して削除された文字は非図形文字である。削除を元に戻す
;;; には C-x uを実行すればよい。
;;;
;;; 上記の方法で知った制御文字の位置にカーソルを移動し[C-x =]コマンド
;;; を使えば、制御文字の種類が表示される。
;;;
(defun putch (ch)
  (declare (type character ch))
  (let (char)
    (when (<= 0 *logical-cursor-position* (view-area-end))
      (setf char (control-to-char ch))
      (if (graphic-char-p ch)
          (putc char)
          (highlight-mode-putc char)
          )
      (incf *logical-cursor-position*)
      ) ;; end when
    )   ;; end let
  ) ;; end putch

;;;
;;; 制御文字に対応する文字を返す。
;;;
(defun control-to-char (ch)
  (declare (type character ch))
  (if (graphic-char-p ch) (return-from control-to-char ch))
  (when (and (characterp (newline-symbol)) (char= ch #\Newline))
    (return-from control-to-char (newline-symbol)))
  (setf ch (pure-control-to-char ch))
  (if (not (graphic-char-p ch)) (return-from control-to-char #\?))
  (cond
   ((eq *print-case* :downcase)
    (char-upcase ch))
   ((eq *print-case* :upcase)
    (char-downcase ch))
   ((eq *print-case* :capitalize)
    (char-upcase ch))))

(defun pure-control-to-char (ch)
  (declare (type character ch))
  (let ((str-or-ch ""))
    (declare (type (or character simple-string) str-or-ch))
    (setf str-or-ch (to-circumflex-accent-char ch))
    (cond
     ((stringp str-or-ch)
      (char str-or-ch 1))
     ((characterp str-or-ch)
      str-or-ch))))

;;;
;;; 制御文字であれば慣例にしたがって '^'を前置する。
;;; そうでなければ、文字そのものを返す。
;;;
(defun to-circumflex-accent-char (ch)
  (declare (type character ch))
  (case ch
    (#\^@       "^@")
    (#\^A       "^A")
    (#\^B       "^B")
    (#\^C       "^C")
    (#\^D       "^D")
    (#\^E       "^E")
    (#\^F       "^F")
    (#\^G       "^G")
    (#\^H       "^H")
    (#\^I       "^I")
    (#\^J       "^J")
    (#\^K       "^K")
    (#\^L       "^L")
    (#\^M       "^M")
    (#\^N       "^N")
    (#\^O       "^O")
    (#\^P       "^P")
    (#\^Q       "^Q")
    (#\^R       "^R")
    (#\^S       "^S")
    (#\^T       "^T")
    (#\^U       "^U")
    (#\^V       "^V")
    (#\^W       "^W")
    (#\^X       "^X")
    (#\^Y       "^Y")
    (#\^Z       "^Z")
    (#\^[       "^[")
    (#\^\\      "^\\")
    (#\^]       "^]")
    (#\^^       "^^")
    (#\^_       "^_")
    (otherwise  ch)))

;;;
;;; テキスト中の#\Newlineの表示用文字を設定／取得する。
;;; 設定した文字は「強調表示」される。
;;;
(defun newline-symbol (&optional (ch #\$ sw))
  (cond
   ((null sw) *newline-symbol*)
   (t (setf *newline-symbol* ch))))

;;; C-x = (#'what-cursor-position)
;;; ポイントの直後にある文字の文字コードとポイント位置、カーソル位置を表示する。
;;; 不可視の制御文字が混入した際に有用。任意の文字を入力すると元の表示に戻る。
;;;
;;; Char=[^Q] (#o021, 17, #x11) point=32 of 127(25%) column 12
;;;
;;; 上記の文字'c'が制御文字であれば慣例に従い[^Q]のような形式で表示する。次に続くカッコ内は8進、10進、16進
;;; での文字'c'の文字コード。[#o]は8進、[#x]は16進数であることを表すCommon Lispでの進数表現。
;;;
;;; ポイントがテキスト終端にある場合は文字に関する情報は表示しない。
;;;
;;; End-of-text: point=64 column 12
;;;
;;; 行頭の桁位置は 0と数える。
;;;
(defun what-cursor-position ()
  (let (n ch pos col str fmt tm)
    (setf pos *point*)
    (setf col (zero-base-physical-cursor-position))
    (setf fmt "Char=[~a] (\#\o~3,'0o, ~3,'0d, \#\x~2,'0x) point=~d of ~d(~d\%) column ~d")
    (cond
      ((not (end-of-text-p))
       (setf ch (current-char))
       (setf n (char-code ch))
       (setf ch (to-circumflex-accent-char ch)) ;; 制御文字を"^Q"のような形式の文字列に変換する。
       (setf str (format nil fmt ch n n n pos *ncl* (floor (* 100 (/ (1+ pos) *ncl*))) col))
       )
      (t
       (setf str (format nil "End-of-text: point ~d column ~d" pos col))
       )
      ) ;; end cond
    (setf tm (blink-paren-deley)) ;; 対応するカッコへのジャンプを抑止。
    (blink-paren-deley 0)
    (with-prompt str (getchar)) ;; 文字列[str]を表示し、文字入力があったら元の表示に戻す。
    (blink-paren-deley tm)
    ) ;; end let
  ) ;; end what-cursor-position

;;;
;;; 文字出力関数。
;;;
(defun putc (c)
  (declare (type character c))
  (if *echo* (write-char c)))

;;;
;;; 数値を文字の列として先頭桁から順次表示する。
;;; 文字列化した数値を返す(確認用)。
;;;
(defun putnum-as-char (num)
  (declare (type fixnum num))
  (let ((str-num (format nil "~d" num)))
    (dotimes (i (length str-num))
      (putc (char str-num i))
      ) ;; end dotimes
    (finish-output)
    str-num
    ) ;; end let
  ) ;; end putnum-as-char

;;;
;;; 強調表示モードで文字を出力する。
;;;
(defun highlight-mode-putc (c)
  (declare (type character c))
  (highlight-mode t)
  (putc c)
  (highlight-mode nil))

;;;
;;; テキストの内部表現を（通常の）文字列に変換する。
;;;
(defun pack (char-list)
  (declare (type list char-list))
  (concatenate 'string char-list))

;;;
;;; 文字列を（内部表現の）テキストに変換する。
;;;
;;; [17]> (time (dotimes (i 10000000) (concatenate 'list "abcdef")))
;;; Real time: 5.641012 sec.
;;; Run time: 5.640752 sec.
;;; Space: 960001408 Bytes
;;; GC: 441, GC time: 1.495499 sec.
;;; NIL
;;; [18]> (time (dotimes (i 10000000) (coerce "abcdef" 'list)))
;;; Real time: 6.418538 sec.
;;; Run time: 6.418198 sec.
;;; Space: 960001408 Bytes
;;; GC: 441, GC time: 1.497728 sec.
;;; NIL
;;;
(defun unpack (str)
  (declare (type simple-string str))
  (concatenate 'list str)) ;; or (coerce str 'list)

;;;
;;; 文字コード体系に依存しない「数字→数値」の変換を行う。
;;;
(defun char-to-digit (ch)
  (case ch
    (#\0        0)
    (#\1        1)
    (#\2        2)
    (#\3        3)
    (#\4        4)
    (#\5        5)
    (#\6        6)
    (#\7        7)
    (#\8        8)
    (#\9        9)
    (otherwise  nil)))

(defun digit-symbol-to-digit (sym)
    #|
  ;; sbclではコンパイルできてしまう。caseの比較はeqlなので文字列型での比較は常に[nil]。
  ;; clispでは正しくコンパイル・エラーになる。
  ;;
  ;; HyperSpec:
  ;; The value of eql is true of two objects, x and y, in the folowing cases:
  ;;
  ;; 1. If x and y are eq.
  ;; 2. If x and y are both numbers of the same type and the same value.
  ;; 3. If they are both characters that represent the same character.
  ;;
  ;; Otherwise the value of eql is false.
  ;;
  (case sym
    (#.+digit-0+        0)
    (#.+digit-1+        1)
    (#.+digit-2+        2)
    (#.+digit-3+        3)
    (#.+digit-4+        4)
    (#.+digit-5+        5)
    (#.+digit-6+        6)
    (#.+digit-7+        7)
    (#.+digit-8+        8)
    (#.+digit-9+        9)
    (otherwise nil)
    ) ;; end case
    |#
  (cond
    ((string= sym +digit-0+) 0)
    ((string= sym +digit-1+) 1)
    ((string= sym +digit-2+) 2)
    ((string= sym +digit-3+) 3)
    ((string= sym +digit-4+) 4)
    ((string= sym +digit-5+) 5)
    ((string= sym +digit-6+) 6)
    ((string= sym +digit-7+) 7)
    ((string= sym +digit-8+) 8)
    ((string= sym +digit-9+) 9)
    (t nil)
    ) ;; end cond
  ) ;; end digit-symbol-to-digit

;;;
;;; 「数値→数字」の変換を行う
;;;
(defun digit-to-char (n)
  (case n
    (0          #\0)
    (1          #\1)
    (2          #\2)
    (3          #\3)
    (4          #\4)
    (5          #\5)
    (6          #\6)
    (7          #\7)
    (8          #\8)
    (9          #\9)
    (otherwise nil)))

;;;
;;; ベル音を有効にするか否かの可否を設定する。
;;; nil なら無効、nil 以外なら有効に設定される。
;;; 引数がない場合は、現在の設定値を返す。
;;;
(defun enable-audio-bell (&optional (s t sw))
  (cond
   ((null sw) *audio-bell*)
   (t (setf *audio-bell* s))))

;;;
;;; 1文字削除時のundo情報を保存する。
;;;
(defun save-delete-undo-info (ch)
  (declare (type character ch))
  (save-undo-info '- (list ch)))

;;;
;;; 逆方向への1文字削除時のundo情報を保存する。
;;;
(defun save-backward-delete-undo-info (ch)
  (declare (type character ch))
  (save-undo-info '-- (list ch)))

;;;
;;; リージョン・キル時のundo情報を保存する。
;;;
(defun save-kill-undo-info (char-lst)
  (save-undo-info '- char-lst))

;;;
;;; 逆方向へのリージョン・キル時のundo情報を保存する。
;;;
(defun save-backward-kill-undo-info (char-lst)
  (save-undo-info '-- char-lst))

;;;
;;; 1文字挿入時のundo情報を保存する。
;;;
(defun save-self-insert-undo-info (ch)
  (declare (type character ch))
  (save-undo-info '+ (list ch)))

;;;
;;; 文字列挿入時のundo情報を保存する。
;;;
(defun save-insert-undo-info (char-lst)
  (save-undo-info '+ char-lst))

;;;
;;; undo情報を保存する。保存ステップ数が設定回数を越えていたら
;;; 最新の設定回数分を残して古い情報を捨てる。
;;;
;;; 現在の版ではマークの値は保存しているだけで使用していない。
;;;
;;; undo情報のデータ構造は次のとおり。
;;;     (ポイント マーク (挿入削除種別 (文字データ)))
;;; データは例えば
;;;     (0 nil (- (#\( #\l #\o #\a #\d)))
;;;
(defun save-undo-info (insert-or-kill char-lst)
  (push (list *point* *mark* (cons insert-or-kill (list char-lst)))
        *command-undo-info*)
  (setf *max-undo-length* (max *max-undo-length* (length *undo-info*)))
  (if (and (undo-limit) (> (length *undo-info*) (undo-limit)))
    (setf *undo-info* (head (undo-limit) *undo-info*))))

;;;
;;; 第2引数で与えられるリストの先頭から num個目までの要素を持つリストを返す。
;;; リストの長さが[num]個以下のときは lst全体が返る。
;;;
(defun head (num lst)
  (let (len)
    (setf len (length lst))
    (cond
     ((>= num len) lst)
     (t (reverse (nthcdr (- len num) (reverse lst)))))))

;;;
;;; undo情報をリセットする。
;;;
(defun reset-undo-info ()
  (set-command-undo-info nil)
  (set-undo-control nil)
  (set-undo-info nil)
  (set-redo-info nil))

(defun set-command-undo-info (lst)
  (setf *command-undo-info* lst))

(defun command-undo-info () *command-undo-info*)

(defun set-undo-control (s) (setf *undo-control* s))

(defun undo-control () *undo-control*)

(defun undo-info () *undo-info*)

(defun set-undo-info (n) (setf *undo-info* n))

(defun push-undo-info (n) (push n *undo-info*))

(defun redo-info () *redo-info*)

(defun set-redo-info (n) (setf *redo-info* n))

(defun push-redo-info (n) (push n *redo-info*))

;;;
;;; undo回数に対する制限値を設定する。
;;; 設定回数の上限はない。nilを指定すると無制限となる。
;;; 引数を指定しないと設定されている回数を返す。
;;; 設定された制限回数が有効になるのは次の行の入力開始から。
;;;
(defun undo-limit (&optional (step 300 sw))
  (cond
   ((null sw) *undo-limit*)
   (t (setf *undo-limit* step))))

;;;
;;; C-x u [M-,]
;;; 過去の変更(挿入／削除／キル)をundoする。
;;; 連続して実行することで次々にundoできる。
;;;
(defun advertised-undo ()
  (let (tm)
    (setf tm (blink-paren-deley))
    (blink-paren-deley 0)
    (undo)
    (blink-paren-deley tm)))

(defun undo ()
  (let (undo-list)
    (setf *exec-undo* nil)
    (when (not
           (or (advertised-undo-command-p (last-command))
               (advertised-redo-command-p (last-command))))
      (setf *redo-info* nil))
    (when (null *undo-info*)
      (audio-bell)
      (return-from undo nil))
    (setf *undo-control* 'undo)
    (setf undo-list (pop *undo-info*))
    (when (debug-print-p "undo")
      (format t "undo:undo-list=~s, *undo-info*=~s~%" undo-list *undo-info*)
      )
    (dolist (cmds undo-list) (true-undo cmds))
    (setf *exec-undo* t)))

;;;
;;; C-x U [M-.]
;;; 過去のundoをundoする。
;;; 最後に(起動しただけでなく実際に)実行したコマンドが
;;; undoかredoのときのみ実行できる。連続して実行するこ
;;; とで次々にredoできる。
;;;
(defun advertised-redo ()
  (let (tm)
    (setf tm (blink-paren-deley))
    (blink-paren-deley 0)
    (redo)
    (blink-paren-deley tm)))

(defun redo ()
  (let (redo-list)
    (when (null *redo-info*)
      (audio-bell)
      (return-from redo nil))
    (cond
     ((and (advertised-undo-command-p (last-command)) *exec-undo*)
      (setf *undo-control* 'redo))
     ((and (advertised-redo-command-p (last-command)) *exec-redo*)
      (setf *undo-control* 'redo))
     ((null *undo-info*)
      (setf *undo-control* 'redo))
     (t (setf *exec-redo* nil)
        (audio-bell)
        (return-from redo nil)))
    (setf redo-list (pop *redo-info*))
    (dolist (cmds redo-list) (true-undo cmds))
    (setf *exec-redo* t)))

(defun true-undo (cmds)
  (let (point insert-or-kill char-lst match-p
              ;;mark
              )
    (save-mark-info)
    (setf point (nth 0 cmds))
    ;;(setf mark (nth 1 cmds))
    (setf insert-or-kill (nth 0 (nth 2 cmds))) ;; '+' means inserted data, '-' means killed data.
    (setf char-lst (nth 1 (nth 2 cmds)))
    (when (debug-print-p "true-undo")
      (format t "true-undo(0):insert-or-kill=~s, char-lst=~s~%" insert-or-kill char-lst)
      )
    (cond
      ((equal insert-or-kill '-) ;; delete/kill, undo is insert.
       (move-point-to point)
       (insert char-lst)
       (backward-char (length char-lst)))
      ((equal insert-or-kill '--) ;; backward delete/kill, undo is insert.
       (move-point-to point)
       (insert char-lst))
      ((equal insert-or-kill '+) ;; insert, undo is kill (not delete).
       (setf match-p (search char-lst (subseq *text* point) :test #'equal))
       (when (debug-print-p "true-undo")
         (format t "true-undo(1):match-p=~s~%" match-p)
         )
       (cond
         ((exactly-matched match-p) ;; ポイント位置から一致しているかを確認。fail-safe guard.
          (move-point-to point)
          (kill-ring-suspend t)
          ;;(forward-char (length char-lst))
          ;;(delete-backward-char (length char-lst))
          (delete-char (length char-lst))
          )
         (t (audio-bell)))))
    (align-mark)))

;;;
;;; *redo-info*/*undo-info*に記録されているundo情報を打ち消すための
;;; リストを作成して返す。
;;;
(defun reverse-do (info-list)
  (let (cmds result)
    (setf result nil)
    (loop
      (when (null info-list) (return result))
      (setf cmds (pop info-list))
      (push (mapcar #'pure-reverse-do cmds) result))))

(defun pure-reverse-do (cmd)
  (let (point mark insert-or-kill char-list)
    (when (null cmd) (return-from pure-reverse-do nil))
    (setf point (nth 0 cmd))
    (setf mark (nth 1 cmd))
    (setf insert-or-kill (nth 0 (nth 2 cmd)))
    (setf char-list (nth 1 (nth 2 cmd)))
    (cond
     ((equal insert-or-kill '-)
      (list point mark (cons '+ (list char-list))))
     ((equal insert-or-kill '--)
      (list point mark (cons '+ (list char-list))))
     ((equal insert-or-kill '+)
      (list point mark (cons '-- (list char-list))))
     (t (line-edit-break (format nil "break at (pure-reverse-do ~a)" cmd))))))

;;;
;;; 関数 searchの返した結果が先頭で一致しているかどうかを調べる。
;;;
(defun exactly-matched (p)
  (and (numberp p) (zerop p)))

;;;
;;; 物理行のうち、プロンプトを除き、ユーザが入力可能な文字幅を計算し設定する。
;;; 最初のカラムをゼロ桁とする。
;;;
(defun physical-line-window-size ()
  (setf *physical-line-window-size* (- (current-physical-column-size) (current-prompt-length)))
  )

(defun view-area-start ()
#+ :use-history-pkg (current-prompt-length)
#- :use-history-pkg 0
  ) ;; end view-area-start

(defun view-area-end ()
  (current-physical-column-size)
  )

;;;
;;; ポイント位置以降の#\Newlineの位置を返す。
;;; もしポイント位置以降に#\Newlineが存在しなければ[nil]を返す。
;;;
(defun next-newline-position (&optional (text *text*) (p *point*))
  (position #\Newline text :test #'char= :start p))

;;;
;;; [*text*]内のポイント位置以前の#\Newlineの位置を返す。
;;; もしポイント位置以前に#\Newlineが存在しなければ[nil]を返す。
;;;
(defun previous-newline-position (&optional (text *text*) (p *point*))
  (position #\Newline text :from-end t :test #'char= :end p))

;;;
;;; 水平スクロールを行う際のデフォルト文字数を設定する。
;;; 引数を指定しない場合は設定値を返す。
;;; 初期デフォルト値は *physical-line-window-size*の15%。
;;;
(defun hscroll-unit (&optional (size nil sw))
  (when (null *hscroll-unit*)
    (setf *hscroll-unit* (floor (* (physical-line-window-size) 15/100))))
  (cond
   ((null sw) *hscroll-unit*)
   (t (setf *hscroll-unit* size))))

;;;
;;; [old-text]と[new-text]の最長一致部分列を見つけ[old-text]内での開始位置と長さを返す。
;;;
;;;     (find-longest-common-segment "abcd"     "abcdefg")      = (0 . 4)
;;;     (find-longest-common-segment "abcdef"   "abcd")         = (0 . 4)
;;;     (find-longest-common-segment "abcdef"   "abcxyzdefg")   = (0 . 3)
;;;     (find-longest-common-segment "abcdef"   "adefg")        = (3 . 3)
;;;     (find-longest-common-segment "abcdef"   "xyzabcd")      = (0 . 4)
;;;     (find-longest-common-segment "abcdef"   "def")          = (3 . 3)
;;;     (find-longest-common-segment "abc"      "")             = (0 . 0)
;;;
(defun find-longest-common-segment (old-text new-text &key (test #'char=))
  "[old-text]と[new-text]の最長一致部分列を見つけ[old-text]内の開始位置と長さを返す。"
  ;;(declare (optimize (speed 3) (safety 0) (debug 0)))
  (let* ((vec-1 (coerce old-text 'simple-vector))
         (vec-2 (coerce new-text 'simple-vector))
         (len-1 (length vec-1))
         (len-2 (length vec-2))
         ;; 1次元配列で空間を節約
         (prev-row (make-array (1+ len-2) :element-type 'fixnum :initial-element 0))
         (curr-row (make-array (1+ len-2) :element-type 'fixnum :initial-element 0))
         (max-len 0)
         (start-idx 0))

    (declare (type simple-vector vec-1 vec-2)
             (type (simple-array fixnum (*)) prev-row curr-row)
             (type fixnum len-1 len-2 max-len start-idx))

    (dotimes (i len-1)
      (declare (type fixnum i))
      (dotimes (j len-2)
        (declare (type fixnum j))
        (if (funcall test (svref vec-1 i) (svref vec-2 j))
            (let ((current-len (the fixnum (1+ (aref prev-row j)))))
              (declare (type fixnum current-len))
              (setf (aref curr-row (1+ j)) current-len)
              (when (> current-len max-len)
                (setf max-len current-len
                      start-idx (the fixnum (- (1+ i) current-len))))
              )
            (setf (aref curr-row (1+ j)) 0)
            ) ;; end if
        ) ;; end dotimes
      ;; 行の入れ替え（コピー）
      (dotimes (k (1+ len-2))
        (declare (type fixnum k))
        (setf (aref prev-row k) (aref curr-row k))
        ) ;; end dotimes
      ) ;; end outer dotimes

    (cons start-idx max-len)
    ) ;; end let*
  ) ;; end find-longest-common-segment

;;;
;;; #\Newlineをまたいで移動した際に表示を調節する。
;;;
(defun sync-line ()
  (let (pos)
    (setf *newline-position* (previous-newline-position))
    (setf pos *point*)
    (cond
      ((equal *newline-position* *last-newline-position*) ;; 同じ行にいる。
       nil
       )
      ((empty-text-p) ;; 空行。
       nil
       )
      ((< *point* (view-area-end))
       (beginning-of-line 1)
       )
      ) ;; end cond
    (move-point-to pos)
    (need-refresh-line t)
    (setf *last-newline-position* *newline-position*)))

(defun sync-logical-cursor-position-to-current-point ()
  (move-logical-cursor-to (third (display-range)))
  )

;;;
;;; 論理座標系のポイント[x]をゼロ・ベース物理座標系での位置に変換する。
;;;
(defun zero-base-physical-position (x)
  (- x (view-area-start))
  ) ;; end zero-base-physical-system-position

(defun display-range ()
  "現在の論理測位系でのポイント位置、論理行の長さ、行表示用ウインドウ幅の3者の関係から
論理測位系でのゼロ位置から表示すべき論理行の始点、終点、ポイント位置の論理測位系カーソル位置のリストを返す。
"
  (let (
        (p (point))
        (l (line-length))
        (e (physical-line-window-size)) ;; 論理測位系での現在の行の長さ。
        )
    (cond ;; プロンプト終了位置をゼロとする論理測位系で考える。pattern-1
      ((<= l e)
       ;;                              p                                             l   e
       ;;0----+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----
       ;;[                                                                           ]
       ;;(need-refresh-line nil)
       (list 0 l p)
       )
      ((<= e p l)
       (cond
         ((> (- l p) e) ;; pからlの距離がeより大きい場合。pattern-2
          ;;                         e                        p                             l
          ;;0----+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----
          ;;                                                  [                        ]
          ;;(need-refresh-line t)
          (list p (+ p e) 0) ;; pから(+ p e)までが表示範囲。
          )
         ((<= (- l p) e) ;; pからlの距離がeより小さいか等しい場合。pattern-3
          ;;                                                            e         p                   l
          ;;0----+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----
          ;;                              [                                                           ]
          ;;(need-refresh-line t)
          (list (- l e) l (- p (- l e))) ;; (- l e)からlまでが表示範囲。
          )
         ) ;; end cond
       )   ;; end (<= e p l)
      ((<= p e l)
       (cond
         ((> (- l p) e) ;; pからlの距離がeより大きい場合。pattern-4
          ;;          p                                                      e              l
          ;;0----+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----
          ;;          [                                                                ]
          ;;(need-refresh-line t)
          (list p (+ p e) 0) ;; pから(+ p e)までが表示範囲。
          )
         ((<= (- l p) e) ;; pからlの距離がeより小さいか等しい場合。pattern-5
          ;;                                                            p         e         l
          ;;0----+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----
          ;;          [                                                                     ]
          ;;(need-refresh-line t)
          (list (- l e) l (- p (- l e))) ;; (- l e)からlまでが表示範囲。
          )
         ) ;; end cond
       )                    ;; end (<= p e l)
      )                     ;; end cond
    )                       ;; end let
  ) ;; end display-range

(defun display-whole-line (line)
  (move-logical-cursor-to 0)
  (pure-delete-line-from-here)
  (dolist (ch line)
    (putch ch)
    )
  (finish-output)
  )

;;;
;;; 現在の行を表示する。[(current-line)]は最新の行内容、ポイントも正しい位置にある。
;;;
(defun display-line ()
  (let* (
        (c-line (current-line *text* *point*))
        (l-line (current-line *last-text* *last-point*))
        (common-segment (find-longest-common-segment l-line c-line)) ;; 最長一致文字列の位置と長さ。
        (tmp (display-range))
        (display-start (first tmp))     ;; 表示すべき論理行の始点。
        (display-end   (second tmp))    ;; 表示すべき論理行の終点。
        (cursor-position-for-current-point (third tmp)) ;; ポイント位置の論理測位系カーソル位置。
        (display-width (- display-end display-start))   ;; 表示すべき論理行の文字数。
        (c-length (length c-line))
        (l-length (length l-line))
        )

    ;;(setf c-line (current-line *text* *point*))
    ;;(setf l-line (current-line *last-text* *last-point*))
    ;;(setf common-segment (find-longest-common-segment l-line c-line))

    ;;(setf tmp (display-range))
    ;;(setf display-start (first tmp))
    ;;(setf cursor-position-for-current-point (third tmp))

    (cond
      ;;--------------------------------------------------------------------------------------
      ((equal l-line c-line)            ;; 行に変化なし。ポイント移動(カーソル移動)の可能性あり。
       (cond
         ((<= c-length display-width) ;; 表示用ウインドウ幅より文字数が少ないならカーソル移動のみ。
          (when (need-refresh-line-p) ;; 隠れていた部分が存在する場合は全体を再表示。
            (display-whole-line c-line)
            (need-refresh-line nil)
            ) ;; end when
          (move-logical-cursor-to cursor-position-for-current-point)
          )
         ;;---------------------------------------------------------------------------------
         ((> c-length display-width) ;; 表示用ウインドウ幅より文字数が多い場合。
          ;; ポイント位置が表示されるように描画する。
          (move-logical-cursor-to 0)
          (pure-delete-line-from-here)
          (dolist (ch (subseq c-line display-start display-end))
            (putch ch)
            )
          ;;(finish-output)
          (move-logical-cursor-to cursor-position-for-current-point)
          (need-refresh-line t)
          )
         ) ;; end cond
       )
      ;;--------------------------------------------------------------------------------------
      ((and                             ;; 空行に文字追加。
        (zerop l-length)                ;; 前回の行が空行。
        (zerop display-start)           ;; 論理行の先頭から表示。
        )
       (move-logical-cursor-to 0)       ;; 表示用ウインドウ先頭(プロンプト直後)にカーソルを移動。
       (cond
         ((<= c-length display-width) ;; 表示すべき行の長さが表示用ウインドウ幅より短い。
          (dolist (ch c-line)         ;; 表示すべき行全体を描画。
            (putch ch)
            ) ;; end dolist
          (need-refresh-line nil)
          )
         ;;---------------------------------------------------------------------------------
         ((> c-length display-width) ;; 表示すべき行の長さが表示用ウインドウ幅より長い。
          ;; 表示用ウインドウ右端に論理行の行末が表示されるように表示する。
          (dolist (ch (subseq c-line (- c-length display-width) c-length))
            (putch ch)
            ) ;; end dolist
          (need-refresh-line t)
          )
         ) ;; end cond
       ;;(finish-output)
       (move-logical-cursor-to cursor-position-for-current-point)
       )
      ;;--------------------------------------------------------------------------------------
      ((and
        (> c-length l-length)           ;; 前回より文字数が増えた。
        (plusp l-length)                ;; 前回の行は空行ではない。
        (zerop display-start)           ;; 論理行の先頭から表示。
        (zerop (car common-segment))    ;; 前回内容と先頭から一致している文字が1文字以上ある。
        (plusp (cdr common-segment))
        )
       (let ((n (the fixnum 0)))
         (setf n (cdr common-segment)) ;; 先頭から[n]文字一致(c-length > l-length >= n >= 1)。
         (cond
           ((< c-length display-width) ;; 表示すべき行の文字数が表示用ウインドウ幅より少ない。 
            (move-logical-cursor-to (1+ n)) ;; display-width > c-length > n なので安全。
            (pure-delete-line-from-here) ;; [n+1]文字目以降の表示を消去。
            (dolist (ch (subseq c-line (1+ n))) ;; [c-line]の[n+1]文字目以降を描画。
              (putch ch)
              )
            (need-refresh-line nil)
            ;;(finish-output)
            (move-logical-cursor-to cursor-position-for-current-point)
            )
           ;;---------------------------------------------------------------------------------
           ((>= c-length display-width) ;; 表示すべき行の文字数が表示用ウインドウ幅より多いか同じ。
            (move-logical-cursor-to 0)
            (pure-delete-line-from-here)
            (dolist (ch (subseq c-line (- c-length display-width)))
              (putch ch)
              )
            (need-refresh-line t)
            ;;(finish-output)
            (move-logical-cursor-to cursor-position-for-current-point)
            )
           ) ;; end cond
         )   ;; end let
       )
      ;;--------------------------------------------------------------------------------------
      ((and
        (< c-length l-length)                   ;; 前回より文字数が減った。
        (plusp l-length)                        ;; 前回の行は空行ではない。
        (zerop display-start)                   ;; 論理行の先頭から表示。
        (zerop (car common-segment))            ;; 前回内容と先頭から一致している文字が1文字以上ある。
        (plusp (cdr common-segment))
        (equal c-line (subseq l-line 0 c-length));; 減ったのは行末部分(c-line部分までは一致)。
        )
       (if (need-refresh-line-p)
           (display-whole-line c-line)
           (progn
             (move-logical-cursor-to c-length) ;; 一致している部分の次の文字位置にカーソルを移動。
             (pure-delete-line-from-here) ;; 現在のカーソル位置以降の表示を削除。
             (move-logical-cursor-to cursor-position-for-current-point)
             (need-refresh-line nil)
             ) ;; end progn
           ) ;; end if
       (finish-output)
       ) ;; end and
      ;;--------------------------------------------------------------------------------------
      (t                                        ;; 上記以外 → 行全体を表示し直す。
       (move-logical-cursor-to 0)
       (pure-delete-line-from-here)
       (cond
         ((< c-length display-width) ;; 表示すべき行の文字数が表示用ウインドウ幅より少ない。
          (dolist (ch c-line)        ;; そのまま全てを描画。
            (putch ch)
            ) ;; end dolist
          (need-refresh-line nil)
          )
         ;;---------------------------------------------------------------------------------
         ((>= c-length display-width) ;; 表示すべき行の文字数が表示用ウインドウ幅より多いか同じ。
          ;; 表示用ウインドウ右端に論理行の行末が表示されるように表示する。
          (dolist (ch (subseq c-line (- c-length display-width) c-length))
            (putch ch)
            )
          )
         ) ;; end cond
       (need-refresh-line t)
       ;;(finish-output)
       (move-logical-cursor-to cursor-position-for-current-point)
       ) ;; end [t]
      ;;--------------------------------------------------------------------------------------
      ) ;; end cond
    (finish-output)
    ) ;; end let*
  ) ;; end display-line

;;; C-x <
;;; 行を左に[n]カラム、スクロールする。
;;; [左に[n]カラムスクロールする]とは現在のカーソル位置より[n]だけ右側の行を表示すること。
;;; そのためカーソル位置を変えずにポインタを[n]だけ増やす。
;;; ポイント位置の文字をカーソル位置に表示すれば行が左に[n]カラム、スクロールしたことになる。
;;; ただし、ポイントが[(line-length)]を超えることはない。
;;;
(defun scroll-left (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
   ((null n)
    (pure-scroll-left (hscroll-unit)))
   ((zerop n) nil)
   ((> n 0)
    (pure-scroll-left n))
   ((< n 0)
    (pure-scroll-right (- n)))))

(defun pure-scroll-left (n)
  (if (empty-text-p)
      (return-from pure-scroll-left nil)
      )
  (cond
    ((<= (+ *point* n) (text-length))
     ;;(move-point-to (+ *point* n))
     (move-point-right n)
     )
    ((> (+ n *point*) (text-length))
     (move-point-to (min (+ *point* n) (text-length)))
     )
    )
  ;;(need-refresh-line t)
  )
  
;;; C-x >
;;; 行を右に[n]カラム、スクロールする。
;;; [右に[n]カラムスクロールする]とは現在のカーソル位置に[n]だけ左側の行を表示すること。
;;; そのためカーソル位置を変えずにポインタを[n]だけ減らす。
;;; ポイント位置の文字をカーソル位置に表示すれば行が右に[n]カラム、スクロールしたことになる。
;;; ただし、ポイントは[0]以下にならない。
;;;
(defun scroll-right (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (cond
   ((null n)
    (pure-scroll-right (hscroll-unit)))
   ((zerop n) nil)
   ((> n 0)
    (pure-scroll-right n))
   ((< n 0)
    (pure-scroll-left (- n)))))

(defun pure-scroll-right (n)
  (if (empty-text-p)
      (return-from pure-scroll-right nil)
      ) ;; end if
  ;;(setf *hscroll-size* (max 0 (- *hscroll-size* n)))
  ;;(if (> *point* (view-area-end))
  ;;    (move-point-to (view-area-end))
  ;;    ) ;; end if
  (cond
    ((<= n *point*)
     (move-point-left n)
     )
    ((> n *point*)
     (move-point-to (max 0 (- *point* n)))
     )
    ) ;; end cond
  ;;(need-refresh-line t)
  )

;;;
;;; スクロール量をゼロに戻す。
;;;
(defun reset-scroll ()
  (when (> *hscroll-size* 0)
    (setf *hscroll-size* 0)
    ;;(need-refresh-line t)
    ) ;; end when
  ) ;; end reset-scroll

;;; C-v
;;; テキストを縦方向にスクロールして次の論理行を表示する。
;;; 次の論理行が存在しなければ何もしない。
;;;
(defun scroll-up (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (dotimes (i n) (pure-scroll-up))
  ) ;; end scroll-up

(defun pure-scroll-up ()
  (let (np cp)
    (setf cp (zero-base-physical-cursor-position))
    (setf np (next-newline-position))
    (when (and np (>= np *point*))
      (move-point-to np)
      (if (not (end-of-text-p)) (forward-char 1))
      (sync-line)
      (setf cp (min cp (1- (- (view-area-end) (view-area-start)))))
      (move-point-right cp)
      ;;(need-refresh-line t)
      ) ;; end when
    )   ;; end let
  ) ;; end pure-scroll-up

;;; M-v
;;; テキストを縦方向にスクロールして直前の論理行を表示する。
;;; 直前の論理行が存在しなければ何もしない。
;;;
(defun scroll-down (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  (dotimes (i n) (pure-scroll-down)))

(defun pure-scroll-down ()
  (let (np cp)
    (if (beginning-of-text-p) (return-from pure-scroll-down nil))
    (setf cp (zero-base-physical-cursor-position)) ;Cursor  Position
    (setf np (previous-newline-position))          ;Newline Position
    (if (or (null np) (zerop np)) (return-from pure-scroll-down nil))
    (move-point-to (1- np))
    (beginning-of-line 1)
    (sync-line)
    (setf cp (min cp (1- (- (view-area-end) (view-area-start)))))
    (move-point-right cp)
    ;;(need-refresh-line t)
    ) ;; end let
  ) ;; end pure-scroll-down

;;;
;;; 自動スクロールのオフセット値を設定する。
;;;
;;; 左右にスクロールしている状態で左右端から更に左右に移動する際に
;;; 余分にスクロールするカラム数を指定する。
;;;
;;; 0 または nilを指定すると余分なスクロールを行わない 1カラム毎の
;;; スクロールとなり、数値以外 (tを推奨)を指定するとポイント周囲に
;;; 可能な限りの文字を表示できるようにスクロールする。
;;;
;;; 引数がない場合は現在の設定を返す。
;;;
(defun auto-scroll-offset (&optional (num 4 sw))
  (cond
   ((null sw) *auto-scroll-offset*)
   ((null num) (setf *auto-scroll-offset* 0))
   (t (setf *auto-scroll-offset* num))))


;;;
;;; 削除／キルはせず、プロンプト以降の表示のみを消す。
;;;
(defun clear-line ()
  (move-raw-cursor-to 0)
  (pure-delete-line))

;;; C-u
;;; 次のコマンド {command} を {positive-number} 回実行する。
;;;
;;; 次に指定されるコマンドを実行すべき回数を返す。
;;;
;;;     C-u ['+'|'-'] [{positive-number}] {command}
;;;
;;; {positive-number}を省略すると 4が指定されたと見なす。
;;; ただし、'-'だけが指定された場合は -1、'+'だけが指定
;;; された場合は +1が指定されたと見なす。
;;;
;;; 戻り値である実行回数が暗黙の指定か明示的指定かの別も
;;; 返される。第二の値がnil であれば省略値が適用されたこ
;;; とを示し、nil 以外であれば明示的に指定された値が適用
;;; されたことを示す。
;;;
;;; 数字を{positive-number}回入力できるようにするためにデフォルトでは[*universal-argument-digit-separater*]で
;;; '/' を{positive-number}の入力終了マークとしている。
;;; '/' を{positive-number}回入力したい場合は'/'を2度タ
;;; イプする。
;;;
;;; 例えば C-u 5/6 と入力すると'6'が5回入力される。
;;;
(defun universal-argument ()
  (let ( (num 0) (sign nil) (exist-digit nil) )
    (case (peek-ahead) ;; ['+' | '-']の符号指定がある場合の処理。
      (#\+ (getchar) (setf sign +1))
      (#\- (getchar) (setf sign -1))
      ) ;; end case
    (loop ;; [{positive-number}]の処理。数字の列が入力されれば数値として[num]に設定する。
      (when (char= (peek-ahead) *universal-argument-digit-separater*) ;; デフォルトは #\/(スラッシュ).
        (getchar)
        (return))
      (if (not (digit-char-p (peek-ahead))) (return))
      (setf exist-digit t)
      (setf num (+ (* num 10) (char-to-digit (getchar))))
      ) ;; end loop
    (cond ;; C-uコマンドで設定する繰り返し回数を得る。
      ((and (numberp sign) exist-digit)
       (setf num (* sign num)))
      ((and (numberp sign) (not exist-digit))
       (setf num (* sign *default-repeat-count*)))
      ((and (null sign) exist-digit)
       num) ;; == (setf num num)
      ((and (null sign) (not exist-digit))
       (setf num *default-repeat-count*))
      ) ;; end cond
    (when (debug-print-p "universal-argument")
      (format t "universal-argument(0):num=~s~%" num)
      (format t "universal-argument(0):*repeat-count*=~s~%" *repeat-count*)
      ) ;; end when
    (multiply-repeat-count num) ;; 連続してC-uが実行される場合、前回の前置引数に乗じる。
    (when (debug-print-p "universal-argument")
      (format t "universal-argument(1):*repeat-count*=~s~%" *repeat-count*)
      ) ;; end when
    (if (macro-mode-p) (push-keyboard-macro (repeat-count)))
    (values (repeat-count) (or sign exist-digit))
    ) ;; end let
  ) ;; end universal-argument

(defun multiply-repeat-count (count)
  (if (numberp count)
      (setf *repeat-count* (* *repeat-count* count))
      (warn "multiply-repeat-count: count(~s) must be number.~%" count)
      ) ;; end if
  ) ;; end multiply-repeat-count

(defun reset-repeat-count () (setf *repeat-count* 1))

(defun repeat-count () *repeat-count*)

(defun last-command () *last-command*)

(defun universal-argument-digit-separater (&optional (separater-char #\/ sw))
  (cond
    ((null sw)
     *universal-argument-digit-separater*
     )
    ((and ;; 繰り返し回数指定の数値と入力文字としての数字用の区切り文字なので空白文字類と数字('0'〜'9')は禁止。
      (characterp separater-char)
      (not (member separater-char (append +number-char+ +white-space-char+) :test #'char=))
      )
     (setf *universal-argument-digit-separater* separater-char)
     )
    (t
     (warn "universal-argument-digit-separater: argument must be character.~%")
     )
    ) ;; end cond
  ) ;; end universal-argument-digit-separater

;;;
;;; 最後に実行した関数を記録しておく。
;;;
(defun set-last-command (cmd)
  (when (not (member cmd *last-command-inhibit-list*))
    (setf *last-command* cmd)))

;;;
;;; vi 系エディタの redoコマンドなど *last-command*への
;;; 設定対象としてはいけない関数を登録する。初期値は[nil]。
;;;
(defun set-last-command-inhibit-list (&optional lst)
  (cond
   ((null lst)
    *last-command-inhibit-list*)
   ((atom lst)
    (set-last-command-inhibit-list (list lst)))
   (t
    (setf *last-command-inhibit-list* (append *last-command-inhibit-list* lst)))))

(defun last-char () *last-char*)

;;;
;;; 数字の列を読み、数値として返す。
;;;
(defun read-number ()
  (let (num)
    (setf num (char-to-digit (last-char)))
    (loop
      (if (not (digit-char-p (peek-ahead))) (return-from read-number num))
      (setf num (+ (* num 10) (char-to-digit (getchar)))))))

;;;
;;; 数字列を数値に変換する多値関数。デフォルト値はない。
;;;
;;; 第一の値は変換した数値、第二の値は符号の種別 (+1, -1, nil)、
;;; 第三の値は数値に変換されなかった残りの引数。
;;;
;;; + または -のみが指定された場合は nilを返し、第二の値で符号
;;; の種別を返す。
;;;
;;; (string-to-number "123") ==> 123 nil ""
;;; (string-to-number "  + 123") ==> 123 1 ""
;;; (string-to-number "-123") ==> -123 -1 ""
;;; (string-to-number " -  123 abc ") ==> -123 -1 " abc "
;;;
;;; (string-to-number "+1") ==> 1 1 ""
;;; (string-to-number " +") ==> nil 1 ""
;;; (string-to-number "-1") ==> -1 -1 ""
;;; (string-to-number " -") ==> nil -1 ""
;;;
;;; (string-to-number "+0") ==> 0 1 ""
;;; (string-to-number " 0") ==> 0 nil ""
;;; (string-to-number "-0") ==> 0 -1 ""
;;;
;;; (string-to-number "")   ==> nil nil ""
;;; (string-to-number " ?") ==> nil nil "?"
;;;
(defun string-to-number (str)
  (let (lst num sign exist-digit)
    (when (not (stringp str))
      (return-from string-to-number (values nil nil "")))
    (setf lst (unpack str))
    (setf num 0)
    (setf sign nil)
    (setf exist-digit nil)
    (loop
      (if (null lst) (return-from string-to-number (values nil nil "")))
      (if (not (member (car lst) +white-space-char+)) (return))
      (pop lst))
    (case (car lst)
      (#\+      (pop lst) (setf sign +1))
      (#\-      (pop lst) (setf sign -1))
      (otherwise nil))
    (loop
      (if (null lst) (return))
      (if (not (member (car lst) +white-space-char+)) (return))
      (pop lst))
    (loop
      (if (null lst) (return))
      (when (not (digit-char-p (car lst))) (return))
      (setf exist-digit t)
      (setf num (+ (* num 10) (char-to-digit (pop lst)))))
    (cond
     ((and sign exist-digit)
      (values (* sign num) sign (pack lst)))
     ((and sign (not exist-digit))
      (values nil sign (pack lst)))
     ((and (null sign) exist-digit)
      (values num nil (pack lst)))
     ((and (null sign) (not exist-digit))
      (values nil nil (pack lst))))))

;;;
;;; 数字列を数値に変換する多値関数。デフォルト値を持つ。
;;;
;;; 第一の値は変換した数値、第二の値は符号種別(+1,-1,nil)、
;;; 第三の値は数値に変換されなかった残りの引数。
;;;
;;; '+' または '-'のみの数字列の場合は、それぞれ +1と -1を
;;; 返す。
;;;
;;; 符号も数値も存在しなかった場合はキーワード引数 default
;;; で指定された値 (デフォルト値は 4) を返すが、第二の値は
;;; nil を返す。
;;;
;;; これによりデフォルト値が明示的に指定されたのか、何も存
;;; 在しなかったためにデフォルト値が返されたのかを区別でき
;;; る。
;;;
(defun meta-string-to-number (str &key (default 4))
  (let (num sign rest)
    (multiple-value-setq (num sign rest) (string-to-number str))
    (cond
     ((and sign num)
      (values num sign rest))
     ((and sign (null num))
      (values sign sign rest))
     ((and (null sign) num)
      (values num sign rest))
     ((and (null sign) (null num))
      (values default nil rest)))))

;;; C-x (
;;; キーボード・マクロの定義を開始する。
;;; 反復回数が指定された場合は現在のキーボード・マクロを
;;; 実行し、その定義にキーボードから入力するコマンドを追
;;; 加する。
;;;
(defun start-kbd-macro ()
  (cond
   ((repeat-count)
    (pop *keyboard-macro*)      ;removes (repeat-count)
    (call-last-kbd-macro 1))
   (t (setf *keyboard-macro* nil)))
  (setf *record-macro* t))

(defun push-keyboard-macro (s)
  (push s *keyboard-macro*))

;;; C-x )
;;; キーボード・マクロの定義を終了する。
;;; 反復回数が指定されると定義完了とともに指定した回数だけ
;;; キーボード・マクロを実行する。ただし、定義しているとき
;;; を（実行しているので）１回目の実行と数える。
;;;
(defun end-kbd-macro ()
  (let (n)
    (setf n (repeat-count))
    (setf *record-macro* nil)
    (cond
     ((null n) nil)
     ((zerop n)
      (call-last-kbd-macro 0))
     ((> (1- n) 0)
      (call-last-kbd-macro (1- n))))))

;;; C-x e
;;; 最新のマクロを実行する。
;;;
(defun call-last-kbd-macro (&optional (n nil))
  (when (null n)
    (setf n (select-repeat-count n))
    )
  ;;(reset-repeat-count)
  (setf *macro-mode* t)
  (cond
   ;;((null n)
   ;; (true-call-last-kbd-macro 1))
   ((zerop n)
    (call-last-kbd-macro-forever))
   ((> n 0)
    (true-call-last-kbd-macro n)))
  (setf *macro-mode* nil))

(defun macro-mode-p () *macro-mode*)

;;;
;;; エラーが起きるか C-gが入力されるまでマクロを無限に繰り返す。
;;;
(defun call-last-kbd-macro-forever ()
  (let (ch)
    (catch 'quit-macro
      (loop
        (dolist (cmd (last-kbd-macro))
          (setf ch (read-char-no-hang))
          (when (and ch (char= ch *ctrl-g*))
            (throw 'quit-macro nil))
          (complex-do-command cmd)
          ;;(sync-point-and-cursor)
          ) ;; end dolist
        ) ;; end loop
      ) ;; end catch
    ) ;; end let
  ) ;; end call-last-kbd-macro-forever

;;;
;;; マクロを指定回数繰り返す。
;;;
(defun true-call-last-kbd-macro (n)
  (catch 'quit-macro
    (dotimes (i n)
      (catch 'abort-macro
        (dolist (cmd (last-kbd-macro))
          (complex-do-command cmd)
          ;;(sync-point-and-cursor)
          ) ;; end dolist
        ) ;; end catch
      ) ;; end dotimes
    ) ;; end catch
  ) ;; end true-call-last-kbd-macro

;;; C-x q
;;; マクロ定義に確認応答を追加する。
;;;
(defun kbd-macro-query ()
  (let (ch tm)
    (when (not *record-macro*)
      (xsleep (kbd-macro-query-time))
      (setf tm (blink-paren-deley)) ;; 対応するカッコへのジャンプを抑止。
      (blink-paren-deley 0)
      (loop
        (with-prompt "Proceed with macro? (y/n/q, or C-l)"
         (setf ch (getchar)))
        (cond
         ((member ch '(#\y #\Space) :test #'char=)
          (return-from kbd-macro-query nil))
         ((member ch '(#\n #\Rubout) :test #'char=)
          (throw 'abort-macro nil))
         ((member ch '(#\q #\Return) :test #'char=)
          (throw 'quit-macro nil))
         ((char= ch #\^L)
          ;;(sync-point-and-cursor)
          (xsleep (kbd-macro-query-time))))
        ) ;; end loop
      (blink-paren-deley tm) ;; 対応するカッコへのジャンプを復活。
      ) ;; end when
    ) ;; end let
  ) ;; end kbd-macro-query

;;;
;;; C-x qで処理を続けるかどうかの問い合わせ表示を行う前に
;;; テキストを何秒間表示しておくかを設定する。
;;;
;;; 引数がない場合は現在の設定値を返す。
;;;
(defun kbd-macro-query-time (&optional (tm 2 sw))
  (cond
   ((null sw) *kbd-macro-query-time*)
   ((numberp tm) (setf *kbd-macro-query-time* tm))))

;;; C-x C-k
;;; 最新のマクロを定義ファイルに書き出し、内容を編集する。
;;;
(defun edit-kbd-macro ()
  (save-macro)
  (ed (macro-file))
  (load-macro))

;;;
;;; 最新のマクロの内容を返す。
;;;
(defun last-kbd-macro ()
  (reverse *keyboard-macro*))

;;;
;;; 最新のマクロをファイルに保存する。
;;;
(defun save-macro (&optional (fname (macro-file)))
  (with-open-file (s fname :direction :output)
    (prin1 (last-kbd-macro) s)
    (terpri s)
    (return-from save-macro fname)))

;;;
;;; 指定したファイルからマクロをロードする。
;;;
(defun load-macro (&optional (fname (macro-file)))
  (with-open-file (s fname :direction :input)
    (let (tmp)
      (setf tmp (read s nil +eos+))
      (when (not (eq tmp +eos+))
        (setf *keyboard-macro* (reverse tmp))))))

;;;
;;; マクロを保存／ロードするデフォルトのファイル名を設定する。
;;; 引数がなければ現在の設定ファイル名を返す。
;;;
(defun macro-file (&optional (fn *macro-file* sw))
  (cond
   ((null sw) *macro-file*)
   ((or (stringp fn) (pathnamep fn))
    (setf *macro-file* fn))))

;;;
;;; 行を構成する情報をスタックに保存する。
;;;
(defun save-line ()
  (push *text* *line-stack*)
  (push *mark* *line-stack*)
  (push *ncl* *line-stack*)
  (push *point* *line-stack*))

;;;
;;; 行を構成する情報をスタックから復元する。
;;;
(defun restore-line ()
  (move-point-to   (pop *line-stack*))
  (setf *ncl*  (pop *line-stack*))
  (setf *mark* (pop *line-stack*))
  (setf *text* (pop *line-stack*)))

;;;
;;; マーク位置を調整するために必要な情報を保存する。
;;;
(defun save-mark-info ()
  (push *point* *save-mark-info*)
  (push *mark* *save-mark-info*)
  (push *ncl* *save-mark-info*))

;;;
;;; キル／削除後にマーク位置を調整する。
;;;
(defun align-mark ()
  (setf *mark* (pure-align-mark)))

(defun pure-align-mark ()
  (let (point mark len killed)
    (setf len (pop *save-mark-info*))
    (setf mark (pop *save-mark-info*))
    (setf point (pop *save-mark-info*))
    (setf killed (abs (- len *ncl*)))
    (if (null mark) (return-from pure-align-mark nil))
    (if (empty-text-p) (return-from pure-align-mark nil))
    (if (< *point* point)
      (cond     ;backward-kill
       ((<= mark (- point killed)) mark)
       ((<= point mark) (- mark killed))
       (t nil))
      (cond     ;forward-kill
       ((<= mark point) mark)
       ((>= mark (+ point killed)) (- mark killed))
       (t nil)))))

;;;
;;; 基本的な述語と関数の定義
;;;

;;;
;;; 空白文字類か否かを返す。
;;;
(defun white-space-p (ch)
  (if (not (characterp ch)) (return-from white-space-p nil))
  (member ch +white-space-char+))

;;;
;;; 区切り文字類か否かを返す。
;;;
(defun break-char-p (ch)
  (if (not (characterp ch)) (return-from break-char-p nil))
  (member ch *break-char*))

;;;
;;; 少なめの区切り文字で区切り文字類を定義する。
;;;
(defun narrow-break-char ()
  (setf *break-char* +narrow-break-char+))

;;;
;;; 多めの区切り文字で区切り文字類を定義する。
;;;
(defun wide-break-char ()
  (setf *break-char* +wide-break-char+))

;;;
;;; 引数で指定する文字を区切り文字類に追加する。
;;;
(defun append-break-char (&optional lst)
  (cond
   ((null lst) *break-char*)
   ((atom lst)
    (if (not (member lst *break-char*)) (push lst *break-char*)))
   ((listp lst)
    (if (not (member (car lst) *break-char*)) (push (car lst) *break-char*))
    (append-break-char (cdr lst)))))

;;;
;;; 引数で指定する文字を区切り文字類から削除する。
;;;
(defun remove-break-char (&optional lst)
  (cond
   ((null lst) *break-char*)
   ((atom lst)
    (remove lst *break-char*))
   ((listp lst)
    (remove (car lst) (remove-break-char (cdr lst))))))

;;;
;;; 普通文字類か否かを返す。
;;;
(defun normal-char-p (ch)
  (declare (type character ch))
  (not (or (white-space-p ch) (break-char-p ch))))

;;;
;;; 各種述語の定義
;;;
(defun start-kbd-macro-p (cmd) (and (functionp cmd) (eq cmd #'start-kbd-macro)))
;;(defun start-kbd-macro-p (cmd)
;;  (and (functionp cmd) (string-equal-by-symbol-name cmd 'start-kbd-macro)))

(defun end-kbd-macro-p (cmd) (and (functionp cmd) (eq cmd #'end-kbd-macro)))
;;(defun end-kbd-macro-p (cmd)
;;  (and (functionp cmd) (string-equal-by-symbol-name cmd 'end-kbd-macro)))

(defun end-input-p (cmd) (and (functionp cmd) (eq cmd #'end-input)) )
;;(defun end-input-p (cmd)
;;   (and (functionp cmd) (string-equal-by-symbol-name cmd 'end-input)) )

(defun advertised-undo-command-p (cmd) (and (functionp cmd) (eq cmd #'advertised-undo)))
;;(defun advertised-undo-command-p (cmd)
;;   (and (functionp cmd) (string-equal-by-symbol-name cmd 'advertised-undo)))

(defun advertised-redo-command-p (cmd) (and (functionp cmd) (eq cmd #'advertised-redo)))
;;(defun advertised-redo-command-p (cmd)
;;   (and (functionp cmd) (string-equal-by-symbol-name cmd 'advertised-redo)))

(defun universal-argument-command-p (cmd) (and (functionp cmd) (eq cmd #'universal-argument)))
;;(defun universal-argument-command-p (cmd)
;;   (and (functionp cmd) (string-equal-by-symbol-name cmd 'universal-argument)))

(defun allow-yank-pop-commands-p (cmd)
  ;;(and (functionp cmd) (member-by-symbol-name cmd *allow-yank-pop-commands*)))
  (and (functionp cmd) (member cmd *allow-yank-pop-commands* :test #'eq)))

(defun kill-commands-p (cmd)
  ;;(and (functionp cmd) (member-by-symbol-name cmd *kill-commands*)))
  (and (functionp cmd) (member cmd *kill-commands* :test #'eq)))

(defun call-by-keyboard-p () *call-by-keyboard*)

;;;
;;; 新規追加コマンドをグループに追加するためのコマンド群。
;;;
(defun add-allow-yank-pop-commands (&optional lst)
  (cond
   ((null lst) *allow-yank-pop-commands*)
   ((atom lst) (add-allow-yank-pop-commands (list lst)))
   (t (setf *allow-yank-pop-commands* (append *allow-yank-pop-commands* lst)))))

(defun add-kill-commands (&optional lst)
  (cond
   ((null lst) *kill-commands*)
   ((atom lst) (add-kill-commands (list lst)))
   (t (setf *kill-commands* (append *kill-commands* lst)))))

(defun add-prefix-commands (&optional lst)
  (cond
   ((null lst) *prefix-commands*)
   ((atom lst) (add-prefix-commands (list lst)))
   (t (setf *prefix-commands* (append *prefix-commands* lst)))))

;;; M-C-c
;;; このパッケージをデバッグする際に使用する代替break関数。
;;;
(defun line-edit-break (&optional (msg "line-edit-break") (quiet nil))
  (let (pkg)
    (cooked-mode)
    (setf pkg *package*)
    (format t "~a~%" msg)
    (if (null quiet) (line-edit-pkg-debug-print))
    (unwind-protect
        (break)
      (setf *package* pkg)
      (raw-mode)
      (init-line-edit)
      (finish-output))))

(defun line-edit-pkg-debug-print ()
  (dprt)
  (format t "(text-length) = ~d~%" (text-length))
  (format t "*text* = ~s~%" *text*)
  (format t "inverted *text* = ~s~%" (invert-list *text*))
  (format t "packed text = ~s~%" (pack *text*))
  (format t "inverted packed text = ~s~%" (pack (invert-list *text*)))
  (format t "(physical-line-window-size) = ~d~%" (physical-line-window-size))
  (format t "(line-length) = ~d~%" (line-length))
  (format t "(current-line) = ~s~%" (current-line))
  (format t "(last-command) = ~s~%" (last-command))
  (format t "*undo-control* = ~s~%" *undo-control*)
  (format t "(length *undo-info*) = ~s~%" (length *undo-info*))
  (format t "*undo-info* = ~s~%" *undo-info*)
  (format t "(length *redo-info*) = ~s~%" (length *redo-info*))
  (format t "*redo-info* = ~s~%" *redo-info*)
  (format t "(hscroll-unit) = ~d~%" (hscroll-unit))
  (format t "*hscroll-size* = ~d~%" *hscroll-size*)
  (format t "*newline-position* = ~s~%" *newline-position*)
  (format t "*last-newline-position* = ~s~%" *last-newline-position*)
  (format t "(need-refresh-line-p) = ~d~%" (need-refresh-line-p))
  ) ;; end line-edit-pkg-debug-print

(defun dprt ()
  (format t "*point* = ~d~%" *point*)
  (format t "*mark* = ~d~%" *mark*)
  (format t "*zero-base-physical-cursor-position* = ~d~%" *zero-base-physical-cursor-position*)
  (format t "(view-area-start) = ~d~%" (view-area-start))
  (format t "(view-area-end) = ~d~%" (view-area-end))
  (format t "current display =~%")
  (display-line)
  (terpri))

;;;
;;; コマンドの実行履歴リストを返す。
;;;     コマンド実行履歴の記録開始は      M-C-s (start)
;;;     コマンド実行履歴の記録終了は      M-C-e (end)
;;; コマンド実行履歴リスト[(command-trace)]には
;;;     (繰り返し回数 コマンド テキスト ポイント マーク *undo-info* *redo-info*)
;;; からなるリストが逆順(=新しいものほど前)に記録されている。
;;;

;;;
;;; M-C-s
;;;
(defun start-command-trace ()
  (set-command-trace 0)
  (set-command-trace-list
   (list '("\#num" "repeat-count" "Command" "Text" "point" "mark" "undo-info" "redo-info")))
  (return-from start-command-trace t))

;;;
;;; M-C-e
;;;
(defun end-command-trace ()
  (push-command-trace-list
   (list (command-trace) (repeat-count) (packed-text)
         (point) (mark) (undo-info) (redo-info)))
  (set-command-trace nil))

(defun trace-list (&optional help)
  (cond
   ((null help)
    (cdr (reverse *command-trace-list*)))
   (t (reverse *command-trace-list*))))

(defun command-trace () *command-trace*)

(defun set-command-trace (s)
  (setf *command-trace* s))

(defun command-trace-list () *command-trace-list*)

(defun set-command-trace-list (s)
  (setf *command-trace-list* s))

(defun push-command-trace-list (s)
  (push s *command-trace-list*))

;;;
;;; global-set-key 記法のコマンド文字列を「文字」の列に変換する。
;;;
;;;     \C-x    =>      +ctrl-x+
;;;     \M-x    =>      +meta-code+ x
;;;     _       =>      #\space
;;;     \_      =>      _
;;;     \x      =>      x
;;;     x       =>      x
;;;     |str|   =>      str
;;;     [str]   =>      (defined-key-list) に従って定義文字列に変換
;;;
(defun batch-str (str)
  (let (lst word ch result tmp)
    (setf lst (unpack str))
    (setf result nil)
    (loop
      (if (null lst) (return))
      (setf lst (remove-preceding-white-spaces lst))
      (cond
       ((char= (first lst) +backslash-ch+)
        (cond
         ((and                          ;\C-x or \M-x ?
           (>= (length lst) 4)
           (or
            (equal (subseq lst 1 3) +meta-prefix+)
            (equal (subseq lst 1 3) +control-prefix+)))
          (pop lst)                     ;remove '\'
          (cond
           ((char= (first lst) (first +control-prefix+))
            (pop lst)                   ;remove 'C'
            (pop lst)                   ;remove '-'
            (push (control-code (pop lst)) result))
           ((char= (first lst) (first +meta-prefix+))
            (pop lst)                   ;remove 'M'
            (pop lst)                   ;remove '-'
            (push +meta-code+ result)
            (push (pop lst) result))))
         (t
          (pop lst)                     ;remove '\'
          (push (pop lst) result))))
       ((char= (first lst) +left-square-bracket-ch+)
        (setf word nil)
        (setf ch (pop lst))
        (push ch word)
        (loop
          (if (null lst) (return))
          (setf ch (pop lst))
          (push ch word)
          (if (char= ch +right-square-bracket-ch+) (return)))
        (setf tmp (pack (reverse word)))
        (setf result (append (reverse (unpack (get-def tmp))) result)))
       ((char= (first lst) +vertical-bar-ch+) ;for |string| form
        (pop lst)                       ;remove '|'
        (loop
          (if (null lst) (return))
          (if (char= (first lst) +vertical-bar-ch+) (return (pop lst)))
          (push (pop lst) result)))
       ((char= (first lst) +underscore-ch+) ;'_' for visual space.
        (pop lst)
        (push #\space result))
       (t (push (pop lst) result))))
    (push #\return result)
    (pack (reverse result))))

(defun get-def (str)
  (cdr (true-get-def str (defined-key-list))))

(defun true-get-def (str lst)
  (cond
   ((null lst) nil)
   ((atom (car lst)) nil)
   ((not (stringp (caar lst))) nil)
   ((string= str (caar lst))
    (car lst))
   (t (true-get-def str (cdr lst)))))

;;;
;;; 文字 ch に対応するコントロール・コードを返す。
;;;
(defun control-code (ch)
  (case (char-upcase ch)
    (#\@ +ctrl-@+)
    (#\A +ctrl-a+)
    (#\B +ctrl-b+)
    (#\C +ctrl-c+)
    (#\D +ctrl-d+)
    (#\E +ctrl-e+)
    (#\F +ctrl-f+)
    (#\G +ctrl-g+)
    (#\H +ctrl-h+)
    (#\I +ctrl-i+)
    (#\J +ctrl-j+)
    (#\K +ctrl-k+)
    (#\L +ctrl-l+)
    (#\M +ctrl-m+)
    (#\N +ctrl-n+)
    (#\O +ctrl-o+)
    (#\P +ctrl-p+)
    (#\Q +ctrl-q+)
    (#\R +ctrl-r+)
    (#\S +ctrl-s+)
    (#\T +ctrl-t+)
    (#\U +ctrl-u+)
    (#\V +ctrl-v+)
    (#\W +ctrl-w+)
    (#\X +ctrl-x+)
    (#\Y +ctrl-y+)
    (#\Z +ctrl-z+)
    (#\\ +ctrl-\+)
    (#\] +ctrl-]+)
    (#\^ +ctrl-^+)
    (#\_ +ctrl-_+)
    (#\[ +ctrl-[+)
    (otherwise ch)))

;;;
;;; このパッケージのメイン関数。
;;;
;;;     init-text       初期テキスト。nilなら空テキスト。
;;;     batch-cmd       バッチ編集用コマンド。
;;;     mode-name       バッチ・コマンドのコマンド体系を示すモード名。
;;;
;;;     (line-edit "This is a pen." "\\C-u 3 \\M-f _long" "emacs-mode")
;;; and
;;;     (line-edit "This is a pen." "3w i long_" "vi-mode")
;;; both returns
;;;     "This is a long pen."
;;;
(defun line-edit (&optional (init-text "") (batch-cmd "") (mode-name nil)) ;; mode-nameをnilに戻す
  (let (tmp saved-mode)
    ;; mode-name が与えられた時（NILでも空文字でもない時）だけモードを切り替える
    (when (and mode-name (not (string= mode-name "")))
       (setf saved-mode (editor-mode))
       (set-editor-mode mode-name))
    
    (init-line-edit)

    (setf tmp (true-line-edit init-text batch-cmd))
    
    ;; モードを戻す際も同様のガード
    (when (and mode-name (not (string= mode-name "")))
       (set-editor-mode saved-mode)
       ) ;; end when
    
    (return-from line-edit (if (stringp tmp) tmp ""))
    ) ;; end let
  ) ;; end line-edit

(defun true-line-edit (&optional init-text batch-cmd)
  (init-line-edit init-text)
  (cond
    ((or
      (null batch-cmd) ;; batch-cmd がない、または空文字列の場合は、通常のループを実行してその結果を返す
      (and (stringp batch-cmd) (string= batch-cmd ""))
      )
     (line-edit-command-loop)
     )
    ((stringp batch-cmd) ;; batch-cmd がある場合は、ストリームを切り替えて実行
     (let (tmp)
       (with-input-from-string (*standard-input* (batch-str batch-cmd))
         (with-output-to-string (*standard-output*)
           (setf tmp (line-edit-command-loop))
           ) ;; end with-output-to-string
         )   ;; end with-input-from-string
       tmp   ;; tmp を返して cond を抜ける
       )
     )
    (t 
     (line-edit-command-loop)
     )
    ) ;; end cond
  ) ;; end true-line-edit

;;;
;;; 初期設定を行う。
;;;
(defun init-line-edit (&optional (init-text ""))
  (clear-input)
  (move-point-to 0)
  (move-logical-cursor-to 0)
  (setf *ncl* (length init-text))
  (setf *text* (unpack init-text))
  (setf *last-text* nil)
  (setf *mark* nil)
  (setf *suspend-switch* t)
  (setf *record-macro* nil)
  (setf *macro-mode* nil)
  (need-refresh-line nil)
  (reset-scroll)
  (reset-undo-info))

;;;
;;; line-edit終了時に復帰・改行を行うか否かを制御する。
;;;
(defun line-edit-put-newline (&optional (use t sw))
  (cond
   ((null sw) *line-edit-put-newline*)
   (t (setf *line-edit-put-newline* use))))

;;;
;;; 対話用コマンド・ループ。
;;; コマンド入力を受取り、処理し、表示を更新する。
;;;
(defun line-edit-command-loop ()
  (let (cmd text-buff)

    (setf *echo* t)
    (reset-scroll)

    (setf *last-text* nil)
    (setf text-buff *text*)

    (setf *newline-position* (previous-newline-position))
    (setf *last-newline-position* *newline-position*)
    (setf *current-completion-keymap* *default-completion-keymap*)

    (with-raw-input-mode ;; macro. 何が起きてもcooked-modeに復帰してから終了する。
        (catch :exit-line-edit
          (loop
            (catch :control-g

              (when *terminal-resized-p* ;; 端末のサイズ変更シグナルがオンなら行を書き直す。
                (display-line)
                (setf *terminal-resized-p* nil)
                )

              (reset-repeat-count)
              (set-last-command cmd)
              (setf cmd (get-command)) ;; get new command
              (when (and *record-macro* (not (end-kbd-macro-p cmd)))
                (push cmd *keyboard-macro*))
              (when (end-input-p cmd)
                (postlude-input)
                (return-from line-edit-command-loop (packed-text))
                )

              (complex-do-command cmd) ;; コマンド実行。

              (setf *last-text* text-buff)
              (setf text-buff *text*)

              (display-line)
              (finish-output)
              
              (when (and
                     (member (current-char) *parenthesis-list*) ;; まずカッコ類かをチェック。
                     (not (blink-paren-just-inserted))
                     (blink-paren-p) ;; リテラル/文字列内かのチェックが毎文字走るので最後にチェック。
                     )
                (jump-and-return-balanced-paren)
                (finish-output)
                ) ;; end when
              (cond
                ((not (kill-commands-p cmd))
                 (kill-ring-suspend t))
                ((not (allow-yank-pop-commands-p cmd))
                 (setf *allow-yank-pop* nil))
                ) ;; end cond
              )   ;; end catch :control-g
            )     ;; end loop
          )       ;; end catch :exit-line-edit
      )           ;; end with-raw-input-mode
    )             ;; end let
  ) ;; end line-edit-command-loop

;;;
;;; コマンド入力後の後処理を行う。
;;;
(defun postlude-input ()
  (when (line-edit-put-newline)
    (writeln)
    )
  (setf *zero-base-physical-cursor-position* 0)
  (search-from nil)
  (setf *mark* nil)
  (reset-undo-info)
  (reset-scroll)
  ) ;; end postlude-input

;;;
;;; コマンド実行の前処理、本処理、後処理の全てを複合して行う。
;;;
(defun complex-do-command (cmd)
  (pre-do-command cmd)
  (do-command cmd) ;; [cmd]がC-uであれば関数[universal-argument]が実行される。
  (when (not
         (or
          (advertised-undo-command-p cmd)
          (advertised-redo-command-p cmd)
          (universal-argument-command-p cmd)
          ) ;; end or
         ) ;; end not
    (post-do-command) ;; undo/redo情報の後処理を行う。
    )
  (when (universal-argument-command-p cmd) ;; [cmd]が[universal-argument]なら後続コマンドを読む。
    (complex-do-command (get-command))
    ) ;; end when
  ;;)   ;; end let
  ) ;; end comple-do-command

;;
;; 未定義動作制御文字を無視するかどうかを設定、または現在の設定を返す。
;;
;; 設定が[nil]の場合は未定義動作制御文字を無視する。
;; 設定が[t]の場合は(関数[do-command]が)16進表記の文字列を返す。
;;
;; 制御文字を入力したい場合は関数[quoted-insert]を使う(emacs-modeではC-q)。
;; 入力された制御文字の種類を確認したい場合は、確認したい文字の上にカーソルを置き
;; 関数[what-cursor-position]を実行する(emacs-modeではC-x =)。
;;
(defun ignore-invalid-command-p (&optional (val t sw))
  (if (null sw)
      *ignore-invalid-command*
      (setf *ignore-invalid-command* val)
      ) ;; end if
  ) ;; end ignore-invalid-command-p

;;;
;;; 渡された引数が関数であれば、その関数を実行し、
;;; 文字であれば[*otherwise-function*]で指定された関数を実行する。
;;;
(defun do-command (cmd)
  (setf *call-by-keyboard* t)
  (cond
    ((characterp cmd)
     (cond
       ((and ;; 入力が非図形文字かつ未定義動作制御文字を無視しない場合は16進表記の文字列を入力する。
         (not (ascii-printable-char-p cmd)) ; 本来は ((not (graphic-char-p cmd))
         (not (ignore-invalid-command-p))
         )
        (self-insert-string (make-description cmd)))
       ((and ;; 入力が非図形文字かつ未定義動作制御文字をコマンドとして無視する場合はベルを鳴らして警告する。
         (not (ascii-printable-char-p cmd))
         (ignore-invalid-command-p)
         )
        (audio-bell)
        )
       (t (funcall (eval *otherwise-function*) cmd)))   ;; == (t (self-insert cmd)))
     ) ;; end inner cond
    ((stringp cmd)
     (self-insert-string cmd))
    ((functionp cmd)
     (funcall cmd))
    (t (line-edit-break
        (format nil "~%error in do-command: function or character expected (~s)" cmd) t))
    ) ;; end cond
  (setf *call-by-keyboard* nil)
  ) ;; end do-command

;;;
;;; コマンド実行の準備を行う。
;;; 結果が nilでない場合は do-commandとpost-do-commandを実行する。
;;;
(defun pre-do-command (cmd)
  ;;デバッグ用のトレースが設定されていれば情報を記録する。
  (when (command-trace)
    (push-command-trace-list
     (list (command-trace) (repeat-count) cmd (packed-text)
           (point) (mark) (undo-info) (redo-info)))
    (set-command-trace (1+ (command-trace))))
  #|
  (when (and (universal-argument-command-p cmd) (macro-mode-p))
    (when (debug-print-p "pre-do-command")
      (format t "pre-do-command: cmd=~s~%" cmd)
      )
    ;;(when (not (macro-mode-p))
    ;;  (funcall cmd) ;;前置コマンド用関数を実行する。
    ;;  (push-keyboard-macro (repeat-count))
    ;;  ) ;; end when
      (push-keyboard-macro (repeat-count))
    ;;(return-from pre-do-command t)
    (return-from pre-do-command nil)
    ) ;; end when
  |#
  ;; [cmd]がundoでもredoでもuniversal-argumentでもない場合は、undo情報とredo情報の順序を整理する。
  (when (not
         (or
          (advertised-undo-command-p cmd)
          (advertised-redo-command-p cmd)
          (universal-argument-command-p cmd)
          ) ;; end or
         ) ;; end not
    (set-undo-info (append (redo-info) (reverse-do (redo-info)) (undo-info)))
    (set-redo-info nil)
    ) ;; end when
  (set-undo-control nil)
  (set-command-undo-info nil)
  (return-from pre-do-command t)
  ;;(return-from pre-do-command nil)
  ) ;; end pre-do-command

;;;
;;; undo/redo情報の後処理を行う。
;;;
;;(defun post-do-command (cmd)
(defun post-do-command ()
  (when (command-undo-info)
    (cond
     ((equal (undo-control) 'undo)
      (push-redo-info (command-undo-info)))
     ((equal (undo-control) 'redo)
      (push-undo-info (command-undo-info)))
     (t (push-undo-info (command-undo-info))))
    ) ;; end when
  ) ;; end post-do-command

;;;
;;; キーボードから入力を受け取り実行すべき関数を返す。
;;; 定義されていないキー列が入力された場合は、一致しなかった最初の文字を返す。
;;; a → b → c というキー列があり、a,bまでは一致するキー列があったが b 以降に c で続く定義された
;;; キー列が存在しなかった場合は[c]を返す。
;;;
(defun get-command (&optional (keymap (global-keymap)))
  "キー入力の列から登録された関数を取り出す関数。

コマンド・キー列として定義されていない通常の1文字は関数[self-insert]に渡されて入力文字となる。
登録されていないキー列が入力された場合は[nil]を返す。

2025-12-24 Control, Metaに加えてSuperキーも定義できるようにした。
Superキーはコマンド・キー(⌘)やWindowsキーに割り当てるのが自然だが端末ソフトやOSに
横取りされる場合が多く、文字コードとして受け取ることも困難な場合が多い。
本プログラムではESC+ESCをSuperキーとして解釈している。
altキーをMetaキーとして使う場合が多いが、端末ソフトはalt+[key]をタイプすると
ESC+[key]を返す。従ってESC+[key]としてもalt+[key]と同じである。
Meta+[key]がESC+[key]なので、Super+[key]はESC+ESC+[key]とした。
Super + Meta + Control + [key]などの3重修飾キーの定義も可能。Super, Meta, Control
の入力順は入力受け取り時に Super→Meta→Controlに正規化している。コマンド登録用の
関数global-set-keyの修飾子も同じ順序に正規化しているので、修飾子のタイプ順、定義順は自由。
"
  (let (sym)
    (setf sym (true-get-command (getsym) keymap))
    (cond
      ((null sym)
       (clear-symbol-buffer)
       *last-char*
       )
      ((stringp sym)
       (setf sym (search-key sym keymap))
       (cond
         ((null sym)
          (audio-bell)
          (clear-symbol-buffer)
          (get-command keymap))
         (t (car (second sym))))
       ) ;; end inner cond
      (t sym)
      ) ;; end cond
    )   ;; end let
  ) ;; end get-command

(defun true-get-command (key keymap)
  (let (p)
    (setf p (search-key key keymap))
    (loop
      (cond
        ((null p)
         (return-from true-get-command nil)
         )
        ((null (cdr (second p)))
         (return-from true-get-command (car (second p)))
         )
        ) ;; end cond
      (setf p (search-key (getsym) (cdr p)))
      ) ;; end loop
    )   ;; end let
  ) ;; end true-get-command

;;;
;;; 関数[getsym]と関数[clear-symbol-buffer]にローカルな変数[symbol-buffer]を定義する。
;;;
(let
    ((symbol-buffer nil))
  ;;キーボードから文字を読み込み、シンボルを返す。
  (defun getsym (&optional (stream *standard-input*) (use-super-key-p t))
    (cond
      ((null symbol-buffer)
       (setf symbol-buffer (normalize-symbol-seq (true-getsym stream use-super-key-p)))
       (pop symbol-buffer))
      (t (pop symbol-buffer))))

  (defun clear-symbol-buffer () ;;; symbol bufferをクリアする。
    (setf symbol-buffer nil))

  ) ;; end let

(defun translate-char-to-string-symbol (char &optional (use-super-key-p t))
  (cond
    ((and
      (identity use-super-key-p)
      (char= char +ESC+)
      )
     (let ((next-ch (peek-ahead))) ;; ESC+ESCをスーパー・キーとして解釈する。
       (cond
         ((eql next-ch +ESC+) ;; ESCの次の文字もESCであれば
          (getchar) ;; 次のESCを読み捨てて[Super]キーと解釈する。    
          (list +super-string+) ;; [Super]キー。
          )
         (t
          ;;(append (list +meta-string+)) ;; [Meta]キー。
          (list +meta-string+) ;; [Meta]キー。
          )
         ) ;; end cond
       )   ;; end let
     )
    ((and
      (null use-super-key-p)
      (char= char +ESC+)
      )
     (list +meta-string+)
     )
    ;;
    ;; 開発者注: 
    ;; ここで case ではなく cond と char= を使用しているのは、定数（+ctrl-a+ 等）を
    ;; 読込時評価(#.)なしでそのまま正しく評価させるため。
    ;; case のキー部分に定数を使うには #. が必須となるが、それを許容すると600行目付近の
    ;; 定数定義(defconstant +ctrl-@ (code-char 0))...を(eval-when (:compile-toplevel ...
    ;; で囲む必要が生じ、コードの可読性と処理系間(SBCL/CLISP等)でのポータビリティを損なうため、
    ;; あえて標準的な評価規則に従うcondを採用している。
    ;;
    ((char= char +ctrl-@+) (list +control-string+ +at-sign+ )) ;; => ("control" "at-sign")
    ((char= char +ctrl-a+) (list +control-string+ +letter-a+)) ;; => ("control" "letter-a")
    ((char= char +ctrl-b+) (list +control-string+ +letter-b+))
    ((char= char +ctrl-c+) (list +control-string+ +letter-c+))
    ((char= char +ctrl-d+) (list +control-string+ +letter-d+))
    ((char= char +ctrl-e+) (list +control-string+ +letter-e+))
    ((char= char +ctrl-f+) (list +control-string+ +letter-f+))
    ((char= char +ctrl-g+) (list +control-string+ +letter-g+))
    ((char= char +ctrl-h+) (list +control-string+ +letter-h+))
    ((char= char +ctrl-i+) (list +control-string+ +letter-i+))
    ((char= char +ctrl-j+) (list +control-string+ +letter-j+))
    ((char= char +ctrl-k+) (list +control-string+ +letter-k+))
    ((char= char +ctrl-l+) (list +control-string+ +letter-l+))
    ((char= char +ctrl-m+) (list +control-string+ +letter-m+))
    ((char= char +ctrl-n+) (list +control-string+ +letter-n+))
    ((char= char +ctrl-o+) (list +control-string+ +letter-o+))
    ((char= char +ctrl-p+) (list +control-string+ +letter-p+))
    ((char= char +ctrl-q+) (list +control-string+ +letter-q+))
    ((char= char +ctrl-r+) (list +control-string+ +letter-r+))
    ((char= char +ctrl-s+) (list +control-string+ +letter-s+))
    ((char= char +ctrl-t+) (list +control-string+ +letter-t+))
    ((char= char +ctrl-u+) (list +control-string+ +letter-u+))
    ((char= char +ctrl-v+) (list +control-string+ +letter-v+))
    ((char= char +ctrl-w+) (list +control-string+ +letter-w+))
    ((char= char +ctrl-x+) (list +control-string+ +letter-x+))
    ((char= char +ctrl-y+) (list +control-string+ +letter-y+))
    ((char= char +ctrl-z+) (list +control-string+ +letter-z+))
    ((char= char +ctrl-\+) (list +control-string+ +backslash+))
    ((char= char +ctrl-]+) (list +control-string+ +right-square-bracket+))
    ((char= char +ctrl-^+) (list +control-string+ +circumflex-accent+))
    ((char= char +ctrl-_+) (list +control-string+ +underscore+))
    ((char= char +ctrl-?+) (list +control-string+ +question-mark+))
    ((char= char #\Space) (list +space+))
    (t
     (list (gryph-to-description *last-char*)))
    ) ;; end outer cond
  ) ;; end translate-char-to-string-symbol

;; [文字]を[文字シンボルの列]に変換する。
(defun true-getsym (&optional (stream *standard-input*) (use-super-key-p nil))
  (setf *last-char* (getchar stream))
  (translate-char-to-string-symbol *last-char* use-super-key-p)
  ) ;; end true-getsym

;;;
;;; keymapの要素のcarが[str]である要素を返す。
;;;
(defun search-key (str &optional (keymap *current-completion-keymap*))
  (let (tmp)
    (setf tmp (car keymap))
    (cond
      ((and
        (atom tmp)
        (stringp tmp)
        )
       (if (string-equal str tmp)
           keymap
           nil
           ) ;; end if
       )
      (t
       (dolist (s keymap)
         (if (string-equal str (car s))
             (return-from search-key s)
             ) ;; end if
         )     ;; end dolist
       )       ;; end [t]
      )        ;; end cond
    )          ;; end let
  ) ;; end search-key

;;;
;;; コマンドに対するキー列と実行すべき関数を引数としてコマンド実行に必要な遷移表を
;;; 作成してスペシャル変数[*global-keymap*]に保存する。
;;;
;;; [*defined-key-list*]の形式は
;;; (("[Return]" . "\\C-m") ("[Enter]" . "\\C-j") ("[Tab]" . "\\C-i") ("[Backspace]" . "\\C-h")
;;; ("[delete]" . "\\C-?")) :test #'string-equal)=("[Backspace]" . "\\C-h")
;;;
;;; [5]> (setf x '(("[Return]" . "\\C-m") ("[Enter]" . "\\C-j") ("[Tab]" . "\\C-i")
;;; ("[Backspace]" . "\\C-h") ("[delete]" . "\\C-?"))) ("[Return]" . "\\C-m")
;;; ("[Enter]" . "\\C-j") ("[Tab]" . "\\C-i") ("[Backspace]" . "\\C-h") ("[delete]" . "\\C-?"))
;;;
;;; [6]> (assoc "[Backspace]" x :test #'string-equal)
;;; ("[Backspace]" . "\\C-h")
;;;
(defun global-set-key (str key-def)
  "コマンドに対するキー列と実行すべき関数を引数としてコマンド実行に必要な遷移表を
作成してスペシャル変数[*global-keymap*]に保存する。

(global-set-key \"\\C-f\" #'forward-char) として
         C-f とすると
    (funcall #'forward-char)

を評価する。

第1引数に[nil]を指定すると(global-set-key ...)で指定されなかったキー列に対する
処理関数の指定となる。デフォルトは self-insert。
"
  (set-key str key-def '*global-keymap*)
  ) ;; end global-set-key

;; 関数[global-set-key]の一般形。
(defun set-key (str key-def keymap)
  (let ((alias-val nil))
    (setf alias-val (assoc str *defined-key-list* :test #'string-equal))
    (cond
      ((null str)
       ;;(setf *otherwise-function* key-def))
       *otherwise-function*
       )
      ((and ;; [define-key]で定義した名前付きキーシーケンスをキーシーケンスに置き換える。
        (stringp str)
        (identity alias-val)
        )
       (when (debug-print-p "set-key")
         (format t "=== set-key ====================================================================~%")
         (format t "(set-key ~s ~s ~s)=~%" str key-def keymap)
         (format t "(assoc ~s ~s :test #'string-equal)=~s~%" str *defined-key-list* alias-val)
         (format t "key-seq-to-normalized-symbol-seq=~s~%"(key-seq-to-normalized-symbol-seq (cdr alias-val)))
         ) ;; end when [debug-print-p]
       (set-keymap keymap (key-seq-to-normalized-symbol-seq (cdr alias-val)) key-def)
       )
      ((stringp str)
       (set-keymap keymap (key-seq-to-normalized-symbol-seq str) key-def)
       )
      (t (line-edit-break "set-key: string or nil expected" t)) ;; 各種デバッグ情報を表示する。
      ) ;; end cond
    )   ;; end let
  ) ;; end set-key

;;;
;;; 遷移表[keymap]に[str]と[key-def]のセットを登録する。
;;;
;;(defun define-keymap (keymap str key-def)
;;  (set-key str key-def keymap)
;;  )

;;;
;;; global-set-keyの初期化を行う。
;;;
(defun clear-global-set-key ()
  (setf *defined-key-list* nil)
  (setf *global-keymap* nil))

;;;
;;; コマンド・キー列の遷移表を返す。
;;;
(defun global-keymap ()
#| emacs-mode.lisp実行後の[*global-keymap*]の内容。

(("control" ("at-sign" (LINE-EDIT-PKG:SET-MARK-COMMAND)) ("circumflex-accent" (LINE-EDIT-PKG:SCROLL-DOWN))
  ("letter-a" (LINE-EDIT-PKG:BEGINNING-OF-LINE)) ("letter-b" (LINE-EDIT-PKG:BACKWARD-CHAR))
  ("letter-d" (LINE-EDIT-PKG:DELETE-CHAR)) ("letter-e" (LINE-EDIT-PKG:END-OF-LINE))
  ("letter-f" (LINE-EDIT-PKG:FORWARD-CHAR))
  ("letter-h" (LINE-EDIT-PKG:DELETE-BACKWARD-CHAR) ("[Backspace]") ("[Rubout]"))
  ("letter-j" (LINE-EDIT-PKG:SELF-INSERT-NEWLINE) ("[Linefeed]")) ("letter-k" (LINE-EDIT-PKG:KILL-LINE))
  ("letter-l" (LINE-EDIT-PKG:REDRAW)) ("letter-m" ("[Return]")) ("letter-n" (LINE-EDIT-PKG::NEXT-LINE))
  ("letter-o" (LINE-EDIT-PKG:SET-MARK-COMMAND)) ("letter-p" (LINE-EDIT-PKG::PREVIOUS-LINE))
  ("letter-q" (LINE-EDIT-PKG:QUOTED-INSERT)) ("letter-s" (LINE-EDIT-PKG:ISEARCH-FORWARD))
  ("letter-t" (LINE-EDIT-PKG:TRANSPOSE-CHARS)) ("letter-u" (LINE-EDIT-PKG:UNIVERSAL-ARGUMENT))
  ("letter-v" (LINE-EDIT-PKG:SCROLL-UP)) ("letter-w" (LINE-EDIT-PKG:KILL-REGION))
  ("letter-x" ("capital-U" (LINE-EDIT-PKG:ADVERTISED-REDO))
   ("control" ("letter-f" (LINE-EDIT-PKG:FIND-FILE)) ("letter-k" (LINE-EDIT-PKG:EDIT-KBD-MACRO))
    ("letter-s" (LINE-EDIT-PKG:SAVE-BUFFER)) ("letter-u" (LINE-EDIT-PKG:UP-LIST))
    ("letter-w" (LINE-EDIT-PKG:WRITE-FILE)) ("letter-x" (LINE-EDIT-PKG:EXCHANGE-POINT-AND-MARK)))
   ("equals-sign" (LINE-EDIT-PKG:WHAT-CURSOR-POSITION)) ("greater-than-sign" (LINE-EDIT-PKG:SCROLL-RIGHT))
   ("left-parenthesis" (LINE-EDIT-PKG:START-KBD-MACRO)) ("less-than-sign" (LINE-EDIT-PKG:SCROLL-LEFT))
   ("right-parenthesis" (LINE-EDIT-PKG:END-KBD-MACRO)) ("small-e" (LINE-EDIT-PKG:CALL-LAST-KBD-MACRO))
   ("small-i" (LINE-EDIT-PKG:INSERT-FILE)) ("small-q" (LINE-EDIT-PKG:KBD-MACRO-QUERY))
   ("small-r" ("capital-R" (LINE-EDIT-PKG:RESTORE-REGISTERS)) ("capital-S" (LINE-EDIT-PKG:SAVE-REGISTERS))
    ("small-i" (LINE-EDIT-PKG:INSERT-REGISTER)) ("small-s" (LINE-EDIT-PKG:COPY-TO-REGISTER)))
   ("small-u" (LINE-EDIT-PKG:ADVERTISED-UNDO)))
  ("letter-y" (LINE-EDIT-PKG:YANK)) ("underscore" (LINE-EDIT-PKG:SET-MARK-COMMAND)))
 ("meta" ("at-sign" (LINE-EDIT-PKG:MARK-WORD)) ("backslash" (LINE-EDIT-PKG:DELETE-HORIZONTAL-SPACE))
  ("capital-O" ("capital-A" (LINE-EDIT-PKG::PREVIOUS-LINE)) ("capital-B" (LINE-EDIT-PKG::NEXT-LINE))
   ("capital-C" (LINE-EDIT-PKG:FORWARD-CHAR)) ("capital-D" (LINE-EDIT-PKG:BACKWARD-CHAR)))
  ("comma" (LINE-EDIT-PKG:ADVERTISED-UNDO))
  ("control" ("at-sign" (LINE-EDIT-PKG:MARK-SEXP)) ("letter-b" (LINE-EDIT-PKG:BACKWARD-SEXP))
   ("letter-c" (LINE-EDIT-PKG:LINE-EDIT-BREAK)) ("letter-d" (LINE-EDIT-PKG:DOWN-LIST))
   ("letter-e" (LINE-EDIT-PKG:END-COMMAND-TRACE)) ("letter-f" (LINE-EDIT-PKG:FORWARD-SEXP))
   ("letter-h" (LINE-EDIT-PKG:BACKWARD-KILL-WORD)) ("letter-k" (LINE-EDIT-PKG:KILL-SEXP))
   ("letter-n" (LINE-EDIT-PKG:FORWARD-LIST)) ("letter-o" (LINE-EDIT-PKG:MARK-SEXP))
   ("letter-p" (LINE-EDIT-PKG:BACKWARD-LIST)) ("letter-s" (LINE-EDIT-PKG:START-COMMAND-TRACE))
   ("letter-t" (LINE-EDIT-PKG:TRANSPOSE-SEXPS)) ("letter-u" (LINE-EDIT-PKG:BACKWARD-UP-LIST))
   ("letter-w" (LINE-EDIT-PKG:APPEND-NEXT-KILL)) ("underscore" (LINE-EDIT-PKG:MARK-SEXP)))
  ("greater-than-sign" (LINE-EDIT-PKG::END-OF-HISTORY))
  ("left-parenthesis" (LINE-EDIT-PKG:INSERT-PARENTHESIS))
  ("left-square-bracket" ("capital-A" (LINE-EDIT-PKG::PREVIOUS-LINE))
   ("capital-B" (LINE-EDIT-PKG::NEXT-LINE)) ("capital-C" (LINE-EDIT-PKG:FORWARD-CHAR))
   ("capital-D" (LINE-EDIT-PKG:BACKWARD-CHAR)) ("digit-3" ("tilde" ("[delete]"))))
  ("less-than-sign" (LINE-EDIT-PKG::BEGINNING-OF-HISTORY)) ("period" (LINE-EDIT-PKG:ADVERTISED-REDO))
  ("slash" (LINE-EDIT-PKG:MARK-WORD)) ("small-a" (LINE-EDIT-PKG:BEGINNING-OF-TEXT))
  ("small-b" (LINE-EDIT-PKG:BACKWARD-WORD)) ("small-c" (LINE-EDIT-PKG:CAPITALIZE-WORD))
  ("small-d" (LINE-EDIT-PKG:KILL-WORD)) ("small-e" (LINE-EDIT-PKG:END-OF-TEXT))
  ("small-f" (LINE-EDIT-PKG:FORWARD-WORD)) ("small-g" (LINE-EDIT-PKG::GOTO-GLOBAL-MARK))
  ("small-i" (LINE-EDIT-PKG:INSPECT-KEYCODE)) ("small-k" (LINE-EDIT-PKG:KILL-TEXT))
  ("small-l" (LINE-EDIT-PKG:DOWNCASE-WORD)) ("small-m" (LINE-EDIT-PKG::SET-GLOBAL-MARK))
  ("small-n" (LINE-EDIT-PKG:NEXT-WORD)) ("small-o" (LINE-EDIT-PKG:MARK-SEXP))
  ("small-p" (LINE-EDIT-PKG:MOVE-TO-MATCHING-PAREN)) ("small-r" (LINE-EDIT-PKG:REDRAW-ZERO))
  ("small-s" (LINE-EDIT-PKG:JUST-ONE-SPACE)) ("small-t" (LINE-EDIT-PKG:TRANSPOSE-WORDS))
  ("small-u" (LINE-EDIT-PKG:UPCASE-WORD)) ("small-v" (LINE-EDIT-PKG:SCROLL-DOWN))
  ("small-w" (LINE-EDIT-PKG:KILL-RING-SAVE)) ("small-y" (LINE-EDIT-PKG:YANK-POP))
  ("small-z" (LINE-EDIT-PKG:ZAP-TO-CHAR)) ("[Rubout]" (LINE-EDIT-PKG:BACKWARD-KILL-WORD))
  ("[Space]" (LINE-EDIT-PKG:JUST-ONE-SPACE)))
 ("small-c" ("minus-sign" ("small-i" ("[Tab]")))) ("[0xa0]" (LINE-EDIT-PKG:JUST-ONE-SPACE))
 ("[Backspace]" (LINE-EDIT-PKG:DELETE-BACKWARD-CHAR)) ("[delete]" (LINE-EDIT-PKG:DELETE-CHAR))
 ("[Linefeed]" (LINE-EDIT-PKG:SELF-INSERT-NEWLINE)) ("[Return]" (LINE-EDIT-PKG:END-INPUT))
 ("[Rubout]" (LINE-EDIT-PKG:DELETE-BACKWARD-CHAR)) ("[Space]" (LINE-EDIT-PKG:SELF-INSERT-SPACE))
 ("[Tab]" (LINE-EDIT-PKG::COMPLETE-SYMBOL)))
|#
  (cond
   ((atom (car *global-keymap*))
    (list *global-keymap*))
   (t *global-keymap*)))

;;;
;;; キー・シーケンスの別名を定義する関数。
;;;
;;;     (define-key "[delete]" "\\M-\\[3\~")
;;;
(defun define-key (named-key-string key-seq-str)
  (push (cons named-key-string key-seq-str) *defined-key-list*)
  )

;;;
;;; define-key で定義されたシンボルとコード列の記録を返す。
;;;
(defun defined-key-list () *defined-key-list*)

;;
;; xterm拡張エスケープ・シーケンスのモード1におけるshift+alt+editing-keyを定義するための補助関数群。
;;
;; (global-set-key (shift+alt+ctrl :Insert) #'function)
;;
;; のように使う。
;;
;; (format t "(editing-key :Home)=~s~%" (editing-key :Home))
;; (format t "(shift :Home)=~s~%" (shift :Home))
;; (format t "(shift+alt :Home)=~s~%" (shift+alt :Home))
;; (format t "(shift+ctrl :Home)=~s~%" (shift+ctrl :Home))
;; (format t "(shift+alt+ctrl :Home)=~s~%" (shift+alt+ctrl :Home))
;; 
;; (format t "(editing-key :Insert)=~s~%" (editing-key :Insert))
;; (format t "(shift :Insert)=~s~%" (shift :Insert))
;; (format t "(shift+alt :Insert)=~s~%" (shift+alt :Insert))
;; (format t "(shift+ctrl :Insert)=~s~%" (shift+ctrl :Insert))
;; (format t "(shift+alt+ctrl :Insert)=~s~%" (shift+alt+ctrl :Insert))
;; 
;; (format t "(editing-key :up-arrow)=~s~%" (editing-key :up-arrow))
;; (format t "(shift :up-arrow)=~s~%" (shift :up-arrow))
;; (format t "(shift+alt :up-arrow)=~s~%" (shift+alt :up-arrow))
;; (format t "(shift+ctrl :up-arrow)=~s~%" (shift+ctrl :up-arrow))
;; (format t "(shift+alt+ctrl :up-arrow)=~s~%" (shift+alt+ctrl :up-arrow))
;;
;; (editing-key :Home)="\\M-1;1~"
;; (shift :Home)="\\M-1;2~"
;; (shift+alt :Home)="\\M-1;4~"
;; (shift+ctrl :Home)="\\M-1;6~"
;; (shift+alt+ctrl :Home)="\\M-1;8~"
;; (editing-key :Insert)="\\M-2;1~"
;; (shift :Insert)="\\M-2;2~"
;; (shift+alt :Insert)="\\M-2;4~"
;; (shift+ctrl :Insert)="\\M-2;6~"
;; (shift+alt+ctrl :Insert)="\\M-2;8~"
;; (editing-key :up-arrow)="\\M-1;1 A"
;; (shift :up-arrow)="\\M-1;2 A"
;; (shift+alt :up-arrow)="\\M-1;4 A"
;; (shift+ctrl :up-arrow)="\\M-1;6 A"
;; (shift+alt+ctrl :up-arrow)="\\M-1;8 A"
;;
(defun base-editing-key (modifier editing-key-name)
  (case editing-key-name
    (:up-arrow          (format nil "\\M-1;~d A"  modifier))
    (:down-arrow        (format nil "\\M-1;~d B"  modifier))
    (:right-arrow       (format nil "\\M-1;~d C"  modifier))
    (:left-arrow        (format nil "\\M-1;~d D"  modifier))
    (:Home              (format nil "\\M-1;~d~~"  modifier))
    (:Insert            (format nil "\\M-2;~d~~"  modifier))
    (:Delete            (format nil "\\M-3;~d~~"  modifier))
    (:End               (format nil "\\M-4;~d~~"  modifier))
    (:PageUp            (format nil "\\M-5;~d~~"  modifier))
    (:PageDown          (format nil "\\M-6;~d~~"  modifier))
    (:F1                (format nil "\\M-1;~d P"  modifier))
    (:F2                (format nil "\\M-2;~d Q"  modifier))
    (:F3                (format nil "\\M-3;~d R"  modifier))
    (:F4                (format nil "\\M-4;~d S"  modifier))
    (:F5                (format nil "\\M-15;~d~~" modifier))
    (:F6                (format nil "\\M-17;~d~~" modifier)) ;; 間違いではなく歴史的理由により[17]。
    (:F7                (format nil "\\M-18;~d~~" modifier))
    (:F8                (format nil "\\M-19;~d~~" modifier))
    (:F9                (format nil "\\M-20;~d~~" modifier))
    (:F10               (format nil "\\M-21;~d~~" modifier))
    (:F11               (format nil "\\M-23;~d~~" modifier)) ;; 同上。歴史的理由により[23]。
    (:F12               (format nil "\\M-24;~d~~" modifier))
    (otherwise          (warn "base-editing-key: unsupported editing key(~a).~%" editing-key-name))
    ) ;; end case
  ) ;; end shift+

(defun editing-key (editing-key-name)    (base-editing-key +base+ editing-key-name))
(defun shift (editing-key-name)          (base-editing-key (+ +base+ +shift+) editing-key-name))
(defun alt (editing-key-name)            (base-editing-key (+ +base+ +alt+) editing-key-name))
(defun esc (editing-key-name)            (alt editing-key-name)) ;; synonym for alt.
(defun ctrl (editing-key-name)           (base-editing-key (+ +base+ +ctrl+) editing-key-name))
(defun alt+ctrl (editing-key-name)       (base-editing-key (+ +base+ +alt+ctrl+) editing-key-name))
(defun shift+alt (editing-key-name)      (base-editing-key (+ +base+ +shift+alt+) editing-key-name))
(defun shift+ctrl (editing-key-name)     (base-editing-key (+ +base+ +shift+ctrl+) editing-key-name))
(defun shift+alt+ctrl (editing-key-name) (base-editing-key (+ +base+ +shift+alt+ctrl+) editing-key-name))

;;;
;;; [keymap]に遷移表を蓄積する。
;;;
(defun set-keymap (keymap lst def-body)
  (when (debug-print-p "set-keymap")
    (format t "-----------------------------------------------------------------~%")
    (format t "set-keymap:keymap=~s, lst=~s, def-body=~s~%" keymap lst def-body)
    (format t "set-keymap:(symbol-val ~s)=~s~%" keymap (symbol-value keymap))
    (format t "set-keymap:(append ~s (list ~s))=~s~%" lst def-body (append lst (list def-body)))
    (format t "(eval keymap)=~s~%" (eval keymap))
    (format t "set-keymap:make-trans-table=~s~%" (make-trans-table (append lst (list def-body))))
    (format t "(condense (symbol-value keymap) (make-trans-table ...))=~s~%"
            (condense (symbol-value keymap) (make-trans-table (append lst (list def-body))))
            ) ;; end format
    ) ;; end when
  (setf (symbol-value keymap)
        ;;(condense (eval keymap) (make-trans-table (append lst (list def-body))))
        (condense (symbol-value keymap) (make-trans-table (append lst (list def-body))))
        )
  ) ;; end set-keymap

;;;
;;; 引数[keymap]に与えるスペシャル変数に[global-set-key]が作成した遷移表を蓄積する。
;;;
(defun set-global-keymap (lst def-body &optional (keymap '*global-keymap*))
  (set-keymap keymap lst def-body))

;;;
;;; 正規化コマンド・シンボルのリストと実行すべき関数名からなるリストから
;;; コマンド単体の遷移表を作成して返す。
;;;
(defun make-trans-table (lst)
  (cond
   ((null lst) nil)
   ((atom lst) (list lst))
   ((null (cdr lst)) lst)
   (t (cons (car lst) (list (make-trans-table (cdr lst)))))))

;;;
;;; 遷移表[p]と遷移表[q]を統合して冗長性のない単一の遷移表に合成する(Trie木を作成する)関数。
;;;
;;; 同じ遷移ルート(<transition-root>)で<body>だけが異なる場合は第2引数の[q]側の定義に置き換わる。
;;; つまり[p]の定義を[q]の定義で置き換えたければ(condense p q)。逆に[p]の定義を守りたければ引数
;;; の順序を逆にして(condense q p)とする。
;;;
;;; <code>                      ::= <atom> ;
;;; <body>                      ::= <generalized-object> ;
;;; <condensed-transition>      ::= ( <code>* <condensed-transition>+ ) | ( <code>+ <body> ) ;
;;; <transition-table>          ::= ( <condensed-transition>+ ) ;
;;;
;;; A, Bが遷移表であり、AとBに同じ遷移ルート(登録単語)があるとき
;;;     (condense A B) => 遷移表Bの定義が合成された遷移表に残る。
;;;     (condense B A) => 遷移表Aの定義が合成された遷移表に残る。
;;;
;;;     (condense nil nil) => nil
;;;     (condense A nil) => A
;;;     (condense nil A) => A
;;;     (condense A A) => A
;;;     (condense B B) => B
;;;
;;; ==============================================
;;;     実行例
;;; ==============================================
;;;
;;; lst-1=(A B C X)
;;; lst-2=(A B C Y)
;;; lst-3=(A B C Z)
;;; lst-4=(A Q C S)
;;; 
;;; (1)   (condense nil nil)=nil
;;;
;;; (2-1) (condense lst-1 nil)=(a b c x)
;;; (2-2) (condense nil lst-1)=(a b c x)
;;; 
;;; (3-1) (condense lst-1 lst-2)=(a b c y) ;; lst-2の<body>である[y]に置き換わる。
;;; (3-2) (condense lst-2 lst-1)=(a b c x) ;; lst-1の<body>である[x]に置き換わる。
;;; (3-3) (condense (condense lst-1 lst-2) nil)=(a b c y) ;; <transition-root>が同じなら第2引数の<body>優先。
;;; (3-4) (condense nil (condense lst-1 lst-2))=(a b c y)
;;; 
;;; (4-1) (condense (condense lst-2 lst-1) lst-3)=(a b c z) ;; <transition-root>が同じなら第2引数の<body>優先。
;;; (4-2) (condense lst-3 (condense lst-1 lst-2))=(a b c y)
;;; 
;;; (5)   (setf result-1 (condense lst-1 lst-4))=(A (B C X) (Q C S))
;;; (5)   (setf result-2 (condense lst-2 lst-4))=(A (B C Y) (Q C S))
;;; (5-1) (condense result-1 result-2)=(A (B C Y) (Q C S))
;;; (5-2) (condense result-2 result-1)=(A (B C X) (Q C S))
;;;
;;; [p]と[q]は {nil | <transition-table>}
;;;

;;
;; 関数[condense]用の補助関数。
;;
(defun paste (p q)
  (cond
   ((atom (car q))
    (list p q))
   (t (cons p q))))

(defun condense (p q)
  "Trie木用の遷移表を作成して返す関数。引数[p]と[q]は共に<transition-table>.
        <code>                  ::= <atom> ;
        <body>                  ::= <generalized-object> ;
        <condensed-transition>  ::= ( <code>* <condensed-transition>+ ) | ( <code>+ <body> ) ;
        <transition-table>      ::= ( <condensed-transition>+ ) ;
"
  (cond
    ((atom p) q)
    ((atom q) p)
    ((atom (car p))
     (more-simple-condense p q))
    ((atom (car q))
     (more-simple-condense q p))
    ((and
      (null (cdr p))
      (null (cdr q)))
     (condense (car p) (car q)))
    ((null (cdr p))
     (condense (car p) q))
    ((null (cdr q))
     (condense p (car q)))
    ((listp (car p))
     (condense (car p) (condense (cdr p) q)))
    ((listp (car q))
     (condense (condense p (cdr q)) (car q)))
    (t (paste (condense (car p) (car q)) (condense (cdr p) (cdr q))))))

;;;
;;; [q]の第1要素がアトムである場合の処理を行う。
;;; [p]の第1要素がアトムである場合の処理を行わないのは[p]と[q]の順序を保存するため。
;;;
(defun more-simple-condense (p q)
  (cond
   ((atom p) q)
   ((atom q) p)
   ((atom (car q))
    (most-simple-condense p q))
   ((null (cdr q))
    (more-simple-condense p (car q)))
   ((equal (car p) (caar q))
    (cons (most-simple-condense p (car q)) (cdr q)))
   (t (paste (car q) (more-simple-condense p (cdr q))))))

;;;
;;; 二つの遷移表の第一要素が共にアトムである場合の処理を行う。
;;;
;;;     p ::=   (a (b (c)))
;;;     q ::=   (a (f (c (d))))
;;;
;;;     (most-simple-condense p q)
;;;             => (a (b (c)) (f (c (d))))
;;;
(defun most-simple-condense (p q)
  (cond
    ((equal p q) q) ;; added 2026-05-02
    ((atom p) q)
    ((atom q) p)
    ((and ;; (condense '(a b c x) '(a b c y)) => (a b c y) にするためのコード。
     (null (cdr p))
     (null (cdr q)))
     q) ;; (condense '(a b c x) '(a b c y)) => (a b c x) にするなら[p]を返す。
    ((equal (car p) (car q))
     (cons (car p) (condense (cdr p) (cdr q))))
    (t (list p q))))

;;;
;;; GraphViz用のDOT言語形式のテキストを出力する。
;;;     第1引数の[table]には[condense]が生成した遷移表を与える。
;;;     このDOTデータをGraphVizに与えると遷移表の木構造を表すグラフが得られる。
;;;
(defun generate-dot (table fname)
  "遷移表からGraphviz(DOT)形式のデータを出力する"
  (with-open-file (stream fname :direction :output :if-does-not-exist :create :if-exists :supersede)
    (format stream "digraph G {~%")
    (format stream "  node [shape = circle];~%")
    (labels
        (
         (traverse (subtable parent) ;; [subtable]と[parent]を保持するための再帰的局所関数。
           (cond
             ((null subtable)
              nil
              )
             ((atom subtable) ;; 要素がアトムの場合（状態）
              (when parent
                (format stream "  \"~a\" -> \"~a\";~%" parent subtable)
                ) ;; end when
              )
             ((atom (car subtable)) ;; 先頭がアトムの場合 (例: (A B C) や (A (B) (C)))
              (let ((current (car subtable)))
                (when parent
                  (format stream "  \"~a\" -> \"~a\";~%" parent current)
                  ) ;; end when
                (traverse (cdr subtable) current)
                ) ;; end let
              )
             (t ;; 先頭がリストの場合（分岐）
              (dolist (item subtable)
                (traverse item parent)
                ) ;; end dolist
              )
             ) ;; end cond
           )   ;; end traverse
         )
      (traverse table nil)
      ) ;; end labels
    (format stream "}~%")
    ) ;; end with-open-file
  ) ;; end generate-dot

;;;
;;; コマンド文字の列から正規化コマンド文字列のリストを作成する。
;;;
;;; (key-seq-to-normalized-symbol-seq "\\C-\\M-f \\M-p   r")
;;;     => ("meta" "control" "letter-f" "meta" "small-p" "small-r")
;;;
(defun key-seq-to-normalized-symbol-seq (str)
  (unify-control-code (normalize-symbol-seq (key-seq-to-symbol-seq str)))
  )

;;;
;;; コマンド文字列をコマンド名文字列のリストに変換する。
;;;
;;; (key-seq-to-symbol-seq "\\C-\\M-f \\M-p  [delete]  r")
;;;     => ("control" "meta" "small-f" "meta" "small-p" "[delete]" "small-r")
;;;
;;; '[' から ']'までは一つの文字として扱う。'['自体を入力する場合は'\\['と書く。
;;;
;;; > (key-seq-to-normalized-symbol-seq "\\C-\\[ \\[ 3 ~")
;;; ("control" "left-square-bracket" "left-square-bracket" "digit-3" "tilde")
;;;
;;; 例えば \\M-[delete]は ("meta" "[delete]")と変換される。
;;; M-[ は "\\M-\\[", M-] は "\\M-\\["と記す。
;;;
(defun key-seq-to-symbol-seq (str)
  (let (lst result ch word)
    (when (not (stringp str))
      (return-from key-seq-to-symbol-seq nil))
    (setf lst (unpack str))
    (setf result nil)
    (loop
      (if (null lst) (return))
      (setf lst (remove-preceding-white-spaces lst))
      (cond
        ((char= (first lst) +left-square-bracket-ch+) ;; '['から']'まではひとつの文字として扱う。
         (setf word nil)
         (setf ch (pop lst))
         (push ch word)
         (loop
           (if (null lst) (return))
           (setf ch (pop lst))
           (push ch word)
           (if (char= ch +right-square-bracket-ch+) (return)))
         (push (concatenate 'string (reverse word)) result)
         ) ;; end char=
        ((and
          (char= (first lst) +backslash-ch+) ;; \C- or \M- ?
          (>= (length lst) 3)
          (or
           (equal (subseq lst 1 3) +meta-prefix+)
           (equal (subseq lst 1 3) +control-prefix+)
           (equal (subseq lst 1 3) +super-prefix+)
           )
          )
         (pop lst) ;; remove backslash.
         (cond
           ((char= (first lst) (first +control-prefix+))
            (setf lst (cdr lst))
            (push +control-string+ result))
           ((char= (first lst) (first +meta-prefix+))
            (setf lst (cdr lst))
            (push +meta-string+ result))
           ((char= (first lst) (first +super-prefix+))
            (setf lst (cdr lst))
            (push +super-string+ result))
           )
         ) ;; end and
        ((char= (first lst) +backslash-ch+) ;; stand alone backslash.
         (pop lst)
         (when (not (null lst))
           (push (gryph-to-description (first lst)) result))
         )
        (t
         (push (gryph-to-description (first lst)) result))
        ) ;; end cond
      (pop lst)
      ) ;; end loop
    (reverse result)
    ) ;; end let
  ) ;; end key-seq-to-symbol-seq

;;;
;;; [normalize-symbol-seq]関数の定義。Controlと Metaの二重修飾子を "\\M-\\C-x"の形式に統一する。
;;;
;;; ("control" "meta" "small-a") => ("meta" "control" "small-a")
;;; ("control" "meta" "small-f" "meta" "small-p" "small-r")
;;;     => ("meta" "control" "small-f" "meta" "small-p" "small-r")
;;;

;;; 修飾キーかどうかを判定する補助関数
;;; (defconstant +modifier-priority+ (list +super-string+ +meta-string+ +control-string+))
(defun modifier-p (symbol-name)
  (and
   (stringp symbol-name)
   (member symbol-name +modifier-priority+ :test #'string=)
   ) ;; end and
  ) ;; end modifier-p

;;; リストの先頭から連続する修飾キーだけを抽出する補助関数
(defun extract-modifiers (lst)
  (if (and lst (modifier-p (car lst)))
      (cons (car lst) (extract-modifiers (cdr lst)))
      nil)
  ) ;; end extract-modifiers

;;; 正規化関数の本体
;;;
;;; <command> ::= <modifier>* <modified-char> <char>* ;
;;; <modifier> ::= <super> | <meta> | <control> ;
;;; <modified-char> ::= <letter-a>...<letter-z> | <printable-char> ;
;;;
(defun normalize-symbol-seq (lst)
  (cond
    ((or
      (null lst)
      (atom lst)
      )
     lst
     )
    ;; 先頭が修飾キーの場合の処理。Meta, Controlに加えてSuperキーを追加した版。更に追加可能。
    ((modifier-p (car lst))
     (let* ((modifiers (extract-modifiers lst)) ;; 修飾キーの塊を抽出
            (rest-list (nthcdr (length modifiers) lst))) ;; 残りのリストを取得
       (setf modifiers (remove-duplicates modifiers :test #'string-equal)) ;; [Super] [Super]などを縮約。

       (append
        ;; 抽出した修飾キーのみを優先順位でソート
        ;; (defconstant +modifier-priority+ (list +super-string+ +meta-string+ +control-string+))
        (sort modifiers
              #'(lambda (a b)
                (< (position a +modifier-priority+ :test #'string=)
                   (position b +modifier-priority+ :test #'string=)
                   )
                ) ;; end lambda
              )   ;; end sort
        ;; 残りの部分は再帰的に処理（Meta Meta a のようなケースにも対応）
        (normalize-symbol-seq rest-list)
        ;;rest-list
        )
       ) ;; end let
     )
    ;; 先頭が修飾キーでない場合は、そのまま次へ
    (t
     (cons (car lst) (normalize-symbol-seq (cdr lst)))
     )
    ) ;; end cond
  ) ;; end normalize-symbol-seq

;;;
;;; コントロール・コードと組み合わせる英字を統一する。
;;;
;;; ("meta" "control" "capital-f" "meta" "small-p" "small-r")
;;;     => ("meta" "control" "letter-f" "meta" "small-p" "letter-r")
;;;
(defun unify-control-code (lst)
  (cond
   ((null lst) nil)
   ((atom lst) lst)
   ((null (cdr lst)) lst)
   ((string= (car lst) +control-string+)
    (append (unified-control-symbol (cadr lst)) (unify-control-code (cddr lst))))
   (t (cons (car lst) (unify-control-code (cdr lst))))))

;;;
;;; コントロール・コードと組み合わせる英字を大小文字のない文字に統一した
;;; コントロール・コード・シンボルを返す。
;;;
(defun unified-control-symbol (sym)
  (list +control-string+ (unified-symbol sym)))

;;;
;;; 大文字・小文字を統一する。
;;;
(defun unified-symbol (str)
  (cond
    ((or (string= str +capital-A+) (string= str +small-a+))     +letter-a+)
    ((or (string= str +capital-B+) (string= str +small-b+))     +letter-b+)
    ((or (string= str +capital-C+) (string= str +small-c+))     +letter-c+)
    ((or (string= str +capital-D+) (string= str +small-d+))     +letter-d+)
    ((or (string= str +capital-E+) (string= str +small-e+))     +letter-e+)
    ((or (string= str +capital-F+) (string= str +small-f+))     +letter-f+)
    ((or (string= str +capital-G+) (string= str +small-g+))     +letter-g+)
    ((or (string= str +capital-H+) (string= str +small-h+))     +letter-h+)
    ((or (string= str +capital-I+) (string= str +small-i+))     +letter-i+)
    ((or (string= str +capital-J+) (string= str +small-j+))     +letter-j+)
    ((or (string= str +capital-K+) (string= str +small-k+))     +letter-k+)
    ((or (string= str +capital-L+) (string= str +small-l+))     +letter-l+)
    ((or (string= str +capital-M+) (string= str +small-m+))     +letter-m+)
    ((or (string= str +capital-N+) (string= str +small-n+))     +letter-n+)
    ((or (string= str +capital-O+) (string= str +small-o+))     +letter-o+)
    ((or (string= str +capital-P+) (string= str +small-p+))     +letter-p+)
    ((or (string= str +capital-Q+) (string= str +small-q+))     +letter-q+)
    ((or (string= str +capital-R+) (string= str +small-r+))     +letter-r+)
    ((or (string= str +capital-S+) (string= str +small-s+))     +letter-s+)
    ((or (string= str +capital-T+) (string= str +small-t+))     +letter-t+)
    ((or (string= str +capital-U+) (string= str +small-u+))     +letter-u+)
    ((or (string= str +capital-V+) (string= str +small-v+))     +letter-v+)
    ((or (string= str +capital-W+) (string= str +small-w+))     +letter-w+)
    ((or (string= str +capital-X+) (string= str +small-x+))     +letter-x+)
    ((or (string= str +capital-Y+) (string= str +small-y+))     +letter-y+)
    ((or (string= str +capital-Z+) (string= str +small-z+))     +letter-z+)
    (t  str)))

;;;
;;; #\Space から#\~ までの図形文字に対する descriptionを返す。
;;; 非図形文字を渡すと文字コードを表す "[0xa0]" という形式の
;;; 2桁の16進数で表された文字列を返す（小文字）。
;;;
(defun gryph-to-description (ch)
  (declare (type character ch))
  (case ch
    (#\a        +small-a+)
    (#\b        +small-b+)
    (#\c        +small-c+)
    (#\d        +small-d+)
    (#\e        +small-e+)
    (#\f        +small-f+)
    (#\g        +small-g+)
    (#\h        +small-h+)
    (#\i        +small-i+)
    (#\j        +small-j+)
    (#\k        +small-k+)
    (#\l        +small-l+)
    (#\m        +small-m+)
    (#\n        +small-n+)
    (#\o        +small-o+)
    (#\p        +small-p+)
    (#\q        +small-q+)
    (#\r        +small-r+)
    (#\s        +small-s+)
    (#\t        +small-t+)
    (#\u        +small-u+)
    (#\v        +small-v+)
    (#\w        +small-w+)
    (#\x        +small-x+)
    (#\y        +small-y+)
    (#\z        +small-z+)
    (#\A        +capital-A+)
    (#\B        +capital-B+)
    (#\C        +capital-C+)
    (#\D        +capital-D+)
    (#\E        +capital-E+)
    (#\F        +capital-F+)
    (#\G        +capital-G+)
    (#\H        +capital-H+)
    (#\I        +capital-I+)
    (#\J        +capital-J+)
    (#\K        +capital-K+)
    (#\L        +capital-L+)
    (#\M        +capital-M+)
    (#\N        +capital-N+)
    (#\O        +capital-O+)
    (#\P        +capital-P+)
    (#\Q        +capital-Q+)
    (#\R        +capital-R+)
    (#\S        +capital-S+)
    (#\T        +capital-T+)
    (#\U        +capital-U+)
    (#\V        +capital-V+)
    (#\W        +capital-W+)
    (#\X        +capital-X+)
    (#\Y        +capital-Y+)
    (#\Z        +capital-Z+)
    (#\0        +digit-0+)
    (#\1        +digit-1+)
    (#\2        +digit-2+)
    (#\3        +digit-3+)
    (#\4        +digit-4+)
    (#\5        +digit-5+)
    (#\6        +digit-6+)
    (#\7        +digit-7+)
    (#\8        +digit-8+)
    (#\9        +digit-9+)
    (#\+        +plus-sign+)
    (#\<        +less-than-sign+)
    (#\=        +equals-sign+)
    (#\>        +greater-than-sign+)
    (#\$        +dollar-sign+)
    (#\`        +backquote+)
    (#\^        +circumflex-accent+)
    (#\~        +tilde+)
    (#\#        +sharp-sign+)
    (#\%        +percent-sign+)
    (#\&        +ampersand+)
    (#\*        +asterisk+)
    (#\@        +at-sign+)
    (#\[        +left-square-bracket+)
    (#\\        +backslash+)
    (#\]        +right-square-bracket+)
    (#\{        +left-brace+)
    (#\|        +vertical-bar+)
    (#\}        +right-brace+)
    (#\!        +exclamation-mark+)
    (#\"        +double-quote+)
    (#\'        +single-quote+)
    (#\(        +left-parenthesis+)
    (#\)        +right-parenthesis+)
    (#\,        +comma+)
    (#\_        +underscore+)
    (#\-        +minus-sign+)
    (#\.        +period+)
    (#\/        +slash+)
    (#\:        +colon+)
    (#\;        +semicolon+)
    (#\?        +question-mark+)
    (#\Space    +space+)
    (otherwise  (make-description ch) )))

(defun make-description (ch)
  (declare (type character ch))
  (string-downcase (format nil "[\#x~2,'0x]" (char-code ch)))
  ) ;; end make-description

(defun remove-preceding-white-spaces (lst)
  (loop
    (when (null lst) (return-from remove-preceding-white-spaces nil))
    (when (not (white-space-p (car lst)))
        (return-from remove-preceding-white-spaces lst))
    (pop lst)))

(defun control-prefix-p (lst)
  (and
   (char= (first lst) (first +control-prefix+))
   (char= (second lst) (second +control-prefix+))))

(defun meta-prefix-p (lst)
  (and
   (char= (first lst) (first +meta-prefix+))
   (char= (second lst) (second +meta-prefix+))))

;;;
;;; 遷移表の遷移キーの第1要素レベルをソートする。
;;;
;;(defun sort-first-level (keymap)
;;  (stable-sort keymap #'char< :key #'car))

;; 大文字小文字を区別して読み込む。
(defun case-sensitive-read (&optional input-stream eof-error-p eof-value recursive-p)
  (let ((*readtable* *case-sensitive-readtable*))
    ;;(read input-stream eof-error-p eof-value recursive-p)
    (handler-case (read input-stream eof-error-p eof-value recursive-p)
      (end-of-file () (message :line-edit-pkg+case-sensitive-read-001 "括弧が足りません。~%") eof-value)
      (error (c) (message :line-edit-pkg+case-sensitive-read-002 "その他のエラー: ~a~%" c) eof-value)
      ) ;; end handler-case
    ) ;; end let
  )   ;; end case-sensitive-read

;;
;; 遷移表を作成するためのシンボルが記述されたファイルを読み込んで内容をリストにしたものを返す。
;;
;; 最もシンプルなファイル形式はシンボルを列記したファイル。記述されたシンボル名を大文字小文字の区別ありで
;; 読み込む。シンボル名のみを列記したファイルは、シンボル名を文字列に変換して取り込まねばならず、そのため
;; にキーワード引数[:return-as-string]に[t]を与える。デフォルトは[t]。
;;
(defun read-keyword-file (in-file &optional (verbose (verbose-message)))
  "引数で指定されたファイルがあれば、その内容(シンボル)を読み込んで返す。"
  (let ((result nil))
    (if (null in-file) (return-from read-keyword-file nil))
    (with-open-file (stream in-file :direction :input :if-does-not-exist nil)
      (do* ((eos (cons nil nil))
            (data (case-sensitive-read stream nil eos nil) ;; (<変数> <初期値> <ステップ>)
                  (case-sensitive-read stream nil eos nil)) ) ;; <-- ステップ。
           ((eq data eos) (reverse result)) ;; (<終了条件> <式-1>...<式-n>)

        (push data result)
        ) ;; end do*
      )   ;; end with-open-file
    (when (and result verbose)
      (format t "keyword-file ~a loaded.~%" in-file)
      )
    (return-from read-keyword-file result)
    ) ;; end let
  ) ;; end read-keyword-file

;;
;; 引数情報付きキーワードの参照時刻と参照回数を記録した最新の情報を保存する。
;;      前回記録したファイルは末尾に".backup"を付加して保存される。
;;      前々回以前のファイルは削除される。
;;
(defun write-keyword-file-with-backup
    (&optional (out-file *syntax-info-file*) (info-list *syntax-info-list*))
  (let (credit-string backup-file-exist backup-file abs-out-file)
    (setf credit-string
"
;;; ===========================================================================
;;; Completion Dictionary Data
;;;
;;; The syntax information for Common Lisp symbols was derived from:
;;; 1. Common Lisp HyperSpec (CLHS) by Kent M. Pitman (LispWorks).
;;;    (c) 1996-2005 LispWorks.
;;; 2. Slim-CLHS project by Inaimathi (GitHub), which provides extracted 
;;;    one-line syntax summaries for ANSI CL symbols.
;;;
;;; Combined and formatted for 'line-edit-pkg' by Gemini (Google AI) 2025.
;;; Modified by Isao Daigo.
;;; ===========================================================================
;;
;; <syntax-info>        ::= ( <name> :last-access <time> :count <count-number> <type> <info> ) ;;
;; <name>               ::= <string> ;;
;; <time>               ::= {1900年1月1日0時0分0秒からの経過秒数} ;; universal-time.
;; <count-number>       ::= {定義本体が採用された回数} ;;
;; <type>               ::= :function | :macro | :special | :constant | :class 
;;                              | :declaration | :document | :type ;;
;; <info>               ::= {情報本体(文字列)} ;;
;;
;; <time>と<count>の初期値は[0(zero)]。
"
)

    (when (debug-print-p "write-keyword-file-with-backup(1)")
      (format t "credit-string=~s~%" credit-string)
      (format t "out-file(1)=~s~%" out-file)
      ) ;; end when

    (if (or (null out-file) (not (stringp out-file)))
        (return-from write-keyword-file-with-backup nil)
        ) ;; end if

    (when (probe-file (config-file-abs-path out-file))          ;; 存在するならバックアップ・ファイルに変更。
      (setf abs-out-file (config-file-abs-path out-file))       ;; 絶対パス名に変えておく。

      (when (debug-print-p "write-keyword-file-with-backup(2)")
        (format t "out-file(2)=~s~%" out-file)
        ) ;; end when

      (setf backup-file (concatenate 'string abs-out-file ".backup"))   ;; バックアップ用に名前を変更する。
    
      (when (debug-print-p "write-keyword-file-with-backup(3)")
        (format t "backup-file=~s~%" backup-file)
        )

      (setf backup-file-exist (probe-file backup-file)) ;; バックアップ・ファイルが存在するかチェック。
      (when backup-file-exist
        (delete-file backup-file) ;; 存在するならば削除。
        ) ;; end when
      (rename-file abs-out-file backup-file) ;; 現在の[*syntax-info-file*]をバックアップ・ファイルに変更。
      ) ;; end when

    ;; [*syntax-info-file*]に最新の内容を書き込む。
    (with-open-file
        (stream abs-out-file :direction :output :if-does-not-exist :create :if-exists :supersede)

      ;;(format t  "out-file=~s, *syntax-info-file*=~s~%" out-file *syntax-info-file*)
      (when (string-equal out-file *syntax-info-file*)
        (format stream "~a~%" credit-string)
        ) ;; end when

      (dolist (p (reverse info-list)) ;; 読み込んだときに逆順になっているので再度逆順にして書き出す。
        (format stream "~s~%" p)
        ) ;; end dolist
      ) ;; end with-open-file
    ) ;; end let
  ) ;; end write-keyword-file-with-backup

(defun user-keymap-added-p ()
  *user-keymap-added-p*
  )

(defun save-completion-dictionaries ()
  ;;(write-keyword-file-with-backup *syntax-info-file* *syntax-info-list*) ;; 基本的に変化しないので不要。
  (write-keyword-file-with-backup *user-info-file* *user-info-list*)
  )

;;
;; <syntax-info>        ::= ( <name> :last-access <time> :count <count-number> <type> <info> ) ;;
;; <name>               ::= <string> ;;
;; <time>               ::= {1900年1月1日0時0分0秒からの経過秒数} ;;
;; <count-number>       ::= {定義本体が採用された回数} ;;
;; <type>               ::= :function | :macro | :special | :constant | :class | :declaration |
;;                          :document | :type ;;
;;
(defun get-syntax-name (syntax-info)
  (first syntax-info)
  )

(defun get-syntax-last-access-time (syntax-info)
  (nth 2 syntax-info)
  )

(defun set-syntax-last-access-time (syntax-info &optional (new-access-time (get-universal-time)))
  (setf (nth 2 syntax-info) new-access-time)
  )

(defun get-syntax-count (syntax-info)
  (nth 4 syntax-info)
  )

(defun set-syntax-count (syntax-info &optional (new-count nil))
  (when (null new-count)
    (setf new-count (+ 1 (get-syntax-count syntax-info))) ;; デフォルトは前回のカウント数+1。
    ) ;; end when
  (when (not (numberp new-count))
    (error "line-edit-pkg::set-syntax-count: 第2引数(~s)は[nil]か数値のみ許されます。~%" new-count)
    )
  (setf (nth 4 syntax-info) new-count)
  )

;; [syntax-info]内の<count-number>の値を1増やす。
(defun increment-syntax-count (syntax-info)
  (incf (nth 4 syntax-info))
  )

(defun get-syntax-type (syntax-info)
  (nth 5 syntax-info)
  )

(defun get-syntax-info-body (syntax-info)
  (nth 6 syntax-info)
  )

;;
;; 補完候補の優先順位を計算する指数減衰スコアの半減期を設定/読み出す。
;;
(declaim (ftype (function (&optional t) t) half-life-sec))
(declaim (ftype (function (&optional t) t) half-life-hour))

(let (
      (priority-half-life +priority-half-life-init+)
      )

  (defun half-life-sec (&optional (sec nil sw) ) ;; defafult=14日(秒単位)。
    (cond
      ((and ;; 引数がなく、かつ[priority-half-life]が整数ならば[priority-half-life]を返す。
        (null sw)
        (integerp priority-half-life)
        )
       priority-half-life
       )
      ((and ;; 引数がなく、かつ[priority-half-life]が整数でないなら初期値に設定し直し、初期値を返す。
        (null sw)
        (not (integerp priority-half-life))
        )
       (setf priority-half-life +priority-half-life-init+)
       )
      ((and ;; 引数に整数が指定されていれば、引数を[priority-half-life]に設定して、引数の値を返す。
        (identity sw)
        (integerp sec)
        )
       (setf priority-half-life sec)
       )
      ((and ;; 引数が指定されているが整数でない場合は[priority-half-life]に初期値に設定し直し、初期値を返す。
        (identity sw)
        (not (integerp sec))
        )
       (setf priority-half-life +priority-half-life-init+)
       )
      ) ;; end cond
    )   ;; end priority-half-life

  (defun half-life-hour (&optional (hour nil))
    (cond
      ((null hour)
       (floor (/ (half-life-sec) 60))
       )
      ((integerp hour)
       (half-life-sec (* hour 60 60))
       )
      (t
       (warn "half-life-hour: argument shuld be [nil] or integer.~%")
       )
      ) ;; end cond
    )   ;; end half-life-hour

  ) ;; end let

;;
;; [syntax-info]の前回参照時刻と定義が採用された回数情報を総合して優先度を計算する。
;;
;; 優先順位の計算には指数減衰スコアを使用する。
;;
;;      Count:採用回数。
;;      deltaT:現在時刻と最終参照時刻の差。
;;      tau(タウ):半減期。
;;
;;      Score = Count x 0.5^(deltaT/tau)
;;
;; <syntax-info> ::= ( <name> :last-access <time> :count <count-number> <type> <info> ) ;;
;; <name> ::= <string> ;;
;; <time> ::= {1900年1月1日0時0分0秒からの経過秒数} ;; universal-time.
;; <count-number> ::= {定義本体が採用された回数} ;;
;; <type> ::= :function | :macro | :special | :constant | :class | :declaration | :document | :type ;;
;; <info> ::= {情報本体(文字列)} ;;
;;
(defun calculate-priority (syntax-info reference-time &optional (tau (half-life-sec)))
  (let* ((last-access-time (get-syntax-last-access-time syntax-info))
         (time-diff (max 0 (- reference-time last-access-time))) ;; 時計の狂いなどで負の値になるのを防止。
         (count (get-syntax-count syntax-info))
         )

    (handler-case
        (* (log (1+  count) 10) (expt 0.5d0 (/ time-diff tau))) ;; double float.
      (floating-point-underflow () 0.0d0))
    ) ;; end let*
  ) ;; end calculate-priority

;;
;; ソート時点での補完候補のスコアを元に優先順位の高い順に整列する。
;;
(defun sort-by-priority (syntax-info-list)
  (let ((lst (copy-list syntax-info-list))
        (reference-time (get-universal-time))) ;; ソート中に基準時刻が変化しないように固定。
    (stable-sort lst #'> :key (lambda (info) (calculate-priority info reference-time)))
    ) ;; end let
  ) ;; end sort-by-priority

;;;
;;; <character-group>内の要素のcarが[ch]であるリストを返す。
;;;
;;; <code>                      ::= <atom> ;
;;; <body>                      ::= <generalized-object> ;
;;; <character-group>           ::= ( <code>+ (<character-group>)+ ) |  ( <code>+ <body> ) ;
;;;
(defun search-key-by-char (ch transition-table)
  (dolist (p transition-table)
    (when (and (characterp (first p)) (char= ch (first p)))
      (return-from search-key-by-char p)
      ) ;; end when
    ) ;; end dolist
  (return-from search-key-by-char nil)
  ) ;; end search-key-by-char

(defun case-sensitive-read-from-string (str &optional eof-error-p eof-value)
  (let ((*readtable* *case-sensitive-readtable*))
    (handler-case
        (read-from-string str eof-error-p eof-value)
      (end-of-file ()
        (message :line-edit-pkg+case-sensitive-read-from-string-001 "括弧が足りません。~%") eof-value)
      (error (c)
        (message :line-edit-pkg+case-sensitive-read-from-string-002 "その他のエラー: ~a~%" c) eof-value)
      ) ;; end handler-case
    ) ;; end let
  )   ;; end case-sensitive-read-from-string


  ;;
  ;; シンボル一覧のリストから関数[complete-symbol]用のinfo-listを作成する。
  ;; このinfo-listから関数[make-completion-keymap]で遷移表[keymap]を作成する。
  ;;
  ;; => (("blink-paren" :|last-access| 0 :|count| 0 :|function| "line-edit-pkg:blink-paren")..)
  ;;
  (defun make-info-list (pkg-name &optional  (symbol-kind :external))
    (let (
          (str "")
          (pkg nil)
          (sym-lst nil)
          (result nil)
          (q nil)
          (process-ok t)
          info
          num
          temp
          )

      (cond
        ((find-package pkg-name) ;; パッケージか？
         (setf pkg-name (string-downcase (package-name pkg-name)))
         )
        ((symbolp pkg-name) ;; シンボル名か？
         (setf pkg-name (string-downcase (symbol-name pkg-name)))
         )
        ((stringp pkg-name) ;; 文字列か？
         (setf pkg-name (string-downcase pkg-name))
         )
        (t
         (warn "make-info-list: Argument must be package, symbol or string.~%")
         )
        ) ;; end cond

      (setf pkg (find-package (string-upcase pkg-name))) ;; パッケージ名は一般的に大文字。
      (cond
        ((equal symbol-kind :external)
         (multiple-value-setq (sym-lst num) (package-util:get-external-symbols pkg))
         )
        ((equal symbol-kind :internal)
         (multiple-value-setq (sym-lst num) (package-util:get-internal-symbols pkg))
         )
        ((equal symbol-kind :inherited)
         (multiple-value-setq (sym-lst num) (package-util:get-inherited-symbols pkg))
         )
        ) ;; end cond

      (setf result nil)
      (setf process-ok t)
      (dolist (p sym-lst)

        (cond
          ((equal symbol-kind :external)
           (setf q (string-downcase (concatenate 'string pkg-name ":" (symbol-name p))))
           )
          ((equal symbol-kind :internal)
           (setf q (string-downcase (concatenate 'string pkg-name "::" (symbol-name p))))
           )
          ((and
            (equal symbol-kind :inherited)
            (not (member p (packages-exception-list) :test #'string-equal))
            )
           (setf temp (package-name (symbol-package p)))
           (setf q (string-downcase (concatenate 'string temp ":" (symbol-name p))))
           )
          (t
           (setf process-ok nil)
           )
          ) ;; end cond

        (when process-ok
          ;;(format t "(symbol-attribute ~s)=~s~%" p (symbol-attribute p))
          (if (equal symbol-kind :inherited)
              (setf str (format nil "(~s :last-access 0 :count 0 :inherited-~a ~s)"
                                (string-downcase (symbol-name p))
                                (string-downcase (symbol-name (symbol-attribute p)))
                                q
                                ) ;; end format
                    )             ;; end setf
              (setf str (format nil "(~s :last-access 0 :count 0 :~a ~s)"
                                (string-downcase (symbol-name p))
                                (string-downcase (symbol-name (symbol-attribute p)))
                                q
                                ) ;; end format
                    )
              ) ;; end if

          ;;(format t "str=~s~%" str)
          (setf info (case-sensitive-read-from-string str nil +eos+))
          ;;(format t "info=~s~%" info)
          (push info result)
          (setf process-ok t)
          ) ;; end when

        ) ;; end dolist

      (values (reverse result) num)
      ) ;; end let
    )   ;; end make-info-list

  ;;
  ;; 関数[make-completion-keymap]のラッパー関数。
  ;; パッケージのexternal,internal,inherited 各シンボルを対象とした遷移表を作成する。
  ;; ただし[:common-lisp]パッケージは引数情報付きの遷移表を用意してあるので対象外。
  ;;
  (defun make-package-symbol-completion-keymap (pkg-name &optional (symbol-kind :external))
    (let ((keymap nil) temp num)

      (cond
        ((find-package pkg-name)
         (setf pkg-name (string-downcase (package-name pkg-name)))
         )
        ((symbolp pkg-name)
         (setf pkg-name (string-downcase (symbol-name pkg-name)))
         )
        ((stringp pkg-name)
         (setf pkg-name (string-upcase pkg-name))
         )
        (t
         (warn "make-package-symbol-completion-keymap: Argument must be package, symbol or string.~%")
         )
        ) ;; end cond

      (when (not (member  pkg-name (packages-exception-list) :test #'string-equal))
        (multiple-value-setq (temp num) (make-info-list pkg-name symbol-kind))
        (setf keymap (make-completion-keymap temp))
        ) ;; end when

      (return-from make-package-symbol-completion-keymap (values keymap num))
      ) ;; end let
    )   ;; end make-current-external-symbol-completion-keymap

  ;;
  ;; 引数がパッケージのニックネームか否かを返す。
  ;;
  (defun package-nickname-p (name)
    (let ((pkg (find-package name)))
      (and pkg
           (member (string name) (package-nicknames pkg) :test #'string-equal)
           )
      ) ;; end let
    ) ;; end package-nickname-p

  ;;
  ;; パッケージ名用の補完リストを作成する関数。
  ;;
  ;;    ニックネーム → ニックネーム、プロパーネーム
  ;;    プロパーネーム → プロパーネーム、(find-package プロパーネーム)
  ;;
  (defun make-info-list-for-package ()
    (let (
          (pkg-lst nil)
          (nickname-list nil)
          (str "")
          (result nil)
          (info nil)
          (eos (cons nil nil))
          )
      ;; システム内のすべてのパッケージ名文字列をソートしたリストを得る。
      (setf pkg-lst (sort (mapcar #'package-name (list-all-packages)) #'string<))

      (when (debug-print-p "make-info-list-for-package")
        (format t "pkg-list=~s~%" pkg-lst)
        )

      (dolist (p pkg-lst)
        (when (not (member p (package-exclusion-list) :test #'string-equal))
          (setf nickname-list (package-name-case-list-convert (package-nicknames p)))
          (cond
            ((null nickname-list) ;; ニックネームが存在しないときはパッケージ名→(find-package パッケージ名)。
             ;;(format t "p=~s~%" p)
             (setf str (format nil "(~s :last-access 0 :cont 0 :package ~s)"
                               (package-name-case-convert p)
                               (package-name-case-convert (concatenate 'string "(find-package :" p ")"))
                               ) ;; end format
                   )             ;; end setf
             ;;(format t "str(1)=~s~%" str)
             (setf info (case-sensitive-read-from-string str nil eos))
             ;;(format t "info(1)=~s~%" info)
             (pushnew info result)
             )
            (t ;; ニックネームが存在するときはニックネーム→プロパーネーム「も」追加する。
             (dolist (q nickname-list)
               ;;--------------------------------------------------------
               (setf str (format nil "(~s :last-access 0 :count 0 :package ~s)"
                                 (package-name-case-convert q)
                                 (package-name-case-convert p)
                                 ) ;; end format
                     )             ;; end setf
               ;;(format t "str(2)=~s~%" str)
               (setf info (case-sensitive-read-from-string str nil eos))
               ;;(format t "info(2)=~s~%" info)
               (pushnew info result)
               ) ;; end dolist
             ;;--------------------------------------------------------
             (setf str
		   (format nil "(~s :last-access 0 :count 0 :package ~s)"
			   (package-name-case-convert p)
			   (package-name-case-convert
			    (concatenate 'string "(package-nicknames :" p ")"))
                               ) ;; end format
                   )             ;; end setf
             ;;(format t "str(3)=~s~%" str)
             (setf info (case-sensitive-read-from-string str nil eos))
             ;;(format t "info(3)=~s~%" info)
             (pushnew info result)
             ;;--------------------------------------------------------
             ) ;; end [t]
            )  ;; end cond
          )    ;; end when
        )        ;; end dolist

      (values (reverse result) (length result))
      ) ;; end let
    ) ;; end make-info-list-for-package

;;
;; 補完機能のための遷移表を作成する関数。
;;
;; 同じ要素を追加しても遷移表には重複登録されない。
;; 
;; > (time (dotimes (i 1000)
;;         (line-edit-pkg::make-completion-keymap
;;          (line-edit-pkg::make-info-list :line-edit-pkg))))
;;
;; Evaluation took:
;;   0.361 seconds of real time
;;   0.360626 seconds of total run time (0.348697 user, 0.011929 system)
;;   [ Real times consist of 0.007 seconds GC time, and 0.354 seconds non-GC time. ]
;;   [ Run times consist of 0.006 seconds GC time, and 0.355 seconds non-GC time. ]
;;   100.00% CPU
;;   763,259,177 processor cycles
;;   520,401,600 bytes consed
;;
;; 13th Gen intel Core i7-13700 × 24/64GB Ubuntu 24.04.3 LTS
;; 外部シンボル数319個を取得して遷移表を作成するまで1回当たり0.361/1000秒(約1/3000秒)。
;; => 人間の検知限界(1/100秒)の約30倍速いのでリアルタイムに実行しても大丈夫。
;; => 約30倍遅いのはCore i3クラスだがメモリ速度を考えると2015年頃のCore i5クラスまでが快適使用の限界と推定。
;;
(defun make-completion-keymap (&optional (info-list *syntax-info-list*))
  (let ((result nil) (lst nil))
    (dolist (s info-list)
      (setf lst (append (unpack (car s)) (list s)))
      (setf result (condense result lst))
      ) ;; end dolist
    (return-from make-completion-keymap result)
    ) ;; end let
  ) ;; end make-completion-keymap

;;
;; 引数で与えられたリスト内の補完候補の全ての定義本体を返す。
;;
;; [sbcl:(27.2MB)16:00:07 #2153]> (format t "~s~%" a)
;; ((#\a #\b
;;   (#\o #\r #\t ("abort" :FUNCTION "syntax: abort &optional condition = |"))
;;   (#\s ("abs" :FUNCTION "syntax: abs number = absolute-value")))
;;  (#\z #\e #\r #\o #\p
;;   ("zerop" :FUNCTION "syntax: zerop number = generalized-boolean")))
;; NIL
;; [sbcl:(28.1MB)16:00:38 #2154]> (format t "~s~%" (get-completion-body-in-list a))
;; (("abort" :FUNCTION "syntax: abort &optional condition = |")
;;  ("abs" :FUNCTION "syntax: abs number = absolute-value")
;;  ("zerop" :FUNCTION "syntax: zerop number = generalized-boolean"))
;; NIL
;;   
(defun get-completion-body-in-list (&optional (lst *current-completion-keymap*))
  (cond
    ((null lst)
     nil)
    ((stringp (car lst))
     (list lst) )
    ((and
      (characterp (car lst))
      (stringp (car (cdr lst))) )
     (list (cdr lst)) )
    ((and
      (characterp (car lst))
      (identity (cdr lst)) )
     (get-completion-body-in-list (cdr lst)) )
    ((and
      (listp (car lst))
      (null (cdr lst)) )
     (get-completion-body-in-list (car lst)) )
    ((and
      (listp (car lst))
      (identity (cdr lst)) )
     (append (get-completion-body-in-list (car lst)) (get-completion-body-in-list (cdr lst))) )
    ) ;; end cond
  ) ;; end get-completion-body-in-list

#+ debug
(defun debug-get-matched-candidates (num char-list char-group)
  (when (debug-print-p "get-matched-candidates")
    (format t "(~d) char-list=~s~%" num char-list)
    (format t "(~d) char-group=~s~%" num char-group)
    (finish-output)
    )
  )

;;
;; 補助関数。
;; [get-matched-candidates]の引数はアトムのリストを許したいが、文字の場合は大文字/小文字の区別をしないための関数。
;;
(defun case-insensitive-equal (p q)
  (cond
    ((and (characterp p) (characterp q))
     (char-equal p q)
     )
    (t
     (equal p q)
     )
    ) ;; end cond
  ) ;; end case-insensitive-equal

;;;
;;; Trie木である[keymap]内の先頭が[atom-list]に一致するすべての候補の本体を返す。
;;;
;;; (get-matched-candidates "write") ==>
;;;  ((write-sequence last-access 0 count 0 function
;;;    write-sequence seq stream &key start end => seq)
;;;   (write-string last-access 0 count 0 function
;;;    write-string string &optional stream &key start end => string)
;;;   (write-line last-access 0 count 0 function
;;;    write-line string &optional stream &key start end => string)
;;;   (write-char last-access 0 count 0 function
;;;    write-char character &optional stream => character)
;;;   (write-byte last-access 0 count 0 function write-byte byte stream => byte)
;;;   (write-to-string last-access 0 count 0 function
;;;    write-to-string object &key escape radix base circle pretty level length case gensym array => string)
;;;   (write last-access 0 count 0 function
;;;    write object &key stream escape radix base circle pretty level length case gensym array => object))
;;;
(defun get-matched-candidates (atom-list keymap)
  (let ( (target-keymap nil) (result nil) sym)

    ;; [keymap]が[nil]なら[nil]を返す。
    (when (null keymap)
      (message :line-edit-pkg+get-matched-candidates-001 "遷移表が空です。~%")
      (return-from get-matched-candidates nil)
      )

    (when (null keymap)
      (return-from get-matched-candidates nil)
      )
    (setf target-keymap (copy-seq keymap))

    (loop
      (setf sym (first atom-list))
      #+ :debug (debug-get-matched-candidates 1 atom-list target-keymap) ;; (1)
      (cond
        ((null atom-list)
         (if (null target-keymap)
             (return-from get-matched-candidates nil)
             (return-from get-matched-candidates (get-completion-body-in-list target-keymap))
             ) ;; end if
         )
        ((null target-keymap)
         #+ :debug (debug-get-matched-candidates 2 atom-list target-keymap) ;; (2)
         (return-from get-matched-candidates nil)
         )
        ((atom target-keymap)
         #+ :debug (debug-get-matched-candidates 3 atom-list target-keymap) ;; (3)
         (return-from get-matched-candidates nil)
         )
        ((and
          (listp target-keymap)                 ;; リスト。
          (atom (first target-keymap))          ;; 先頭はアトム。
          (case-insensitive-equal sym (first target-keymap)) ;; 先頭が一致。
          )
         (pop atom-list) ;; 次のアトムに対して以降を調べる。
         (setf target-keymap (cdr target-keymap))
         #+ :debug (debug-get-matched-candidates 4 atom-list target-keymap) ;; (4)
         )
        ((and
          (listp target-keymap)                 ;; リスト。
          (atom (first target-keymap))          ;; 先頭はアトム。
          (not (case-insensitive-equal sym (first target-keymap))) ;; 先頭はアトムだが一致しない。
          )
         #+ :debug (debug-get-matched-candidates 5 atom-list target-keymap) ;; (5)
         (return-from get-matched-candidates nil)
         )
        ((and
          (listp target-keymap)         ;; リスト。
          (listp (first target-keymap)) ;; 先頭もリスト。
          )
         #+ :debug (debug-get-matched-candidates 6 atom-list target-keymap) ;; (6)
         (setf result nil)
         (dolist (p target-keymap)
           (setf result (get-matched-candidates atom-list p))
           (when (identity result)
             (return-from get-matched-candidates result)
             ) ;; end when
           )   ;; end dolist
         #+ :debug (debug-get-matched-candidates 7 atom-list target-keymap) ;; (7)
         (return-from get-matched-candidates nil)
         ) ;; end [and]
        )  ;; end cond
      )    ;; end loop

    ) ;; end let
  ) ;; end get-matched-candidates

;;;
;;; 先頭文字列が[str]に一致する候補全てのリストを返す。一致する候補がなければ[nil]を返す。
;;; [str]に[nil]または空文字列[""]を与えたときは[keymap]内の全ての候補を返す。
;;;
;;; <code>              ::= <atom> ;
;;; <body>              ::= <generalized-object> ;
;;; <transition>        ::= ( <code>* <transition-table>+ ) |  ( <code>+ <body> ) ;
;;; <transition-table>  ::= ( <transition>+ ) ;
;;;
;;; 13th Gen Intel Core i7-13700 x 24/64GB, ubuntu 24.04.4LTS
;;; (declaim (optimize (safety 0) (speed 3) (space 0) (debug 0) (compilation-speed 0)))
;;;
;;; [sbcl:line-edit-pkg=309(56.3MB)13:57:31 #1027]> (time (dotimes (i 10000) (get-candidates "write")))
;;; Evaluation took:
;;;   0.019 seconds of real time
;;;   0.018302 seconds of total run time (0.012353 user, 0.005949 system)
;;;   [ Real times consist of 0.008 seconds GC time, and 0.011 seconds non-GC time. ]
;;;   [ Run times consist of 0.007 seconds GC time, and 0.012 seconds non-GC time. ]
;;;   94.74% CPU
;;;   38,718,260 processor cycles
;;;   17,915,344 bytes consed
;;;
;;; ==> 約1.9μ(マイクロ)秒/回
;;;
(defun get-candidates (&optional (str "") (keymap *current-completion-keymap*))
  (declare (type (or null simple-string) str))
  (if (or (null str) (and (stringp str) (zerop (length str))))
      (get-completion-body-in-list keymap)
      (get-matched-candidates (unpack str) keymap)
      ) ;; end if
  ) ;; end get-candidates

(defun syntax-completion-keymap ()
  *syntax-completion-keymap* ;; Common Lisp syntax info.
  )

(defun user-completion-keymap ()
  *user-completion-keymap* ;; user defined info.
  )

(defun default-completion-keymap ()
  *default-completion-keymap* ;; := (condense (user-completion-keymap) (syntax-completion-keymap))
  )

(defun current-completion-keymap () ;; := (condense (default-completion-keymap) some-keymap)
  *current-completion-keymap*
  )

(defun set-current-completion-keymap (keymap)
  (setf line-edit-pkg::*current-completion-keymap* keymap)
  )

(defun add-to-current-completion-keymap (keymap)
  (setf *current-completion-keymap* (condense *current-completion-keymap* keymap))
  )

;; [*user-info-list*]に記録する形式のリストを追加する。
(defun add-this-keyword (s)
  (declare (type simple-string s))
  (let (p attr sym home-pkg status status-2 sep long-name)

    ;; [complete-symbol]での問い合わせは登録されていない場合のみ。したがって[complete-symbol]経由では不要。
    (when (find s *user-info-list* :test #'string-equal :key #'car) ;; 既に同名の補完候補が登録済み。
      (message :line-edit-pkg+add-this-keyword-001
               "同じ名前の補完候補文字列が登録済みです。削除して入れ替えますか。~%")
      (if (yes-or-no-p)
          (setf *user-info-list* (remove s *user-info-list* :test #'string-equal :key #'car))
          (return-from add-this-keyword nil)
          ) ;; end if
      ) ;; end when

    (multiple-value-setq (sym status) (find-symbol (string-upcase s) *package*))
    (cond
      ((null sym)
       (setf home-pkg nil)
       (setf attr "unknown"))
      (t
       (setf home-pkg (package-name (symbol-package sym)))
       (setf attr (string-downcase (type-of-symbol sym)))
       )
      ) ;; end cond
    (cond
      ((null status)
       (setf sep "#:"))
      ((equal status :internal)
       (setf sep "::"))
      ((equal status :external)
       (setf sep ":"))
      ((equal status :inherited)
       (multiple-value-setq (sym status-2) (find-symbol (string-upcase s) (find-package home-pkg)))
       (cond
         ((equal status-2 :internal)
          (setf sep "::"))
         ((equal status-2 :external)
          (setf sep ":"))
         (t
          (warn "add-this-keyword: can not happen.~%")
          )
         ) ;; end inner cond
       ) ;; end ((equal..
      ) ;; end outer cond
    (if (null status)
        (setf long-name (concatenate 'string  sep (string-downcase s)))
        (setf long-name (concatenate 'string  (string-downcase home-pkg) sep (string-downcase s)))
        ) ;; end if
    (setf attr (intern attr "KEYWORD"))
    (setf p (list s :|last-access| 0 :|count| 0 attr long-name))
    (pushnew p *user-info-list*)
    (set-syntax-last-access-time p)
    (increment-syntax-count p)
    (setf *user-completion-keymap* (condense *user-completion-keymap* p))
    (setf *user-keymap-added-p* t)
    (return-from add-this-keyword (format nil "~s" p))
    ) ;; end let
  ) ;; end add-this-keyword

(defun control-code-to-readable-string (code)
  (cond
    ((char= code +ctrl-@+) "[C-@]") ;; #\Null
    ((char= code +ctrl-a+) "[C-a]")
    ((char= code +ctrl-b+) "[C-b]")
    ((char= code +ctrl-c+) "[C-c]")
    ((char= code +ctrl-d+) "[C-d]")
    ((char= code +ctrl-e+) "[C-e]")
    ((char= code +ctrl-f+) "[C-f]")
    ((char= code +ctrl-g+) "[C-g]")
    ((char= code +ctrl-h+) "[C-h]")
    ((char= code +ctrl-i+) "[Tab]")
    ((char= code +ctrl-j+) "[Newline]") ;; #\Linefeed
    ((char= code +ctrl-k+) "[C-k]")
    ((char= code +ctrl-l+) "[C-l]")
    ((char= code +ctrl-m+) "[Return]")
    ((char= code +ctrl-n+) "[C-n]")
    ((char= code +ctrl-o+) "[C-o]")
    ((char= code +ctrl-p+) "[C-p]")
    ((char= code +ctrl-q+) "[C-q]")
    ((char= code +ctrl-r+) "[C-r]")
    ((char= code +ctrl-s+) "[C-s]")
    ((char= code +ctrl-t+) "[C-t]")
    ((char= code +ctrl-u+) "[C-u]")
    ((char= code +ctrl-v+) "[C-v]")
    ((char= code +ctrl-w+) "[C-w]")
    ((char= code +ctrl-x+) "[C-x]")
    ((char= code +ctrl-y+) "[C-y]")
    ((char= code +ctrl-z+) "[C-z]")
    ((char= code +ctrl-[+) "[Esc]")
    ((char= code +ctrl-\+) "[C-\\]")
    ((char= code +ctrl-]+) "[C-\]]")
    ((char= code +ctrl-^+) "[C-\^]")
    ((char= code +ctrl-_+) "[C-\_]")
    ((char= code +ctrl-?+) "[Del]") ;; C-?
    ((char= code #\Space) "[Space]")
    (t (string code))
    ) ;; end cond
  ) ;; end control-code-to-readable-string

;; 現在行の冒頭部分を表示幅いっぱい一定時間(=[*long-sleep-time*])表示する。
(defun show-head ()
  (let ((line-text (pack (current-line))))
    (move-logical-cursor-to 0)
    (pure-delete-line) ;; カーソル位置以降の[表示]を消去。
    (dotimes (i (min (length (current-line)) (physical-line-window-size)))
      (putch (char line-text i))
      )
    (finish-output)
    (xsleep *long-sleep-time*)
    (end-of-line)
    (move-logical-cursor-to 0)
    (pure-delete-line)
    ) ;; end let
  ) ;; end show-head

;;
;; 遷移表[*complete-symbol-keymap*]にキー列[key-seq]と、その結果として返す定義本体[key-def]を定義する。
;; [global-set-key]とは定義を作成する遷移表が異なるだけ。
;; 遷移表の遷移要素の実装は文字列なので[key-def]は文字列型以外。
;;
(defun complete-symbol-set-key (key-seq key-def)
  (when (stringp key-def)
    (error "(complete-symbol-set-key key-seq key-def) : [key-def] do not allow string.")
    )
  ;;  (global-set-key key-seq key-def) == (set-key key-seq key-def '*global-keymap*)
  (set-key key-seq key-def '*complete-symbol-keymap*)
  ) ;; end complete-symbol-set-key

;;
;; 遷移表[local]内から入力されたキー列に応じた登録文字列を返す。
;; 一致するキー列がなかった場合は一致しなかった最初の文字を返す。
;;
(defun get-key-def-for-complete-symbol ()
  (get-command *complete-symbol-keymap*)
  )

(defun clear-key-def-for-complete-symbol ()
  (setf *complete-symbol-keymap* nil)
  )

(defun get-key-help-for-complete-symbol ()
  (let (source-list)
    (cond
      ((and
        (listp *complete-symbol-used-key-def*)
        (= (length *complete-symbol-used-key-def*) 7)
        )
       (setf source-list (copy-seq *complete-symbol-used-key-def*))
       )
      (t
       (setf source-list (copy-seq  +complete-symbol-used-key-def-init+))
       )
      ) ;; end cond
    ;; '(:previous-candidate :next-candidate :current-candidate :short-candidate :long-candidate
    ;;   :redraw :cancel)
    (list (nth 0 source-list) (nth 1 source-list) (nth 2 source-list) (nth 3 source-list)
          (nth 4 source-list) (nth 5 source-list) (nth 6 source-list) )
    ) ;; end let
  ) ;; end get-key-help-for-complete-symbol

;;
;; 入力中の単語と先頭部分が一致する単語を順次表示する。大文字・小文字の区別は行わない。
;;
;; [Tab]キーをタイプするごとに次の補完候補を表示する。
;; [C-p]キーをタイプするごとにひとつ前の候補の表示に戻る。
;; [SPC]キーをタイプするごとに短い補完候補と長い補完候補の表示が切り替わる。
;; [C-j]をタイプすると表示されている補完候補を選択。
;; [C-l]をタイプすると常に長い補完候補を選択。
;; [C-r]をタイプすると行全体を書き直す。
;; [ESC]キーをタイプすると補完をキャンセル。
;;
(defun complete-symbol ()
  (let
      (
       str                      ;; 文字列保管用の一時変数。
       user-text                ;; ユーザが入力中のテキスト。
       (pt 0)                   ;; ポイント位置記録用。
       (break-char nil)         ;; デフォルト区切り文字定義リストの保管用。
       (candidates nil)         ;; 補完候補を列挙したファイル内とのリンクを保護している文字列のリスト。
       (candidate nil)          ;; [candidates]リスト内の要素。
       (word-start nil)         ;; 補完候補文字列の[*text*]内での先頭位置。
       (sorted-candidates nil)  ;; 補完候補を列挙したファイル内とのリンクが切れている候補文字列のリスト。
       (sorted-candidate nil)   ;; 補完候補を列挙したファイル内のリストとのリンクが切れているリスト。
       (number-of-candidates 0) ;; 入力した文字列と先頭文字列が一致する補完候補の個数。
       (candidate-number 0)     ;; 処理対象とする補完候補のリスト先頭からの番号。
       (need-show-head t)       ;; 文字数の長い補完候補に対して初回のみ自動で行頭・行末の遷移表示を行う。
       (key-help-list nil)      ;; 補完時のキー割り当てコードのリスト。
       )
    (declare (type (or null simple-string) str))
    (declare (type (or null simple-string) user-text))

    (labels
        (
         (setup-candidates ()
           ;; 現在のポイントから、単語の開始位置までの文字列を再取得
           (setf pt *point*)

           (when (null pt)
             (message :line-edit-pkg+complete-symbol-001
                      "現在の位置(ポイント)が不明です。先頭位置に設定します。~%")
             (setf pt 0)
             ) ;; end when

           ;; 現在の単語の先頭に移動しポイント位置を返す。ポイントが移動しなかったときは[nil]。
           (setf word-start (backward-word))

           ;; 現在の単語の先頭への移動が行われなかった場合、および区切り文字一つだけ移動したときは
           ;; ノーマル文字による単語が存在していなかったということ。
           (when (or (null word-start)
                     (member (character-at word-start) +common-lisp-break-char+ :test #'char=)) 
             (setf word-start pt)
             )

           (setf str (pack (subseq (current-line) word-start pt)))
           (setf user-text (pack (current-line))) ;; ユーザが入力しているテキストを保存。

           (when (debug-print-p "complete-symbol-000")
             (format t "pt=~s, word-start=~s~%" pt word-start)
             (format t "str=~s~%" str)
             (format t "user-text=~s~%" user-text)
             ;;
             ;;(format t "(length (get-candidates \"\" *current-completion-keymap\*))=~d~%"
             ;;        (length (get-candidates "" *current-completion-keymap*)))
             ;;
             ;; この書き方だとCLISP 2.49.93+ (2018-02-18) では以下の誤った警告が出る。 
             ;;
             ;; Compiling file /home/daigo/Lisp/line-edit/line-edit-pkg.lisp ...
             ;; WARNING: in COMPLETE-SYMBOL-SETUP-CANDIDATES in lines 7792..8045 :
             ;; |""| is neither declared nor bound,
             ;; it will be treated as if it were declared SPECIAL.
             ;; Wrote file /home/daigo/Lisp/line-edit/line-edit-pkg.fas
             ;; The following special variables were not defined:
             ;; LINE-EDIT-PKG::|""|
             ;;
             ;; CLISPでの無用な警告を回避するために書き換えた。
             (format t "(length (get-candidates ~s *current-completion-keymap\*))=~d~%"
                     "" (length (get-candidates "" *current-completion-keymap*)))
             (format t "(length (get-candidates ~s \*current-completion-keymap\*))=~d~%"
                     str (length (get-candidates str *current-completion-keymap*)))
             ) ;; end when
         
           ;; 新しい候補リストを取得
           (setf candidates (get-candidates str *current-completion-keymap*))
           (setf number-of-candidates (length candidates))
         
           ;; 候補が0件かチェック。
           (if (zerop number-of-candidates)
               (progn ;; then clause ;; 「候補なし」と表示。
                 (move-point-to 0)
                 (kill-line)
                 (self-insert-string " [No Match] Save this keyword? (y/n) ")
                 (display-line)
                 (let (ch)
                   (setf ch (getchar)) ;; raw-mode中なので[Return]なしで入力終了。
                   (cond
                     ;;((member ch '(#\Y #\y +ctrl-j+ +ctrl-m+ #\Newline) :test #'char=) ;; 警告が出る。
                     ((member ch (list #\Y #\y +ctrl-j+ +ctrl-m+ #\Newline) :test #'char=)
                      (self-insert-string "...Yes")
                      (display-line)
                      (finish-output)
                      (xsleep *sleep-time*) ;; 関数[sleep]の精度が低い場合に使用する。
                      ;;(sleep *sleep-time*)
                      (move-point-to 0)
                      (kill-line)
                      (move-logical-cursor-to 0)
                      (pure-delete-line-from-here)
                      (self-insert-string
                       (concatenate 'string "\(line-edit-pkg\:add-this-keyword \"" str "\"\)"))
                      (add-this-keyword str) ;; add [str] to [*user-info-list*] for save.
                      (display-line)
                      (finish-output)
                      (return-from complete-symbol nil)
                      )
                     (t ;; 元の入力を復元して終了。
                      (self-insert-string "...No")
                      (display-line)
                      (finish-output)
                      (xsleep *sleep-time*) ;; 関数[sleep]の精度が低い場合に使用する。
                      ;;(sleep *sleep-time*)
                      (move-point-to 0)
                      (kill-line)
                      (move-logical-cursor-to 0)
                      (pure-delete-line-from-here)
                      (self-insert-string user-text)
                      (display-line)
                      (finish-output)
                      (return-from complete-symbol nil)
                      )
                     ) ;; end cond
                   )   ;; end let
                 (return-from complete-symbol nil)
                 ) ;; end progn
               (setf sorted-candidates (sort-by-priority (copy-list candidates)))
               ) ;; end if
           )     ;; end setup-candidates

         ;; 最終採用時刻、通算採用回数を記録する。
         (record-statistics ()
           (let ((info sorted-candidate))
             (when info
               (set-syntax-last-access-time info) ;; 最終採用時刻の記録。
               (increment-syntax-count info) ;; 最終採用回数の記録。
               )                             ;; end when
             )
           ) ;; end record-statistics

         )

      (unwind-protect
           (progn
             (setf break-char *break-char*) ;; 現在の区切り文字の定義を保存。
             (setf *break-char* +common-lisp-break-char+) ;; 区切り文字の定義をCommon Lispでの定義に変更。
             (setup-candidates)
             (setf need-show-head t)
             (setf candidate-number 0)
             (setf key-help-list (get-key-help-for-complete-symbol))

             (loop
               (let (
                     (short-or-long 0)
                     selected-input
                     )
                 (declare (type fixnum short-or-long))
                 (declare (type (or character symbol) selected-input))

                 (when (debug-print-p "complete-symbol-001")
                   (format t "selected-input(0)~%")
                   )

                 (setf sorted-candidate (nth candidate-number sorted-candidates))
                 (loop ;; 短い補完候補と長い補完候補の切り替え処理を行うループ。
                   (let (tm) ;; 対応するカッコへの移動は抑止。
                     (move-point-to word-start) ;; 補完候補の先頭文字にポインタを移動。
                     (kill-line) ;; 補完候補の先頭文字列以降を削除。
                     (move-logical-cursor-to (third (display-range)))
                     (pure-delete-line-from-here)

                     ;; [SPC]キーをタイプするごとに短い補完候補と長い補完候補の表示を切り替わる。
                     (if (zerop short-or-long)
                         (self-insert-string (get-syntax-name sorted-candidate))      ;; 短い補完候補を用意。
                         (self-insert-string (get-syntax-info-body sorted-candidate)) ;; 長い補完候補を用意。
                         ) ;; end if

                     (setf tm (blink-paren-deley))
                     (blink-paren-deley 0)

                     (self-insert-string (format nil " [~d/~d] ([SPC]/NXT=~a/PRV=~a/OK=~a/X=~a)"
                                                 (1+ candidate-number) number-of-candidates
                                                 (nth 1 key-help-list) ;; :next-candidate
                                                 (nth 0 key-help-list) ;; :previous-candidate
                                                 (nth 2 key-help-list) ;; :current-candidate
                                                 (nth 6 key-help-list) ;; :cancel
                                                 )
                                         )

                     ;; 表示した補完候補の文字数が現在の表示幅より多い場合の処理。
                     ;; 設定秒数間、行先頭部分以降を表示し、行末までの表示に戻る。
                     ;;
                     (when (and need-show-head (> (length (current-line)) (physical-line-window-size)))
                       (show-head)
                       (setf need-show-head nil)
                       )
                     (blink-paren-deley tm)

                     (display-line)
                     (move-point-to word-start) ;; ポイントは補完候補の先頭位置に移動する。
                     )                          ;; end let

                   (setf selected-input (get-key-def-for-complete-symbol)) ;; キー列から選択肢を得る。

                   ;; sbclでは(safety 0)だと[selected-input]が文字型でなくてもエラーが出ず(t...)へ飛ぶ。
                   ;; (if (char= selected-input #\Space)
                   (if (and (characterp selected-input) (char= selected-input #\Space))
                       (setf short-or-long (mod (1+ short-or-long) 2))
                       (return) ;; スペース以外が入力されたら選択された処理へ。
                       ) ;; end if

                   ) ;; end first part loop

                 (cond
                   ;;--------------------------------------------------------------------------------
                   ((equal selected-input :next-candidate)
                    (if (= candidate-number (1- number-of-candidates))
                        (setf candidate-number 0) ;; 最後の補完候補の「次」は最初の補完候補。
                        (incf candidate-number)
                        ) ;; end if
                    ) ;; goto next loop.
                   ;;--------------------------------------------------------------------------------
                   ((equal selected-input :previous-candidate) ;; ひとつ前の補完候補の表示へ。
                    (if (zerop candidate-number)
                        (setf candidate-number (1- number-of-candidates)) ;; 最初の候補の「前」は最後の候補。
                        (decf candidate-number)
                        ) ;; end if
                    ) ;; goto next loop.
                   ;;--------------------------------------------------------------------------------
                   ((or
                     (and
                      (= short-or-long 0) ;; 偶数回の補完候補切り替えで
                      (equal selected-input :current-candidate) ;; 現在の候補選択なら短い補完候補。
                      )
                     (equal selected-input :short-candidate) ;; :short-candidateなら常に短い補完候補。
                     )
                    (move-point-to word-start)
                    (kill-line)
                    (setf candidate (get-syntax-name sorted-candidate)) ;; 補完文字列のみ。
                    (self-insert-string candidate)
                    (display-line)
                    (record-statistics)
                    (return-from complete-symbol nil)
                    )
                   ;;--------------------------------------------------------------------------------
                   ((or
                     (and
                      (= short-or-long 1)                      ;; 奇数回の補完候補切り替えで
                      (equal selected-input :current-candidate)) ;; 現在の候補選択なら長い補完候補。
                     (equal selected-input :long-candidate)      ;; :long-candidateなら常に長い補完候補。
                     )
                    (move-point-to word-start)
                    (kill-line) ;; ポイント位置から行末までを削除する。
                    (setf candidate (get-syntax-info-body sorted-candidate)) ;; 長い補完候補。
                    (self-insert-string candidate)
                    (display-line)
                    (record-statistics)
                    (return-from complete-symbol nil)
                    )
                   ;;--------------------------------------------------------------------------------
                   ((equal selected-input :redraw) ;; redraw
                    (show-head)
                    (display-line)
                    (finish-output)
                    ) ;; goto next loop.
                   ;;--------------------------------------------------------------------------------
                   ((equal selected-input :cancel) ;; キャンセル。
                    (beginning-of-line 1)
                    (kill-line)
                    (move-logical-cursor-to 0) ;; この2行がないと[vi-mode]時に[user-text]以降が消えない。
                    (pure-delete-line 0)       ;; この2行がないと[vi-mode]時に[user-text]以降が消えない。
                    (self-insert-string user-text) ;; 元に戻す。
                    (display-line)
                    (return-from complete-symbol nil)
                    )
                   ;;--------------------------------------------------------------------------------
                   (t ;; 上記以外。案内メッセージを表示して終了。
                    (let (msg)
                      ;; '(:previous-candidate(0) :next-candidate(1) :current-candidate(2)
                      ;;   :short-candidate(3) :long-candidate(4) :redraw(5) :cancel(6))
                      ;;(setf msg (format nil "Next=~a, Prev.=~a, Ok=~a, Redraw=~a, Cancel=~a"
                        ;;              (nth 1 key-help-list) (nth 0 key-help-list) (nth 2 key-help-list)
                        ;;              (nth 5 key-help-list) (nth 6 key-help-list) )) 
                      (setf msg (format nil "for more infomation, type (help-complete)"))

                      (clear-kill-ring)
                      (beginning-of-line 1) ;; 行の先頭に移動。
                      (kill-line)
                      (self-insert-string msg)
                      (display-line)
                      (when (getchar) ;; 何かキーが入力されるまで案内メッセージを表示しておく。
                        (beginning-of-line 1)
                        (kill-line) ;; 表示していたメッセージを行バッファから消去。
                        (move-logical-cursor-to 0)
                        (pure-delete-line-from-here)
                        (self-insert-string user-text) ;; 元々表示されていたテキストを行バッファに入力。
                        (display-line)
                        ) ;; end when
                      (return-from complete-symbol nil)
                      )                ;; end local let
                    )                  ;; end [t]
                   ;;--------------------------------------------------------------------------------
                   )                   ;; end cond
                 )                     ;; end let
               )                       ;; end loop
             )                         ;; end progn
        (setf *break-char* break-char) ;; 行編集コマンド使用時に便利な定義に戻す。
        )                              ;; end unwind-protect
      (return-from complete-symbol nil)
      ) ;; end labels
    )   ;; end let
  )     ;; end complete-symbol

;;;
;;; Hook function for C-p and C-n
;;;
;;; 現在の行の先頭とポイントの間の文字列を後方/前方に向かって探す。見つ
;;; かればそのヒストリ行を表示する。 ポイントの位置は前回のヒストリ行の
;;; ポイント位置と同じ。
;;;

#- :use-history-pkg
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun previous-line (&optional n) nil) ;; C-p
  (defun next-line (&optional n) nil)     ;; C-n
  (defun beginning-of-history (&optional count) nil)
  (defun end-of-history (&optional count) nil)
  (defun goto-history (n) nil)
  (defun set-global-mark () nil)
  (defun goto-global-mark () nil)
  )

#+ :use-history-pkg
(eval-when (:compile-toplevel :load-toplevel :execute)
;;; 履歴を逆向き（古くなる方向）に検索する。
;;; 最後に検索に一致した位置を記録し、次回は前回より古い履歴を対象
;;; として検索する。
;;;
;;; (history-pkg::history-search-backward str search-frm) は検索に成功
;;; すると、検索に一致した履歴文字列の
;;;
;;; ((ヒストリ番号 . 配列番号) 検索一致先頭位置) を返す。
;;;
;;; 現在の仕様では、行の先頭からの一致のみを対象としているため検索一致
;;; 先頭位置は常にゼロである。
;;;
  (defun previous-line (&optional (n nil))
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (cond
      ((zerop n) nil)
      ((> n 0)
       (dotimes (i n) (true-previous-line)))
      ((< n 0)
       (next-line (- n)))))

  (defun true-previous-line ()
    (let (pos found lst str search-frm s n)
      (setf pos *point*)
      (setf search-frm (search-from))
      (when (oldest-history-p search-frm) (return-from true-previous-line nil))
      (setf lst (subseq *text* 0 pos))
      (multiple-value-setq (s n) (expand-history lst))
      (setf str (pack lst))
      (if (null str) (setf str ""))
      (cond
        ((not (null s))
         (search-from n)
         (beginning-of-line 1)
         (kill-ring-suspend t)
         (kill-line 1)
         (pop-kill-ring)
         (init-line-edit s)
         (move-point-to 0)
         )
        (t (setf found (history-pkg:history-search-backward str search-frm))
           ;;(t (setf found (history-search-backward str search-frm))
           (when found
             (search-from (caar found))
             (beginning-of-line 1)
             (kill-ring-suspend t)
             (kill-line 1)
             (pop-kill-ring)
             (init-line-edit (hist-buf (cdar found)))
             (move-point-to pos)
             ;;(need-refresh-line t)
             ) ;; end when
           )   ;; end [t]
        )      ;; end cond
      )        ;; end let
    ) ;; end true-previous-line

;;; un-binded function
;;; 引数で指定された履歴番号に移動する。
;;;
  (defun goto-history (num)
    (let (s pos)
      (if (or (not (integerp num)) (not (hist-range-p num)))
          (return-from goto-history nil))
      (setf pos *point*)
      ;;(multiple-value-setq (s n) (expand-history (make-hist-string num)))
      (setf s (expand-history (make-hist-string num)))
      (search-from num)
      (beginning-of-line 1)
      (kill-ring-suspend t)
      (kill-line 1)
      (pop-kill-ring)
      (init-line-edit s)
      (move-point-to pos)
      )
    )

  (defun make-hist-string (n)
    (let ((lst nil) num i)
      (setf num n)
      (loop
        (if (zerop num) (return-from make-hist-string (push #\! lst)))
        (multiple-value-setq (num i) (floor num 10))
        (push (digit-to-char i) lst))))

;;; 指定した文字列で始まる履歴位置に移動する。
  (defun goto-history-by-string (str)
    (let ((search-frm (1- (history-pkg:history-number))) ;; 最新から探す
          (pos *point*)
          found)
      (setf found (history-pkg:history-search-backward str search-frm))
      (when found
        (search-from (caar found))
        (beginning-of-line 1)
        (kill-ring-suspend t)
        (kill-line 1)
        (pop-kill-ring)
        (init-line-edit (history-pkg:hist-buf (cdar found)))
        (move-point-to pos)
        ;;(need-refresh-line t)
        ) ;; end when
      )   ;; end let
    ) ;; end goto-history-by-string

;;; C-n
;;; 履歴を前向き（新しくなる方向）に検索する。
;;; 最後に検索に一致した位置を記録し、次回は前回より新しい履歴を対象
;;; として検索する。
;;;
;;; (history-search-forward str search-frm)は検索に成功
;;; すると、検索に一致した履歴文字列の
;;;
;;; ((ヒストリ番号 . 配列番号) 検索一致先頭位置) を返す。
;;;
;;; 現在の仕様では、行の先頭からの一致のみを対象としているため検索一致
;;; 先頭位置は常にゼロである。
;;;
  (defun next-line (&optional (n nil))
    (when (null n)
      (setf n (select-repeat-count n))
      )
    (cond
      ((zerop n) nil)
      ((> n 0)
       (dotimes (i n) (true-next-line)))
      ((< n 0)
       (previous-line (- n)))))

  (defun true-next-line ()
    (let (pos found lst str search-frm s n)
      (setf pos *point*)
      (setf search-frm (search-from))
      (when (and search-frm (= search-frm (car (history-pkg:current-history))))
        (kill-text)
        (return-from true-next-line nil))
      (setf lst (subseq *text* 0 pos))
      (setf str (pack lst))
      (if (null str) (setf str ""))
      (multiple-value-setq (s n) (expand-history lst))
      (cond
        ((not (null s))
         (search-from n)
         (beginning-of-line 1)
         (kill-ring-suspend t)
         (kill-line 1)
         (pop-kill-ring)
         (init-line-edit s)
         (move-point-to 0)
         ;;(need-refresh-line t)
         )
        (t (setf found (history-search-forward str search-frm))
           (when found
             (search-from (caar found))
             (beginning-of-line 1)
             (kill-ring-suspend t)
             (kill-line 1)
             (pop-kill-ring)
             (init-line-edit (hist-buf (cdar found)))
             (move-point-to pos)
             ;;(need-refresh-line t)
             ) ;; end when
           ) ;; end [t]
        ) ;; end cond
      ) ;; end let
    ) ;; end true-next-line

;;;
;;; 最後に検索した履歴番号を記録する。
;;; 引数を指定しなかった場合は、記録されている履歴番号を返す。
;;; nilは最新の履歴番号を意味する。
;;;
  (defun search-from (&optional (num nil sw))
    (cond
      ((null sw) *search-from*)
      (t (setf *search-from* num))))

;;;
;;; リング構造の履歴バッファに記録されている最も古い履歴か？
;;;
  (defun oldest-history-p (hist-num)
    (and (numberp hist-num)
         (= hist-num (car (last-live-history)))))

;;;
;;; 引数がヒストリ番号を表す文字リストであれば
;;; 対応する履歴文字列と履歴番号を返し、そうでなければ nilを返す。
;;;
;;; <ヒストリ番号> ::= '!' ['-'] <number>
;;;                      '!' '!'
;;;
;;; ex. (expand-history (unpack "!-3"))
;;;       (expand-history (make-hist-string 1234)))
;;;
  (defun expand-history (lst)
    (let (num n s)
      (loop                             ;skip white space
            (cond
              ((null lst) (return-from expand-history nil))
              ((char= (car lst) #\!)
               (pop lst)
               (return))
              ((member (car lst) +white-space-char+) (pop lst))
              (t (return-from expand-history nil))))
      (loop
        (cond
          ((null lst) (return-from expand-history nil))
          ((member (car lst) +white-space-char+) (pop lst))
          (t (return))))
      (cond
        ((null lst)
         (return-from expand-history nil))
        ((char= (car lst) #\!)
         (setf n (car (history-pkg:current-history)))
         (setf s (hist-buf (get-hist n))))
        ((char= (car lst) #\-)
         (setf num (meta-string-to-number (pack lst) :default 4))
         (setf n (+ (car (history-pkg:current-history)) num 1))
         (setf s (hist-buf (get-hist n))))
        ((digit-char-p (car lst))
         (setf n (meta-string-to-number (pack lst) :default 4))
         (setf s (hist-buf (get-hist n))))
        (t (return-from expand-history nil)))
      (return-from expand-history (values s n))))

;;; M-<
;;; リング構造の履歴バッファの先頭（最古の履歴が記録されている）
;;; に移動する。
;;;
  (defun beginning-of-history ()
    (let (last-live)
      (setf last-live (last-live-history))
      (search-from (car last-live))
      (beginning-of-line 1)
      (kill-ring-suspend t)
      (kill-line 1)
      (pop-kill-ring)
      (init-line-edit (hist-buf (cdr last-live)))
      (if *undo-info* (line-edit-break "beginning-of-history"))
      ;;(need-refresh-line t)
      (beginning-of-line 1)))

;;; M->
;;; リング構造の履歴バッファの末尾（最新の履歴を記録している位置）
;;; に移動する。
;;;
  (defun end-of-history ()
    (kill-text)
    (goto-history (1- (history-number))) ;; go to last history.
    )

;;; [C-u [num]] M-m x (Mark global-mark)
;;; 前置引数で指定された履歴番号をマーク 'x'に記録する。前置引数
;;; が指定されていなければ現在の履歴番号を記録する。
;;; 前置引数が 0 なら、グローバル・マーク 'x'そのものを削除する。
;;; 将来、指定された履歴が履歴リング・バッファから消えてしまう場
;;; 合に備えて、履歴内容も保存しておく。
;;;
;;; 履歴リストは以下の通り：
;;;     (マーク 履歴番号 ポイント位置 履歴内容)
;;;
  (defun set-global-mark ()
    (let (mark hist-num str)
      (setf mark (getchar))
      (cond
        ((repeat-count)
         (setf hist-num (repeat-count))
         (setf str (expand-history (make-hist-string hist-num))))
        (t (setf hist-num (1+ (car (history-pkg:current-history))))
           (setf str (packed-text))))
      (pure-set-global-mark mark hist-num *point* str)))

  (defun pure-set-global-mark (mark hist-num point str)
    (cond
      ((null mark) nil)
      ((null (assoc mark *global-mark*))
       (push (list mark hist-num point str) *global-mark*))
      (t (setf (cdr (assoc mark *global-mark*)) (list hist-num point str))))
    (setf *global-mark*
          (remove-if #'(lambda (x) (zerop (second x))) *global-mark*))
    (sort-global-mark))

;;;
;;; グローバル・マーク 'x'の内容を返す。
;;;
  (defun get-global-mark (x)
    (assoc x *global-mark*))

;;;
;;; グローバル・マーク 'x'のポイント位置と履歴番号を返す（多値）。
;;; 指定されたグローバル・マークが存在していなければ[nil]を返す。
;;;
  (defun eval-global-mark (x)
    (let (lst)
      (setf lst (get-global-mark x))
      (cond
        ((null lst) (values nil nil))
        (t (values (third lst) (second lst))))))

;;;
;;; グローバル・マークの全内容を表示する。
;;;
  (defun view-global-mark ()
    (if (null *global-mark*) (return-from view-global-mark nil))
    (dolist (i *global-mark* t) (prin1 i) (terpri)))

;;;
;;; グローバル・マークをソートする。
;;;
  (defun sort-global-mark ()
    (setf *global-mark*
          (sort *global-mark* #'(lambda (x y) (char< (car x) (car y))))))

;;;
;;; すべてのグローバル・マークを消去する。
  (defun clear-global-mark ()
    (setf *global-mark* nil))

;;;
;;; グローバル・マークの全内容をファイルに保存する。
;;;
  (defun save-global-mark (&optional fname)
    (if (null fname) (setf fname (global-mark-file)))
    (with-open-file (stream fname :direction :output)
      (dolist (i *global-mark* t)
        (prin1 i stream)
        (terpri stream))))

;;;
;;; グローバル・マークを保存するファイルを設定する。
;;;
  (defun global-mark-file (&optional fname)
    (cond
      ((null fname) *global-mark-file*)
      (t (setf *global-mark-file* fname))))

;;;
;;; グローバル・マークを読み込む。
;;;
  (defun load-global-mark (&optional fname)
    (let (form)
      (if (null fname) (setf fname (global-mark-file)))
      (when (probe-file fname)
        (clear-global-mark)
        (with-open-file (stream fname :direction :input)
          (loop
            (setf form (read stream nil +eos+))
            (when (eq form +eos+) (return-from load-global-mark t))
            (pure-set-global-mark
             (first form) (second form) (third form) (fourth form)))))))

;;; M-g x (Go to global-mark)
;;; 指定されたグローバル・マークの位置に移動する。
;;; グローバル・マークで指定された履歴がリング・バッファ内に残っていれば
;;; そこに移動し、そうでなければ、あらかじめ保存しておいた履歴内容を表示
;;; する。
;;;
  (defun goto-global-mark ()
    (let (lst mark hist-num point str)
      (setf mark (getchar))
      (setf lst (get-global-mark mark))
      (setf hist-num (second lst))
      (setf point (third lst))
      (setf str (fourth lst))
      (cond
        ((hist-range-p hist-num)
         (goto-history hist-num))
        (t
         (beginning-of-line 1)
         (kill-ring-suspend t)
         (kill-line 1)
         (pop-kill-ring)
         (init-line-edit str)))
      (if (null point) (move-point-to 0)
          (move-point-to point))) )
  ) ;; end eval-when

(let (
      (last-check-time 0)
      (check-interval (floor (* 0.5 internal-time-units-per-second))) ;; 0.5秒間隔。
      )
  (declare (type integer last-check-time))
  (declare (type integer check-interval))

  (defun check-elapsed-time ()
    (let* (
           (current-time (get-internal-real-time))
           (delta (- current-time last-check-time))
           )
      (declare (type integer current-time))

      (if (> delta check-interval)
          (setf last-check-time current-time)
          nil
          )
      ) ;; end let
    )   ;; end elapsed-time

  (defun change-interval-second (sec)
    (when (plusp sec)
      (setf check-interval (floor (* sec internal-time-units-per-second)))
      )
    )

  ;;
  ;; 物理端末の行幅を返す。
  ;;
  (defun current-physical-column-size ()
    (when (and ;; 端末幅変更フラグがオン、かつチェック間隔が[check-interval]より長ければ更新。
           *terminal-resized-p*
           (check-elapsed-time)
           )
      (setf *last-terminal-size* (true-current-physical-column-size))
      (setf *terminal-resized-p* nil)
      ) ;; end when
    (return-from current-physical-column-size (max 1 *last-terminal-size*)) ;; ゼロ・ガード。
    )

  ;;
  ;; 物理端末の行幅を強制的に最新状態に更新する。
  ;;
  (defun update-physical-column-size ()
    (let (temp)
      (setf *terminal-resized-p* nil)
      (setf temp (true-current-physical-column-size))
      (if (and (numberp temp) (plusp temp))
          (setf *last-terminal-size* temp)
          (setf *last-terminal-size* 80)
          )
      ) ;; end let
    )

  ) ;; end let clause

;; ========================================================================================
;;
;; 端末にxterm(互換)端末かを問い合わせる関数群。本体関数は[xterm-p]。
;; (互換)端末であれば端末が回答した(互換)端末名を表すキーワードを返す。そうでなければ[nil]を返す。
;; 端末からの応答を待つためミリ秒以上の時間を要するので呼び出し回数は最低限であること。
;;
(defun request-xterm-p (stream)
  (format stream "~c[>c" +ESC+)
  (finish-output stream)
  (force-output stream)
  )

;;
;; ※ SBCLのI/Oバッファ同期に関する重要な情報。
;; SBCLにおいて、標準入力(または/dev/tty)から非同期に応答を得る際、
;; listenだけではOS側のバッファ更新を検知していない。
;; そのため、xterm-p側でread-char-no-hangを実行してストリームを
;; 強制的にアクティブにしている。
;; ここでunread-charを行うと、SBCLが再びイベント待ち（ブロック）状態に
;; 戻ってしまうため、読み取った先頭の1文字は引数経由で受け取っている。
;;
(defun parse-xterm-info (stream leading-char)
  (let (ch (num 0) (result nil) (time-1 (get-internal-real-time)) (terminal-type nil))

    (setf result (translate-char-to-string-symbol leading-char nil))
    (loop
      (when (listen stream) (return))
      (when (setf ch (read-char-no-hang stream))
        (unread-char ch stream)
        (return)
        )
      (when (> (elapsed-time time-1 (get-internal-real-time)) *time-out-time*)
        (return-from parse-xterm-info nil) )
      (sleep *long-sleep-for-wait*)
      )

    ;;(format t "time for listen=~d~%" (elapsed-time time-1 (get-internal-real-time))) ;; 0 sec.

    ;;(setf time-1 (get-internal-real-time))
    (clear-symbol-buffer)
    (loop
      (setf ch (read-char-no-hang stream))
      (if (characterp ch)
          (unread-char ch stream)
          (return)
          ) ;; end if
      (push (getsym stream nil) result)
      (sleep *sleep-for-wait*)
      ) ;; end loop
    ;;(format t "time for read-char-no-hang&unread-char=~d~%"
        ;;    (elapsed-time time-1 (get-internal-real-time))) ;; around 1/500 sec.

    (setf result (reverse result))
    (if (equal (list +meta-string+ +left-square-bracket+ +greater-than-sign+) (subseq result 0 3))
        (setf terminal-type (nthcdr 3 result))
        (return-from parse-xterm-info nil)
        ) ;; end if
    (loop
      (if (not (member (car terminal-type) +digit-symbol+ :test #'string=)) (return))
      ;;(setf sym (pop terminal-type))
      ;;(setf num (+ (* num 10) (digit-symbol-to-digit sym)))
      (setf num (+ (* num 10) (digit-symbol-to-digit (pop terminal-type))))
      ) ;; end loop

    ;; 0        VT100 全ての基本となるエントリ。
    ;; 1        VT220 現代のエミュレータの「実質的な標準」の最小単位。
    ;; 2        VT240/VT241 ReGIS(ベクトル描画)対応。
    ;;18        VT330 モノクロ・グラフィックス。
    ;;19        VT340 カラー・グラフィックス。16/4096色。カーソル色変更機能の可能性があるのも、この端末以降。
    ;;24        VT320 テキスト専用の中位モデル。モノクロ端末。
    ;;32        VT382 日本語（漢字）対応端末。 日本市場において非常に重要。
    ;;41        VT420 セッション対応、水平スクロール等。
    ;;61        VT510 gnome-terminal(VTE)が返す値。 最終期のテキスト機。
    ;;64        VT520 複数セッション、高度なウィンドウ管理。
    ;;65        VT525 カラー対応、最高峰のハードウェア機。
    ;;欠番(3-17, 20-23等)(予約済み/特殊) Wyse端末や、DEC内部の試作機、あるいはOEMメーカー向け。
    (setf terminal-type
          (case num
            (0  :vt100)
            (1  :vt220)
            (2  :vt240)
            (18 :vt330)
            (19 :vt340)
            (24 :vt320)
            (32 :vt382)
            (41 :vt420)
            (61 :vt510)
            (64 :vt520)
            (65 :vt525)
            (otherwise nil)
            ) ;; end case
          )   ;; end setf

    (return-from parse-xterm-info terminal-type)
    ) ;; end let
  ) ;; end parse-xterm-info

;;
;; 端末にxterm(互換)端末かを問い合わせる関数。
;; (互換)端末であれば端末が回答した(互換)端末名を表すキーワードを返す。そうでなければ[nil]を返す。
;; 端末からの応答を待つためミリ秒以上の時間を要するので呼び出し回数は最低限であること。
;;
(defun xterm-p ()
  (let (result leading-char)

    (raw-mode)

    (let ((tty (open "/dev/tty" :direction :io :if-exists :overwrite :element-type 'character)))
      (unwind-protect
           (progn
             ;; xterm(互換)端末か否かを問い合わせる。回答は入力への出力として返るので読み出す。
             (request-xterm-p tty)
             (finish-output tty)
             (force-output tty)
             (sleep *time-out-time*)
             (listen tty)
             (setf leading-char (read-char-no-hang tty)) ;; 処理系によっては関数[listen]では正解を得られない。
             (setf result (parse-xterm-info tty leading-char)))
        (close tty)
        ) ;; end unwind-protect
      )   ;; end let

    (cooked-mode)
    (return-from xterm-p result)
    ) ;; end let
  ) ;; end xterm-p

;;
;; 拡張エスケープ・シーケンスをサポートしているか？
;;
;; ESC P 1 $ r <設定値> ; m ESC \ 
;;
;; 'P'の次が'1'なら <設定値>(モード値)は0,1,2のいずれか。
;;      0       拡張エスケープ・シーケンスサポートなし。
;;      1       Homeなどの特殊キーのみ拡張エスケープ・シーケンス形式でキーコードを返す。
;;      2       全てのキーに対して拡張エスケープ・シーケンス形式でキーコードを返す。
;;
(defun true-parse-request-modify-other-key-response (stream)
  (let (ch sym (result nil) (time-1 (get-internal-real-time)))
    (line-edit-pkg::clear-symbol-buffer)

    (loop ;; 入力があるか設定時間切れになるまで待機。
          (when (listen stream) (return))
          (when (setf ch (read-char-no-hang stream))
            (unread-char ch stream)
            (return)
            )
          (when (> (elapsed-time time-1 (get-internal-real-time)) *time-out-time*)
            (return-from true-parse-request-modify-other-key-response nil) )
          (sleep *sleep-for-wait*)
          ) ;; end loop

    (line-edit-pkg::clear-symbol-buffer)
    (loop ;; 処理系(sbcl)のバッファにデータが届いていない場合、OSに文字が届いていれば処理系に通知させる。
          (setf ch (read-char-no-hang stream))
          (if (characterp ch)
              (unread-char ch stream)
              (return)
              ) ;; end if
          (setf sym (getsym stream nil))
          (push sym result)
          (sleep *sleep-for-wait*)
          ) ;; end loop

    (return-from true-parse-request-modify-other-key-response (reverse result))

    ) ;; end let
  ) ;; end true-parse-request-modify-other-key-response

(defun request-modify-other-key-setting (stream)
  (format stream"~cP$q4;m~c\\" +ESC+ +ESC+) ;; ESC P $ q 4 ; m ESC \
  ) ;; end request-modify-other-key-setting

;;
;; xterm互換端末であれば拡張エスケープ・シーケンスの現在のモード番号(0,1,2)を返す。
;; そうでなければ[nil]を返す。
;;
(defun parse-request-modify-other-key-response ()
  (let (result)
    (raw-mode)
    (let ((tty (open "/dev/tty" :direction :io :if-exists :overwrite :element-type 'character)))
      (unwind-protect
           (progn
             (format tty "~c[>4;1m" +ESC+) ;; まずはモード1への設定を試みる。
             (sleep 1/10)
             (request-modify-other-key-setting tty)
             (finish-output tty)
             (force-output tty)
             (sleep *long-sleep-for-wait*)
             (listen tty)
             (setf result (true-parse-request-modify-other-key-response tty))
             ) ;; end progn
        (close tty)
        ) ;; end unwind-protect
      )   ;; end let
    (cooked-mode)
    (return-from parse-request-modify-other-key-response result)
    )   ;; end let
  ) ;; end parse-request-modify-other-key-response

;; ========================================================================================

#+sbcl 
(defun true-current-physical-column-size ()
  (let (
        (result
          (ignore-errors
           (with-output-to-string (s)
             ;; /dev/tty からサイズを読み取り、出力を取得する
             (sb-ext:run-program "/bin/sh" '("-c" "stty size < /dev/tty")
                                 :output s :error nil :input nil))))
        )
    (if (and result (stringp result))
        (let ((parts (split-string result #\Space :remove-empty-p t)))
          (if (second parts)
              (or (parse-integer (second parts) :junk-allowed t)
                  *physical-line-window-size*) ;; パース失敗時の予備
              *physical-line-window-size*
              ) ;; end if
          )     ;; end let
        *physical-line-window-size*
        ) ;; end if
    )     ;; end let
  ) ;; end true-current-physical-column-size

#+clisp
(defun true-current-physical-column-size ()
  (ignore-errors
   ;; 標準入力を指定せずに実行
   (with-open-stream (s (ext:make-pipe-input-stream "stty size <&2"))
     (let ((result (read-line s nil nil)))
       (when (and result (stringp result))
         (let ((parts (split-string result #\Space :remove-empty-p t)))
           (if (second parts)
               (parse-integer (second parts) :junk-allowed t)
               *physical-line-window-size*
               ) ;; end if
           )     ;; end let
         )       ;; end when
       )         ;; end outer let
     )           ;; end with-open-stream
   )             ;; end ignore-errors
  ) ;; end current-physical-column-size

#+sbcl
(sb-sys:enable-interrupt 
 sb-unix:sigwinch
 (lambda (signal code scp)
   (declare (ignore signal code scp))
   ;; サイズが変わったらフラグを立てる。関数[line-edit-command-loop]で監視し行を書き直す。
   (setf *terminal-resized-p* t)
   )
 )

#+clisp
(ext:without-package-lock ("POSIX") ;; 機能していない。
  ;;(posix:signals posix:+SIGWINCH+
  ;;(posix::signal posix::sigwinch
  (posix::signal
   (symbol-value (find-symbol "SIGWINCH" :posix))
   #'(lambda (signal)
       (declare (ignore signal))
       ;; サイズが変わったらフラグを立てる。関数[line-edit-command-loop]で監視し行を書き直す。
       (setf *terminal-resized-p* t)
       )
   )
  )

#|
#+clisp
(ext:set-signal-handler ;; 機能していない。
 ext:*sigwinch*
 (lambda ()
   (format t "signal accept.~%")
   (setf *terminal-resized-p* t)
   ))
|#

;;
;; 初期設定用ファイルの自動読み込みなどを行う。
;;
;; 指定された初期設定ファイルをカレント・ディレクトリ→ホーム・ディレクトリの順に探す。
;; 読み込んだキーワード文字列を大文字小文字の違いを無視した辞書順にソートする。
;; キーワードのリストが[*syntax-info-list*]に、[*user-info-list*]をひとつにした遷移表が
;; [*default-completion-keymap*]に保存される。
;;=================================================================================
(eval-when (:load-toplevel :execute) ;; コンパイル済みコードの読み込み時とソースコードの読み込み時に評価する。

  (when (not (suppress-important-message))
    (format t "==========================================================~%")
    (format t "~a/~a~%" (line-edit-version) (lisp-implementation-type))
    (format t "readline package for Common Lisp, by Common Lisp.~%")
    (format t "Copyright (C) Isao Daigo 2000-2026~%")
    (format t "Type (help) for help.~%")
    (format t "(select-language xx) for select message-language to xx.~%")
    (format t "xx = :ja, :en, :de, :fr, :zh-hans, :zh-hant, :ko, :zu~%")
    #+ :use-history-pkg (format t "history-pkg commands available.~%")
    #- :use-history-pkg (format t "do not use history-pkg.~%")
    (format t "==========================================================~%")
    ) ;; end when

  ;; 日本語と英語、ドイツ語、フランス語、韓国語、中国語(簡体字/繁体字)、ズールー語のメッセージ・データを読み込む。
  (support-functions:read-registered-message)

  ;; 起動時の端末幅を初期値に設定する。
  (setf *last-terminal-size* (update-physical-column-size))

  ;; 前回終了時のエディタ・モードを記録した設定ファイルがあれば内容に従って設定する。メッセージ出力は抑止。
  (load (config-file-abs-path *editor-mode-file*) :if-does-not-exist nil)

  ;; --------------------------------------------------------------------------------------------------
  ;; ユーザ用の初期設定ファイルを読み込む。エディタ・モード設定があるかどうかは任意(ないかも知れない)。
  ;; 関数[verbose-message]や出力メッセージ用言語設定などを記録しておけるユーザ用初期設定ファイル。
  ;; [~/.config/line-edit/line-edit-init.lisp]を読み込んで内容を順に評価する。
  ;;
  (load (config-file-abs-path *line-edit-init*) :if-does-not-exist nil)
  ;; --------------------------------------------------------------------------------------------------

  ;;
  ;; 補完コマンド用の約800種のCommon Lisp関数情報とユーザ設定情報を設定する。
  ;;
  ;; (condense *user-completion-keymap* *syntax-completion-keymap*)とすれば[*syntax-info-file*]の定義
  ;; が[*user-info-list*]の定義より優先するが、[*syntax-info-file*]を書き換えないよう警告するため、そして
  ;; [*user-info-list*]の重複定義が無視されていることを明示するために敢えて重複定義をリストアップしている。
  ;;
  ;; 実際はふたつのキーマップを単に合成すれば第2引数のキーマップの定義が優先される。
  ;;
  ;; A, Bが遷移表であり、AとBにルートが同じで定義本体が異なる遷移ルートが存在するとき
  ;;    (condense A B) => 遷移表Bの定義が、合成された遷移表に残る。
  ;;    (condense B A) => 遷移表Aの定義が、合成された遷移表に残る。
  ;;
  ;;    (condense nil nil) => nil
  ;;    (condense A nil) => A
  ;;    (condense nil A) => A
  ;;    (condense A A) => A
  ;;    (condense B B) => B
  ;;
  ;; となるよう定義してある。
  ;;

  ;; 引数情報付きのキーワード・ファイルを読み込む。[read-keyword-file]のメッセージを抑止。
  (setf *syntax-info-list* (read-keyword-file (config-file-abs-path *syntax-info-file*) nil))

  (when (null *syntax-info-list*)
    (message :line-edit-pkg+eval-when-001 "標準関数の引数情報付き補完用キーワード・ファイル(~a)が空です。~%"
             (config-file-abs-path *syntax-info-file*))
    ) ;; end when

  (setf *syntax-target-words* nil)
  (dolist (p *syntax-info-list*)
    (pushnew (car p) *syntax-target-words*)
    )

  (setf *syntax-completion-keymap* (make-completion-keymap *syntax-info-list*))

  ;; ユーザが追加した補完候補情報を読み込む。[read-keyword-file]のメッセージを抑止。
  (setf *user-info-list* (read-keyword-file (config-file-abs-path *user-info-file*) nil))

  (when (null *user-info-file*)
    (message :line-edit-pkg+eval-when-002
             "ユーザ定義補完用キーワード・ファイル(~a)が存在しません。~%" *user-info-file*)
    ) ;; end when
    
  (setf *user-target-words* nil)
  (dolist (p *user-info-list*)
    (pushnew (car p) *user-target-words*)
    )

  (let (
        (bad-words nil)
        (ok-word-list nil)
        (new-user-info-list nil)
        (package-name-completion-keymap nil)
        )
    (setf bad-words (intersection *syntax-target-words* *user-target-words* :test #'string-equal))
    (when bad-words
      (message
       :line-edit-pkg+eval-when-003
       "~{~a~^, ~} がシステムの補完キーワード定義と重複しています。~%~a 内の重複する定義を使用しません。"
       bad-words (find-current-and-home-dir *user-info-file*))
      ) ;; end when

    (setf ok-word-list (set-difference *user-target-words* bad-words :test #'string-equal))

    (if ok-word-list ;; 重複した定義を除いてもユーザ側キーワード定義が残っている。
        (progn ;; 重複した定義部分を除いた[*user-info-list*]を作る。
          (dolist (p *user-info-list*)
            (when (member (car p) ok-word-list :test #'string-equal)
              (pushnew p new-user-info-list)
              )
            ) ;; end dolist
          (setf *user-info-list* new-user-info-list)
          (setf *user-completion-keymap* (make-completion-keymap *user-info-list*))
          (setf *default-completion-keymap*
                (condense *user-completion-keymap* *syntax-completion-keymap*)
                ) ;; end setf
          )       ;; end progn
        )         ;; end if

    ;; パッケージ名用の補完リストを作成する。
    ;;  ニックネーム → ニックネーム/プロパーネーム
    ;;  プロパーネーム → プロパーネーム/(find-package プロパーネーム)
    (setf package-name-completion-keymap (make-completion-keymap (make-info-list-for-package)))

    ;; [*default-completion-keymap*] := [package-name-completion-keymap]
    ;;                                  + [*user-completion-keymap*]
    ;;                                  + [*syntax-completion-keymap*] ;; 以後、固定。
    (setf *default-completion-keymap*
          (condense package-name-completion-keymap *default-completion-keymap*))
    (setf *current-completion-keymap* (copy-seq *default-completion-keymap*))
    (when (and package-name-completion-keymap (verbose-message))
      (message :line-edit-pkg+eval-when-004 "現時点で存在するパッケージ名に対する補完情報を作成しました。~%")
      ) ;; end when

    ) ;; end let

  ;;
  ;; 端末がカラー対応端末の場合、カーソルのカラー表示変更機能を備えているかを初回のみ検査する。
  ;; 設定ファイルを作成し、情報を書き込むので2回目以降は検査は行わない。
  ;; 実行時に挿入モード時のカーソル表示色を変更すると、自動的に変更内容を設定ファイルに記録する。
  ;;
  (block check-terminal-ability
    (let ((terminal-type nil) tmp)
      ;; 設定ファイルが存在していなければ作成する。存在していれば何もせずに終了する。
      (setf tmp (config-file-abs-path (cursor-info-file-name)))
      (if (probe-file tmp)
          (return-from check-terminal-ability nil) ;; ファイルが存在しているならチェック済み。
          (touch tmp)
          ) ;; end if

      (setf terminal-type (xterm-p))
      ;; 端末は vt340, vt382, vt420, vt510, vt520, vt525 のいずれかか？
      (when (member terminal-type +xterm-color-terminals+ :test #'eql)
        (when (verbose-message)
          (support-functions:message
           :line-edit-pkg+check-terminal-ability-001
           "端末に対する問い合わせによると端末はカラー表示対応端末であるDEC ~aです。~%"
           (subseq (symbol-name terminal-type) 0))
          )
        (format t "~%*** ")
        (support-functions:test-can-use-color-cursor) ;; 端末がカーソル色変更機能を備えているか検証。
        )
      ) ;; end let
    ) ;; end block check-terminal-ability

  ;; カーソル色変更機能有無確認ファイルの内容を読み込む。
  (when (null (load (config-file-abs-path (cursor-info-file-name)) :if-does-not-exist nil))
    (warn "cursor-info-file does not exist.~%") ;; 上記ブロックでの処理により必ず存在しているはず。
    )

  ;; 最終ガード : ここに至ってエディタ・モードが未定義ならば、デフォルトのエディタ・モードに設定する。
  (when (null *global-keymap*)
    (set-editor-mode *default-editor-mode* nil) ;; without message. default=emacs-mode.
    ;;(set-editor-mode "emacs-mode" nil)
    ;;(set-editor-mode "vi-mode" nil)
    ;;(set-editor-mode "WordMaster-mode" nil)
    )

  ) ;; end eval-when
;;=================================================================================

#+ :build-as-packages (provide :line-edit-pkg)
