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

# For quick testing only - for actual Dockerfile builds see https://hub.docker.com/r/harisekhon/alpine-github
.PHONY: docker-alpine
docker-alpine:
	./docker_mount_build_exec.sh alpine

# For quick testing only - for actual Dockerfile builds see https://hub.docker.com/r/harisekhon/debian-github
.PHONY: docker-debian
docker-debian:
	./docker_mount_build_exec.sh debian

# For quick testing only - for actual Dockerfile builds see https://hub.docker.com/r/harisekhon/centos-github
.PHONY: docker-centos
docker-centos:
	./docker_mount_build_exec.sh centos

# For quick testing only - for actual Dockerfile builds see https://hub.docker.com/r/harisekhon/ubuntu-github
.PHONY: docker-ubuntu
docker-ubuntu:
	./docker_mount_build_exec.sh ubuntu
