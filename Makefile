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

include Makefile.in

.PHONY: build
build: system-packages
	:

.PHONY: test
test:
	./all.sh

.PHONY: clean
clean:
	@echo Nothing to clean

.PHONY: wc
wc:
	wc -l *.sh .bash.d/*.sh
