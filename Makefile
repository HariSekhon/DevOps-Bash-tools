#
#  Author: Hari Sekhon
#  Date: 2016-01-17 12:56:53 +0000 (Sun, 17 Jan 2016)
#
#  vim:ts=4:sts=4:sw=4:noet
#
#  https://github.com/harisekhon/bash-tools
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback
#
#  https://www.linkedin.com/in/harisekhon
#

include Makefile.in

REPO := HariSekhon/DevOps-Bash-tools

CODE_FILES := $(shell find . -type f -name '*.sh' -o -type f -name '.bash*' | sort)

CONF_FILES := \
    .ansible.cfg \
    .editorconfig \
    .gitconfig \
    .gitignore \
    .my.cnf \
    .screenrc \
    .toprc \
    .tmux.conf \
    .vimrc \
    .Xdefaults \
    .Xmodmap

.PHONY: build
build: system-packages aws
	@:

.PHONY: install
install: build bash python aws

.PHONY: uninstall
uninstall: bash-unlink
	@echo "Not removing any system packages for safety"

.PHONY: bash
bash:
	@setup/setup_bash.sh
	@echo "linking dot files to \$$HOME directory: $$HOME"
	@f=""; [ -n "$$FORCE" ] && f="-f"; \
	for filename in $(CONF_FILES); do \
		ln -sv $$f "$$PWD/$$filename" ~ 2>/dev/null; \
	done || :
	@ln -sv $$f ~/.gitignore ~/.gitignore_global 2>/dev/null || :

.PHONY: bash-unlink
bash-unlink:
	@for filename in $(CONF_FILES) .gitignore_global; do \
		if [ -L ~/"$$filename" ]; then \
			rm -fv ~/"$$filename"; \
		fi; \
	done || :
	@echo "Must manually remove sourcing from ~/.bashrc and ~/.bash_profile"

.PHONY: python
python:
	@./python_pip_install_if_absent.sh setup/pip-packages-desktop.txt

.PHONY: aws
aws:
	@./python_pip_install_if_absent.sh awscli

.PHONY: test
test:
	./all.sh

.PHONY: clean
clean:
	@echo Nothing to clean

.PHONY: ls-scripts
ls-scripts:
	@$(MAKE) ls-code | grep -v -e '/kafka_wrappers/' -e '/lib/' -e '\.bash'

.PHONY: lsscripts
lsscripts: ls-scripts
	@:

.PHONY: wc-scripts
wc-scripts:
	@$(MAKE) ls-scripts | xargs wc -l
	@printf "Total Scripts: "
	@$(MAKE) ls-scripts | wc -l

.PHONY: wcscripts
wcscripts: wc-scripts
	@:

.PHONY: wc-scripts2
wc-scripts2:
	@printf "Total Scripts: "
	@$(MAKE) ls-scripts | wc -l
	@printf "Total line count without # comments: "
	@$(MAKE) ls-scripts | xargs sed 's/#.*//;/^[[:space:]]*$$/d' | wc -l

.PHONY: wcscripts2
wcscripts2: wc-scripts2
	@:
