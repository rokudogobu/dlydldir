
#  Copyright (c) 2019-2023 rokudogobu
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

DIR_LAUNCHAGENTS      = $(HOME)/Library/LaunchAgents
DIR_EXECUTABLE        = $(libexecdir)/$(IDENTIFIER)

DLYDLDIR_EXECUTABLE   = $(DIR_EXECUTABLE)/$(NAME)
DLYDLDIR_LAUNCHAGENT  = $(DIR_LAUNCHAGENTS)/$(PLIST_DLYDLDIR)

.PHONY: help build install uninstall bootstrap bootout status clean

.DEFAULT_GOAL := help

help: ## Show this help. This is default target.
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[1;4;39m%s\033[0m\n    %s\n\n", $$1, $$2}'

build: $(NAME) $(PLIST_DLYDLDIR) ## Build executable and generate service configuration file.

clean: ## Delete generated files in project directory.
	@-rm $(PLIST_DLYDLDIR) $(NAME)

install: $(DLYDLDIR_EXECUTABLE) $(DLYDLDIR_LAUNCHAGENT) ## Generate and place the files.

bootstrap: ## Bootstrap the service into gui domain of current user.
	@test -f '$(DLYDLDIR_LAUNCHAGENT)' && launchctl bootstrap gui/$(UID)/ $(DLYDLDIR_LAUNCHAGENT)

status: ## Display the last exit status of this service.
	@launchctl list | grep -G '^PID\|$(IDENTIFIER)'

bootout: ## Remove the service from gui domain of current user.
	@-launchctl bootout gui/$(UID)/$(IDENTIFIER)

uninstall: bootout ## Bootout and delete installed files.
	@-rm $(DLYDLDIR_LAUNCHAGENT)
	@-rm -rf "$(DIR_EXECUTABLE)"

#
#
#

$(NAME): *.swift
	@swiftc -O -framework Foundation -o $@ $^

$(DLYDLDIR_EXECUTABLE): $(NAME) $(DIR_EXECUTABLE)
	@cp $^

$(DLYDLDIR_LAUNCHAGENT): $(PLIST_DLYDLDIR) $(DIR_LAUNCHAGENTS) 
	@cp $^

$(PLIST_DLYDLDIR):
	@echo '' | plutil -convert xml1 -o $@ -
	@plutil -insert Label -string '$(IDENTIFIER)' $@
	@plutil -insert ProgramArguments -json '[]' $@
	@plutil -insert ProgramArguments.0 -string '$(DLYDLDIR_EXECUTABLE)' $@
	@plutil -insert RunAtLoad -bool YES $@
	@plutil -insert StartCalendarInterval -json '{"Minute": 0, "Hour": 0}' $@

$(DIR_LAUNCHAGENTS) $(DIR_EXECUTABLE):
	@mkdir -p $@
