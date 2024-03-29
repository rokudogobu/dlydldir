
#  Copyright (c) 2019-2021 rokudogobu
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#  http://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

prefix               ?= $(HOME)/.local
exec_prefix          ?= $(prefix)
libexecdir           ?= $(exec_prefix)/libexec

#

NAME                  = dlydldir
IDENTIFIER            = io.github.rokudogobu.$(NAME)

UID                  := $(shell id -u)

PLIST_DLYDLDIR        = $(IDENTIFIER).plist

DIR_WORKING           = $(HOME)/Downloads
DIR_LAUNCHAGENTS      = $(HOME)/Library/LaunchAgents
DIR_EXECUTABLE        = $(libexecdir)/$(IDENTIFIER)

DLYDLDIR_EXECUTABLE   = $(DIR_EXECUTABLE)/$(NAME)
DLYDLDIR_LAUNCHAGENT  = $(DIR_LAUNCHAGENTS)/$(PLIST_DLYDLDIR)

OS_VER               := $(shell sw_vers -productVersion | awk -F. '{printf "%2d%02d%02d",$$1,$$2,$$3}')
OS_GE_MAVERICKS      := $(shell if test $(OS_VER) -ge 101400; then echo true; fi)
SIP_ENABLED          := $(findstring enabled, $(if $(shell which csrutil), $(shell csrutil status)))

.PHONY: help generate install uninstall bootstrap bootout status clean

.DEFAULT_GOAL := help

help: ## Show this help. This is default target.
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[1;4;39m%s\033[0m\n    %s\n\n", $$1, $$2}'

generate: $(NAME) $(PLIST_DLYDLDIR) ## Build executable and generate service configuration file.

install: generate $(DIR_LAUNCHAGENTS) $(DIR_EXECUTABLE) ## Generate and place the files.
	@cp $(NAME) $(DIR_EXECUTABLE)
	@cp $(PLIST_DLYDLDIR) $(DIR_LAUNCHAGENTS)
	$(if $(and $(SIP_ENABLED),$(OS_GE_MAVERICKS)), $(info *** warning: SIP is enabled. Please make sure '$(DLYDLDIR_EXECUTABLE)' is permitted 'Full Disk Access'. ))

bootstrap: ## Bootstrap service into gui domain of current user.
	@test -f '$(DLYDLDIR_LAUNCHAGENT)' && launchctl bootstrap gui/$(UID)/ $(DLYDLDIR_LAUNCHAGENT)

status: ## Display the last exit status of service.
	@launchctl list | grep -G '^PID\|$(IDENTIFIER)'

bootout: ## Remove service from gui domain of current user.
	@-launchctl bootout gui/$(UID)/$(IDENTIFIER)

uninstall: bootout ## Bootout and delete installed files.
	@-rm $(DLYDLDIR_LAUNCHAGENT) $(DLYDLDIR_EXECUTABLE)
	@-unlink $(DIR_WORKING)/today

clean: ## Delete generated files in project directory.
	@-rm $(PLIST_DLYDLDIR) $(NAME)

#
#
#

$(NAME): *.swift
	@swiftc -O -framework Foundation -o $@ $^

$(PLIST_DLYDLDIR):
	@echo '' | plutil -convert xml1 -o $@ -
	@plutil -insert Label -string '$(IDENTIFIER)' $@
	@plutil -insert ProgramArguments -json '[]' $@
	@plutil -insert ProgramArguments.0 -string '$(DLYDLDIR_EXECUTABLE)' $@
	@plutil -insert RunAtLoad -bool YES $@
	@plutil -insert StartCalendarInterval -json '{"Minute": 0, "Hour": 0}' $@

$(DIR_LAUNCHAGENTS) $(DIR_EXECUTABLE):
	@mkdir -p $@
