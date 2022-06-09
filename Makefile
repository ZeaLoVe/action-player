ENV ?= demo
TARGET_DIR ?= $(CURDIR)/target
SCRIPTS_DIR ?= $(CURDIR)/scripts

setup:
   bash ${SCRIPTS_DIR}/setup.sh

build:
   bash ${SCRIPTS_DIR}/build.sh

run:
   bash .${SCRIPTS_DIR}/run.sh
