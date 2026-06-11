;;;; last updated : 2026-01-30 17:10:08(JST)

;;;
;;; WordMasterのビデオ・モードのコマンドを定義。
;;;
(use-package :line-edit-pkg)
(use-package :external-command)
(in-package  :line-edit-pkg)

(wide-break-char)       ; default "word" definition.
(set-break-code #\^C)

;; 行頭からポイントまでを削除。
(defun delete-line-from-beginning-of-line (&optional (count 1))
  (setf count (select-repeat-count count))
  (kill-line (- count)))

;; 行全体を削除。
(defun delete-text ()
  (end-of-text)
  (set-mark-command)
  (beginning-of-text)
  (kill-region))

(defun wm-true-start-overwrite-mode ()
  (let (ch lst)
    (setf lst nil)
    (loop
      (setf ch (getch))
      (cond
        ((or
          (char= ch #\^V)
          (char= ch #\Newline))
         (return-from wm-true-start-overwrite-mode (values ch (reverse lst))))
        ((char= ch #\^H)
         (delete-backward-char))
        (t
         (delete-char)
         (self-insert ch)
         (push ch lst)
         (sync-point-and-cursor)))
      (sync-point-and-cursor))))

;;; 挿入モードに切り替えてC-vか #\Newlineが
;;; 入力されるまで入力文字を挿入する。#\Newlineが
;;; 入力された場合は入力全体を一気に終了させる。
;;;
;;; (glabal-set-key "\\C-v" #`wm-start-insert-mode)
(defun wm-start-overwrite-mode (&optional (count 1))
  (let (ch lst)
    (setf count (select-repeat-count count))
    (if (<= count 0) (setf count 1))
    (unwind-protect
         (progn ;; protected form
           (when (external-command:can-use-color-cursor-p) ;; 挿入モード中のカーソルの色を指定。
             (external-command:set-cursor-color-by-name (current-cursor-color-name))
             (finish-output)
             )
           (multiple-value-setq (ch lst) (wm-true-start-overwrite-mode))
           (dotimes (i (1- count)) (insert lst))
           (cond
             ((char= ch #\^V) ;; C-v
              (return-from wm-start-overwrite-mode nil))
             ((char= ch #\Newline)
              (postlude-input)
              (throw :exit-line-edit (packed-text))) ;; line-edit-pkg内の:exit-line-editに飛ぶ。
             (t (line-edit-break "at [start-insert-mode]: can not happen.~%")))
           )                                  ;; end progn
      ;; cleanup form
      (external-command:reset-cursor-color) ;; カーソルの色をリセット。
      )                                     ;; end unwind-protect
    )                                       ;; end let
  )                                         ;; end start-insert-mode
