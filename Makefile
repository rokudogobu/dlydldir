
#  Copyright (c) 2019 rokudogobu
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

NAME                = dlydldir
IDENTIFIER          = io.github.rokudogobu.$(NAME)

DIR_WORKING         = $(HOME)/Downloads
DIR_LAUNCHAGENTS    = $(HOME)/Library/LaunchAgents

UID                := $(shell id -u)

LABEL_MKDIR         = $(IDENTIFIER).mkdir
LABEL_DEFAULTS      = $(IDENTIFIER).defaults
LABEL_RMDIR         = $(IDENTIFIER).rmdir

PLIST_MKDIR         = $(DIR_LAUNCHAGENTS)/$(LABEL_MKDIR).plist
PLIST_DEFAULTS      = $(DIR_LAUNCHAGENTS)/$(LABEL_DEFAULTS).plist
PLIST_RMDIR         = $(DIR_LAUNCHAGENTS)/$(LABEL_RMDIR).plist

OS_VER             := $(shell sw_vers -productVersion | awk -F. '{printf "%2d%02d%02d",$$1,$$2,$$3}')
OS_GE_MAVERICKS    := $(shell if test $(OS_VER) -ge 101400; then echo true; fi)
SIP_ENABLED        := $(findstring enabled, $(if $(shell which csrutil), $(shell csrutil status)))

.PHONY: help install uninstall bootstrap bootout list

.DEFAULT_GOAL := help

help: ## Show this help. This is default target.
	@echo
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[1;4;39m%s\033[0m\n    %s\n\n", $$1, $$2}'

install: $(PLIST_MKDIR) $(PLIST_DEFAULTS) $(PLIST_RMDIR) ## Generate service configuration files.
	$(if $(and $(SIP_ENABLED),$(OS_GE_MAVERICKS)), $(info *** warning: SIP is enabled. Please make sure $(shell which defaults) is permitted 'Full Disk Access'. ))

bootstrap: ## Bootstrap services into gui domain of current user.
	@test -f '$(PLIST_MKDIR)'    && launchctl bootstrap gui/$(UID)/ '$(PLIST_MKDIR)'
	@test -f '$(PLIST_DEFAULTS)' && launchctl bootstrap gui/$(UID)/ '$(PLIST_DEFAULTS)'
	@test -f '$(PLIST_RMDIR)'    && launchctl bootstrap gui/$(UID)/ '$(PLIST_RMDIR)'

list: ## Display a list of the last exit status of services.
	@launchctl list | grep -G '^PID\|$(IDENTIFIER)'

bootout: ## Remove services from gui domain of current user.
	@-launchctl bootout gui/$(UID)/$(LABEL_MKDIR)
	@-launchctl bootout gui/$(UID)/$(LABEL_DEFAULTS)
	@-launchctl bootout gui/$(UID)/$(LABEL_RMDIR)

uninstall: bootout ## Delete service configuration files and some related files.
	@-rm '$(PLIST_DEFAULTS)' '$(PLIST_MKDIR)' '$(PLIST_RMDIR)' $(DIR_WORKING)/.$(NAME)
	@-unlink '$(DIR_WORKING)/today'

$(DIR_LAUNCHAGENTS):
	@mkdir '$(DIR_LAUNCHAGENTS)'

$(PLIST_MKDIR): $(DIR_LAUNCHAGENTS)
	@echo '' | plutil -convert xml1 -o $@ -
	@plutil -insert Label -string '$(LABEL_MKDIR)' $@
	@plutil -insert WorkingDirectory -string '$(DIR_WORKING)' $@
	@plutil -insert ProgramArguments -json '[]' $@
	@plutil -insert ProgramArguments.0 -string '$(shell which sh)' $@
	@plutil -insert ProgramArguments.1 -string '-c' $@
	@plutil -insert ProgramArguments.2 -string 'TODAY=$$(date "+%Y-%m-%d") && ( mkdir $$TODAY || test -d $$TODAY ) && ln -fhs $$TODAY today && touch .$(NAME)' $@
	@plutil -insert RunAtLoad -bool YES $@
	@plutil -insert StartCalendarInterval -json '{"Minute": 0, "Hour": 0}' $@

$(PLIST_DEFAULTS): $(DIR_LAUNCHAGENTS)
	@echo '' | plutil -convert xml1 -o $@ -
	@plutil -insert Label -string '$(LABEL_DEFAULTS)' $@
	@plutil -insert WorkingDirectory -string '$(DIR_WORKING)' $@
	@plutil -insert WatchPaths -json '[]' $@
	@plutil -insert WatchPaths.0 -string '$(DIR_WORKING)/.$(NAME)' $@
	@plutil -insert ProgramArguments -json '[]' $@
	@plutil -insert ProgramArguments.0 -string '$(shell which defaults)' $@
	@plutil -insert ProgramArguments.1 -string 'write' $@
	@plutil -insert ProgramArguments.2 -string '-app' $@
	@plutil -insert ProgramArguments.3 -string 'Safari' $@
	@plutil -insert ProgramArguments.4 -string 'DownloadsPath' $@
	@plutil -insert ProgramArguments.5 -string '-string' $@
	@plutil -insert ProgramArguments.6 -string '$(DIR_WORKING)/today' $@

$(PLIST_RMDIR): $(DIR_LAUNCHAGENTS)
	@echo '' | plutil -convert xml1 -o $@ -
	@plutil -insert Label -string '$(LABEL_RMDIR)' $@
	@plutil -insert WorkingDirectory -string '$(DIR_WORKING)' $@
	@plutil -insert WatchPaths -json '[]' $@
	@plutil -insert WatchPaths.0 -string '$(DIR_WORKING)/.$(NAME)' $@
	@plutil -insert ProgramArguments -json '[]' $@
	@plutil -insert ProgramArguments.0 -string '$(shell which find)' $@
	@plutil -insert ProgramArguments.1 -string '.' $@
	@plutil -insert ProgramArguments.2 -string '(' $@
	@plutil -insert ProgramArguments.3 -string '(' $@
	@plutil -insert ProgramArguments.4 -string '-depth' $@
	@plutil -insert ProgramArguments.5 -string '2' $@
	@plutil -insert ProgramArguments.6 -string '-type' $@
	@plutil -insert ProgramArguments.7 -string 'f' $@
	@plutil -insert ProgramArguments.8 -string '-name' $@
	@plutil -insert ProgramArguments.9 -string '.DS_Store' $@
	@plutil -insert ProgramArguments.10 -string ')' $@
	@plutil -insert ProgramArguments.11 -string '-or' $@
	@plutil -insert ProgramArguments.12 -string '(' $@
	@plutil -insert ProgramArguments.13 -string '-depth' $@
	@plutil -insert ProgramArguments.14 -string '1' $@
	@plutil -insert ProgramArguments.15 -string '-type' $@
	@plutil -insert ProgramArguments.16 -string 'd' $@
	@plutil -insert ProgramArguments.17 -string '-empty' $@
	@plutil -insert ProgramArguments.18 -string '-regex' $@
	@plutil -insert ProgramArguments.19 -string './[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}' $@
	@plutil -insert ProgramArguments.20 -string '-not' $@
	@plutil -insert ProgramArguments.21 -string '-samefile' $@
	@plutil -insert ProgramArguments.22 -string 'today' $@
	@plutil -insert ProgramArguments.23 -string ')' $@
	@plutil -insert ProgramArguments.24 -string ')' $@
	@plutil -insert ProgramArguments.25 -string '-delete' $@
