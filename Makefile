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

.PHONY: build
build:
	echo Nothing to build	

.PHONY: test
test:
	./all.sh

.PHONY: update
update:
	git pull

.PHONY: update-no-recompile
update-no-recompile:
	git pull

.PHONY: clean
clean:
	@echo Nothing to clean

.PHONY: push
push:
	git push
