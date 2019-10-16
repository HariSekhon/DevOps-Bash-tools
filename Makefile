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

CONF_FILES := $(shell sed "s/\#.*//; /^[[:space:]]*$$/d" setup/files.conf)

.PHONY: *

.PHONY: build
build: system-packages aws
	@:

.PHONY: install
install: build link python aws

.PHONY: uninstall
uninstall: unlink
	@echo "Not removing any system packages for safety"

.PHONY: bash
bash: link
	@:

.PHONY: link
link:
	@setup/shell_link.sh

.PHONY: unlink
unlink:
	@setup/shell_unlink.sh

.PHONY:
ccmenu:
	@setup/setup_ccmenu.sh

.PHONY: desktop
desktop: install
	@if [ -x /sbin/apk ];        then $(MAKE) apk-packages-desktop; fi
	@if [ -x /usr/bin/apt-get ]; then $(MAKE) apt-packages-desktop; fi
	@if [ -x /usr/bin/yum ];     then $(MAKE) yum-packages-desktop; fi
	@if [ -x /usr/local/bin/brew -a `uname` = Darwin ]; then $(MAKE) homebrew-packages-desktop; fi
	@# do these late so that we have the above system packages installed first to take priority and not install from source where we don't need to
	@$(MAKE) perl
	@$(MAKE) golang
	@# no packages any more since jgrep is no longer found
	@#$(MAKE) ruby

.PHONY: apk-packages-desktop
apk-packages-desktop: system-packages
	@echo "Alpine desktop not supported at this time"
	@exit 1

.PHONY: apt-packages-desktop
apt-packages-desktop: system-packages
	NO_FAIL=1 NO_UPDATE=1 $(BASH_TOOLS)/apt-install-packages.sh setup/deb-packages-desktop.txt

.PHONY: yum-packages-desktop
yum-packages-desktop: system-packages
	NO_FAIL=1 NO_UPDATE=1 $(BASH_TOOLS)/yum-install-packages.sh setup/rpm-packages-desktop.txt

.PHONY: homebrew-packages-desktop
homebrew-packages-desktop: system-packages
	NO_FAIL=1 NO_UPDATE=1 $(BASH_TOOLS)/brew-install-packages.sh setup/homebrew-packages-desktop*.txt

.PHONY: perl
perl: system-packages
	NO_FAIL=1 NO_UPDATE=1 $(BASH_TOOLS)/perl_cpanm_install_if_absent.sh setup/cpan-packages-desktop.txt

.PHONY: golang
golang: system-packages
	NO_FAIL=1 $(BASH_TOOLS)/golang_get_install_if_absent.sh setup/go-packages-desktop.txt

.PHONY: ruby
ruby: system-packages
	NO_FAIL=1 $(BASH_TOOLS)/ruby_install_if_absent.sh setup/gem-packages-desktop.txt

.PHONY: python
python: system-packages
	@./python_pip_install_if_absent.sh setup/pip-packages-desktop.txt

.PHONY: aws
aws: system-packages
	@./python_pip_install_if_absent.sh awscli

.PHONY: test
test:
	./all.sh

.PHONY: clean
clean:
	@rm -fv setup/terraform.zip

.PHONY: ls-scripts
ls-scripts:
	@$(MAKE) ls-code | grep -v -e '/kafka_wrappers/' -e '/lib/' -e '\.bash'

.PHONY: lsscripts
lsscripts: ls-scripts
	@:

.PHONY: wc-scripts
wc-scripts:
	@$(MAKE) ls-scripts | xargs wc -l
	@printf "Total Script files: "
	@$(MAKE) ls-scripts | wc -l

.PHONY: wcscripts
wcscripts: wc-scripts
	@:

.PHONY: wc-scripts2
wc-scripts2:
	@printf "Total Scripts files: "
	@$(MAKE) ls-scripts | wc -l
	@printf "Total line count without # comments: "
	@$(MAKE) ls-scripts | xargs sed 's/#.*//;/^[[:space:]]*$$/d' | wc -l

.PHONY: wcscripts2
wcscripts2: wc-scripts2
	@:
