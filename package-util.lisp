;;;
;;; パッケージ操作用関数を集めたパッケージ。
;;;
;;; last updated : 2026-04-11 10:26:00(JST)
;;;
;;; 2026-06-20 パッケージ間の依存(ユース)関係をGraphvizで表示する関数[view-package-dependency-graph]を実装。
;;;

#+ :build-as-packages
(defpackage :package-util
  (:use :common-lisp)
  (:use :support-functions)
  (:nicknames :px :dir)
  (:export
   #:cd
   #:pwd
   #:pushd
   #:popd
   #:dirs
   #:rotate-down-dir
   #:rotdd
   #:rotd
   #:rotate-up-dir
   #:rotud
   #:exchgd
   #:ls
   #:auto-show-dirs
   #:number-of-external-symbols
   #:set-package-name-case
   #:get-package-name-case
   #:name-case-convert
   #:package-changed-by-package-util
   #:package-changed-by-package-util-p
   #:package-name-case-convert
   #:package-name-case-list-convert
   #:packages-exception-list
   #:package-exclusion-list
   #:shortest-nickname
   #:get-external-symbols
   #:get-internal-symbols
   #:get-inherited-symbols
   #:symbol-attribute
   #:type-of-symbol
   #:last-package
   #:view-package-dependency-graph ;; パッケージ間の依存(ユース)関係をGraphvizで表示する。
   #:view-pkg-dep
   )
  )

(declaim (optimize (safety 0) (speed 3) (space 0) (debug 0) (compilation-speed 0))) ;; maximum speed.
;;(declaim (optimize (safety 3) (speed 0) (space 0) (debug 3) (compilation-speed 0))) ;; maximum safety

#+ :build-as-packages (in-package :package-util)

(defconstant +graphviz-shape+
  '(:box :oval :ellipse :egg :circle :double-circle :triangle :diamond :trapezoid :hexgon :septagon
    :octagon :doubleoctagon :tripleoctagon :invtriangle :invtrapezium :house :invhouse :Mdiamond
    :Msquare :square :star :underline :note :tab :folder :box3d))
