#
# make lisp=sbcl
# make lisp=clisp
# make lisp=gcl
#
# make source-dir=~/Lisp/xxx

lisp ?= sbcl
source-dir ?= ~/Lisp/line-edit

ifeq ($(lisp),sbcl)
	obj = fasl
	options = --noinform --load
else ifeq ($(lisp),clisp)
	obj = fas
	options = --quiet -ansi
else ifeq ($(lisp),gcl)
	obj = o
	options = -batch -eval '(setq si::*break-enable* nil)' \
	                 -eval '(defun si::universal-error-handler (&rest args) (si::bye 1))' \
	                 -eval '(unless (fboundp (quote cl:defpackage)) (load "ansi-lib" :if-does-not-exist nil))' \
	                 -eval '(use-package :cl)' -load
endif

compile-command = $(lisp) $(options)

# .PHONY: install
# install:
# 	@chmod +x setup.sh
# 	@./setup.sh

# 必要なファイルのコンパイルを行って実行可能モジュールを作る。

all : $(source-dir)/history-repl.$(obj) \
	$(source-dir)/package-util.$(obj) \
	$(source-dir)/support-functions.$(obj)

# 削除対象を確認するためのテスト用（削除はしない）
check-clean :
ifeq ($(lisp),sbcl)
	find $(source-dir) \( -name "*.$(obj)" -o -name "*.lib" \) -type f
else
	find $(source-dir) -name "*.$(obj)" -type f
endif

# オブジェクト・ファイルの削除
clean :
ifeq ($(lisp,sbcl)
	find $(source-dir) \( -name "*.$(obj)" -o -name "*.lib" \) -type f -delete
else
	find $(source-dir) -name "*.$(obj)" -type f -delete
endif

$(source-dir)/support-functions.$(obj) : \
			$(source-dir)/support-functions.lisp
	$(lisp) $(options) $(source-dir)/compile-support-functions.lisp

$(source-dir)/package-util.$(obj) : \
			$(source-dir)/package-util.lisp \
			$(source-dir)/support-functions.$(obj)
	$(lisp) $(options) $(source-dir)/compile-package-util.lisp

$(source-dir)/print-color-string.$(obj) : \
			$(source-dir)/print-color-string.lisp \
			$(source-dir)/support-functions.$(obj)
	$(lisp) $(options) $(source-dir)/compile-print-color-string.lisp

$(source-dir)/history-pkg.$(obj) : \
			$(source-dir)/history-pkg.lisp \
			$(source-dir)/print-color-string.$(obj) \
			$(source-dir)/support-functions.$(obj)
	$(lisp) $(options) $(source-dir)/compile-history-pkg.lisp

$(source-dir)/line-edit-pkg.$(obj) : \
			$(source-dir)/line-edit-pkg.lisp \
			$(source-dir)/history-pkg.$(obj) \
			$(source-dir)/support-functions.$(obj)
	$(lisp) $(options) $(source-dir)/compile-line-edit-pkg.lisp

$(source-dir)/history-repl.$(obj) : \
			$(source-dir)/history-repl.lisp \
			$(source-dir)/package-util.$(obj) \
			$(source-dir)/print-color-string.$(obj) \
			$(source-dir)/history-pkg.$(obj) \
			$(source-dir)/line-edit-pkg.$(obj) \
			$(source-dir)/support-functions.$(obj)
	$(lisp) $(options) $(source-dir)/compile-history-repl.lisp

# パスとタイムスタンプを確認するためのデバッグ用ターゲット
# check-path:
# 	@echo "--- Path Debug ---"
# 	@echo "HOME: $(HOME)"
# 	@echo "SOURCE-DIR: $(source-dir)"
# 	@echo "Target Path: $(source-dir)/external-command/external-command.$(obj)"
# 	@echo "--- File Existence and Timestamp ---"
# 	ls -l $(source-dir)/external-command/external-command.lisp
# 	ls -l $(source-dir)/external-command/external-command.$(obj)
