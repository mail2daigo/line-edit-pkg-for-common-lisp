;;;; last updated : 2026-04-30 13:05:12(JST)

;;;
;;; vi-mode実装に必要な関数群の定義。
;;;
;;; 新しいコマンドを追加するために定義した関数は
;;;
;;;     (funcall '関数名)
;;; 
;;; という引数なしの形式で呼び出される。前置引数で設定
;;; される繰り返し回数は、定義する関数内部で
;;;
;;;     関数 (repeat-count)
;;;
;;; を呼び出すことで得られる。
;;;
;;; 定義した関数をキーボードからのコマンドによって呼び
;;; 出せるようにするには
;;;
;;;     (global-set-key "コマンド列" '関数名)
;;;
;;; とする。たとえば、キーボードから 'd' 'w'とタイプし
;;; たときに関数 delete-wordを呼び出すようにするには
;;;
;;;     (global-set-key "dw" 'delete-word)
;;;
;;; とする。
;;;
;;; キーボードからのコマンド入力によって呼び出されたの
;;; か、他の関数から (delete-word)のように通常の方法で
;;; 呼び出されたのかは、
;;;
;;;     関数 (call-by-keyboard-p)
;;;
;;; によって判別できる。
;;;
;;;     関数 (select-repeat-count n)
;;;
;;; は、現在の関数がキーボードからのコマンド入力によっ
;;; て呼び出されている場合は関数(repeat-count)の値を返
;;; し、そうでない場合は、自身の引数の値を返す。ただし、
;;; 関数(repeat-count)の値が nilの場合は、キーボードか
;;; らのコマンド入力によって呼び出されている場合であっ
;;; ても、自身の第 1引数を評価した値を返す。
;;;
;;; したがって、新たなコマンドを定義する関数において、
;;; 第 1引数を省略可能な繰り返し回数を受け取る引数とし
;;; て定義し、その第 1引数に省略時の既定値を与えて関数
;;; を定義すれば (select-repeat-count)を利用できる。
;;;
;;; たとえばポイントが存在する行の空白文字でない最初の
;;; 文字（の直前のポイント）に移動するコマンドは
;;;
;;; (defun first-char-of-line (&optional (count 1))
;;;   (setf count (select-repeat-count count))  ;繰り返し回数の取得。
;;;   (beginning-of-line count)                 ;指定回数行分前の行頭へ移動。
;;;   (skip-white-space))                       ;先頭の空白文字をスキップ。
;;;
;;; と定義できる。
;;;
;;; 前置引数によって繰り返し回数が与えられている状態で
;;; キーボードからのコマンドによって first-char-of-line
;;; が呼び出されれば、キーボードから与えられた繰り返し
;;; 回数がシンボル countに与えられ、キーボードから繰り
;;; 返し回数が与えられていなければ、シンボル countの省
;;; 略時既定値である '1'が与えられる。更に、この関数を
;;;
;;;     (first-char-of-line)
;;;
;;; という形式で他の関数から呼び出した場合にも、定義の
;;; 際に意図したとおり
;;;
;;;     (first-char-of-line 1)
;;;
;;; として機能する。当然だが、引数を省略せずに
;;;
;;;     (first-char-of-line 1)
;;;
;;; と書けば、シンボル countには '1'が与えられる。
;;;

(use-package :line-edit-pkg)
(use-package :external-command)
(in-package  :line-edit-pkg)

(wide-break-char)       ; default "word" definition.
(set-break-code #\^C)
(add-prefix-commands '(digit-argument))
(set-last-command-inhibit-list '(vi-redo))

;; (global-set-key "1"          'digit-argument) 
;; (global-set-key "2"          'digit-argument) 
;; (global-set-key "3"          'digit-argument) 
;; (global-set-key "4"          'digit-argument) 
;; (global-set-key "5"          'digit-argument) 
;; (global-set-key "6"          'digit-argument) 
;; (global-set-key "7"          'digit-argument) 
;; (global-set-key "8"          'digit-argument) 
;; (global-set-key "9"          'digit-argument) 
(defun digit-argument ()
  (unread-char (last-char))
  (universal-argument))

(declaim (ftype (function () (values character list)) true-start-insert-mode))

;;; (global-set-key "i" #'start-insert-mode) 
;;;
;;; 挿入モードに切り替えてESC(#\^[)か #\Newlineが
;;; 入力されるまで入力文字を挿入する。#\Newlineが
;;; 入力された場合は入力全体を一気に終了させる。
;;;
(defun start-insert-mode (&optional (count 1))
  (let (ch lst)
    (setf count (select-repeat-count count))
    (if (<= count 0) (setf count 1))
    (unwind-protect
         (progn ;; protected form
           (when (external-command:can-use-color-cursor-p) ;; 挿入モード中のカーソルの色を指定。
             (external-command:set-cursor-color-by-name (current-cursor-color-name))
             (finish-output)
             )
           (multiple-value-setq (ch lst) (true-start-insert-mode))
           (dotimes (i (1- count)) (insert lst))
           (cond
             ;;((char= ch #\^[) ;; ESC
             ((char= ch +ESC+) ;; ESC
              (return-from start-insert-mode nil))
             ((or
               (char= ch #\Newline)
               (char= ch #\Return) ;; [\#Return]の値は規格上未定義。処理系によっては[#\Newline]と同じ。
               )
              (postlude-input) ;; 入力処理の後始末を行う。
              (throw :exit-line-edit (packed-text))) ;; line-edit-pkg内の:exit-line-editに飛ぶ。
             (t (line-edit-break "at [start-insert-mode]: can not happen.~%")))
           ) ;; end progn
      ;; cleanup form
      (external-command:reset-cursor-color) ;; カーソルの色をリセット。
      ) ;; end unwind-protect
    )   ;; end let
  ) ;; end start-insert-mode

(defun true-start-insert-mode ()
  (let (ch lst)
    (setf lst nil)
    (loop
      (setf ch (getch))
      (cond
       ((or
         ;;(char= ch #\^[)
         (char= ch +ESC+)
         (char= ch #\Newline))
        (return-from true-start-insert-mode (values ch (reverse lst))))
       ;;((char= ch #\^H)
       ((char= ch +ctrl-h+)
        (delete-backward-char))
       (t
        (self-insert ch)
        (push ch lst))
       ) ;; end cond
      (display-line)
      ) ;; end loop
    ) ;; end let
  ) ;; end true-start-insert-mode

;(global-set-key "\\^" #'first-char-of-line) 
(defun first-char-of-line (&optional (count 1))
  (setf count (select-repeat-count count))
  (beginning-of-line count)
  (skip-white-space))

;(global-set-key "\\|" #'nth-char-of-line) 
(defun nth-char-of-line (&optional (count 1))
  (setf count (select-repeat-count count))
  (beginning-of-line count)
  (forward-char count))

;(global-set-key "W" #'next-xword) 
(defun next-xword (&optional (count 1))
  (setf count (select-repeat-count count))
  (narrow-break-char)
  (next-word count)
  (wide-break-char))

;(global-set-key "B" #'backward-xword) 
(defun backward-xword (&optional (count 1))
  (setf count (select-repeat-count count))
  (narrow-break-char)
  (backward-word count)
  (wide-break-char))

;(global-set-key "e" #'end-of-word) 
(defun end-of-word (&optional (count 1))
  (setf count (select-repeat-count count))
  (forward-word count)
  (backward-char))

;(global-set-key "E" #'end-of-xword) 
(defun end-of-xword (&optional (count 1))
  (setf count (select-repeat-count count))
  (narrow-break-char)
  (forward-word count)
  (backward-char)
  (wide-break-char))

;(global-set-key "I" #'insert-from-beginning-of-line) 
(defun insert-from-beginning-of-line (&optional (count 1))
  (setf count (select-repeat-count count))
  (beginning-of-line)
  ;;(sync-point-and-cursor)
  ;;(display-line)
  (start-insert-mode count))

;(global-set-key "O" #'insert-from-beginning-of-text) 
(defun insert-from-beginning-of-text (&optional (count 1))
  (setf count (select-repeat-count count))
  (beginning-of-text)
  ;;(sync-point-and-cursor)
  ;;(display-line)
  (start-insert-mode count))

;(global-set-key "a" #'append-char) 
(defun append-char (&optional (count 1))
  (setf count (select-repeat-count count))
  (forward-char)
  ;;(sync-point-and-cursor)
  ;;(display-line)
  (start-insert-mode count))

;(global-set-key "A" #'append-to-end-of-line) 
(defun append-to-end-of-line (&optional (count 1))
  (setf count (select-repeat-count count))
  (end-of-line)
  ;;(sync-point-and-cursor)
  ;;(display-line)
  (start-insert-mode count))

;(global-set-key "o" #'append-to-end-of-text) 
(defun append-to-end-of-text (&optional (count 1))
  (setf count (select-repeat-count count))
  (end-of-text)
  ;;(sync-point-and-cursor)
  ;;(display-line)
  (start-insert-mode count))

;(global-set-key "J" #'join-next-line) 
(defun join-next-line ()
  (end-of-line)
  (delete-char))

;(global-set-key "p" #'append-region) 
(defun append-region (&optional (count 1))
  (setf count (select-repeat-count count))
  (forward-char)
  (dotimes (i (abs count)) (yank)))

;(global-set-key "P" #'insert-region) 
(defun insert-region (&optional (count 1))
  (setf count (select-repeat-count count))
  (dotimes (i (abs count)) (yank)))

;(global-set-key "y l" #'vi-yank-char) 
(defun vi-yank-char (&optional (count 1))
  (let (pos)
    (setf count (select-repeat-count count))
    (setf pos (point))
    (set-mark-command)
    (forward-char count)
    (kill-ring-save)
    (move-point-to pos)))

;(global-set-key "y h" #'vi-yank-backward-char)
(defun vi-yank-backward-char (&optional (count 1))
  (let (pos)
    (setf count (select-repeat-count count))
    (setf pos (point))
    (set-mark-command)
    (backward-char count)
    (kill-ring-save)
    (move-point-to pos)))

;(global-set-key "y w" #'vi-yank-word) 
(defun vi-yank-word (&optional (count 1))
  (let (pos)
    (setf count (select-repeat-count count))
    (setf pos (point))
    (set-mark-command)
    (next-word count)
    (kill-ring-save)
    (move-point-to pos)))

;(global-set-key "y b" #'vi-yank-backward-word) 
(defun vi-yank-backward-word (&optional (count 1))
  (let (pos)
    (setf count (select-repeat-count count))
    (setf pos (point))
    (set-mark-command)
    (backward-word count)
    (kill-ring-save)
    (move-point-to pos)))

;(global-set-key "y W" #'vi-yank-xword) 
(defun vi-yank-xword (&optional (count 1))
  (let (pos)
    (setf count (select-repeat-count count))
    (setf pos (point))
    (set-mark-command)
    (next-xword count)
    (kill-ring-save)
    (move-point-to pos)))

;(global-set-key "y B" #'vi-yank-backward-xword) 
(defun vi-yank-backward-xword (&optional (count 1))
  (let (pos)
    (setf count (select-repeat-count count))
    (setf pos (point))
    (set-mark-command)
    (backward-xword count)
    (kill-ring-save)
    (move-point-to pos)))

;(global-set-key "y 0" #'vi-yank-from-beginning-of-line)        ;zero
(defun vi-yank-from-beginning-of-line (&optional (count 1))
  (let (pos)
    (setf count (select-repeat-count count))
    (setf pos (point))
    (set-mark-command)
    (beginning-of-line count)
    (kill-ring-save)
    (move-point-to pos)))

;(global-set-key "y $" #'vi-yank-to-end-of-line) 
(defun vi-yank-to-end-of-line (&optional (count 1))
  (let (pos)
    (setf count (select-repeat-count count))
    (setf pos (point))
    (set-mark-command)
    (end-of-line count)
    (kill-ring-save)
    (move-point-to pos)))

;(global-set-key "y $" #'vi-yank-line) 
(defun vi-yank-line ()
  (let (pos)
    (setf pos (point))
    (beginning-of-line 1)
    (set-mark-command)
    (end-of-line 1)
    (kill-ring-save)
    (move-point-to pos)))

;(global-set-key "r" #'replace-character) 
(defun replace-character (&optional (count 1))
  (let (ch)
    (setf count (select-repeat-count count))
    (if (<= count 0) (setf count 1))
    (setf ch (getch))
    (dotimes (i count)
      (delete-char)
      (self-insert ch))
    ;;(sync-point-and-cursor)
    (display-line)
    )
  )

;(global-set-key "R" #'replace-characters) 
(defun replace-characters (&optional (count 1))
  (let (ch lst)
    (setf count (select-repeat-count count))
    (setf lst nil)
    (loop
      (setf ch (getch))
      (if (char= ch #\^[) (return))
      (delete-char)
      (self-insert ch)
      (push ch lst)
      ;;(sync-point-and-cursor)
      (display-line)
      ) ;; end loop
    (setf lst (reverse lst))
    (if (<= count 0) (setf count 1))
    (dotimes (i (1- count)) (insert lst))
    ;;(sync-point-and-cursor)
    (display-line)
    )
  )

;(global-set-key "d w" #'delete-word) 
(defun delete-word (&optional (count 1))
  (setf count (select-repeat-count count))
  (kill-word count))

;(global-set-key "d b" #'delete-backward-word) 
(defun delete-backward-word (&optional (count 1))
  (setf count (select-repeat-count count))
  (backward-kill-word count))

;(global-set-key "d W" #'delete-xword) 
(defun delete-xword (&optional (count 1))
  (setf count (select-repeat-count count))
  (narrow-break-char)
  (delete-word count)
  (wide-break-char))

;(global-set-key "d B" #'delete-backward-xword) 
(defun delete-backward-xword (&optional (count 1))
  (setf count (select-repeat-count count))
  (narrow-break-char)
  (delete-backward-word count)
  (wide-break-char))

;(global-set-key "d $" #'delete-line) 
(defun delete-line (&optional (count 1))
  (setf count (select-repeat-count count))
  (kill-line count))

;(global-set-key "d 0" #'delete-line-from-beginning-of-line) 
(defun delete-line-from-beginning-of-line (&optional (count 1))
  (setf count (select-repeat-count count))
  (delete-line (- count)))

;(global-set-key "d d" #'delete-text) 
(defun delete-text ()
  (end-of-text)
  (set-mark-command)
  (beginning-of-text)
  (kill-region))

;(global-set-key "c l"          'change-character) 
;(global-set-key "s"            'change-character) 
(defun change-character (&optional (count 1))
  (setf count (select-repeat-count count))
  (delete-char count)
  (self-insert (getch)))

;(global-set-key "c h"          'change-backward-character) 
(defun change-backward-character (&optional (count 1))
  (setf count (select-repeat-count count))
  (delete-backward-char count)
  (start-insert-mode))

;(global-set-key "c w" #'change-word) 
(defun change-word (&optional (count 1))
  (setf count (select-repeat-count count))
  (delete-word count)
  ;;(sync-point-and-cursor)
  ;;(display-line)
  (start-insert-mode))

;(global-set-key "c b" #'change-backward-word) 
(defun change-backward-word (&optional (count 1))
  (setf count (select-repeat-count count))
  (delete-backward-word count)
  ;;(sync-point-and-cursor)
  ;;(display-line)
  (start-insert-mode))

;(global-set-key "c W" #'change-xword) 
(defun change-xword (&optional (count 1))
  (setf count (select-repeat-count count))
  (narrow-break-char)
  (delete-word count)
  ;;(sync-point-and-cursor)
  ;;(display-line)
  (start-insert-mode)
  (wide-break-char))

;(global-set-key "c B" #'change-backward-xword) 
(defun change-backward-xword (&optional (count 1))
  (setf count (select-repeat-count count))
  (delete-backward-xword count)
  ;;(sync-point-and-cursor)
  ;;(display-line)
  (start-insert-mode))

;(global-set-key "c $" #'change-to-end-of-line) 
(defun change-to-end-of-line (&optional (count 1))
  (setf count (select-repeat-count count))
  (delete-line count)
  ;;(sync-point-and-cursor)
  ;;(display-line)
  (start-insert-mode))

;(global-set-key "c 0" #'change-from-beginning-of-line) 
(defun change-from-beginning-of-line ()
  (delete-line -1)
  (beginning-of-line)
  (start-insert-mode))

;(global-set-key "c c" #'change-line) 
;(global-set-key "S" #'change-line) 
(defun change-line ()
  (beginning-of-line)
  (replace-characters)
  (delete-line)
  ;;(sync-point-and-cursor)
  (display-line)
  )

;(global-set-key "\\~" #'exchange-case) 
(defun exchange-case (&optional (count 1))
  (let (ch)
    (setf count (select-repeat-count count))
    (if (<= count 0) (setf count 1))
    (dotimes (i count nil)
      (setf ch (current-char))
      (cond
       ((upper-case-p ch)
        (delete-char)
        (self-insert (char-downcase ch)))
       ((lower-case-p ch)
        (delete-char)
        (self-insert (char-upcase ch)))
       (t (forward-char))))))

;(global-set-key "\\." #'vi-redo) 
(defun vi-redo (&optional (count 1))
  (let (cmd n)
    (setf count (select-repeat-count count))
    (if (<= count 0) (setf count 1))
    (setf cmd (last-command))
    (setf n (repeat-count))
    (dotimes (i count t)
      (funcall cmd n))))

;(global-set-key "\\(" #'insert-symbolic-expression)
(defun insert-symbolic-expression ()
  (self-insert #\()
  ;;(sync-point-and-cursor)
  (display-line)
  (start-insert-mode))

(defun vi-warning (ch)
  (audio-bell)
  (format nil "un-defined key sequence reached (~a)" ch))

(in-package :cl-user)
