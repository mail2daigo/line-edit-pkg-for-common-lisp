;;;; 
;;;; last updated : 2026-07-19 11:00:39(JST)
;;;; 
;;;; Copyright (C) [2025-2026] [Isao Daigo]
;;;; 
;;;; This program is free software: you can redistribute it and/or modify
;;;; it under the terms of the GNU General Public License as published by
;;;; the Free Software Foundation, either version 3 of the License, or
;;;; any later version.
;;;; 
;;;; This program is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;; GNU General Public License for more details.
;;;; 
;;;; You should have received a copy of the GNU General Public License
;;;; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;;;;
;;;;
;;;; プログラムから出力する文字列をカラーで表示するためのANSI Common Lisp用パッケージ
;;;;
;;;; 実行に利用できるのはxterm互換端末(推奨)かANSI互換端末。dumb(ダム)端末でも動くが色は出ない。
;;;; ANSI端末互換かxterm端末互換かは本パッケージ・ロード時に環境変数"TERM"の内容を読んでxterm互換か
;;;; ansi互換かを調べて自動的に設定している。
;;;;
;;;; Common Lispの実行環境から
;;;;
;;;;            (print-colored-string 'blue "Blue string.")
;;;;
;;;; とすると青色で[Blue string.]と表示される。戻り値は第2引数自身。第2引数の文字列部分に
;;;; 書式付き指定を行いたい場合は
;;;;
;;;;            (print-colored-string 'blue (format nil "(+ 2 3) = ~d" (+ 2 3)))
;;;;
;;;; などと関数[format]の第1引数に[nil]を指定して文字列を作れば良い。この例であれば
;;;;
;;;;            (+ 2 3) = 5
;;;;
;;;; という文字列が青色で表示される。結果として ["(+ 2 3) = 5"]という文字列が返る。
;;;;
;;;; キーワード引数 :bold :italic :underline :invert :strike に[nil]以外を与えて呼び出すと
;;;;
;;;;            :bold t                 太字または高輝度にする(端末による)。
;;;;            :italic t               斜体にする。
;;;;            :underine t             下線をつける
;;;;            :invert t               前景色と背景色を入れ替える。
;;;;            :strike t               打ち消し線を引く。
;;;;
;;;; という文字属性で出力できる。複数指定可能。順序不問。同じ属性を複数回指定しても1回指定したのと
;;;; 同じ。
;;;;
;;;; 代表的な色記号としてxterm系とansi系に対して以下のように色番号を定義したシンボルを用意してある。
;;;; この定義済みの色記号を使うことでxterm互換256色端末とANSI互換8色端末で色指定を切り替えることなく
;;;; 共通のコードで矛盾なく同じプログラム・コードが使えます。
;;;;
;;;; 下記がXterm系256色でのカラー・コードの初期値。規格上の純色を割り当ててある。
;;;; 関数[adjust-xterm-color-code]で自由に変更可。
;;;;
;;;; 'red      196
;;;; 'green     46
;;;; 'blue      21
;;;; 'cyan      51
;;;; 'magenta  201 
;;;; 'yellow   226
;;;; 'gray     239
;;;; 'black    232
;;;;
;;;; ansiカラーの場合、[gray]が[white]に置き換わり最大8色まで。こちらは基本色と、その高輝度版の
;;;; 8色✕2しかない。色の変更は色の入れ替えになり混乱するので再定義は禁止している。
;;;;
;;;; 色見本は
;;;; 
;;;;            (show-all-color)
;;;; 
;;;; とすると実行中の端末モードがxterm互換端末かANSI互換端末かに応じて色見本が出力される。
;;;; xterm互換端末なら256色。ANSI互換端末なら8色が表示される。xterm互換端末では色相変化、
;;;; 明度変化、彩度変化のグラデーション表示を行うこともできる。
;;;;
;;;;            詳細は[print-color-string使用方法.pdf]を参照。
;;;;
;;;; xtermの256色から red, green, blue, cyan, magenta, yellow, gray, black の8色に
;;;; どの色(カラー・コード)を与えるかを再定義するための関数[adjust-xterm-color-code]を用意してある。
;;;;
;;;;            (adjust-xterm-color-code 'red 162)
;;;;
;;;; とするとxterm互換256色モードでの[red]のカラー・コードがカラー・コード162の色に置き換わる。
;;;;
;;;; 第1引数に色名を指定し、第2引数に設定したい色のカラーコードを与える。
;;;; この関数を引数なしで呼び出すと、現在のカラーコードの見本を出力する。
;;;; 第1引数を指定して第2引数を省略すると第1引数で指定した現在の色見本を表示する。
;;;; 第1引数がシンボルの場合は、そのシンボルに第2引数で指定されたカラー・コードを設定し、色見本を表示する。
;;;; 第1引数はユーザ定義のシンボルでも良い。第1引数はカラー・コード(0..255)でも良いが、その場合、第2引数
;;;; は指定できない。第1引数で指定したカラー・コードの色見本を表示する。
;;;;
;;;; 第１引数に指定できる既定のシンボルとして[red,green,yellow,blue,magenta,cyan,gray,black]
;;;; を用意してある。['blue]のように指定すれば定義された色が出力される。
;;;;
;;;; 実行例は「print-color-string使用方法.pdf」を参照。
;;;;

#+ :build-as-packages
(defpackage :print-color-string
  (:use :common-lisp)
  (:use :support-functions)
  (:export
   #:adjust-xterm-color-code    ;; type (documentation 'adjust-xterm-color-code 'function)
   #:cancel-bold
   #:cancel-invert
   #:cancel-italic
   #:cancel-strike
   #:cancel-underline
   #:change-to-black            ;; #'(lambda () (print-color-string:chg-attr :color 'black))と同じ。
   #:change-to-blue             ;; 以下同様。
   #:change-to-cyan
   #:change-to-gray
   #:change-to-green
   #:change-to-magenta
   #:change-to-red
   #:change-to-yellow
   #:chg-attr                   ;; 文字列の途中で文字属性を変更するエスケープ・シーケンスを作成する。
   #:current-terminal-type
   #:help-color
   #:make-escape-sequence       ;; 指定されたエスケープ・シーケンス文字列を組み立てる。
   #:print-colored-string       ;; type (documentation 'print-colored-string 'function)
   #:set-ansi-text-color
   #:set-ansi-background-color
   #:set-to-bold
   #:set-to-invert
   #:set-to-italic
   #:set-to-strike
   #:set-terminal-env
   #:set-to-underline
   #:set-xterm-text-color
   #:set-xterm-background-color
   #:show-all-color             ;; xtermの全256色の色見本を表示する。
   #:show-all-gradation         ;; 色相・明度・彩度のxterm 256色で表現可能なグラデーションを表示する。
   #:show-ansi-color            ;; ansi端末モードで利用できる基本8色の色見本を表示する。
   #:show-basic-colors          ;; 記号名で定義した基本8色の色見本を表示する。
   #:show-hue-gradient          ;; 指定した2つの色の間の色相変化を表示する。
   #:show-saturation-gradient   ;; 指定した純色から高明度グレーへの彩度変化を表示する。
   #:show-xterm-color           ;; xterm端末モードで利用できる全256色の色見本を表示する。
   #:reset-all-attributes       ;; バグなどで色と文字属性が乱れた場合にすべての色と属性情報をリセットする。
   )
  ) ;; end defpackage

(declaim (optimize (safety 0) (speed 3) (space 0) (debug 0) (compilation-speed 0)))     ;; maximum speed.
;;(declaim (optimize (safety 3) (speed 0) (space 0) (debug 3) (compilation-speed 0)))   ;; maximum safety

#+ :build-as-packages
(in-package :print-color-string) ;; このファイル末尾に[(provide :print-color-string)]がある。

;;; Generated FTYPE declaims for print-color-string.lisp (by sbcl. Modified)
;;; ----------------------------------------------------
(declaim (ftype (function nil fixnum) return-fixnum))
(declaim (ftype (function nil fixnum) save-terminal-env))
(declaim (ftype (function nil fixnum) restore-terminal-env))
(declaim (ftype (function (symbol &optional t) fixnum) set-terminal-env))
(declaim (ftype (function nil cons) current-terminal-env))
(declaim (ftype (function nil (member t)) reset-terminal-env))
(declaim (ftype (function (&optional t t t) (member t)) adjust-xterm-color-code))
(declaim (ftype (function (t t &key (:bold t) (:italic t) (:underline t) (:invert t)
                             (:strike t) (:text-or-background t) (:use-terpri t)) t)
		print-colored-string))
(declaim (ftype (function nil symbol) current-terminal-type))
(declaim (ftype (function nil (member nil xterm ansi)) is-xterm-or-ansi))
(declaim (ftype (function (&optional t) symbol) current-color))
(declaim (ftype (function (t t) (or nil fixnum)) get-numerical-color-code))
(declaim (ftype (function (t) t) ansi-terminal-p))
(declaim (ftype (function (t) t) xterm-terminal-p))
;;(declaim (ftype (function (symbol) (member t)) set-xterm-text-color))
;;(declaim (ftype (function (symbol) (member t)) set-xterm-background-color))
;;(declaim (ftype (function (symbol) (member t)) set-ansi-text-color))
;;(declaim (ftype (function (symbol) (member t)) set-ansi-background-color))
(declaim (ftype (function nil (member t)) reset-all-attributes))
(declaim (ftype (function
                 (t &key (:bold t) (:italic t) (:underline t) (:invert t) (:strike t))
                 (or list (simple-array character (0)))) make-escape-sequence))
(declaim (ftype (function (t &key (:bold t) (:italic t) (:underline t) (:invert t) (:strike t))
                 (or string null)) put-escape-sequence))
(declaim (ftype (function nil (member t)) show-basic-colors))
(declaim (ftype (function nil (member nil)) help-color))
;;(declaim (ftype (function (&optional t) t) debug-print))
(declaim (ftype (function (t) boolean) alist-p))
(declaim (ftype (function (&key (:start fixnum) (:end fixnum)) (values boolean &optional))
                show-xterm-color-range))
(declaim (ftype (function (&key (:range t)) fixnum) show-xterm-color))
(declaim (ftype (function (&key (:start fixnum) (:end fixnum)) (values boolean &optional))
                show-ansi-color))
(declaim (ftype (function nil fixnum) show-all-color))
(declaim (ftype (function (t)
                 (values
                  (or (simple-array character (18))
                      (simple-array character (14))
                      (simple-array character (13)) null)
                  &optional)) valid-xterm-256-color-code-p))
(declaim (ftype (function (t) *) valid-xterm-256-color-code-range-p))
(declaim (ftype (function (t)
                 (values
                  (or (simple-array character (3)) (simple-array character (6))
                      (simple-array character (7)) (simple-array character (4))
                      (simple-array character (5)) null)
                  &optional)) valid-ansi-8-color-code-p))
(declaim (ftype (function (t) *) valid-ansi-8-color-code-range-p))
(declaim (ftype (function (fixnum fixnum fixnum) (values fixnum &optional)) xterm-rgb-code))
(declaim (ftype (function (fixnum fixnum fixnum fixnum fixnum fixnum)
                          (values list &optional)) make-gradient))
(declaim (ftype (function (list fixnum fixnum fixnum fixnum fixnum fixnum)
                          (values boolean &optional)) display-gradient))
(declaim (ftype (function (&optional fixnum fixnum) boolean) show-red-brightness-to-light))
(declaim (ftype (function (&optional fixnum fixnum) boolean) show-red-brightness-to-dark))
(declaim (ftype (function (&key (:to-light t)) boolean) show-red-brightness))
(declaim (ftype (function (&optional fixnum fixnum) boolean) show-green-brightness-to-light))
(declaim (ftype (function (&optional fixnum fixnum) boolean) show-green-brightness-to-dark))
(declaim (ftype (function (&key (:to-light t)) boolean) show-green-brightness))
(declaim (ftype (function (&optional fixnum fixnum) boolean) show-blue-brightness-to-light))
(declaim (ftype (function (&optional fixnum fixnum) boolean) show-blue-brightness-to-dark))
(declaim (ftype (function (&key (:to-light t)) boolean) show-blue-brightness))
(declaim (ftype (function (&optional fixnum fixnum) boolean) show-cyan-brightness-to-light))
(declaim (ftype (function (&optional fixnum fixnum) boolean) show-cyan-brightness-to-dark))
(declaim (ftype (function (&key (:to-light t)) boolean) show-cyan-brightness))
(declaim (ftype (function (&optional fixnum fixnum) boolean) show-magenta-brightness-to-light))
(declaim (ftype (function (&optional fixnum fixnum) boolean) show-magenta-brightness-to-dark))
(declaim (ftype (function (&key (:to-light t)) boolean) show-magenta-brightness))
(declaim (ftype (function (&optional fixnum fixnum) boolean) show-yellow-brightness-to-light))
(declaim (ftype (function (&optional fixnum fixnum) boolean) show-yellow-brightness-to-dark))
(declaim (ftype (function (&key (:to-light t)) boolean) show-yellow-brightness))
(declaim (ftype (function (&key (:to-light t)) (values null &optional)) show-monochrome-brightness))
(declaim (ftype (function (fixnum fixnum fixnum) (values (cons single-float) &optional)) rgb-to-hsv))
(declaim (ftype (function (single-float single-float single-float) (values (cons fixnum) &optional))
                hsv-to-rgb))
(declaim (ftype (function (fixnum fixnum fixnum)
                 (values (or (integer 0 0) (integer 16 255)) &optional)) calculate-xterm-code))
(declaim (ftype (function (fixnum fixnum fixnum fixnum fixnum fixnum
                                  &key (:no-duplicates t)) list) hue-gradient-xterm))
(declaim (ftype (function (fixnum fixnum fixnum &key (:no-duplicates t)) list)
                saturation-gradient-xterm-reverse))
(declaim (ftype (function (fixnum fixnum fixnum &key (:no-duplicates t))
                 (values
                  ;;(or list (simple-array * (*)) sb-kernel:extended-sequence)
                  list
                  &optional)) saturation-gradient-xterm))
(declaim (ftype (function (&key (:from t) (:to t)) (values null &optional)) show-hue-gradient))
(declaim (ftype (function (t &key (:to-light t)) (values null &optional)) show-saturation-gradient))
(declaim (ftype (function (t &key (:to-light t)) boolean) show-brightness))
(declaim (ftype (function (&key (:hue t) (:brightness t) (:saturation t))
                 (values boolean &optional)) show-all-gradation))
(declaim (ftype (function (fixnum) (values cons &optional)) xterm-code-to-rgb))
(declaim (ftype (function (t &key (:test t)) (values list &optional)) remove-duplicates-preserving-order))
(declaim (ftype (function nil (values (or simple-string null) &optional)) terminal-type))
(declaim (ftype (function nil
                 (values (or (mod 17592186044411) boolean) &optional)) is-xterm-compatible-sub))
(declaim (ftype (function nil (values (member nil xterm) &optional)) is-xterm-compatible))
(declaim (ftype (function nil (values boolean &optional)) is-ansi-compatible-sub))
(declaim (ftype (function nil (values (member ansi nil) &optional)) is-ansi-compatible))
(declaim (ftype (function nil (values boolean &optional)) dumb-terminal-p-sub))
(declaim (ftype (function nil (values (member nil dumb) &optional)) dumb-terminal-p))
(declaim (ftype (function (fixnum)
                 (values (or null (simple-array character (*))) &optional)) make-space))
(declaim (ftype (function (fixnum) (or string nil)) show-color))

;; SGR(Select Graphic Rendition)のStyle Attributes.
(defconstant +bold+              1) ;; 太字または高輝度にする。
(defconstant +cancel-bold+      22) ;; 太字解除。
(defconstant +italic+            3) ;; 斜体にする。
(defconstant +cancel-italic+    23) ;; 斜体解除。
(defconstant +underline+         4) ;; 下線をつける
(defconstant +cancel-underline+ 24) ;; 下線解除。
(defconstant +invert+            7) ;; 前景色と背景色を入れ替える。
(defconstant +cancel-invert+    27) ;; 前景色と背景色を入れ替え解除。。
(defconstant +strike+            9) ;; 打ち消し線を引く。      
(defconstant +cancel-strike+    29) ;; 打ち消し線解除。

(defconstant max-resolution 256)

(defconstant magic-number 0) ;; fixnum for compiler optimaization.

;; それぞれの「色」に対して設定するカラー・コード値の定義。色味は好みで変更できる。
;; xcolorの場合、最大256色定義できる。https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
;; (show-all-color)と上記の設定方法を参照。
(defparameter *xcolor-black*    232) ;; R G B = 0 0 0
(defparameter *xcolor-red*      196) ;; R G B = 5 0 0
(defparameter *xcolor-green*     46) ;; R G B = 0 5 0
(defparameter *xcolor-blue*      21) ;; R G B = 0 0 5
(defparameter *xcolor-cyan*      51) ;; R G B = 0 5 5 (=G+B)
(defparameter *xcolor-magenta*  201) ;; R G B = 5 0 5 (=R+B)
(defparameter *xcolor-yellow*   226) ;; R G B = 5 5 0 (=R+G)
(defparameter *xcolor-gray*     239) ;; 232..255の24段階のグレースケール中の値。

;; ansiカラーの場合、最大8色まで。カラー・コードは2進3ビット。
;; つまりカラー・コード = (赤のビット x 2^0) + (緑のビット x 2^1) + (青のビット x 2^2)
(defparameter *ansi-black*      0) ;; R G B = 0 0 0
(defparameter *ansi-red*        1) ;; R G B = 1 0 0
(defparameter *ansi-green*      2) ;; R G B = 0 1 0
(defparameter *ansi-yellow*     3) ;; R G B = 1 1 0
(defparameter *ansi-blue*       4) ;; R G B = 0 0 1
(defparameter *ansi-magenta*    5) ;; R G B = 1 0 1
(defparameter *ansi-cyan*       6) ;; R G B = 0 1 1
(defparameter *ansi-white*      7) ;; R G B = 1 1 1

(defparameter *xterm-basic-color-list*
  '(
    (red        .       *xcolor-red*)
    (green      .       *xcolor-green*)
    (blue       .       *xcolor-blue*)
    (cyan       .       *xcolor-cyan*)
    (magenta    .       *xcolor-magenta*)
    (yellow     .       *xcolor-yellow*)
    (gray       .       *xcolor-gray*)
    (black      .       *xcolor-black*)
    )
  )

(defparameter *ansi-basic-color-list*
  '(
    (black     .       *ansi-black*)
    (red       .       *ansi-red*)
    (green     .       *ansi-green*)
    (blue      .       *ansi-blue*)
    (cyan      .       *ansi-cyan*)
    (magenta   .       *ansi-magenta*)
    (yellow    .       *ansi-yellow*)
    (white     .       *ansi-white*)
    )
  )

(defparameter *predefined-xcolor-names* (mapcar #'first *xterm-basic-color-list*))
(defparameter *predefined-ansi-names* (mapcar #'first *ansi-basic-color-list*))
(defparameter *predefined-color-names* (union *predefined-xcolor-names* *predefined-ansi-names*))

(defparameter *predefined-xterm-terminal-type* '(xterm-text-color xterm-background-color xterm-terminal))
(defparameter *predefined-ansi-terminal-type* '(ansi-text-color ansi-background-color ansi-terminal))
(defparameter *predefined-terminal-type*
  (append *predefined-xterm-terminal-type* *predefined-ansi-terminal-type*))

(defparameter *sample-string* "0123456789")

;; 彩色方法として背景色を選択する場合は「'xterm-background-color」を、
;; 色付き文字を選択する場合は「'xterm-text-color」を定義する。
;; 実行時に定義を変更する場合は関数「color-type」で設定する。
(defvar *current-terminal-type* 'xterm-text-color)
;;(defvar *current-terminal-type* 'xterm-text-color)
;;(defvar *current-terminal-type* 'ansi-background-color)
;;(defvar *current-terminal-type* 'ansi-text-color)

(defparameter *terminal-capability* 'xterm)
;;(defparameter *terminal-capability* 'ansi)
;;(defparameter *terminal-capability* 'dumb)

;;(defparameter *basic-color-list* *ansi-basic-color-list*)
(defparameter *basic-color-list* *xterm-basic-color-list*)

(defvar *current-color* 'black) ;; Initial value.

;;(defvar *color-mode-level* 1)
(defvar *current-env* nil)
;;(defvar *debug-print* nil)

(defmacro suppress-style-warning (&body body)
  "指定された BODY 内で style-warning を抑制する。"
  `(handler-bind ((style-warning #'muffle-warning))
     ,@body))

(defun save-terminal-env ()
  (push (list *current-terminal-type* *current-color*) *current-env*)
  (when (debug-print-p "save-terminal-env")
    (format t "save-terminal-env:*current-env*=~s~%" *current-env*)
    )
  (return-fixnum) ;; returns magic-number (fixnum)
  )

(defun restore-terminal-env ()
  (let (last-env)
    (setf last-env (pop *current-env*))
    (cond
      ((and
        (null last-env)
        (is-xterm-compatible)
        )
       (set-terminal-env 'xterm-text-color 'black) ;; 初期値。
       (reset-all-attributes)
       )
      ((and
        (null last-env)
        (is-ansi-compatible)
        )
       (set-terminal-env 'ansi-text-color 'black) ;; 初期値。
       (reset-all-attributes)
       )
      (t
       ;;(set-terminal-type (nth 0 last-env))
       ;;(current-color (nth 1 last-env))
       (set-terminal-env (nth 0 last-env) (nth 1 last-env))
       (reset-all-attributes)
       )
      ) ;; end cond
  (when (debug-print-p "restore-terminal-env")
    (format t "restore-terminal-env:*current-env*=~s~%" *current-env*)
    )
    )   ;; end let
  (return-fixnum) ;; return fixnum for optimaization.
  ) ;; end restore-terminal-env

(defun set-terminal-env (terminal-type &optional (color nil))
  "端末タイプと出力する色を設定する。
see ref. http://en.wikipedia.org/wiki/ANSI_escape_code"
  (cond
    ((string-equal-by-symbol-name terminal-type 'xterm-text-color)
     (setf *basic-color-list* *xterm-basic-color-list*)
     (setf *current-terminal-type* 'xterm-text-color)
     (when (identity color)
       (set-xterm-text-color color) ;; (setf *current-color* color)も行っている。
       )
     )
    ((string-equal-by-symbol-name terminal-type 'xterm-background-color)
     (setf *basic-color-list* *xterm-basic-color-list*)
     (setf *current-terminal-type* 'xterm-background-color)
     (when (identity color)
       (set-xterm-background-color color) ;; (setf *current-color* color)も行っている。
       )
     )
    ((string-equal-by-symbol-name terminal-type 'ansi-text-color)
     (setf *basic-color-list* *ansi-basic-color-list*)
     (setf *current-terminal-type* 'ansi-text-color)
     (when (identity color)
       (set-ansi-text-color color) ;; (setf *current-color* color)も行っている。
       )
     )
    ((string-equal-by-symbol-name terminal-type 'ansi-background-color)
     (setf *basic-color-list* *ansi-basic-color-list*)
     (setf *current-terminal-type* 'ansi-background-color)
     (when (identity color)
       (set-ansi-background-color color) ;; (setf *current-color* color)も行っている。
       )
     )
    (t
     ;;(format t "~%引数(terminal-type=~s)に不正な値が設定されています。" terminal-type)
     (message :print-color-string+set-terminal-env-001
              "~%引数(terminal-type=~s)に不正な値が設定されています。" terminal-type)
     (reset-all-attributes)
     (break)
     )
    ) ;; end cond
  (return-fixnum)
  ) ;; end set-terminal-env

(defun current-terminal-env ()
  (list (current-terminal-type) (current-color))
  )

(defun reset-terminal-env ()
  "端末に対する以後の出力を端末既定色に設定する。"
  ;;(when (>= (color-mode-level) 1)
  (setf *current-env* nil)
  (cond
    ((is-xterm-compatible)
     (reset-all-attributes)
     (set-terminal-env 'xterm-text-color 'black)
     ;;(setf *terminal-capability* 'xterm)
     )
    ((is-ansi-compatible)
     (reset-all-attributes)
     (set-terminal-env 'ansi-text-color 'black)
     ;;(setf *terminal-capability* 'ansi)
     )
    ((dumb-terminal-p)
     ;;(setf *terminal-capability* 'dumb)
     ;;(error "現在の端末タイプは~aです。ANSI互換端末かXterm互換端末でないと利用できません。~%" (terminal-type))
     (return-fixnum)
     )
    )
  (reset-all-attributes)
  ;;)
  (return-from reset-terminal-env  t)
  )

(defun adjust-xterm-color-code
    (&optional (color nil color-sw) (new-color-code nil new-color-code-sw) (quiet nil))
  "Xターミナルの256色から red, green, blue, cyan, magenta, yellow, black, gray の8色に
どの色（カラーコード）を与えるかを再定義するための関数。
この関数を引数なしで呼び出すと、現在のカラーコードの見本を出力する。
第1引数に色名を指定し、第2引数に設定したい色のカラーコードを与える。
第1引数を指定して第2引数を省略すると第1引数で指定した現在の色見本を表示する。
第1引数と第2引数を両方指定すると第1引数で指定された色を第二引数で指定されたカラー・コードの
色に変更して、変更前と変更後の色見本を表示する。
"
  (let ((color-change-before nil) (color-code nil))

    (save-terminal-env)
    (cond
      ((ansi-terminal-p (current-terminal-type))
       ;;(format t "ANSI互換端末ではカラーコードの再定義はできません。~%")
       (message :print-color-string+adjust-xterm-color-code-001
                "ANSI互換端末ではカラーコードの再定義はできません。~%")
       )
      ((and ;; 引数が2つとも存在しないとき。
        (null color-sw)
        (null new-color-code-sw)
        )
       (when (not quiet)
         (show-basic-colors)
         )
       )
      ((and ;; 第1引数が既定の色名シンボルで第2引数が指定されていなかった場合。
        (symbolp color)
        (member-by-symbol-name color *predefined-xcolor-names*)
        (null new-color-code-sw)
        )
       (when (not quiet)
         ;;(format t "現在の ~a のカラー・コードは " (string-downcase color))
         (message :print-color-string+adjust-xterm-color-code-002
                  "現在の ~a のカラー・コードは " (string-downcase color))
         (show-color (get-numerical-color-code color 'xterm-terminal))
         (finish-output)
         )
       )
      ((and ;; 第1引数が既定の色名シンボルで第2引数が指定されている場合。
        (symbolp color)
        (member-by-symbol-name color *predefined-xcolor-names*)
        (valid-xterm-256-color-code-p new-color-code)
        )
       (setf color-change-before color)
       ;; 現在のカラー・コード。
       (setf color-code (get-numerical-color-code color 'xterm-terminal))
       (when (not quiet)
         ;;(format t "現在の ~a のカラー・コードは " (string-downcase color))
         (message :print-color-string+adjust-xterm-color-code-002
                  "現在の ~a のカラー・コードは " (string-downcase color))
         (show-color color-code)
         (terpri)
         (finish-output)
         ;;(change-xterm-color-code color new-color-code)
         (setf (rest (assoc-by-symbol-name color *xterm-basic-color-list*)) new-color-code)
         ;;(format t "新しい ~a のカラー・コードは " (string-downcase color))
         (message :print-color-string+adjust-xterm-color-code-003
                  "新しい ~a のカラー・コードは " (string-downcase color))
         (show-color new-color-code)
         (finish-output)
         )
       )
      ((and ;; 第1引数が既定の色名シンボルではないシンボルで第2引数がない場合。
        (symbolp color)
        (not (member-by-symbol-name color *predefined-xcolor-names*))
        (null new-color-code-sw)
        )
       (setf color-change-before color)
       (when (not quiet)
         ;;(format t "現在の ~a のカラー・コードは " (string-downcase color-change-before))
         (message :print-color-string+adjust-xterm-color-code-004
                  "現在の ~a のカラー・コードは " (string-downcase color-change-before))
         (show-color (eval color))
         (finish-output)
         )
       )
      ((and ;; 第1引数が既定の色名シンボルではないシンボルで第2引数が指定されている場合。
        (symbolp color)
        (not (member-by-symbol-name color *predefined-xcolor-names*))
        (valid-xterm-256-color-code-p (eval color))
        (valid-xterm-256-color-code-p new-color-code)
        )
       (setf color-change-before color)
       (when (not quiet)
         ;;(format t "現在の ~a のカラー・コードは " (string-downcase color-change-before))
         (message :print-color-string+adjust-xterm-color-code-004
                  "現在の ~a のカラー・コードは " (string-downcase color-change-before))
         (show-color (eval color-change-before))
         (show-color (eval color-change-before))
         (terpri)
         (finish-output)
         ;;(format t "変更後の色は~a" (make-space 18))
         (message :print-color-string+adjust-xterm-color-code-005 "変更後の色は~a" (make-space 18))
         (show-color new-color-code)
         (setf (symbol-value color) new-color-code)
         (finish-output)
         (terpri)
         ) ;; end when
       )
      ((and ;; 第1引数が数値で指定されたカラー・コードの場合。第2引数は許されない。
        (valid-xterm-256-color-code-p color)
        (null new-color-code-sw)
        )
       (when (not quiet)
         ;;(format t "指定されたカラー・コードは ")
         (message :print-color-string+adjust-xterm-color-code-006 "指定されたカラー・コードは ")
         (show-color color)
         (finish-output)
         )
       )
      (t
       ;;(format t "第1引数が数値であるカラー・コードの場合、第2引数は指定できません。~%")
       (message :print-color-string+adjust-xterm-color-code-007
                "第1引数が数値であるカラー・コードの場合、第2引数は指定できません。~%")
       )
      ) ;; end cond

    (when (debug-print-p "adjust-xterm-color-code")
      (format t "color=~s, new-color-code=~d " color new-color-code)
      ) ;; end when

    (restore-terminal-env)
    (return-from adjust-xterm-color-code t)

    )                       ;; end let
  )   ;; end adjust-xterm-color-code

;; 引数がアトムであればそのまま出力し、リスト内の要素をアトム単位で出力する。
(defun write-flatten (atom-or-list)
  ;;(format t "(write-string-or-list ~s)~%" string-or-list)
  (when (atom atom-or-list)
    (write atom-or-list :escape nil)
    )
  (when (listp atom-or-list)
    (dolist (s atom-or-list)
      (write-flatten s)
      ) ;; end dolist
    ) ;; end when
  ) ;; end write-flatten

;;
;; 指定した色[color]で[atom-or-list]を画面に出力する。
;;
(defun print-colored-string
    (color atom-or-list &key (bold nil b-sw) (italic nil i-sw) (underline nil u-sw) (invert nil v-sw)
                          (strike nil s-sw) (text-or-background 'text-color) (use-terpri nil))
"[color]で指定した色で文字列[atom-or-list]を表示する。指定できる[color]のシンボル名は

ansiカラー・モードの場合[red, green, blue, cyan, magenta, yellow, white, black] 出力する色は固定。

xtermカラー・モードの場合は[red, green, blue, cyan, magenta, yellow, white, black, gray] 色調整可能。
xtermカラー・モードの色を調整したい場合は関数[adjust-xterm-color-code]を使う。

上記以外の色を指定したい場合は

[3]> (show-all-color)

で表示される色見本を見て、その色番号を指定する。

キーワード引数[:text-or-background]に許される値は['background-color]と['text-color]のみ。
['background-color]は背景塗りつぶし、['text-color]は彩色された文字(前景)。

文字列の直後に改行を印字する場合は「:use-terpri t」を追加する。
「:use-terpri nil」なら改行を行わない。「:use-terpri nil」がデフォルト。"

  (let ((color-code nil) (saved-terminal-type nil) (tmp nil))

    (save-terminal-env) ;; 現在の設定を保存。

    (current-color color) ;; 指定された色を以後の既定色とする。

    (when (debug-print-p "print-colored-string")
      (format t "print-colored-string:(symbol-name \'background-color)=~s~%"
              (symbol-name 'background-color))
      (format t "print-colored-string:(symbol-name \'text-color)=~s~%"
              (symbol-name 'text-color))
      (format t "print-colored-string:(member-by-symbol-name ~s ~s)=~s~%"
              text-or-background '(background-color text-color)
              (member-by-symbol-name text-or-background '(background-color text-color)) )
      ) ;; end when

    ;; 前景色でも背景色でもない属性が指定されたら無視してモノクロで出力。
    (when (not (member-by-symbol-name text-or-background '(background-color text-color)))
      (reset-all-attributes)
      (write-flatten atom-or-list)
      (if use-terpri (terpri))
      (restore-terminal-env) ;; 現在の設定を復元。
      (return-from print-colored-string nil)
      ) ;; end when

    ;; 指定された色[color]がシンボルだった場合は基本色として
    ;; 定義した(red,green,blue,cyan,magenta,yellow,black,gray)のいずれかのみ。
    ;; それ以外の色はカラー・コードで直接指定する。
    ;; ansi 8 colorの場合は[0..7]の範囲。       
    ;; xcolorの場合は[0..255]の範囲。
    ;; カラー・コードと実際の色は
    ;;          (show-all-color)
    ;; で色見本が表示される。

    (when (debug-print-p "print-colored-string")
      (format t "(assoc-by-symbol-name ~s ~s)=~s~%" color *basic-color-list*
              (assoc-by-symbol-name color *basic-color-list*))
      ) ;; end when

    ;; 未知の色名シンボルが指定された場合はモノクロで出力。
    (when
        (and
         (symbolp color)
         (not (assoc-by-symbol-name color *basic-color-list*))
         )
      (reset-all-attributes)
      ;;(format t "~a" atom-or-list)
      (write-flatten atom-or-list)
      (restore-terminal-env)
      (return-from print-colored-string nil)
      ) ;; end when

    (setf saved-terminal-type (current-terminal-type))

    (cond ;; 現在の端末タイプを指定された前景色・背景色属性の指定に応じて変更する。
      ((xterm-terminal-p saved-terminal-type) ;; xtermの場合。
       (cond ;; 引数で指定された前景色、背景色の指定に合わせる。
         ((string-equal-by-symbol-name text-or-background 'background-color)
          (set-terminal-env 'xterm-background-color)
          )
         ((string-equal-by-symbol-name text-or-background 'text-color)
          (set-terminal-env 'xterm-text-color)
          )
         )
       )
      ((ansi-terminal-p saved-terminal-type) ;; ansi terminalの場合。
       (cond ;; 引数で指定された前景色、背景色の指定に合わせる。
         ((string-equal-by-symbol-name text-or-background 'background-color)
          (set-terminal-env 'ansi-background-color)
          )
         ((string-equal-by-symbol-name text-or-background 'text-color)
          (set-terminal-env 'ansi-text-color)
          )
         ) ;; end cond
       )
      ) ;; end outer cond

    ;; (when (debug-print-p "print-colored-string")
    ;;   (format t "(get-numerical-color-code ~s ~s)=~d~%" color (current-terminal-type)
    ;;           (get-numerical-color-code color (current-terminal-type)))
    ;;   )

    ;; 前景・背景色指定に応じて端末タイプが変わっている可能性があるので再取得。
    (setf saved-terminal-type (current-terminal-type))

    ;; 第1引数(色)を直接数値で指定している場合。
    (cond
      ((and ;; ansi端末の場合。
        (ansi-terminal-p saved-terminal-type)
        (valid-ansi-8-color-code-p color)
        )
       (setf color-code color)
       )
      ((and ;; xterm端末の場合。
        (xterm-terminal-p saved-terminal-type)
        (valid-xterm-256-color-code-p color)
        )
       (setf color-code color)
       )
      ((and ;; ansi端末だがカラー・コードが正しい範囲でなかった場合 ==> モノクロで出力する。
        (ansi-terminal-p saved-terminal-type)
        (integerp color)
        (not (valid-ansi-8-color-code-p color))
        )
       (reset-all-attributes)
       ;;(format t "~a" atom-or-list)
       (write-flatten atom-or-list)
       (if use-terpri (terpri))
       (restore-terminal-env)
       (return-from print-colored-string nil)
       )
      ((and ;; xterm端末だがカラー・コードが正しい範囲でなかった場合 ==> モノクロで出力する。
        (xterm-terminal-p saved-terminal-type)
        (integerp color)
        (not (valid-xterm-256-color-code-p color))
        )
       (reset-all-attributes)
       ;;(format t "~a" atom-or-list)
       (write-flatten atom-or-list)
       (if use-terpri (terpri))
       (restore-terminal-env)
       (return-from print-colored-string nil)
       )
      ;; 第1引数が色を表すシンボルだった場合。
      ((and ;; シンボルがansi定義の色名だった場合。
        (symbolp color)
        (member-by-symbol-name color *predefined-ansi-names*)
        (ansi-terminal-p saved-terminal-type)
        )
       (setf color-code (get-numerical-color-code color saved-terminal-type))
       )
      ((and ;; シンボルがxterm定義の色名だった場合。
        (symbolp color)
        (member-by-symbol-name color *predefined-xcolor-names*)
        (xterm-terminal-p saved-terminal-type)
        )
       (setf color-code (get-numerical-color-code color saved-terminal-type))
       )
      ((and ;; シンボルがユーザ定義の色名([my-blue]など)だった場合。
        (symbolp color)
        (integerp (eval color))
        )
       (cond
         ((and
           (ansi-terminal-p saved-terminal-type)
           (valid-ansi-8-color-code-p color)
           )
          (setf color-code (eval color))
          )
         ((and
           (xterm-terminal-p saved-terminal-type)
           (valid-xterm-256-color-code-p color)
           )
          (setf color-code (eval color))
          )
         ) ;; end inner cond
       )   ;; end and
      )    ;; end cond

    (when (null color-code)
      ;;(format t "error:カラーコードが未定義、または正しい値ではありません。~%")
      (message :print-color-string+print-colored-string-001
               "error:カラーコードが未定義、または正しい値ではありません。~%")
      (return-from print-colored-string nil)
      )

    (when (debug-print-p "print-colored-string")
      (format t "print-colored-string:color-code=~s~%" color-code)
      )

    (setf tmp nil)
    (when (identity b-sw)
      (setf tmp (append tmp (list :bold bold)))
      )
    (when (identity i-sw)
      (setf tmp (append tmp (list :italic italic)))
      )
    (when (identity u-sw)
      (setf tmp (append tmp (list :underline underline)))
      )
    (when (identity v-sw)
      (setf tmp (append tmp (list :invert invert)))
      )
    (when (identity s-sw)
      (setf tmp (append tmp (list :strike strike)))
      )

    (when (debug-print-p "print-colored-string")
      (format t "print-colored-string:attributes-list(tmp)=~s~%" tmp)
      )

    (apply #'put-escape-sequence color-code tmp) ;; 指定されたエスケープ・シーケンスを出力する。

    (when (debug-print-p "print-colored-string")
      (format t "print-colored-string:atom-or-list=~s~%" atom-or-list)
      )

    (write-flatten atom-or-list) ;; 準備された文字属性で文字列を出力する。
    (finish-output)

    (restore-terminal-env)

    (if use-terpri (terpri))
    (return-from print-colored-string atom-or-list)
    ) ;; end let
  ) ;; end print-colored-string

(defun current-terminal-type ()
  " 彩色方法として背景色を選択する場合は['xterm-background-color]を、
色付き文字を選択する場合は['xterm-text-color]を定義する。
実行時に定義を変更する場合は関数[color-type]で設定する。
(defvar *current-terminal-type* 'xterm-background-color)
(defvar *current-terminal-type* 'xterm-text-color)
(defvar *current-terminal-type* 'ansi-background-color)
(defvar *current-terminal-type* 'ansi-text-color)
"
  *current-terminal-type*
  )

(defun is-xterm-or-ansi ()
  (case *current-terminal-type*
    (xterm-background-color     'xterm)
    (xterm-text-color           'xterm)
    (ansi-background-color      'ansi)
    (ansi-text-color            'ansi)
    (otherwise                  nil)
    ) ;; end case
  ) ;; end is-xterm-or-ansi

(defun current-color (&optional (color nil))
  (cond
    ((null color)
     *current-color*
     )
    (t
     (setf *current-color* color)
     )
    ) ;; end cond
  ) ;; end current-color

(defun get-numerical-color-code (color terminal-type)
  (let ((tmp nil) (color-code nil) (is-ansi-terminal nil) (is-xterm-terminal nil))

    (cond
      ((or
        (null color)
        (null terminal-type)
        )
       (return-from get-numerical-color-code nil)
       )
      ((ansi-terminal-p terminal-type)
       (setf is-ansi-terminal t)
       )
      ((xterm-terminal-p terminal-type)
       (setf is-xterm-terminal t)
       )
      (t
       ;;(format t "第2引数の端末タイプ(~s)は~sのいずれかでなければなりません。~%"
       ;;        terminal-type *predefined-terminal-type*)
       (message :print-color-string+get-numerical-color-code-001
                "第2引数の端末タイプ(~s)は~sのいずれかでなければなりません。~%"
                terminal-type *predefined-terminal-type*)
       (return-from get-numerical-color-code nil)
       )
      ) ;; end cond

    (cond
      ((and ;; 第1引数がシンボルで*predefined-ansi-names*の要素であるとき。
        (symbolp color)
        (identity is-ansi-terminal)
        (member-by-symbol-name color *predefined-ansi-names*)
        )
       (setf tmp (assoc-by-symbol-name color *ansi-basic-color-list*))
       (setf color-code (eval (rest tmp)))
       )
      ((and ;; 第1引数がシンボルで*predefined-xcolor-names*の要素であるとき。
        (symbolp color)
        (identity is-xterm-terminal)
        (member-by-symbol-name color *predefined-xcolor-names*)
        )
       (setf tmp (assoc-by-symbol-name color *xterm-basic-color-list*))
       (setf color-code (eval (rest tmp)))
       )
      ((and ;; 第1引数がシンボルで*predefined-color-names*の要素でないとき。
        (symbolp color)
        (not (member-by-symbol-name color *predefined-color-names*))
        )
       (setf color-code (eval color))
       )
      ((and ;; 第1引数が (r g b) 形式のリストだった場合。
        (listp color)
        (= (length color) 3) 
        (every #'valid-xterm-256-color-code-p color)
        )
       (setf color-code (first (remove-duplicates-preserving-order
                                (make-gradient (nth 0 color) (nth 1 color) (nth 2 color)
                                               (nth 0 color) (nth 1 color) (nth 2 color))))
             ) ;; end setf
       )
      ((and ;; 第1要素が数値でansi端末モーであるとき。
        (integerp color)
        (identity is-ansi-terminal)
        (valid-ansi-8-color-code-p color)
        )
       (setf color-code color)
       )
      ((and ;; 同上。xterm端末モードの場合。
        (identity is-xterm-terminal)
        (valid-xterm-256-color-code-p color)
        )
       (setf color-code color)
       )
      (t
       ;;(format t "第1引数(~s)は既定の色名か正しい範囲のカラー・コードでなければなりません。" color)
       (message :print-color-string+get-numerical-color-code-002
                "第1引数(~s)は既定の色名か正しい範囲のカラー・コードでなければなりません。" color)
       (return-from get-numerical-color-code nil)
       )
      ) ;; end cond
    (return-from get-numerical-color-code color-code)
    )   ;; end let
  ) ;; end get-numerical-color-code


(defun ansi-terminal-p (terminal-type)
"*predefined-ansi-terminal-type* ==> '(ansi-text-color ansi-background-color ansi-terminal)"
    (and
      (symbolp terminal-type)
      (member-by-symbol-name terminal-type *predefined-ansi-terminal-type*)
      )
  )

(defun xterm-terminal-p (terminal-type)
"*predefined-xterm-terminal-type* ==> '(xterm-text-color xterm-background-color xterm-terminal)"
  (and
   (symbolp terminal-type)
   (member-by-symbol-name terminal-type *predefined-xterm-terminal-type*)
   )
  )

(defun set-xterm-text-color (color)
  "X terminalカラー設定で、前景色の文字を指定された[color]で表示するためのエスケープ・シーケンスを出力する。
以後、設定が変更されるまで、ここで指定された文字色での出力となる。"
  (let (color-code)
    (current-color color)
    (setf color-code (get-numerical-color-code color 'xterm-text-color))
    (write #\Escape :escape nil)
    (write #\[ :escape nil)
    (write 38 :escape nil)
    (write #\; :escape nil)
    (write 5 :escape nil)
    (write #\; :escape nil)
    (write color-code :escape nil)
    (write #\m :escape nil)
    (return-from set-xterm-text-color t)
    )
  )

(defun set-xterm-background-color (color)
  "X terminalカラー設定で文字背景を指定された[color]で表示するためのエスケープ・シーケンスを出力する。
以後、設定が変更されるまで、ここで指定された背景色での出力となる。"
  (let (color-code)
    (current-color color)
    (setf color-code (get-numerical-color-code color 'xterm-background-color))
    ;;(when (>= (color-mode-level) 1)
    (write #\Escape :escape nil)
    (write #\[ :escape nil)
    (write 48 :escape nil)
    (write #\; :escape nil)
    (write 5 :escape nil)
    (write #\; :escape nil)
    (write color-code :escape nil)
    (write #\m :escape nil)
    ;;)
    (return-from set-xterm-background-color t)
    )
  )

(defun set-ansi-text-color (color)
  "ANSIで定義された文字を[color]で表示するためのエスケープ・シーケンスを出力する。
以後、設定が変更されるまで、ここで指定された文字色での出力となる。"
  (let (color-code)
    (current-color color)
    (setf color-code (get-numerical-color-code color 'ansi-text-color))
    (write #\Escape :escape nil)
    (write #\[ :escape nil)
    (write (+ color-code 30) :escape nil) ;; 30-37 selected the foreground color.
    (write #\m :escape nil)
    (return-from set-ansi-text-color t)
    )
  )

(defun set-ansi-background-color (color)
  "ANSIで定義された背景色[color]で表示するためのエスケープ・シーケンスを出力する。
以後、設定が変更されるまで、ここで指定された背景色での出力となる。"
  (let (color-code)
    (current-color color)
    (setf color-code (get-numerical-color-code color 'ansi-background-color))
    (write #\Escape :escape nil)
    (write #\[ :escape nil)
    (write (+ color-code 40) :escape nil) ;; 40-47 selected the background color.
    (write #\m :escape nil)
    (return-from set-ansi-background-color t)
    )
  )

(defun reset-all-attributes ()
  "文字色および背景色の設定をリセットする。xterm系とansi系で共通。"
  (when (or (equal *terminal-capability* 'xterm) (equal *terminal-capability* 'ansi))
    ;;(format t "~c[0m" #\Escape)
    (write #\Escape :escape nil)
    (write #\[ :escape nil)
    (write 0 :escape nil)
    (write #\m :escape nil)
    (finish-output)
    ) ;; end when
  (return-from reset-all-attributes t)
  )

(defun chg-attr (&key (color nil c-sw) (bold nil b-sw) (italic nil i-sw)
                   (underline nil u-sw) (invert nil v-sw) (strike nil s-sw))
  (let ((result nil))
    (when (every #'null (list c-sw b-sw i-sw u-sw v-sw s-sw))
      (return-from chg-attr "")
      )

    (when (null c-sw)
      (setf color (current-color))
      )
    (when (valid-color-code-p (get-numerical-color-code color (current-terminal-type)))
      (current-color color)
      )

    (setf result nil)
    (when (identity b-sw)
      (setf result (append result (list :bold bold)))
      )
    (when (identity i-sw)
      (setf result (append result (list :italic italic)))
      )
    (when (identity u-sw)
      (setf result (append result (list :underline underline)))
      )
    (when (identity v-sw)
      (setf result (append result (list :invert invert)))
      )
    (when (identity s-sw)
      (setf result (append result (list :strike strike)))
      )

    (apply #'make-escape-sequence color result)
    )
  ) ;; end chg-attr

;;
;; サポート関数群の定義
;;
;; [history-pkg:set-prompt-element]の関数指定で関数[chg-attr]をlambda式とせず直接に関数名
;; で指定できるように引数なしの特定目的関数を定義している。これにより例えば赤字に変更したいときは
;;      #'(lambda () (print-color-string:chg-attr :color 'red))
;;
;; を
;;      #'change-to-red
;;
;; と書ける。文字属性についても個別にlambda式化せずに引数なしで個別に指定できる。
;;
(defun change-to-red     () (chg-attr :color 'red))
(defun change-to-green   () (chg-attr :color 'green))
(defun change-to-blue    () (chg-attr :color 'blue))
(defun change-to-cyan    () (chg-attr :color 'cyan))
(defun change-to-magenta () (chg-attr :color 'magenta))
(defun change-to-yellow  () (chg-attr :color 'yellow))
(defun change-to-gray    () (chg-attr :color 'gray))
(defun change-to-black   () (chg-attr :color 'black))

(defun set-to-bold       () (chg-attr :bold t))
(defun cancel-bold       () (chg-attr :bold nil))
(defun set-to-italic     () (chg-attr :italic t))
(defun cancel-italic     () (chg-attr :italic nil))
(defun set-to-underline  () (chg-attr :underline t))
(defun cancel-underline  () (chg-attr :underline nil))
(defun set-to-invert     () (chg-attr :invert t))
(defun cancel-invert     () (chg-attr :invert nil))
(defun set-to-strike     () (chg-attr :strike t))
(defun cancel-strike     () (chg-attr :strike nil))

;;
;; 文字属性についてのエスケープ・シーケンスを組み立てる関数。
;;
;; エスケープ・シーケンスの書式は
;;
;; ESC[P(1);P(2);...;P(n)m
;; P(x) ::= <10進整数>
;; P(x)が256色/True Color指定の場合は 38;5;n または 48;5;nという形式。256色モードの色番号範囲参照。
;;
;; ANSI/ECMA-48標準でのパラメータ範囲の定義
;; パラメータの値        意味                          例
;; 0 - 9                スタイル属性（基本）          1 (太字), 4 (下線), 7 (反転)
;; 20 - 29              スタイル解除                      22 (太字/減光解除), 24 (下線解除)
;; 30 - 37              前景色（標準8色）               31 (赤)
;; 40 - 47              背景色（標準8色）               44 (青背景)
;; 38                   拡張前景色（256色/True Color）  38;5;n または 38;2;r;g;b
;; 48                   拡張背景色（256色/True Color）  48;5;n または 48;2;r;g;b
;;
;; 256色モードの色番号範囲
;; インデックスの範囲  色のカテゴリ              構成
;; 0 - 15               標準の16色          標準の8色（30〜37など）とその高輝度版（90〜97など）に対応。
;; 16 - 231             カラーキューブ (216色)  RGB値に基づいて均等に配置された6段階の色相（赤、緑、青）の色。
;; 232 - 255            グレースケール (24色)   黒から白にかけて均等に配置された24段階の濃淡の灰色。

;; 引数の[color]は、その数値範囲と[(current-terminal-type)]の値によって対応するコードを組み立てる。
;; ==> 38;5;n または 48;5;n (n=color)
;;
(defun make-escape-sequence
    (color &key (bold nil b-sw) (italic nil i-sw) (underline nil u-sw)
             (invert nil v-sw) (strike nil s-sw))
  "文字属性についてのエスケープ・シーケンスを組み立てる関数。

ANSI互換ターミナルとX互換ターミナルで共通。

        :bold t         ;; 太字または高輝度にする。
        :bold nil       ;; 太字または高輝度を解除。
        :italic t       ;; 斜体にする。
        :italic nil     ;; 斜体を解除。
        :underline t    ;; 下線をつける
        :underline nil  ;; 下線を解除。
        :invert t       ;; 前景色と背景色を入れ替える。
        :invert nil     ;; 前景色と背景色の入れ替えを解除。
        :strike t       ;; 打ち消し線を引く。  
        :strike nil     ;; 打ち消し線を解除。

        ESC [ <コード> m
        属性                  設定コード 解除コード 備考
        太字 (Bold)           1               22              明るさも増すことが多い
        薄く表示 (Faint)    2               22              サポート外のターミナルもあり
        イタリック (Italic)        3               23      
        下線 (Underline)      4               24      
        点滅 (Blink)          5               25
        反転 (Invert)         7               27              文字色と背景色を入れ替える
        非表示 (Hidden)              8               28              パスワード入力時などに使用
        取り消し線 (Strike)        9               29
        文字色 (Foreground)                  39              文字色をターミナルのデフォルトに戻す
        背景色 (Background)                  49              背景色をターミナルのデフォルトに戻す

        (defconstant +bold+              1) ;; 太字または高輝度にする。
        (defconstant +cancel-bold+      22) ;; 太字解除。
        (defconstant +italic+            3) ;; 斜体にする。
        (defconstant +cancel-italic+    23) ;; 斜体解除。
        (defconstant +underline+         4) ;; 下線をつける
        (defconstant +cancel-underline+ 24) ;; 下線解除。
        (defconstant +invert+            7) ;; 前景色と背景色を入れ替える。
        (defconstant +cancel-invert+    27) ;; 前景色と背景色を入れ替え解除。。
        (defconstant +strike+            9) ;; 打ち消し線を引く。      
        (defconstant +cancel-strike+    29) ;; 打ち消し線解除。

キーワード名に[nil]以外を与えると指定した属性が付与される。明示的に[nil]を与えると属性の解除。
属性の指定順序が異なっても結果は同じ。

関数の結果として出力すべきエスケープ・シーケンスのリストを返す。キーワード引数がすべて[nil]
だった場合は[nil]を返す。

[3]> (make-escape-sequance 27 :bold t :italic t)
(#\Esc #\[ 38 #\; 5 #\; 27 #\; 1 #\; 3 #\m)
;; ESC [ ; 38(前景色) ; 5(256色モード) ; カラーコード27 ; :bold ; :italic \m(終了)

この結果を関数[put-escape-sequence]に渡すと有効なエスケープ・シーケンスを画面に出力する。
"
  (let (color-code result)

    (when (equal *terminal-capability* 'dumb) ;; dumb端末なら空文字列を返す。
      (return-from make-escape-sequence "")
      )

    (setf result nil)
    (setf color-code (get-numerical-color-code color (current-terminal-type)))

    (when (debug-print-p "make-escape-sequence")
      (format t "(symbol-name ~s)=~s~%" (current-terminal-type)
              (symbol-name (current-terminal-type)))
      (format t "color=~s, color-code=~d~%" color color-code)
      )

    (cond
      ((or
        (not (integerp color-code))
        (null (current-terminal-type))
        )
       (return-from make-escape-sequence "")
       )
      ((string-equal-by-symbol-name (current-terminal-type) 'ansi-text-color)
       (push (+ color-code 30) result)
       (push #\; result)
       )
      ((string-equal-by-symbol-name (current-terminal-type) 'ansi-background-color)
       (push (+ color-code 40) result)
       (push #\; result)
       )
      ((string-equal-by-symbol-name (current-terminal-type) 'xterm-text-color)
       (push 38 result)
       (push #\; result)
       (push 5 result)
       (push #\; result)
       (push color-code result)
       (push #\; result)
       )
      ((string-equal-by-symbol-name (current-terminal-type) 'xterm-background-color)
       (push 48 result)
       (push #\; result)
       (push 5 result)
       (push #\; result)
       (push color-code result)
       (push #\; result)
       )
      ) ;; end cond

    (when (debug-print-p "make-escape-sequence")
      (format t "result(1)=~s~%" result)
      )

    ;; ESC [ <コード> m
    ;; 属性                   設定コード 解除コード 備考
    ;; 太字 (Bold)            1               22              明るさも増すことが多い
    ;; 薄く表示 (Faint)             2               22              サポート外のターミナルもあり
    ;; イタリック (Italic) 3               23      
    ;; 下線 (Underline)               4               24      
    ;; 点滅 (Blink)           5               25
    ;; 反転 (Invert)          7               27              文字色と背景色を入れ替える
    ;; 非表示 (Hidden)               8               28              パスワード入力時などに使用
    ;; 取り消し線 (Strike) 9               29
    ;; 文字色 (Foreground)                   39              文字色をターミナルのデフォルトに戻す
    ;; 背景色 (Background)                   49              背景色をターミナルのデフォルトに戻す
    ;;  
    (when (identity b-sw) ;; :bold が明示的に指定された。
      (if bold
          (push +bold+ result)
          (push +cancel-bold+ result)
          )
      (push #\; result)
      )
    (when (identity i-sw) ;; :bold が明示的に指定された。
      (if italic
          (push +italic+ result)
          (push +cancel-italic+ result)
          )
      (push #\; result)
      )
    (when (identity u-sw) ;; :underline が明示的に指定された。
      (if underline
          (push +underline+ result)
          (push +cancel-underline+ result)
          )
      (push #\; result)
      )
    (when (identity v-sw) ;; :invert が明示的に指定された。
      (if invert
          (push +invert+ result)
          (push +cancel-invert+ result)
          )
      (push #\; result)
      )
    (when (identity s-sw) ;; :strike が明示的に指定された。
      (if strike
          (push +strike+ result)
          (push +cancel-strike+ result)
          )
      (push #\; result)
      )

    (pop result) ;; remove last #\;
    (push #\m result)
    (setf result (reverse result))
    (push #\[ result)
    (push #\Escape result)

    (when (debug-print-p "make-escape-sequence")
      (format t "result(2)=~s~%" result)
      )

    (return-from make-escape-sequence result)
    ) ;; end let
  ) ;; end make-escape-sequence

(defun put-escape-sequence (color &key (bold nil b-sw) (italic nil i-sw) (underline nil u-sw)
                                    (invert nil v-sw) (strike nil s-sw))
  (let (escape-sequence-list attr-list)

    (setf attr-list nil)

    (when (identity b-sw)
      (setf attr-list (append attr-list (list :bold bold)))
      )
    (when (identity i-sw)
      (setf attr-list (append attr-list (list :italic italic)))
      )
    (when (identity u-sw)
      (setf attr-list (append attr-list (list :underline underline)))
      )
    (when (identity v-sw)
      (setf attr-list (append attr-list (list :invert invert)))
      )
    (when (identity s-sw)
      (setf attr-list (append attr-list (list :strike strike)))
      )

    (setf escape-sequence-list (apply #'make-escape-sequence color attr-list))

    ;;(format t "escape-sequence-list=~s~%" escape-sequence-list)
    ;;(format t "(stringp escape-sequence-list)=~s~%" (stirngp escape-sequence-list))

    (when (null escape-sequence-list)
      (return-from put-escape-sequence nil)
      )

    (dolist (code escape-sequence-list)
      (write code :escape nil)
      )

    (return-from put-escape-sequence "")
    )
  )

(defun show-basic-colors ()
  "現在のxtermでの基本色(8色)の色見本を出力する。"
  (save-terminal-env)

  (format t "~axterm current colors~%" (make-space 9))
  (format t "symbol")
  (format t "~a" (make-space 2))
  (format t "code")
  (format t "~a" (make-space 4))
  ;;(format t "前景色")
  (message :print-color-string+show-basic-colors-001 "前景色")
  (format t "~a" (make-space 5))
  ;;(format t "反転色~%")
  (message :print-color-string+show-basic-colors-002 "反転色~%")
  (finish-output)

  (dolist (color *xterm-basic-color-list*)
  ;;
  ;;(defparameter *xterm-basic-color-list*
  ;;'((red        .       *xcolor-red*) ;; 削除対象候補用。パリティ色に使う場合は要注意。
  ;;  (green      .       *xcolor-green*)
  ;;  (blue       .       *xcolor-blue*)
  ;;  (cyan       .       *xcolor-cyan*)
  ;;  (magenta    .       *xcolor-magenta*)
  ;;  (yellow     .       *xcolor-yellow*)
  ;;  (black      .       *xcolor-black*)
  ;;  (gray       .       *xcolor-gray*)
  ;;  )
  ;;)
  ;;
    (set-terminal-env 'xterm-text-color 'black)
    (format t "~8a " (string-downcase (symbol-name (car color))))
    ;;(format t "~3d: " (eval (cdr color)))
    ;;(print-colored-string (car color) "0123456789")
    ;;(format t " ")
    ;;(print-colored-string (car color) "0123456789" :invert t :use-terpri t)
    (show-color (eval (cdr color)))
    (terpri)
    ) ;; end dolist
  (finish-output)

  (restore-terminal-env)

  ;;(format t "~%see also (show-all-color)")
  (message :print-color-string+show-basic-colors-003 "~%(show-all-color)もご覧ください。")
  (return-from show-basic-colors t)
  ) ;; end show-basic-colors

;; (defun do-nothing () magic-number)

(defun return-fixnum () magic-number)

(defun help-color ()
  (message :print-color-string+help-color-001 
           "プログラムから出力する文字列をカラーで表示するためのパッケージ。

指定できるのは
--------------------------------------------------------------------------
'xterm-text-color       = 256色から選んで文字列を出力できるモード。
'xterm-background-color = 256色から選んで文字列の背景色を出力できるモード(or 'xterm)。
'ansi-text-color        = 8色から選んで文字列を出力できるモード。
'ansi-background-color  = 8色から選んで文字列の背景色を出力できるモード(or 'ansi)。
--------------------------------------------------------------------------
のいずれかひとつ。

色見本は

[2]> (print-color-string:show-all-color)

とすると選択した出力モードでの色見本を出力する。代表的な色記号としてxterm系とansi系の
それぞれに対して以下のように色番号を定義したシンボルを用意してある。

'red      196
'green     46
'blue      21
'cyan      51
'magenta  201 
'yellow   226
'gray     239
'black    232

ansiカラーの場合、最大8色まで。

'black      0
'red        1
'green      2
'yellow     3
'blue       4
'magenta    5
'cyan       6
'white      7

これで

[3]> (print-colored-string 'blue \"Blue string.\")
Blue string. <---実際は青色。
\"Blue string.\" <--- 戻り値は指定した文字列。
[4]> (print-bold-string 'green \"Green string.\")
Green string. <---実際は太字の緑色。
\"Green string.\" <--- 戻り値。~%
")
  ) ;; end help-color

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

(defun show-xterm-color-range (&key (start 0)  (end 255))
"指定された範囲のxterm 256カラーの文字コードと色見本を表示する。"

  (when (debug-print-p "show-xterm-color-range")
    (format t "(show-xterm-color-range ~d ~d)~%" start end)
    )

  (when
      (not
       (and
        (valid-xterm-256-color-code-p start)
        (valid-xterm-256-color-code-p end)
        )
       )
    ;;(format t "指定された範囲 ~d〜~d はxtermの正しいカラー・コードの範囲(0..255)ではありません。~%" start end)
    (message :print-color-string+show-xterm-color-range-001
             "指定された範囲 ~d〜~d はxtermの正しいカラー・コードの範囲(0..255)ではありません。~%" start end)
    (return-from show-xterm-color-range nil)
    )
  (format t "~5@t")
  (format t "xterm 256 colors~%")
  ;;(format t "code   前景色      背景色~%")
  (message :print-color-string+show-xterm-color-range-002 "code~3@t前景色~6@t背景色~%")
  (let (color)
    (setf color start)
    (loop
      (if (> color end) (return))
      (show-color color)
      (terpri)
      (incf color)
      ) ;; end loop
    (finish-output)
    ) ;; end let
  (return-from show-xterm-color-range t)
  ) ;; end show-xterm-color-range

(defun show-xterm-color (&key (range nil))
  "指定された範囲のxtermで定義された色を表示する。

(引数なし)                  この関数ドキュメントを表示する。
:range nil                      この関数ドキュメントを表示する。
:range 1                        カラー・コード1の色を表示。
:range '(1)                     カラー・コード1の色を表示。
:range '(0 15)                  カラー・コード0..15の範囲の色を表示。
:range '(1 3 15)                カラー・コード1, 3, 15の3色を表示。
:range '((0 15) (215 255))      カラー・コード0..15と215..255の範囲の色を表示。
:range '(1 (3 15) (215 225))    カラー・コード1とカラー・コード3..15、215..225の範囲の色を表示。

"
  (let (tmp)
    (cond
      ((null range)
       (documentation 'show-xterm-color 'function)
       )
      ((valid-xterm-256-color-code-p range) ;; 単独の数値だった場合。
       (show-xterm-color-range :start range :end range)
       )
      ((and ;; 単独の数値がリストとして渡されていた場合。
        (listp range)
        (= (length range) 1)
        (valid-xterm-256-color-code-p (first range))
        )
       (show-xterm-color-range :start (first range) :end (first range))
       )
      ((and ;; (<数値1> <数値2>)という形式だった場合。
        (listp range)
        (= (length range) 2)
        (every #'valid-xterm-256-color-code-p range)
        )
       (setf tmp (sort range #'< ))
       (show-xterm-color-range :start (first tmp) :end (second tmp))
       )
      ((and ;; (<数値1> <数値2> <数値3> ...) という形式だった場合。
        (listp range)
        (<= (length range) 3)
        (every #'valid-xterm-256-color-code-p range)
        )
       (dolist (p range)
         (show-xterm-color-range :start p :end p)
         ) ;; end dolist
       )
      ((and ;; リストの要素に単独数値とリストが混在している場合。 
        (listp range)
        (<= (length range) 3)
        (some #'listp range)
        (every #'valid-xterm-256-color-code-range-p range)
        )
       (dolist (p range)
         (cond
           ((null p)
            nil
            )
           ((integerp p)
            (show-xterm-color-range :start p :end p)
            )
           ((listp p)
            (show-xterm-color :range p)
            )
           )
         ) ;; end dolist
       )
      (t
       ;;(format t "error:想定外の範囲指定(~s)。~%" range)
       (message :print-color-string+show-xterm-color-001 "エラー:範囲外(~s)です。~%" range)
       )
      ) ;; end cond
    ) ;; end let
  (return-fixnum)
  ) ;; end show-xterm-color

(defun show-ansi-color (&key (start 0) (end 7))
  "指定された範囲のANSI互換端末の8色の文字コードと色見本を表示する。
xterm互換端末の256色と異なり、高々8色しかないので関数[show-xterm-color]
のような表示色の範囲を細かく指定する機能は省略している。

(show-ansi-color)                       カラー・コード0..7(全色)を表示する。
(show-ansi-color :start 0 :end 7)       カラー・コード0..7(全色)を表示する。
(show-ansi-color :start 2 :end 6)       カラー・コード2..6の色を表示する。
(show-ansi-color :start 2)              カラー・コード2..7の色を表示する。
(show-ansi-color :end 5)                        カラー・コード0..5の色を表示する。
"
  (when
      (not
       (and
        (valid-ansi-8-color-code-p start)
        (valid-ansi-8-color-code-p end)
        )
       )
    ;;(format t "指定された範囲 ~dから~d はansiカラー・コードの範囲(0..7)ではありません。~%" start end)
    (message :print-color-string+show-ansi-color-001
             "指定された範囲 ~dから~d はansiカラー・コードの範囲(0..7)ではありません。~%" start end)
    (return-from show-ansi-color nil)
    ) ;; end when

  (format t "~5@t")
  (format t "ansi 8 colors~%")
  ;;(format t "code   前景色      背景色~%")
  (message :print-color-string+show-ansi-color-002 "code~3@t前景色~6@t背景色~%")
  (let (color)
    (setf color start)
    (loop
      (if (> color end) (return))
      (show-color color)
      (terpri)
      ) ;; end loop
    ) ;; end let
  (finish-output)
  (return-from show-ansi-color t)
  ) ;; end show-ansi-color

(defun show-all-color ()
  (cond
    ((string-equal-by-symbol-name (is-xterm-or-ansi) 'ansi)
     (show-ansi-color)
     )
    ((string-equal-by-symbol-name (is-xterm-or-ansi) 'xterm)
     (show-xterm-color-range :start 0 :end 255)
     )
    (t
     (format t "error: show-all-color:can not happen.~%")
     )
    ) ;; end cond
  (return-fixnum)
  ) ;; end show-all-color

(defun valid-color-code-p (color-code)
  (cond
    ((is-xterm-compatible)
     (valid-xterm-256-color-code-range-p color-code)
     )
    ((is-ansi-compatible)
     (valid-ansi-8-color-code-range-p color-code)
     )
    (t
     nil
     )
    ) ;; end cond
  ) ;; end valid-color-code-p

(defun valid-xterm-256-color-code-p (color-code)
  "引数のカラー・コードがX term 256色モードの正しい色番号かどうかを判定する。
正しい場合は色のカテゴリを表す文字列を返す。正しい範囲のカラー・コードでなければ[nil]を返す。

256色モードの色番号範囲

色番号範囲 色のカテゴリ              構成
0 - 15          標準の16色          標準の8色（30〜37など）とその高輝度版（90〜97など）に対応。
16 - 231        カラーキューブ (216色)  RGB値に基づいて均等に配置された6段階の色相（赤、緑、青）の色。
232 - 255       グレースケール (24色)   黒から白にかけて均等に配置された24段階の濃淡の灰色。
"
  (cond
    ((not (integerp color-code))
     nil
     )
    ((<= 0 color-code  15)
     "16 standard colors"
     )
    ((<= 16 color-code 231)
     "231 color cube"
     )
    ((<= 232 color-code 255)
     "24 gray scale"
     )
    (t
     nil
     )
    ) ;; end cond
  ) ;; end valid-xterm-256-color-code-p

(defun valid-xterm-256-color-code-range-p (arg)
  (cond
    ((null arg)
     nil
     )
    ((integerp arg) ;; 単独の数値の場合。
     (valid-xterm-256-color-code-p arg)
     )
    ((and ;; 数値だけからなるリストの場合。
      (listp arg)
      (every #'integerp arg)
      )
     (every #'valid-xterm-256-color-code-p arg)
     )
    ((and ;; リストを含むリストの場合。
      (listp arg)
      (some #'listp arg)
      )
     (dolist (p arg)
       (cond
         ((and ;; リスト内の数値が正しいカラー・コードの範囲に含まれていなかった。
           (integerp p)
           (not (valid-xterm-256-color-code-p p))
           )
          (return-from valid-xterm-256-color-code-range-p nil)
          )
         ((and ;; リスト内のリストが(単独の数値、または数値だけからなるリスト)でなかった。
           (listp p)
           (not (valid-xterm-256-color-code-range-p p))
           )
          (return-from valid-xterm-256-color-code-range-p nil)
          )
         ) ;; end cond
       )   ;; end dolist
     (return-from valid-xterm-256-color-code-range-p t) ;; すべての要素が条件を満たしていたので合格。
     )  ;; end and-clouse
    )   ;; end outer cond
  ) ;; end valid-xterm-256-color-code-range-p

(defun valid-ansi-8-color-code-p (color-code)
  "
色名  前景色コード      背景色コード      備考
Black   30              40
Red     31              41
Green   32              42
Yellow  33              43              Brownの場合もあり
Blue    34              44
Magenta 35              45
Cyan    36              46
White   37              47              通常は明るい灰色

このプログラム内では、ひとつのカラー・コードでひとつの色に対応させることを優先し

Black   0
Red     1
Green   2
Yellow  3
Blue    4
Magenta 5
Cyan    6
White   7

として扱い、実際にエスケープ・シーケンスを出力する際には
端末タイプが[ansi-text-color]（前景色）の場合は[30]を加え、
端末タイプが[ansi-background-color]（背景色）の場合は[40]を加えて処理している。
"
  (case color-code
    (0  "Black")
    (1  "Red")
    (2  "Green")
    (3  "Yellow")
    (4  "Blue")
    (5  "Magenta")
    (6  "Cyan")
    (7  "White")
    (otherwise nil)
    )
  )

(defun valid-ansi-8-color-code-range-p (arg)
  "引数が(<数値1> <数値2>)の形式のリストで、<数値1>と<数値2>が共に正しいansiカラー・コードの
範囲の数値の場合に、引数のリストをソートした結果を返す。
引数が単一の数値のみの場合は、その数値が正しいansiカラー・コードの範囲であれば(<数値> <数値>)
という形のリストを返す。そうでない場合は[nil]を返す。
"
  (cond
    ((null arg)
     nil
     )
    ((integerp arg) ;; 単独の数値の場合。
     (valid-ansi-8-color-code-p arg)
     )
    ((and ;; 数値だけからなるリストの場合。
      (listp arg)
      (every #'integerp arg)
      )
     (every #'valid-ansi-8-color-code-p arg)
     )
    ((and ;; リストを含むリストの場合。
      (listp arg)
      (some #'listp arg)
      )
     (dolist (p arg)
       (cond
         ((and ;; リスト内の数値が正しいカラー・コードの範囲に含まれていなかった。
           (integerp p)
           (not (valid-ansi-8-color-code-p p))
           )
          (return-from valid-ansi-8-color-code-range-p nil)
          )
         ((and ;; リスト内のリストが(単独の数値、または数値だけからなるリスト)でなかった。
           (listp p)
           (not (valid-ansi-8-color-code-range-p p))
           )
          (return-from valid-ansi-8-color-code-range-p nil)
          )
         ) ;; end cond
       )   ;; end dolist
     (return-from valid-ansi-8-color-code-range-p t) ;; すべての要素が条件を満たしていたので合格。
     )  ;; end and-clouse
    ) ;; end cond
  ) ;; end valid-ansi-8-color-code-range-p

(defun xterm-rgb-code (r g b)
  "R, G, B (各0-5) から xterm 256色コード (16-231) を計算する関数。
  code = 16 + 36 x R + 6 x G + B
"
  (+ 16 (* 36 r) (* 6 g) b)
  )

(defun make-gradient (start-r start-g start-b end-r end-g end-b)
  "指定されたRGB (0-5) の範囲でグラデーションを計算し、色コードのリストを返す関数。"
  (let ((steps 5)) ;; 6段階 (0から5) のステップ
    
    (let* ((dr (/ (- end-r start-r) steps))
           (dg (/ (- end-g start-g) steps))
           (db (/ (- end-b start-b) steps)))
      
      (loop for i from 0 to steps
            collect (let* (;; R, G, B 成分を計算し、0-5の整数に丸める
                           (r (round (+ start-r (* dr i))))
                           (g (round (+ start-g (* dg i))))
                           (b (round (+ start-b (* db i)))))
                      (xterm-rgb-code r g b))
            ) ;; end loop
      )       ;; end let*
    )         ;; end let
  ) ;; end make-gradient

(defun display-gradient (code-list start-r start-g start-b end-r end-g end-b)
  "色コードのリストを受け取り、グラデーションをターミナルに表示する。"
  (format t "--- R:~A->~A, G:~A->~A, B:~A->~A ---~%" 
          start-r end-r start-g end-g start-b end-b)
  
  ;; グラデーションを出力
  ;;(format t "code   前景色      背景色~%")
  (message :print-color-string+display-gradient-001 "code~3@t前景色~6@t背景色~%")
  (dolist (code code-list)
    (show-color code)
    (terpri)
    (force-output *standard-output*)
    )
  
  (return-from display-gradient t)
  ) ;; end display-gradient

;;----------------------------------------------------------------------------------
;; RGBは各0..5。つまりxterm互換256色のRGB色空間は6x6x6=218色の色空間。
;;
;; Black        RGB = (0 0 0)
;; Red          RGB = (5 0 0)
;; Green        RGB = (0 5 0)
;; Blue         RGB = (0 0 5)
;; Cyan         RGB = (0 5 5) ;; C=5-R
;; Magenta      RGB = (5 0 5) ;; M=5-G
;; Yellow       RGB = (5 5 0) ;; Y=5-B
;;----------------------------------------------------------------------------------
(defun show-red-brightness-to-light (&optional (min 0) (max 5))
  (display-gradient (make-gradient min min min max min min) min min min max min min)
  )

(defun show-red-brightness-to-dark (&optional (min 0) (max 5))
  (display-gradient (make-gradient max min min min min min) max min min min min min)
  )

(defun show-red-brightness (&key (to-light nil))
  "赤色の明度変化をxterm互換端末256色モードの範囲で可能な限りのステップで表示する。
引数を指定しないか :light t なら濃→淡。:light nil なら淡→濃。
"
  (if to-light
      (show-red-brightness-to-light)
      (show-red-brightness-to-dark)
      )
  ) ;; end show-red-gradient

(defun show-green-brightness-to-light (&optional (min 0) (max 5))
  (display-gradient (make-gradient min min min min max min) min min min min max min)
  )

(defun show-green-brightness-to-dark (&optional (min 0) (max 5))
  (display-gradient (make-gradient min max min min min min) min max min min min min)
  )

(defun show-green-brightness (&key (to-light nil))
  "緑色の明度変化をxterm互換端末256色モードの範囲で可能な限りのステップで表示する。
引数を指定しないか :light t なら濃→淡。:light nil なら淡→濃。
"
  (if to-light
      (show-green-brightness-to-light)
      (show-green-brightness-to-dark)
      )
  )

(defun show-blue-brightness-to-light (&optional (min 0) (max 5))
  (display-gradient (make-gradient min min min min min max) min min min min min max)
  )

(defun show-blue-brightness-to-dark (&optional (min 0) (max 5))
  (display-gradient (make-gradient min min max min min min) min min max min min min)
  )

(defun show-blue-brightness (&key (to-light nil))
  "青色の明度変化をxterm互換端末256色モードの範囲で可能な限りのステップで表示する。
引数を指定しないか :light t なら濃→淡。:light nil なら淡→濃。
"
  (if to-light
      (show-blue-brightness-to-light)
      (show-blue-brightness-to-dark)
      )
  )

(defun show-cyan-brightness-to-light (&optional (min 0) (max 5))
  (display-gradient (make-gradient min min min min max max) min min min min min max)
  )

(defun show-cyan-brightness-to-dark (&optional (min 0) (max 5))
  (display-gradient (make-gradient min max max min min min) min max max min min min)
  )

(defun show-cyan-brightness (&key (to-light nil))
  "シアンの明度変化をxterm互換端末256色モードの範囲で可能な限りのステップで表示する。
引数を指定しないか :light t なら濃→淡。:light nil なら淡→濃。
"
  (if to-light
      (show-cyan-brightness-to-light)
      (show-cyan-brightness-to-dark)
      )
  )

(defun show-magenta-brightness-to-light (&optional (min 0) (max 5))
  (display-gradient (make-gradient min min min max min max) min min min max min max)
  )

(defun show-magenta-brightness-to-dark (&optional (min 0) (max 5))
  (display-gradient (make-gradient max min max min min min) max min max min min min)
  )

(defun show-magenta-brightness (&key (to-light nil))
  "マゼンタの明度変化をxterm互換端末256色モードの範囲で可能な限りのステップで表示する。
引数を指定しないか :light t なら濃→淡。:light nil なら淡→濃。
"
  (if to-light
      (show-magenta-brightness-to-light)
      (show-magenta-brightness-to-dark)
      )
  )

(defun show-yellow-brightness-to-light (&optional (min 0) (max 5))
  (display-gradient (make-gradient min min min max max min) min min min min min max)
  )

(defun show-yellow-brightness-to-dark (&optional (min 0) (max 5))
  (display-gradient (make-gradient max max min min min min) max max min min min min)
  )

(defun show-yellow-brightness (&key (to-light nil))
  "黄色の明度変化をxterm互換端末256色モードの範囲で可能な限りのステップで表示する。
引数を指定しないか :light t なら濃→淡。:light nil なら淡→濃。
"
  (if to-light
      (show-yellow-brightness-to-light)
      (show-yellow-brightness-to-dark)
      )
  )

(defun show-monochrome-brightness (&key (to-light nil))
  "モノクロの明度変化グラデーションを表示する。"
  (let ((codes (hue-gradient-xterm 255 255 255 0 0 0 :no-duplicates t)))
    (if to-light (setf codes (reverse codes)))
    ;;(format t "code   前景色      背景色~%")
    (message :print-color-string+show-monochrome-brightness-001 "code~3@t前景色~6@t背景色~%")
    (dolist (code codes)
      ;;(format t "~C[48;5;~Dm ~C[0m" #\Esc code #\Esc)
      (show-color code)
      (terpri)
      ) ;; end dolist
    )   ;; end let
  ) ;; end show-monochrome-brightness

(defun rgb-to-hsv (r g b)
  "RGB (0-255) を HSV (H:0-360, S:0-1, V:0-1) に変換する。"
  (let* ((r-norm (/ r 255.0))
         (g-norm (/ g 255.0))
         (b-norm (/ b 255.0))
         (max-val (max r-norm g-norm b-norm))
         (min-val (min r-norm g-norm b-norm))
         (delta (- max-val min-val))
         (h 0.0)
         (s (if (= max-val 0.0) 0.0 (/ delta max-val)))
         (v max-val))
    (declare (type single-float h s v))

    (when (> delta 0.0)
      (cond ((= max-val r-norm)
             (setf h (* 60.0 (mod (+ (/ (- g-norm b-norm) delta) 6) 6))))
            ((= max-val g-norm)
             (setf h (* 60.0 (+ (/ (- b-norm r-norm) delta) 2))))
            ((= max-val b-norm)
             (setf h (* 60.0 (+ (/ (- r-norm g-norm) delta) 4)))))
      (when (< h 0.0)
        (incf h 360.0)))
    (list h s v)))

(defun hsv-to-rgb (h s v)
  "HSV (H:0-360, S:0-1, V:0-1) を RGB (0-255) に変換する。"
  (let ((r 0.0) (g 0.0) (b 0.0))
    (if (= s 0.0)
        (setf r v g v b v)
        (let* ((h-prime (/ h 60.0))
               (c (* v s))
               (x (* c (- 1.0 (abs (- (mod h-prime 2.0) 1.0))))))
          (case (floor h-prime)
            (0 (setf r c g x b 0.0))
            (1 (setf r x g c b 0.0))
            (2 (setf r 0.0 g c b x))
            (3 (setf r 0.0 g x b c))
            (4 (setf r x g 0.0 b c))
            (5 (setf r c g 0.0 b x)))
          (let ((m (- v c)))
            (setf r (+ r m) g (+ g m) b (+ b m)))))
    (list (round (* r 255)) (round (* g 255)) (round (* b 255)))))

(defun calculate-xterm-code (r g b)
  "指定されたRGB値 (0-255) に最も近いXterm 256色コードを返す。"
  (let ((min-dist (expt 255 2))
        (best-code 0))

    ;; グレースケール (232-255) の検索
    (dotimes (i 24)
      (let* ((code (+ 232 i))
             (gray-val (+ 8 (* i 10)))
             (dist-sq (+ (expt (- r gray-val) 2)
                         (expt (- g gray-val) 2)
                         (expt (- b gray-val) 2))))
        (when (< dist-sq min-dist)
          (setf min-dist dist-sq
                best-code code))))

    ;; 216色カラーキューブ (16-231) の検索
    (let ((levels '(0 95 135 175 215 255)))
      (dotimes (rr 6)
        (let ((cube-r (nth rr levels)))
          (dotimes (gg 6)
            (let ((cube-g (nth gg levels)))
              (dotimes (bb 6)
                (let* ((cube-b (nth bb levels))
                       (code (+ 16 (* rr 36) (* gg 6) bb)) ; Xtermコード計算式
                       (dist-sq (+ (expt (- r cube-r) 2)
                                   (expt (- g cube-g) 2)
                                   (expt (- b cube-b) 2))))
                  (when (< dist-sq min-dist)
                    (setf min-dist dist-sq
                          best-code code)))))))))

    best-code)
  ) ;; end calculate-xterm-code

(defun hue-gradient-xterm (r1 g1 b1 r2 g2 b2 &key (no-duplicates nil))
  "HSV空間で色相補間を行い、指定されたステップ数のXtermコードリストを返す。"
  (let* ((hsv1 (rgb-to-hsv r1 g1 b1))
         (hsv2 (rgb-to-hsv r2 g2 b2))
         (h1 (nth 0 hsv1)) (s1 (nth 1 hsv1)) (v1 (nth 2 hsv1))
         (h2 (nth 0 hsv2)) (s2 (nth 1 hsv2)) (v2 (nth 2 hsv2))
         (steps max-resolution)
         (results nil)
         (h-diff (- h2 h1)))

    (when (> h-diff 180.0) (decf h-diff 360.0))
    (when (< h-diff -180.0) (incf h-diff 360.0))

    (when (debug-print-p "hue-gradient-xterm")
      (format t "hue-gradient-xterm:h-diff=~d~%" h-diff)
      )

    (let (t-val (h-interp 0.0) (s-interp 0.0) (v-interp 0.0)
          (r-out 0) (g-out 0) (b-out 0) rgb-out)
      (declare (type single-float h-interp s-interp v-interp))

      (dotimes (i steps)
        (declare (type fixnum i))
        (setf t-val (/ i (max 1 (1- steps))))
        (when (debug-print-p "hue-gradient-xterm")
          (format t "hue-gradient-xterm:t-val=~d~%" t-val)
          )
        (setf h-interp (mod (+ h1 (* h-diff t-val)) 360.0))
        (setf s-interp (+ s1 (* (- s2 s1) t-val)))
        (setf v-interp (+ v1 (* (- v2 v1) t-val)))
        (when (debug-print-p "hue-gradient-xterm")
          (format t "hue-gradient-xterm:h-interp=~d, s-interp=~d, v-interp=~d~%"
                  h-interp s-interp v-interp)
          )
        (setf rgb-out (hsv-to-rgb h-interp s-interp v-interp))
        (setf r-out (nth 0 rgb-out))
        (setf g-out (nth 1 rgb-out))
        (setf b-out (nth 2 rgb-out))
        (push (calculate-xterm-code r-out g-out b-out) results)
        ) ;; end dotimes
      )   ;; end let

    (if (identity no-duplicates)
        (the list (remove-duplicates-preserving-order (nreverse results)))
        (the list (nreverse results))
        ) ;; end if

    ) ;; end let*
  ) ;; end hue-gradient-xterm

(defun saturation-gradient-xterm-reverse (r-pure g-pure b-pure &key (no-duplicates nil))
  "無彩色（グレー）から指定された純色への彩度グラデーションを計算する。"
  (let* ((hsv-pure (rgb-to-hsv r-pure g-pure b-pure))
         (h (nth 0 hsv-pure))
         (v (nth 2 hsv-pure))
         (steps max-resolution)
         (results '()))

    (dotimes (i steps)
      (let* ((t-val (/ i (max 1 (1- steps))))
             (s-interp (- 1.0 t-val))
             (rgb-out (hsv-to-rgb h s-interp v))
             (r-out (nth 0 rgb-out))
             (g-out (nth 1 rgb-out))
             (b-out (nth 2 rgb-out)))
        (declare (type fixnum i))

        (push (calculate-xterm-code r-out g-out b-out) results)
        ) ;; end let*
      )   ;; end dotimes

    ;;(nreverse results)

    (if (identity no-duplicates)
        (the list (remove-duplicates-preserving-order results))
        (the list results )) ;; end if

    ) ;; end let*
  ) ;; end saturation-gradient-xterm-reverse

(defun saturation-gradient-xterm (r-pure g-pure b-pure &key (no-duplicates nil))
  "指定された純色から無彩色（グレー）への彩度グラデーションを計算する。"
  (reverse
   (saturation-gradient-xterm-reverse r-pure g-pure b-pure :no-duplicates no-duplicates))
  )

(defun show-hue-gradient (&key (from nil) (to nil))
  "R-G-B-C-M-Y間の任意の2つの色の間の色相変化のグラデーションを表示する。
同じ色の連続する部分は縮約する。
引数に指定できるのは[*xterm-basic-color-list*]に登録されている
        'red
        'green
        'blue
        'cyan
        'magenta
        'yellow
        'gray
のいずれかのシンボルか (R G B) 形式の色成分リスト。RGBはいずれも0..255の範囲の整数。
[*xterm-basic-color-list*]のカラー・コードの初期値は純色を与えてある。カラー・コード
の値を変えた場合は純色からのグラデーションではなくなるので注意。
"
  (let (code-list xterm-code)

    (when (or (null from) (null to)) (return-from show-hue-gradient nil))
    (when (equal from to) (return-from show-hue-gradient nil))

    (when (and (symbolp from)
               (member-by-symbol-name from (mapcar #'first *xterm-basic-color-list*)))
      (setf xterm-code (eval (cdr (assoc-by-symbol-name from *xterm-basic-color-list*))))
      (setf from (xterm-code-to-rgb xterm-code))
      (when (debug-print-p "show-hue-gradient")
        (format t "xterm-code=~s~%" xterm-code)
        (format t "(xterm-code-to-rgb ~s)=~s~%" xterm-code (xterm-code-to-rgb xterm-code))
        )
      )
    
    (when (and (symbolp to)
               (member-by-symbol-name to (mapcar #'first *xterm-basic-color-list*)))
      (setf xterm-code (eval (cdr (assoc-by-symbol-name to *xterm-basic-color-list*))))
      (setf to (xterm-code-to-rgb xterm-code))
      )
    
    (setf code-list (hue-gradient-xterm
                     (nth 0 from) (nth 1 from) (nth 2 from)
                     (nth 0 to) (nth 1 to) (nth 2 to) :no-duplicates t))

    ;;(setf code-list (remove-duplicates-preserving-order code-list))
    (dolist (code code-list)
      (show-color code)
      (terpri)
      ) ;; end dolist
    (finish-output)
    )   ;; end let
  ) ;; end hue-gradient

(defun show-saturation-gradient (color &key (to-light t))
  "純色から高明度グレーへのグラデーションを表示する。
:to-dark t なら高明度グレーから純色へのグラデーション。:to-dark nil なら純色から高明度グレーへのグラデーション。
"
  (let (code-list (rgb-color nil))

    (cond
      ((and ;; 第1引数が既定の色名シンボルだった場合。 
        (symbolp color)
        (member-by-symbol-name color *predefined-xcolor-names*)
        )
       (setf rgb-color 
             (xterm-code-to-rgb
              (eval (cdr (assoc-by-symbol-name color *xterm-basic-color-list*)))))
       )
      ((and ;; 第1引数が既定の色名シンボルではないシンボルだった場合。
        (symbolp color)
        (not (member-by-symbol-name color *predefined-xcolor-names*))
        )
       (setf rgb-color (xterm-code-to-rgb (eval color)))
       )
      ((and ;; 第1引数が (r g b) 形式のリストだった場合。
        (listp color)
        (= (length color) 3) 
        (every #'valid-xterm-256-color-code-p color)
        )
       (setf rgb-color color)
       )
      ((and ;; 第1引数が正しいカラー・コードの数値だった場合。
        (integerp color)
        (valid-xterm-256-color-code-p color)
        )
       (setf rgb-color (xterm-code-to-rgb color))
       )
      (t ;; 上記以外。
       ;;(format t "show-saturation-gradient:第1引数はシンボル、RGBリスト、またはカラー・コードです。~%")
       (message :print-color-string+show-saturation-gradient-001
                "第1引数はシンボル、RGBリスト、またはカラー・コードです。~%")
       (return-from show-saturation-gradient nil)
       )
      ) ;; end cond


    (setf code-list
          (saturation-gradient-xterm (nth 0 rgb-color) (nth 1 rgb-color) (nth 2 rgb-color)
                                     :no-duplicates t))

    (when (null to-light)
      (setf code-list (reverse code-list))
      )

    (dolist (code code-list)
      (show-color code)
      (terpri)
      ) ;; end dolist
    (finish-output)
    ) ;; end let
  )

(defun show-brightness (color &key (to-light nil))
  (let ((color-name nil))
    (when (or (integerp color) (not (symbolp color))) ;; 数値であるか、シンボルでないなら[nil]。
      (return-from show-brightness nil)
      )

    (when (debug-print-p "show-brightness")
      (format t "show-brightness:(string-downcase (symbol-name ~s))=~s~%"
              color (string-downcase (symbol-name color)))
      )

    (setf color-name (string-downcase (symbol-name color)))

    (cond
      ((string= color-name "red")
       (show-red-brightness :to-light to-light))
      ((string= color-name "green")
       (show-green-brightness :to-light to-light))
      ((string= color-name "blue")
       (show-blue-brightness :to-light to-light))
      ((string= color-name "cyan")
       (show-cyan-brightness :to-light to-light))
      ((string= color-name "magenta")
       (show-magenta-brightness :to-light to-light))
      ((string= color-name "yellow")
       (show-yellow-brightness :to-light to-light))
      ((string= color-name "gray")
       (show-monochrome-brightness :to-light to-light))
      (t
       ;;(format t "~%show-brightness:第1引数は既定の色名シンボルでなければなりません。~%")
       (message :print-color-string+show-brightness-001
               "~%show-brightness:第1引数は既定の色名シンボルでなければなりません。~%")
       ;;(format t "既定の色名シンボル=~a~%" (string-downcase *predefined-xcolor-names*))
       (message :print-color-string+show-brightness-002
                "既定の色名シンボル=~a~%" (string-downcase *predefined-xcolor-names*))
       (return-from show-brightness nil)
       )
      ) ;; end cond
    )   ;; end let
  ) ;; end show-brightness

(defun show-all-gradation (&key (hue nil) (brightness nil) (saturation nil))
  "xterm互換端末で配色の参考とするための類型化した色のグラデーションを表示する関数。
  RGB各色相のグラデーションと淡色->濃色グラデーションを実行する。"
    
  (when (not (is-xterm-compatible))
    ;;(format t "xterm互換256色端末でなければグラデーション表示はできません。")
    (message :print-color-string+show-all-gradation-001
             "xterm互換256色端末でなければグラデーション表示はできません。")
    (return-from show-all-gradation nil)
    )

  (when (every #'null (list hue brightness saturation)) ;; すべてが[nil]ならすべてを[t]にする。
    (show-all-gradation :hue t :brightness t :saturation t)
    (return-from show-all-gradation t)
    ) ;; end when

  ;;(format t "--- 端末で使用可能なグラデーション (xterm 256色) ---~%")
  (message :print-color-string+show-all-gradation-002
           "--- 端末で使用可能なグラデーション (xterm 256色) ---~%")
    
  ;; --------------------------------------------------------------------
  ;; 色相変化グラデーション
  ;; --------------------------------------------------------------------
  (when hue
    (format t "~%*** 色相変化グラデーション ***~%")
    
    ;; R -> G (R: 5->0, G: 0->5, B: 0->0)
    ;;(format t "~%R -> G グラデーション (show-hue-gradient :from \'red :to \'green)~%")
    (message :print-color-string+show-all-gradation-003
             "~%R -> G グラデーション (show-hue-gradient :from \'red :to \'green)~%")
    ;;(display-gradient (make-gradient max min min min max min) max min min min max min)
    (show-hue-gradient :from 'red :to 'green)
    
    ;;(format t "~%G -> R グラデーション~%")
    ;;(show-hue-gradient :from 'green :to 'red)
    
    ;; G -> B (R: 0->0, G: 5->0, B: 0->5)
    ;;(format t "~%G -> B グラデーション (show-hue-gradient :from \'green :to \'blue)~%")
    (message :print-color-string+show-all-gradation-004
             "~%G -> B グラデーション (show-hue-gradient :from \'green :to \'blue)~%")
    ;;(display-gradient (make-gradient min max min min min max) min max min min min max)
    (show-hue-gradient :from 'green :to 'blue)
    
    ;;(format t "~%B -> G グラデーション~%")
    ;;(show-hue-gradient :from 'blue :to 'green)

    ;; B -> R (R: 0->5, G: 0->0, B: 5->0)
    ;;(format t "~%B -> R グラデーション (show-hue-gradient :from \'blue :to \'red)~%")
    (message :print-color-string+show-all-gradation-005
             "~%B -> R グラデーション (show-hue-gradient :from \'blue :to \'red)~%")
    ;;(display-gradient (make-gradient min min max max min min) min min max max min min)
    (show-hue-gradient :from 'blue :to 'red)
    
    ;;(format t "~%R -> B グラデーション~%")
    ;;(show-hue-gradient :from 'red :to 'blue)
    ) ;; end when hue

  ;; --------------------------------------------------------------------
  ;; 明度グラデーション：淡色 -> 濃色 グラデーション (黒から純色)
  ;; --------------------------------------------------------------------

  (when brightness
    ;; 赤 (淡 -> 濃 / R: 0->5)
    ;;(format t "~%明度:赤グラデーション (淡 -> 濃) (show-brightness \'red :to-light nil)~%")
    (message :print-color-string+show-all-gradation-006
             "~%明度:赤グラデーション (淡 -> 濃) (show-brightness \'red :to-light nil)~%")
    ;;(display-gradient (make-gradient min min min max min min) min min min max min min)
    ;;(show-red-gradient-to-dark)
    (show-brightness 'red :to-light nil)
    
    ;;(format t "~%明度:赤グラデーション (濃 -> 淡)")
    ;;(display-gradient (make-gradient min min min max min min) min min min max min min)
    ;;(show-brightness 'red :to-light t)
    
    ;; 緑 (淡 -> 濃 / G: 0->5)
    ;;(format t "~%明度:緑グラデーション (淡 -> 濃) (show-brightness \'green :to-light nil)~%")
    (message :print-color-string+show-all-gradation-007
             "~%明度:緑グラデーション (淡 -> 濃) (show-brightness \'green :to-light nil)~%")
    ;;(display-gradient (make-gradient min min min min max min) min min min min max min)
    (show-brightness 'green :to-light nil)

    ;;(format t "~%明度:緑グラデーション (濃 -> 淡)")
    ;;(display-gradient (make-gradient min min min min max min) min min min min max min)
    ;;(show-brightness 'green :to-light t)

    ;; 青 (淡 -> 濃 / B: 0->5)
    ;;(format t "~%明度:青グラデーション (淡 -> 濃) (show-brightness \'blue :to-light nil)~%")
    (message :print-color-string+show-all-gradation-008
             "~%明度:青グラデーション (淡 -> 濃) (show-brightness \'blue :to-light nil)~%")
    ;;(display-gradient (make-gradient min min min min min max) min min min min min max)
    (show-brightness 'blue :to-light nil)

    ;;(format t "~%明度:青グラデーション (濃 -> 淡)")
    ;;(display-gradient (make-gradient min min min min min max) min min min min min max)
    ;;(show-brightness 'blue :to-light t)

    ;;(format t "~%明度:白黒グラデーション（淡→濃）(show-brightness \'gray :to-light nil)~%")
    (message :print-color-string+show-all-gradation-009
             "~%明度:白黒グラデーション（淡→濃）(show-brightness \'gray :to-light nil)~%")
    (show-brightness 'gray :to-light nil)

    ;;(format t "~%明度:白黒グラデーション（濃→淡）(show-brightness \'gray :to-light t)~%")
    ;;(show-brightness 'gray :to-light t)
    ) ;; end when brightness

  ;; --------------------------------------------------------------------
  ;; 濃色 -> 淡色 グラデーション
  ;; --------------------------------------------------------------------

  (when saturation
    ;;(format t "~%彩度グラデーション（純赤から高明度グレーへ）(show-saturation-gradient \'red :to-light t)~%")
    (message :print-color-string+show-all-gradation-010
             "~%彩度グラデーション（純赤から高明度グレーへ）(show-saturation-gradient \'red :to-light t)~%")
    (show-saturation-gradient 'red :to-light t)

    ;;(format t "~%彩度グラデーション（純緑から高明度グレーへ）(show-saturation-gradient \'green :to-light t)~%")
    (message :print-color-string+show-all-gradation-011
             "~%彩度グラデーション（純緑から高明度グレーへ）(show-saturation-gradient \'green :to-light t)~%")
    (show-saturation-gradient 'green :to-light t)

    ;;(format t "~%彩度グラデーション（純青から高明度グレーへ）(show-saturation-gradient \'blue :to-light t)~%")
    (message :print-color-string+show-all-gradation-012
             "~%彩度グラデーション（純青から高明度グレーへ）(show-saturation-gradient \'blue :to-light t)~%")
    (show-saturation-gradient 'blue :to-light t)
    ) ;; end when saturation

  (terpri)
  (finish-output)
  (return-from show-all-gradation t)

  ) ;; end show-all-gradation

(defun xterm-code-to-rgb (code)
  "Xterm 256色コード (0-255) に対応するRGB値のリスト (R G B) を返す。"
  (check-type code (integer 0 255) "Xterm code must be integer range of 0..255.")

  (cond
    ;; グレースケール 24色 (232-255)
    ((>= 255 code 232)
     (let* ((i (- code 232))
            ;; i: 0から23。グレー値は 8 + i * 10 で定義される
            (gray-val (+ 8 (* i 10))))
       (list gray-val gray-val gray-val))
     )
    ((>= 231 code 16) ;; カラーキューブ 216色 (16-231)
     (let* ((relative-code (- code 16))
            ;; R, G, B 各成分に対応する 0-5 のインデックスを抽出
            (rr (floor relative-code 36))
            (gg (floor (mod relative-code 36) 6))
            (bb (mod relative-code 6))
            ;; 各インデックスに対応する RGB の輝度レベル (0-255)
            (levels '(0 95 135 175 215 255)))
       
       (list (nth rr levels) (nth gg levels) (nth bb levels))
       ) ;; end let*
     )
    ((>= 15 code 0) ;; ANSI/標準 16色 (0-15)
     ;; 標準16色は、厳密なRGB定義がターミナルによって異なるが、
     ;; 通常は 0/128/255 の値の組み合わせ。
     ;; 最も一般的な定義（0/128/255 の近似値）を返す。
     (case code
       (0  (list 0 0 0))        ;; Black
       (1  (list 170 0 0))      ;; Red (Dark)
       (2  (list 0 170 0))      ;; Green (Dark)
       (3  (list 170 85 0))     ;; Yellow (Dark)
       (4  (list 0 0 170))      ;; Blue (Dark)
       (5  (list 170 0 170))    ;; Magenta (Dark)
       (6  (list 0 170 170))    ;; Cyan (Dark)
       (7  (list 170 170 170))  ;; White/Light Gray
       (8  (list 85 85 85))     ;; Bright Black/Dark Gray
       (9  (list 255 0 0))      ;; Bright Red
       (10 (list 0 255 0))      ;; Bright Green
       (11 (list 255 255 0))    ;; Bright Yellow
       (12 (list 0 0 255))      ;; Bright Blue
       (13 (list 255 0 255))    ;; Bright Magenta
       (14 (list 0 255 255))    ;; Bright Cyan
       (15 (list 255 255 255))  ;; Bright White
       )                        ;; end case
     )
    ;;(t
    ;; (do-nothing)
    ;; )
    ) ;; end cond
  ) ;; end xterm-code-to-rgb

(defun remove-duplicates-preserving-order (list &key (test #'eql))
  "リストの重複要素を削除し、要素の最初の出現順序を保持した新しいリストを返します。
   :test キーワード引数で比較関数を指定できます（デフォルトは #'EQL）。"
  (let ((seen (make-hash-table :test test)) ;; 既に出現した要素を記録するハッシュテーブル
        (result '())) ;; 順序が逆転した状態で要素を蓄積するリスト
    
    ;; リストを先頭から順に処理
    (dolist (item list)
      ;; 項目がハッシュテーブルに存在しない場合
      (unless (gethash item seen)
        ;; 結果リストの先頭に項目を追加
        (push item result)
        ;; ハッシュテーブルに記録（値は T など何でも良い）
        (setf (gethash item seen) t)))
    
    ;; push で逆順になっているため、結果を反転させて返す
    (nreverse result)
    ) ;; end let
  ) ;; end remove-duplicates-preserving-order

(defun terminal-type ()
  "環境変数 TERM の値を取得する。
 \"xterm\"              XTerm互換 (最も標準的)
 \"xterm-256color\"     XTerm互換 (256色対応)
 \"screen\" / \"tmux\"  XTerm互換 (多重化ソフト)
 \"vt100\" / \"linux\"  非XTerm (古い規格)
"
  #+sbcl  (sb-ext:posix-getenv "TERM")
  #+clisp (ext:getenv "TERM")
  #+gcl   (si:getenv "TERM")
  )

(defun is-xterm-compatible-sub ()
  (let ((term-type (terminal-type)))
    (cond
      ((null term-type)
       nil)
      ((stringp term-type)
       (or
        (search "xterm" term-type :test #'string-equal)
        (string-equal term-type "screen")
        (string-equal term-type "tmux")
        ) ;; end or
       )
      ) ;; end cond
    )   ;; end let
  )

(defun is-xterm-compatible ()
  "現在の端末が XTerm またはその互換エミュレータであるか判別する。"
  (cond
    ((is-xterm-compatible-sub)
     (setf *terminal-capability* 'xterm)
     )
    (t
     nil
     )
    )
  )

(defun is-ansi-compatible-sub ()
  (let ((term-type (terminal-type)))
    (cond
      ((null term-type)
       nil
       )
      ((stringp term-type)
       (or
        (string-equal term-type "linux")
        (string-equal term-type "ansi")
        (string-equal term-type "vt-100")
        ) ;; end or
       )  ;; end stringp
      )   ;; end cond
    )     ;; end let
  ) ;; end is-ansi-compatible

(defun is-ansi-compatible ()
  "現在の端末がansiまたは、その互換エミュレータであるか判別する。"
  (cond
    ((is-ansi-compatible-sub)
     (setf *terminal-capability* 'ansi)
     )
    (t
     nil
     )
    )
  )

(defun dumb-terminal-p-sub ()
  (let ((term-type (terminal-type)))
    (cond
      ((null term-type)
       t
       )
      ((stringp term-type)
       (or
        (string-equal term-type "dumb")
        (string-equal term-type "unknown")
        (string-equal term-type "none")
        ) ;; end or
       )  ;; end stringp
      )   ;; end cond
    )     ;; end let
  )

(defun dumb-terminal-p ()
  "現在の出力先がダム端末(テレタイプなど)であるかを判別する。"
  (cond
    ((dumb-terminal-p-sub)
     (setf *terminal-capability* 'dumb)
    )
    (t
     nil)
    )
  )

(defun make-space (n)
  (when (and (integerp n) (> n 0))
    (make-string n :initial-element #\space)
    )
  )

;;
;; 出力フォーマット統一のために定義。調整する場合は、この関数を変更する。
;;
(defun show-color (code)
  (format t "~3d: " code)
  (print-colored-string code *sample-string*)
  (format t " ")
  (print-colored-string code *sample-string* :invert t)
  ;;(terpri)
  )

;; 初期設定用ファイル("init-print-color-string.lisp")の自動読み込みを行う。
(let (absolute-pathname)
  (setf absolute-pathname (find-current-and-home-dir "init-print-color-string" :ext ".lisp"))

  (when (identity absolute-pathname)
    (load absolute-pathname :if-does-not-exist nil)
    )
  )
;;=================================================================================

(eval-when (:load-toplevel :execute)
  (reset-terminal-env)
  )

;;(show-all-gradation) ;; xterm互換端末で表示可能な各種グラデーションを表示する。

#+ :build-as-packages
(provide :print-color-string)