(defconstant +graphviz-packmode+ '(:node :column :cluster))
(defconstant +graphviz-format+ '(:png :jpeg :jpeg :gif :bmp :svg :svgz :tiff :tif :pdf))
(defconstant +graphviz-layout+ '(:circo :dot)) ;; 不向きなレイアウトは除いた。

(defparameter *package-dependency-graph-fname-prefix* "package-dependency-graph-")
(defparameter *package-stack* nil)
(defparameter *last-package* nil)   ;; 現在のパッケージを記録しておく。
;;(defparameter *last-package* (find-package :cl-user))
(defparameter *auto-show-dirs* 1)
(defparameter *package-case* :downcase)
(defparameter *package-changed* nil)
(defparameter *packages-exception-list*
  '("common-lisp" "keyword" "system")) ;; 外部シンボルを取得しないパッケージ。
(defparameter *package-exclusion-list* ;; パッケージ名補完の対象外とするパッケージ。
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

(defun package-exclusion-list ()
  *package-exclusion-list*
  )

(defun packages-exception-list ()
  *packages-exception-list*
  )

(defun package-changed-by-package-util (flag)
  (setf *package-changed* flag)
  )

(defun package-changed-by-package-util-p ()
  *package-changed*
  )

(defun last-package (&optional (pkg nil))
  (cond
    ((null pkg)
     *last-package*)
    ((packagep (find-package pkg))
     (setf *last-package* pkg) )
    (t (warn "last-package:~a must be package.~%" pkg))
    ) ;; end cond
  )

;;
;; 引数で与えられたパッケージ(パッケージ・オブジェクトまたはパッケージ文字列)によって
;; 用いられるパッケージ文字列のリストを返す。ただし[:verbose t]でない場合は自明なパッケージ
;; [common-lisp]パッケージと[keyword]パッケージは除く。
;; 用いられるパッケージがない場合は[nil]を返す。引数がパッケージでなかった場合も[nil]を返す。
;;
;; [package-use-list]は規格上「他のパッケージを返す」と規定されているが自分自身のパッケージを返すことは
;; 禁止されていない。sbclでは通常は自分自身のパッケージを返すことはないが、このコード上では自分自身も含めて
;; 返された。clispでは、そのようなことはなかった。念の為、自分自身のパッケージ名が含まれていた場合は除外する
;; ようにコーディングしている。
;;
(defun package-string-use-list (pkg &key (verbose nil))
  (let (
	(pkg-use-list nil)
	(result nil)
	tmp
	)
    ;;(format t "package-string-use-list:pkg=~s~%" pkg)
    (when (find-package pkg)
      (setf pkg-use-list (package-use-list (find-package pkg))) ;; パッケージのリストまたは[nil]。
      (when pkg-use-list
        (dolist (p pkg-use-list)
          (setf tmp (package-name p))
          (cond
            ((identity verbose) ;; [verbose]が[t]ならすべてが対象。
             (push tmp result)
             )
            ;; [verbose]が[nil]でも(packages-exception-list)の要素でも自身の表すパッケージでもないなら対象。
            ((not (member tmp
			  (append
			   (packages-exception-list)
			   (list (package-name (find-package pkg)))
			   )
			  :test #'string-equal))
             (push tmp result)
             )
            ) ;; end cond
          )   ;; end dolist
        (setf result (package-name-case-list-convert (sort (copy-seq result) #'string<)))
        ) ;; end when
      )   ;; end when
    (return-from package-string-use-list result)
    ) ;; end let
  )   ;; end package-string-use-list

(defun show-package-string-use-list (pkg)
  (let (package-use-list-string)
    (setf package-use-list-string (package-string-use-list pkg :verbose nil))
    (if package-use-list-string
        (message :package-util+show-package-string-use-list-001
                 "パッケージ ~a をユースしています。~%" package-use-list-string)
        ) ;; end if
    (values)
    )     ;; end let
  )

(defun package-string-used-list (pkg)
  (let ((string-used-by-list nil))
    (when (find-package pkg)
      (setf string-used-by-list (mapcar #'package-name (package-used-by-list pkg)))
      ) ;; end when
    (package-util::package-name-case-list-convert
     (remove (package-name (find-package pkg))
             (sort (copy-seq string-used-by-list) #'string<) :test #'string-equal))
    ) ;; end let
  ) ;; end package-string-used-list

(defun show-package-string-used-list (pkg)
  (let (package-used-list-string)
    (setf package-used-list-string (package-string-used-list pkg))
    (if package-used-list-string
        (message :package-util+show-package-string-used-list-001
                 "パッケージ ~a からユースされています。~%" package-used-list-string)
        ) ;; end if
    (values)
    ) ;; end let
  )

;; 引数で与えられたパッケージの基本名とニックネームを表示する。
(defun show-principal-and-nicknames (pkg)
  (when (null (find-package pkg))
    (return-from show-principal-and-nicknames (values))
    )
  (cond
    ((package-nicknames pkg)
     (format t "~a ~a~%" (find-package pkg) (package-name-case-list-convert (sort-nicknames pkg)))
     )
    (t
     (format t "~a~%" (find-package pkg))
     )
    ) ;; end cond
  (values)
  ) ;; end show-pricipal-and-nicknames

(defun change-package-to (pkg)
  ;;(format t "change-package-to:pkg=~s~%" pkg)
  (if (packagep (find-package pkg))
      (setf *package* (find-package pkg))
      (warn "~s is not a package.~%" pkg)
      ) ;; end if
  ) ;; end change-package-to

;;
;; パッケージ移動の際に設定レベルに応じて情報を表示する。
;;
;;      [nil]   一切表示しない。
;;        0     最低限度表示する。
;;        1     普通レベルに表示する。
;;        2     最大限表示する。
;;
(defun show-additional-info-if-exist ()
  (let (show-level)
    ;;(format t "show-additional-info-if-exist(0)~%")
    (setf show-level (auto-show-dirs))
    (when (and
	   (identity show-level)
	   (integerp show-level)
	   (not (member (package-name *package*) (packages-exception-list) :test #'string-equal))
	   )
      (dirs) ;; show dir stack.
      (if (>= show-level 0) (show-package-string-use-list  *package*))
      (if (>= show-level 1) (show-package-string-used-list *package*))
      )
    (values)
    ) ;; end let
  ) ;; end show-additional-info-if-exist

;; print current working package.
(defun pwd () (show-principal-and-nicknames *package*))

(defun cd (&optional (pkg nil)) ;; change package.
  ;;(format t "cd:pkg=~s~%" pkg)
  (cond
    ((null pkg) ;; [common-lisp-user]パッケージに戻る。
     (change-package-to (find-package :cl-user))
     (setf *package-stack* (list (find-package :cl-user)))
     (package-changed-by-package-util t)
     (show-additional-info-if-exist)
     )
    ((packagep (find-package pkg))
     (change-package-to (find-package pkg))
     (setf *package-stack* (list (find-package pkg)))
     (package-changed-by-package-util t)
     (show-additional-info-if-exist)
     )
    (t
     (warn "package ~a not found." pkg)
     )
    ) ;; end cond
  ) ;; end cd

;;
;; パッケージ名スタックに引数で指定されたパッケージを積み、カレント・パッケージにする。
;;
(defun pushd (pkg) ;; push package.
  (cond
    ((null pkg)
     nil
     )
    ((packagep (find-package pkg))
     (push (find-package pkg) *package-stack*)
     ;;(format t "pushd(1):*package-stack*=~s~%" *package-stack*)
     (change-package-to pkg)
     (package-changed-by-package-util t)
     (show-additional-info-if-exist)
     )
    (t
     (warn "pushd: argument ~s does not designate any package.~%" pkg)
     )
    ) ;; end cond
  ) ;; end pushd

;;
;; パッケージ名スタックの先頭を捨ててスタックの2番目のパッケージ名を返し、カレント・パッケージにする。
;;
;; *package-stack* == nil                 returns :cl-user
;; *package-stack* == (:pkg-1)            returns :cl-user
;; *package-stack* == (:pkg-1 :pkg-2 ...) returns :pkg-2
;;
(defun popd () ;; pop package.
  (let (stack-top)
    (cond
      ((null (setf stack-top (pop *package-stack*))) ;; スタックが空なら[:cl-user]を設定。
       (package-changed-by-package-util t)
       (cd :cl-user)
       )
      ((null (setf stack-top (pop *package-stack*))) ;; 2番目の要素が[nil]の場合も[:cl-user]を設定。
       (package-changed-by-package-util t)
       (cd :cl-user)
       )
      ((packagep stack-top) ;; 2番目の要素がパッケージ。
       (package-changed-by-package-util t)
       (pushd stack-top) ;; スタック2番目の要素をスタック先頭に戻す。
       )
      (t
       (warn "popd: argument ~s in stack ~s, does not designate any package.~%"
	     stack-top *package-stack*)
       (values)
       )
      ) ;; end cond
    )	;; end let
  ) ;; end popd

;;
;; rotate up directory. (a b c) ==> (b c a)
;;
(defun rotate-up-dir ()
  (let (p)
    (cond
      ((null *package-stack*)
       nil
       )
      ((not (listp *package-stack*))
       nil
       )
      ((= (length *package-stack*) 1)
       ;;(first *package-stack*)
       nil ;; do nothing.
       )
      (t
       (setf p (pop *package-stack*))
       (setf *package-stack* (append *package-stack* (list p)))
       (change-package-to (first *package-stack*))
       (package-changed-by-package-util t)
       (show-additional-info-if-exist)
       ) ;; end [t]
      )  ;; end cond
    )    ;; end let
  ) ;; end rotd

(defun rotud () ;; synonym of rotate-up-dir.
  (rotate-up-dir)
  )

(defun rotd () ;; synonym of rotate-up-dir too.
  (rotate-up-dir)
  )

(defun rotate-down-dir () ;; (a b c) ==> (c a b)
  (let (p)
    (cond
      ((null *package-stack*)
       nil
       )
      ((not (listp *package-stack*))
       nil
       )
      ((= (length *package-stack*) 1)
       ;;(first *package-stack*)
       nil ;; do nothing.
       )
      (t
       (setf p (last *package-stack*))
       (setf *package-stack* (append p (butlast *package-stack*)))
       (change-package-to (first *package-stack*))
       (package-changed-by-package-util t)
       (show-additional-info-if-exist)
       ) ;; end [t]
      )  ;; end cond
    )
  )

(defun rotdd () ;; synonym of rotate-down-dir.
  (rotate-down-dir)
  )

;;
;; exchange top and second directory. (a b c) ==> (b a c)
;;
(defun exchgd ()
  (let (p q)
    (cond
      ((null *package-stack*)
       nil
       )
      ((not (listp *package-stack*))
       nil
       )
      ((= (length *package-stack*) 1)
       ;;*package-stack*
       nil ;; do nothing.
       )
      (t
       (setf p (pop *package-stack*)) ;; top of stack.
       (setq q (pop *package-stack*)) ;; second of stack.
       (setf *package-stack* (append (list q p) *package-stack*))
       (change-package-to (first *package-stack*))
       (package-changed-by-package-util t)
       (show-additional-info-if-exist)
       ) ;; end [t]
      )  ;; end cond
    )    ;; end let
  ) ;; end exchgd

;; 引数のリスト内の文字列を小文字化して返す。
(defun string-downcase-list (lst)
  (let ((result nil))
    (dolist (arg lst)
      (if (stringp arg)
          (push (string-downcase arg) result)
          (push arg result)
          )
      ) ;; end dolist
    (reverse result)
    ) ;; end let
  )

(defun dirs () ;; スタックに積まれているパッケージの履歴を表示する。
  (when (null *package-stack*)
    (push *package* *package-stack*)
    )
  (let (
	(i (1- (length *package-stack*)))
	(nickname-list nil)
	)
    (dolist (p *package-stack*)
      (let (
	    (is-current (string-equal (package-name p) (package-name *package*)))
	    )
        (format t "~3d:~c ~a"
                i
                (if is-current #\* #\Space)
                ;;(find-package p)
		p
                ) ;; end format
        )         ;; end let
      (when  (package-nicknames p) ;; ニックネームがあれば短い順に表示する。
        (setf nickname-list (sort-nicknames p))
        (let ((lst nil))
          (dolist (q nickname-list)
            (push (name-case-convert q) lst)
            )
          (format t " ~a" (reverse lst))
          ) ;; end let
        )   ;; end when
      (terpri)
      (decf i)
      ) ;; end dolist
    )   ;; end let
  (values)
  ) ;; end dirs

;;
;; 自動的にパッケージ名のディレクトリ・スタックを表示するかどうかを設定する。
;; 引数がなければ現在の設定状態を返す。
;;
(defun auto-show-dirs (&optional (p nil sw))
  (cond
    ((null sw)
     *auto-show-dirs*
     )
    (t
     (setf *auto-show-dirs* p)
     )
    ) ;; end cond
  ) ;; end auto-show-dirs

;;
;; 引数で指定されたパッケージの外部シンボル数を[str-1]と[str-2]で指定した文字で挟んだ文字列として返す。
;; [history-pkg:set-prompt-element]の[:not-cl-user]との整合性のため[cl-user]パッケージは対象外とする。
;; [cl-user]の外部シンボルは通常は[0]。(px:ls :package :cl-user)で表示することはできる。
;;
(defun number-of-external-symbols (&optional (pkg *package*) (str-1 "") (str-2 ""))
  (let ((lst nil))

    (when (eq (find-package pkg) (find-package :cl-user))
      (return-from number-of-external-symbols "")
      )

    (setf lst (get-external-symbols pkg))

    (return-from number-of-external-symbols (format nil "~a~d~a" str-1 (length lst) str-2))
    ) ;; end let
  ) ;; end number-of-external-symbols

;; シンボルの種別を表す文字列のリストを返す。
(defun type-of-symbol (sym)
  (let ((result nil))
    (setf result (symbol-attribute sym))
    (if (null result)
        (setf result "")
        (setf result (string-capitalize (symbol-name result)))
        ) ;; end if
    (return-from type-of-symbol result)
    ) ;; end let
  ) ;; end type-of-symbol

(defun ls (&key (string "") (package *package*)
             (external t) (internal nil) (inherited nil)
             (verbose t) (quiet nil))
  "指定したパッケージの指定された種類のシンボルを一覧表示する。
        :string \"文字列\"              \"文字列\"を含むシンボルのみを表示する。default \"\"(=all).
        :package 'パッケージ'            パッケージ文字列かパッケージ・オブジェクト。default *package*.
        :external [t/nil]               外部名シンボルを表示する。default [t].
        :internal [t/nil]               内部名シンボルを表示する。default [nil].
        :inherited [t/nil]              継承シンボルを表示する。default [nil].
        :verbose [t/nil]                表示シンボルの属性なども表示する。default [t].
        :quiet [t/nil]                  属性ごとのタイトル表示を行わない。default [nil].
"

  (let (
        (target (find-package package))
        (count 0)
        (total-count 0)
        (kind nil)
        (kind-str nil)
        (lst '(external internal inherited))
        (lst-evaled (list external internal inherited))
        p
        )

    (when (null target)
      (warn "Package ~a not found." package)
      (return-from ls (values))
      ) ;; end when
    
    (when (not (stringp string))
      (setf string (string-downcase (symbol-name string)))
      )

    (setf total-count 0)
    (dotimes (i (length lst))
      (setf p (nth i lst))
      ;;(format t "p=~s~%" p)
      (when (identity (nth i lst-evaled))
        (when (not quiet)
          (format t "~a symbols in ~a:~%"
                  (string-capitalize (symbol-name p))
                  (string-downcase (package-name target))
                  )
          ) ;; end inner when
        (setf count 0)
        (dolist (q (sort (copy-seq (get-symbols target p)) #'string<))
          ;;(format t "q=~s~%" q)
          (when (or (zerop (length string)) (search string (symbol-name q) :test #'string-equal))
            (incf count)
            (cond
              ((identity verbose)
               (setf kind (type-of-symbol q))
               (setf kind-str (if kind (format nil "(~a)" kind) ""))
               (format t "~18@a " kind-str)
               (format t "~a~%" (string-downcase (symbol-name q)))
               )
              (t
               (format t "~8@t~a~%" (string-downcase (symbol-name q)))
               )
              ) ;; end cond
            )
          ) ;; end dolist

        (when (identity verbose)
          (format t "~d symbols~%" count)
          ) ;; end when
        (incf total-count count)
        ) ;; end when
      )   ;; end dotimes
    (when (identity verbose)
      (format t "Total: ~d symbols~%" total-count)
      ) ;; end when
    (values)
    ) ;; end let
  ) ;; end ls

;; 指定されたパッケージの指定されたアクセシビリティのシンボル一覧のリストを返す。
(defun get-symbols (pkg accessibility)
  (cond
    ((eql accessibility 'external)
     (get-external-symbols pkg))
    ((eql accessibility 'internal)
     (get-internal-symbols pkg))
    ((eql accessibility 'inherited)
     (get-inherited-symbols pkg))
    (t (warn "Symbol's accessibility should be :external, :internal, or :inherited.~%"))
    ) ;; end cond
  )

(defun shortest-string (string1 string2)
  "二つの文字列のうち、長さが短い方を返す。"
  (if (< (length string1) (length string2))
      string1
      string2
      ) ;; end if
  ) ;; end shortest-string

(defun find-shortest-string (string-list)
  "リスト内の全ての文字列を比較し、最も短い文字列を返す。"
  ;; リストが空の場合は[nil]を返す
  (when (null string-list)
    (return-from find-shortest-string nil))
  ;; REDUCE がリストの要素を順にshortest-string-reducerに適用する
  (reduce #'shortest-string string-list)
  ) ;; end find-shortest-string

(defun shortest-nickname (pkg)
  "パッケージが複数のニックネームを持つ場合、最も文字数が短いニックネームを返す。"
  (when (null (package-nicknames pkg))
    (return-from shortest-nickname nil)
    )
  (return-from shortest-nickname (find-shortest-string (package-nicknames pkg)))
  ) ;; end shortest-nickname

;; [p],[q] must be string.
;; [p]と[q]の長さを比較して[p]の方が短ければ[t]を返し、そうでなければ[nil]を返す。
;; 長さが同じなら[p]の方が[q]より辞書式順序で前なら[t]を返し、そうでなければ[nil]を返す。
(defun shortest-first-order (p q)
  "2つの文字列を比較して第1引数が第2引数より文字数が短ければ[t]を返し、そうでなければ[nil]を返す。
2つの文字列の長さが同じ場合は第1引数が第2引数より辞書式順序で前ならば[t]を返し、そうでなければ[nil]を返す。"
  (let (len-p len-q)
    (setf len-p (length p))
    (setf len-q (length q))
    (cond
      ((< len-p len-q)
       t)
      ((and
        (= len-p len-q)
        (string< p q))
       t)
      ;;((and ;; 「安定なソート」
      ;;  (= len-p len-q)
      ;;  (string= p q))
      ;; t)
      (t nil)
      ) ;; end cond
    )   ;; end let
  ) ;; end shortest-first-order

(defun sort-nicknames (pkg)
  (when (null (package-nicknames pkg))
    (return-from sort-nicknames nil)
    ) ;; end when
  (sort (copy-seq (package-nicknames pkg)) #'shortest-first-order)
  ) ;; end sort-nicknames

(defun name-case-convert (name-string)
  (package-name-case-convert name-string)
  )

(defun package-name-case-convert (package-name-string)
  "プロンプトに表示するパッケージ名の形式を大文字・小文字・先頭のみ大文字・処理系標準にする。
"
  (let ((package-case nil))
    (setf package-case (get-package-name-case))
    (cond
      ((null package-case)
       package-name-string
       )
      ;; キーワードが[:downcase, :upcase, :capitalize]以外のときは何もしない。
      ((null (member package-case '(:downcase :upcase :capitalize) :test #'equal))
       package-name-string
       )
      ((equal package-case :downcase) ;; [:downcase]なら小文字化して返す。
       (string-downcase package-name-string)
       )
      ((equal package-case :upcase) ;; [:upcase]なら大文字化して返す。
       (string-upcase package-name-string)
       )
      ((equal package-case :capitalize) ;; [:capitalize]なら単語の先頭文字のみ大文字にして返す。
       (string-capitalize package-name-string)
       )
      ) ;; end cond
    )   ;; end let
  ) ;; end package-name-case-convert

(defun package-name-case-list-convert (package-name-string-list)
  (let ((result nil))
    (dolist (p package-name-string-list)
      (push (name-case-convert p) result)
      ) ;; end dolist
    (reverse result)
    ) ;; end let
  ) ;; end package-name-case-list-convert

(defun set-package-name-case (package-case)
  "プロンプト構成指示子のうち

        :current-package
        :original-package-name
        :not-cl-user

のパッケージ名文字列はスペシャル変数

        *package-case*

の設定に従う。それぞれ小文字化、大文字化、キャピタライズを意味する。

        (set-package-name-case :downcase)       ==> 小文字化
        (set-package-name-case :upcase)         ==> 大文字化
        (set-package-name-case :capitalize)     ==> 先頭のみ大文字 
        (set-package-name-case nil)             ==> 処理系の設定通り(通常は大文字)

[nil]なら処理系の返す文字列のまま(通常は大文字)。
"
  (if (member package-case '(:downcase :upcase :capitalize) :test #'equal)
      (setf *package-case* package-case)
      (setf *package-case* nil)
      ) ;; end if
  (return-from set-package-name-case *package-case*)
  ) ;; end set-package-name-case

(defun get-package-name-case ()
  (return-from get-package-name-case *package-case*)
  )

;;
;; シンボルの属性を返す。
;;
(defun symbol-attribute (sym)
  (let ((result nil))
    (if (find-class sym nil) (setf result :class))
    (if (boundp sym) (setf result :variable))
    (if (constantp sym) (setf result :constant))
    (if (find-package sym) (setf result :package))
    (if (fboundp sym) (setf result :function))
    (if (macro-function sym) (setf result :macro)) ;; [:function]かつ[:macro]であれば[:macro]。
    (return-from symbol-attribute result)
    ) ;; end let
  ) ;; end symbol-attribute

(let (
      ;;(last-pkg nil)
      (last-result nil)
      )

  (defun update-symbol-list (pkg)
    (get-external&internal&inherited-symbol-list pkg)
    ) ;; end update-symbol-list

  ;;
  ;; 指定されたパッケージの外部シンボル一覧を文字列化したリストと、その個数を返す。
  ;;
  (defun get-external-symbols (&optional (pkg *package*))
    (update-symbol-list pkg)
    (values (first last-result) (length (first last-result)))
    ;;  ) ;; end let
    )     ;; end get-current-external-symbols

  ;;
  ;; 指定されたパッケージの内部シンボル一覧を文字列化したリストと、その個数を返す。
  ;;
  (defun get-internal-symbols (&optional (pkg *package*))
    (update-symbol-list pkg)
    (values (second last-result) (length (second last-result)))
    ) ;; end get-internal-symbols

  ;;
  ;; [use-package]を介して継承されているシンボル(=内部シンボル)一覧を文字列化したリストと、その個数を返す。
  ;;
  (defun get-inherited-symbols (&optional (pkg *package*))
    (update-symbol-list pkg)
    (values (third last-result) (length (third last-result)))
    ) ;; end get-external-internal-inherited-symbols

  (defun get-external&internal&inherited-symbol-list (&optional (pkg *package*))
    (let ((external-symbols nil)
          (internal-symbols nil)
          (inherited-symbols nil) )
      ;;(setf last-pkg pkg)
      (do-symbols (s (find-package pkg))
        (when (symbol-attribute s)
          (multiple-value-bind (sym status) (find-symbol (symbol-name s) pkg)
            (declare (ignore sym))
            (cond
              ((equal status :external)
               (pushnew s external-symbols))
              ((equal status :internal)
               (pushnew s internal-symbols))
              ((and
                (equal status :inherited)
                (not (equal (symbol-package s) (find-package :common-lisp)))
                )
               (pushnew s inherited-symbols))
              (t nil)
              ) ;; end cond
            )   ;; end multiple-value-bind
          )
        )     ;; end do-symbols
      (setf last-result (list external-symbols internal-symbols inherited-symbols))
      ) ;; end let
    )   ;; end get-external&internal&inherited-symbol-list
  ) ;; end let

;;
;; <package-dependency-data> ::= (<package-data>*) ;
;; <package-data> ::= (<package-name> {nil | (<package-nickname-list>)} {nil | (<package-use-list>)}) ;
;;
(defun package-dependency-list ()
  (let (pkg-nickname-list (result nil) exception-list pkg-str-use-list)

    (set-package-name-case :downcase) ;; パッケージ名文字列を小文字化する。
    (setf exception-list
	  (union (union (package-exclusion-list) (packages-exception-list)) (list "common-lisp-user"))
	  )
    (dolist (pkg (list-all-packages))
      (when (not (member (package-name pkg) exception-list :test #'string-equal))
	(setf pkg-nickname-list (package-name-case-list-convert (sort-nicknames pkg)))
	(setf pkg-str-use-list (package-string-use-list pkg))

	(when (debug-print-p "package-dependency-list")
	  (format t "pkg=~s~%" pkg)
	  (format t "pkg-nickname-list=~s~%" pkg-nickname-list)
	  (format t "pkg-str-use-list=~s~%~%" pkg-str-use-list)
	  )

	(dolist (used-pkg pkg-str-use-list)
	  ;;(format t "used-pkg=~s~%" used-pkg)
	  ;;(finish-output)
	  (push (list
		 (package-name-case-convert (package-name pkg)) ;; [pkg]のパッケージ名文字列。
		 pkg-nickname-list	;; [pkg]のニックネーム文字列のリスト。
		 used-pkg		;; [pkg]がユースしているパッケージ名文字列のリスト。
		 (if used-pkg ;; [pkg]からユースされているパッケージのニックネーム文字列のリスト。
		     (package-name-case-list-convert
		      (sort-nicknames (find-package (string-upcase used-pkg))))
		     nil)
		 )
		result)
	  ) ;; end inner dolist
	)   ;; end dolist
      )	    ;; end when
    ;;(format t "result=~s~%" result)
    (return-from package-dependency-list result)
    ) ;; end let
  ) ;; end package-dependency-list

;; パッケージ依存データからGraphviz(DOT)形式のデータを出力する。
;;  > dot -Tpng 'fname' -o filename.png
;;  > eog filename.png
;; で表示できる。
(defun generate-package-dependency-dot-data
    (pkg-dep-list fname &key (shape :box) (packmode :node) (layout :dot))
  (let (node-shape graph-packmode graph-layout)

    (if (member shape +graphviz-shape+ :test #'equal)
	(setf node-shape (string-downcase (string shape)))
	(progn
	  (warn "generate-package-dependency-dot-data: :shape must be ~s." +graphviz-shape+)
	  (format t "Set shape to \`\:box\`.~%")
	  (setf node-shape "box")
	  )
	)

    (if (member packmode +graphviz-packmode+ :test #'equal)
	(setf graph-packmode (string-downcase (string packmode)))
	(progn
	  (warn "generate-package-dependency-dot-data: :packmode must be ~s." +graphviz-packmode+)
	  (format t "Set packmode to \`\:node\`.~%")
	  (setf graph-packmode "node")
	  )
	)

    (if (member layout +graphviz-layout+ :test #'equal)
	(setf graph-layout (string-downcase (string layout)))
	(progn
	  (warn "generate-package-dependency-dot-data: :layout must be ~s." +graphviz-layout+)
	  (format t "Set layout to \':dot\`.~%")
	  (setf graph-layout "dot")
	  )
	)

    (when (debug-print-p "generate-package-dependency-dot-data")
      (format t "~s~%" pkg-dep-list)
      )

    (with-open-file (stream fname :direction :output :if-does-not-exist :create :if-exists :supersede)
      (format stream "digraph G {~%")
      (format stream "  graph [~%")
      (format stream "    layout = ~a;~%" graph-layout)
      (format stream "    pack = true;~%") ;; グラフ全体を密にパック。
      (format stream (format nil "    packmode = ~s;\~\%" graph-packmode))
      (format stream "  ]~%")
      (format stream (format nil "  node [shape = ~a];\~\%" node-shape))
      (dolist (lst pkg-dep-list)
	;;(format t "lst=~s~%" lst)
	(cond
	  ((and
	    (null (second lst)) ;; パッケージのニックネーム文字列のリスト。
	    (null (fourth lst)) ;; ユースされているパッケージのニックネーム文字列。
	    )
	   (format stream "  \"~a\" -> \"~a\";~%"
		   (third lst) ;; ユースしているパッケージ名文字列のリスト。
		   (first lst) ;; パッケージ名文字列。
		   )
	   )
	  ((and
	    (second lst) ;; パッケージのニックネーム文字列のリスト。
	    (null (fourth lst)) ;; ユースされているパッケージのニックネーム文字列。
	    )
	   (format stream "  \"~a\" -> \"~a (~{~a~^,~})\";~%"
		   (third lst) ;; ユースしているパッケージ名文字列のリスト。
		   (first lst) ;; パッケージ名文字列。
		   (second lst) ;; ニックネーム文字列のリスト。
		   )
	   )
	  ((and
	    (null (second lst)) ;; パッケージのニックネーム文字列のリスト。
	    (fourth lst) ;; ユースされているパッケージのニックネーム文字列。
	    )
	   (format stream "  \"~a (~{~a~^,~})\" -> \"~a\";~%"
		   (third lst) ;; ユースしているパッケージ名文字列のリスト。
		   (fourth lst) ;; ユースされているパッケージのニックネーム文字列。
		   (first lst)	;; パッケージ名文字列。
		   )
	   )
	  ((and
	    (second lst) ;; パッケージのニックネーム文字列のリスト。
	    (fourth lst) ;; ユースされているパッケージのニックネーム文字列。
	    )
	   (format stream "  \"~a (~{~a~^,~})\" -> \"~a (~{~a~^,~})\";~%"
		   (third lst) ;; ユースしているパッケージ名文字列のリスト。
		   (fourth lst) ;; ユースされているパッケージのニックネーム文字列。
		   (first lst)	;; パッケージ名文字列。
		   (second lst) ;; ニックネーム文字列のリスト。
		   )
	   )
	  (t
	   (error "generate-package-dependency-dot-data: can not happen.")
	   )
	  ) ;; end cond
	)   ;; end dolist
      (format stream "}~%")
      ) ;; end with-open-file
    (return-from generate-package-dependency-dot-data fname)
    ) ;; end let
  ) ;; end generatte-package-dependency-dot-data

(defun date-string ()
  (let (tmp)
    (setf tmp (multiple-value-list (get-decoded-time)))
    (format nil "~4d~2,'0d~2,'0d" (sixth tmp) (fifth tmp) (fourth tmp))
    )
  )

(defun time-string ()
  (let (tmp)
    (setf tmp (multiple-value-list (get-decoded-time)))
    (format nil "~2,'0d~2,'0d~2,'0d" (third tmp) (second tmp) (truncate (first tmp)))
    )
  )

(defun viewer (format)
  (if (equal format :pdf)
      #+(or linux unix) "evince"
      #+darwin "open -W -a Preview"
      #+windows "msedge"

      #+(or linux unix) "eog"
      #+darwin "open -W -a Preview"
      #+windows "mspaint" ;; または "powershell -command ..." 等
      )			  ;; end if
  )

;;
;; 除外パッケージ以外のユース情報を作成して描画する。
;;
(defun view-package-dependency-graph (&key (delete-working-files nil) (verbose t) (shape :box)
					(packmode :node) (outfile-format :pdf) (layout :dot))
  (let (fname (exist-dot-command-p nil) (exist-viewer-command-p nil) out-file-name dot-file-name out-ext)

    (setf exist-dot-command-p (absolute-path "dot" :exec-p t)) ;; dotコマンドが存在して実行可能か？
    ;;(when (eql outfile-format :pdf)
    ;;  (setf viewer "evince")
    ;;  )
    (setf exist-viewer-command-p (absolute-path (viewer outfile-format) :exec-p t)) ;; ビューワ・コマンドは？

    (when (not (and exist-dot-command-p exist-viewer-command-p))
      (when (not exist-dot-command-p)
	(warn "Please install Graphviz.~%")
	(format t "Bash~%")
	#+linux (format t "~1,8tsudo apt update~%")
	#+linux (format t "~1,8tsudo apt install graphviz~%")
	) ;; end inner when
      (when (not exist-viewer-command-p)
	(warn "Please install ~a.~%" (viewer outfile-format))
	(format t "Bash~%")
	#+linux (format t "~1,8tsudo apt update~%")
	#+linux (format t "~1,8tsudo apt install ~a~%" (viewer outfile-format))
	)
      (return-from view-package-dependency-graph nil)
      )

    (setf fname (format nil "~a~aT~a"
			*package-dependency-graph-fname-prefix*
			;;(iso-date-string)
			;;(iso-time-string) ;; 文字列中に[":"]が含まれているとxdg-openは誤動作する。
			(date-string)
			(time-string)
			)
	  )

    (when (not (member outfile-format +graphviz-format+ :test #'equal))
      (error "do not support such format ~a~%" outfile-format)
      )

    (setf dot-file-name (concatenate 'string fname ".dot"))
    ;;(setf out-file-name (concatenate 'string fname ".png"))
    (setf out-ext (string-downcase (string outfile-format)))
    (setf out-file-name (concatenate 'string fname "." out-ext))

    (when (debug-print-p "view-package-dependency-graph")
      (format t "fname=~s~%" fname)
      (format t "dot-file-name=~s~%" dot-file-name)
      (format t "out-file-name=~s~%" out-file-name)
      )

    (generate-package-dependency-dot-data
     (package-dependency-list)
     dot-file-name
     :shape shape
     :packmode packmode
     :layout layout
     )

    ;;(exec-command "dot" "-Tpng" dot-file-name "-o" out-file-name)
    (exec-command "dot" (concatenate 'string "-T" out-ext)
		  dot-file-name "-o" out-file-name)
    (when verbose
      ;;(format t "\;\; dot -Tpng ~a -o ~a~%" dot-file-name out-file-name)
      (format t "\;\; dot -T~a ~a -o ~a~%" out-ext dot-file-name out-file-name)
      (format t "\;\; ~a ~a~%" (viewer outfile-format) out-file-name)
      ) ;; end when

    (if delete-working-files
        ;; 削除フラグが t の場合：
        (let ((shell-cmd (format nil "~a ~a 2>/dev/null && rm ~a ~a"
                                 (viewer outfile-format) out-file-name dot-file-name out-file-name)))
          (exec-command "sh" "-c" (format nil "~a &" shell-cmd)))
        
        ;; 削除フラグが nil の場合：
        (exec-command "sh" "-c" (format nil "~a ~a 2>/dev/null &" (viewer outfile-format) out-file-name)))

    ;; if文の外側で verbose フラグをチェックする
    (when (and delete-working-files verbose)
      (format t "dot file [~a]~% and~%viewer file [~a]~% will be deleted after closing the viewer.~%" 
              dot-file-name out-file-name)
      (finish-output)
      ) ;; end when
    (values)
    ) ;; end let
  ) ;; end view-package-dependency-graph

;;
;; 除外指定以外のパッケージ間のユース関係をGraphvizで描画する関数。
;;	:delete-working-files	生成されるdotファイルとpngファイルを描画終了後に削除する。
;;				ファイル名は実行時の日付と時刻を元に自動的に生成する。
;;	:verbose		実行するdotコマンドとビューワ・コマンドをコメントとして表示する。
;;	:shape			Graphvizが描画するノードの形状を指定する。
;;				  :box :oval :ellipse :egg :triangle :diamond :trapezoid :hexgon :octagon
;;	:packmode		Graphvizの描画モードを指定する。
;;				  :node :column :cluster
;;
(defun view-pkg-dep (&key  (outfile-format :pdf) (delete-working-files t) (verbose t)
		       (shape :note) (packmode :node) (layout :dot))
  (view-package-dependency-graph
   :delete-working-files delete-working-files
   :verbose verbose
   :shape shape
   :packmode packmode
   :outfile-format outfile-format
   :layout layout
   )
  )

#+ :build-as-packages (provide :package-util)
