# Do the few things we need to do with repo-health-data

.PHONY: clean requirements test upgrade dev.metabase

.DEFAULT_GOAL := test

ARCH := $(shell uname -m)

DOCKER_IMAGE = metabase/metabase:latest
ifeq ($(ARCH),arm64)
    DOCKER_IMAGE = bobblybook/metabase
endif

export DOCKER_IMAGE

clean:
	rm -rf .cache __pycache__

requirements: ## install development environment requirements
	pip install -r requirements/pip-tools.txt
	pip-sync requirements/dev.txt requirements/private.*

# Define PIP_COMPILE_OPTS=-v to get more information during make upgrade.
PIP_COMPILE = pip-compile --rebuild --upgrade $(PIP_COMPILE_OPTS)

COMMON_CONSTRAINTS_TXT=requirements/common_constraints.txt
.PHONY: $(COMMON_CONSTRAINTS_TXT)
$(COMMON_CONSTRAINTS_TXT):
	wget -O "$(@)" https://raw.githubusercontent.com/edx/edx-lint/master/edx_lint/files/common_constraints.txt || touch "$(@)"

upgrade: export CUSTOM_COMPILE_COMMAND=make upgrade
upgrade: $(COMMON_CONSTRAINTS_TXT)
    ## update the requirements/*.txt files with the latest packages satisfying requirements/*.in
	pip install -r requirements/pip-tools.txt
	# Make sure to compile files after any other files they include!
	$(PIP_COMPILE) --allow-unsafe -o requirements/pip.txt requirements/pip.in
	$(PIP_COMPILE) -o requirements/pip-tools.txt requirements/pip-tools.in
	pip install -r requirements/pip.txt
	pip install -r requirements/pip-tools.txt
	$(PIP_COMPILE) -o requirements/base.txt requirements/base.in
	$(PIP_COMPILE) -o requirements/dev.txt requirements/dev.in

test:
	py.test -v

dev.metabase:
	docker-compose up
