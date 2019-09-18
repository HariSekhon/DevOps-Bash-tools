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

REPO := HariSekhon/DevOps-Bash-tools

CODE_FILES := $(shell find . -type f -name '*.sh' -o -name .bashrc | sort)

CONF_FILES := \
    .ansible.cfg \
    .editorconfig \
    .gitconfig \
    .gitignore \
    .my.cnf \
    .toprc \
    .tmux.conf \
    .vimrc \
    .Xmodmap


include Makefile.in

.PHONY: build
build: system-packages
	:

install:
	@setup/setup_bash.sh
	@echo "linking dot files to \$$HOME directory: $$HOME"
	@f=""; [ -n "$$FORCE" ] && f="-f"; \
	for filename in $(CONF_FILES); do \
		test -f "$$HOME/$$filename" || ln -sv $$f "$$PWD/$$filename" ~; \
	done

.PHONY: test
test:
	./all.sh

.PHONY: clean
clean:
	@echo Nothing to clean

.PHONY: showscripts
showscripts:
	@$(MAKE) showfiles | grep -v -e '/kafka_wrappers/' -e '/lib/' -e '\.bash'

.PHONY: wcscripts
wcscripts:
	@$(MAKE) showscripts | xargs wc -l
	@printf "Total Scripts: "
	@$(MAKE) showscripts | wc -l

.PHONY: wcscripts2
wcscripts2:
	@printf "Total Scripts: "
	@$(MAKE) showscripts | wc -l
	@printf "Total line count without # comments: "
	@$(MAKE) showscripts | xargs sed 's/#.*//;/^[[:space:]]*$$/d' | wc -l
