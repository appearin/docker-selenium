NAME := $(or $(NAME),$(NAME),selenium)
VERSION := $(or $(VERSION),$(VERSION),3.141.59)
NAMESPACE := $(or $(NAMESPACE),$(NAMESPACE),$(NAME))
AUTHORS := appearin
PLATFORM := $(shell uname -s)
BUILD_ARGS := $(BUILD_ARGS)
MAJOR := $(word 1,$(subst ., ,$(VERSION)))
MINOR := $(word 2,$(subst ., ,$(VERSION)))
MAJOR_MINOR_PATCH := $(word 1,$(subst -, ,$(VERSION)))

SHELL=/bin/bash

all: generate_all_custom

generate_all_custom: custom_chrome_save_cache custom_firefox_save_cache

generate_all:	\
	generate_hub \
	generate_nodebase \
	generate_chrome \
	generate_firefox \
	generate_chrome_debug \
	generate_firefox_debug \
	generate_standalone_firefox \
	generate_standalone_chrome \
	generate_standalone_firefox_debug \
	generate_standalone_chrome_debug

build: all

ci: build test

base:
	cd ./Base && docker build $(BUILD_ARGS) -t $(NAME)/base:$(VERSION) .

generate_hub:
	cd ./Hub && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

hub: base generate_hub
	cd ./Hub && docker build $(BUILD_ARGS) -t $(NAME)/hub:$(VERSION) .

generate_nodebase:
	cd ./NodeBase && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

nodebase: base generate_nodebase
	cd ./NodeBase && docker build $(BUILD_ARGS) -t $(NAME)/node-base:$(VERSION) .

generate_chrome:
	cd ./NodeChrome && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

chrome: nodebase generate_chrome
	cd ./NodeChrome && docker build $(BUILD_ARGS) -t $(NAME)/node-chrome:$(VERSION) .

generate_firefox:
	cd ./NodeFirefox && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

firefox: nodebase generate_firefox
	cd ./NodeFirefox && docker build $(BUILD_ARGS) -t $(NAME)/node-firefox:$(VERSION) .

generate_standalone_firefox:
	cd ./Standalone && ./generate.sh StandaloneFirefox node-firefox Firefox $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_firefox: firefox generate_standalone_firefox
	cd ./StandaloneFirefox && docker build $(BUILD_ARGS) -t $(NAME)/standalone-firefox:$(VERSION) .

generate_standalone_firefox_debug:
	cd ./StandaloneDebug && ./generate.sh StandaloneFirefoxDebug node-firefox-debug Firefox $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_firefox_debug: firefox_debug generate_standalone_firefox_debug
	cd ./StandaloneFirefoxDebug && docker build $(BUILD_ARGS) -t $(NAME)/standalone-firefox-debug:$(VERSION) .

generate_standalone_chrome:
	cd ./Standalone && ./generate.sh StandaloneChrome node-chrome Chrome $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_chrome: chrome generate_standalone_chrome
	cd ./StandaloneChrome && docker build $(BUILD_ARGS) -t $(NAME)/standalone-chrome:$(VERSION) .

generate_standalone_chrome_debug:
	cd ./StandaloneDebug && ./generate.sh StandaloneChromeDebug node-chrome-debug Chrome $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_chrome_debug: chrome_debug generate_standalone_chrome_debug
	cd ./StandaloneChromeDebug && docker build $(BUILD_ARGS) -t $(NAME)/standalone-chrome-debug:$(VERSION) .

generate_chrome_debug:
	cd ./NodeDebug && ./generate.sh NodeChromeDebug node-chrome Chrome $(VERSION) $(NAMESPACE) $(AUTHORS)

chrome_debug: generate_chrome_debug chrome
	cd ./NodeChromeDebug && docker build $(BUILD_ARGS) -t $(NAME)/node-chrome-debug:$(VERSION) .

generate_firefox_debug:
	cd ./NodeDebug && ./generate.sh NodeFirefoxDebug node-firefox Firefox $(VERSION) $(NAMESPACE) $(AUTHORS)

firefox_debug: generate_firefox_debug firefox
	cd ./NodeFirefoxDebug && docker build $(BUILD_ARGS) -t $(NAME)/node-firefox-debug:$(VERSION) .

# appear.in custom versions
custom_generate_chrome_%_debug:
	cd ./NodeDebug && ./generate.sh NodeChromeDebug selenium-node-chrome-$* Chrome $(VERSION) $(AUTHORS) $(AUTHORS)

custom_chrome_%_debug: custom_generate_chrome_%_debug custom_chrome
	cd ./NodeChromeDebug && docker build $(BUILD_ARGS) -t $(AUTHORS)/selenium-node-chrome-$*-debug:$(VERSION) .

custom_generate_firefox_%_debug:
	cd ./NodeDebug && ./generate.sh NodeFirefoxDebug selenium-node-firefox-$* Firefox $(VERSION) $(AUTHORS) $(AUTHORS)

custom_firefox_%_debug: custom_generate_firefox_%_debug custom_firefox
	cd ./NodeFirefoxDebug && docker build $(BUILD_ARGS) -t $(AUTHORS)/selenium-node-firefox-$*-debug:$(VERSION) .

custom_chrome_debug: custom_chrome_stable_debug custom_chrome_beta_debug custom_chrome_unstable_debug

custom_firefox_debug: custom_firefox_stable_debug custom_firefox_beta_debug custom_firefox_nightly_debug custom_firefox_esr_debug

custom_chrome: custom_chrome_load_cache
	(cd ./NodeChrome && \
	for ver in chrome-{stable,beta,unstable}; do \
	  curl --head https://dl.google.com/linux/direct/google-$${ver}_current_amd64.deb 2>/dev/null | tr A-Z a-z | grep ^etag: > google-$${ver}.etag; \
	  docker build --build-arg BASE=selenium/node-base:$(VERSION) -f Dockerfile-appearin \
	    --target google-$${ver} -t $(AUTHORS)/selenium-node-$${ver}:$(VERSION) $(BUILD_ARGS) . ;\
	done)

custom_firefox: custom_firefox_load_cache
	(cd ./NodeFirefox && \
	for ver in firefox-{stable,beta,nightly,esr}; do \
	  curl -L --head "https://download.mozilla.org/?product=$${ver/-stable/}-latest-ssl&os=linux64&lang=en-US" 2>/dev/null | tr A-Z a-z | grep ^etag: > $${ver}.etag; \
	  docker build --build-arg BASE=selenium/node-base:$(VERSION) -f Dockerfile-appearin \
	    --target $${ver} -t $(AUTHORS)/selenium-node-$${ver}:$(VERSION) $(BUILD_ARGS) . ;\
	done)

custom_chrome_save_cache: custom_chrome custom_chrome_debug
	./save-cache.sh $(AUTHORS) $(VERSION) chrome chrome-{stable,beta,unstable}{,-debug}

custom_firefox_save_cache: custom_firefox custom_firefox_debug
	./save-cache.sh $(AUTHORS) $(VERSION) firefox firefox-{stable,beta,nightly,esr}{,-debug}

custom_%_load_cache:
	./load-cache.sh $*

release_custom: generate_all_custom
	docker push $(AUTHORS)/selenium-node-chrome-stable:$(VERSION)
	docker push $(AUTHORS)/selenium-node-chrome-stable-debug:$(VERSION)
	docker push $(AUTHORS)/selenium-node-chrome-beta:$(VERSION)
	docker push $(AUTHORS)/selenium-node-chrome-beta-debug:$(VERSION)
	docker push $(AUTHORS)/selenium-node-chrome-unstable:$(VERSION)
	docker push $(AUTHORS)/selenium-node-chrome-unstable-debug:$(VERSION)
	docker push $(AUTHORS)/selenium-node-firefox-stable:$(VERSION)
	docker push $(AUTHORS)/selenium-node-firefox-stable-debug:$(VERSION)
	docker push $(AUTHORS)/selenium-node-firefox-beta:$(VERSION)
	docker push $(AUTHORS)/selenium-node-firefox-beta-debug:$(VERSION)
	docker push $(AUTHORS)/selenium-node-firefox-nightly:$(VERSION)
	docker push $(AUTHORS)/selenium-node-firefox-nightly-debug:$(VERSION)
	docker push $(AUTHORS)/selenium-node-firefox-esr:$(VERSION)
	docker push $(AUTHORS)/selenium-node-firefox-esr-debug:$(VERSION)

tag_latest:
	docker tag $(NAME)/base:$(VERSION) $(NAME)/base:latest
	docker tag $(NAME)/hub:$(VERSION) $(NAME)/hub:latest
	docker tag $(NAME)/node-base:$(VERSION) $(NAME)/node-base:latest
	docker tag $(NAME)/node-chrome:$(VERSION) $(NAME)/node-chrome:latest
	docker tag $(NAME)/node-firefox:$(VERSION) $(NAME)/node-firefox:latest
	docker tag $(NAME)/node-chrome-debug:$(VERSION) $(NAME)/node-chrome-debug:latest
	docker tag $(NAME)/node-firefox-debug:$(VERSION) $(NAME)/node-firefox-debug:latest
	docker tag $(NAME)/standalone-chrome:$(VERSION) $(NAME)/standalone-chrome:latest
	docker tag $(NAME)/standalone-firefox:$(VERSION) $(NAME)/standalone-firefox:latest
	docker tag $(NAME)/standalone-chrome-debug:$(VERSION) $(NAME)/standalone-chrome-debug:latest
	docker tag $(NAME)/standalone-firefox-debug:$(VERSION) $(NAME)/standalone-firefox-debug:latest

release_latest:
	docker push $(NAME)/base:latest
	docker push $(NAME)/hub:latest
	docker push $(NAME)/node-base:latest
	docker push $(NAME)/node-chrome:latest
	docker push $(NAME)/node-firefox:latest
	docker push $(NAME)/node-chrome-debug:latest
	docker push $(NAME)/node-firefox-debug:latest
	docker push $(NAME)/standalone-chrome:latest
	docker push $(NAME)/standalone-firefox:latest
	docker push $(NAME)/standalone-chrome-debug:latest
	docker push $(NAME)/standalone-firefox-debug:latest

tag_major_minor:
	docker tag $(NAME)/base:$(VERSION) $(NAME)/base:$(MAJOR)
	docker tag $(NAME)/hub:$(VERSION) $(NAME)/hub:$(MAJOR)
	docker tag $(NAME)/node-base:$(VERSION) $(NAME)/node-base:$(MAJOR)
	docker tag $(NAME)/node-chrome:$(VERSION) $(NAME)/node-chrome:$(MAJOR)
	docker tag $(NAME)/node-firefox:$(VERSION) $(NAME)/node-firefox:$(MAJOR)
	docker tag $(NAME)/node-chrome-debug:$(VERSION) $(NAME)/node-chrome-debug:$(MAJOR)
	docker tag $(NAME)/node-firefox-debug:$(VERSION) $(NAME)/node-firefox-debug:$(MAJOR)
	docker tag $(NAME)/standalone-chrome:$(VERSION) $(NAME)/standalone-chrome:$(MAJOR)
	docker tag $(NAME)/standalone-firefox:$(VERSION) $(NAME)/standalone-firefox:$(MAJOR)
	docker tag $(NAME)/standalone-chrome-debug:$(VERSION) $(NAME)/standalone-chrome-debug:$(MAJOR)
	docker tag $(NAME)/standalone-firefox-debug:$(VERSION) $(NAME)/standalone-firefox-debug:$(MAJOR)
	docker tag $(NAME)/base:$(VERSION) $(NAME)/base:$(MAJOR).$(MINOR)
	docker tag $(NAME)/hub:$(VERSION) $(NAME)/hub:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-base:$(VERSION) $(NAME)/node-base:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-chrome:$(VERSION) $(NAME)/node-chrome:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-firefox:$(VERSION) $(NAME)/node-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-chrome-debug:$(VERSION) $(NAME)/node-chrome-debug:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-firefox-debug:$(VERSION) $(NAME)/node-firefox-debug:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-chrome:$(VERSION) $(NAME)/standalone-chrome:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-firefox:$(VERSION) $(NAME)/standalone-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-chrome-debug:$(VERSION) $(NAME)/standalone-chrome-debug:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-firefox-debug:$(VERSION) $(NAME)/standalone-firefox-debug:$(MAJOR).$(MINOR)
	docker tag $(NAME)/base:$(VERSION) $(NAME)/base:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/hub:$(VERSION) $(NAME)/hub:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-base:$(VERSION) $(NAME)/node-base:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-chrome:$(VERSION) $(NAME)/node-chrome:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-firefox:$(VERSION) $(NAME)/node-firefox:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-chrome-debug:$(VERSION) $(NAME)/node-chrome-debug:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-firefox-debug:$(VERSION) $(NAME)/node-firefox-debug:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-chrome:$(VERSION) $(NAME)/standalone-chrome:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-firefox:$(VERSION) $(NAME)/standalone-firefox:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-chrome-debug:$(VERSION) $(NAME)/standalone-chrome-debug:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-firefox-debug:$(VERSION) $(NAME)/standalone-firefox-debug:$(MAJOR_MINOR_PATCH)

release: tag_major_minor
	@if ! docker images $(NAME)/base | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/base version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/hub | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/hub version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-base | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-base version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-chrome | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-chrome version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-firefox | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-firefox version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-chrome-debug | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-chrome-debug version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/node-firefox-debug | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/node-firefox-debug version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-chrome | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/standalone-chrome version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-firefox | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/standalone-firefox version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-chrome-debug | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/standalone-chrome-debug version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! docker images $(NAME)/standalone-firefox-debug | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME)/standalone-firefox-debug version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(NAME)/base:$(VERSION)
	docker push $(NAME)/hub:$(VERSION)
	docker push $(NAME)/node-base:$(VERSION)
	docker push $(NAME)/node-chrome:$(VERSION)
	docker push $(NAME)/node-firefox:$(VERSION)
	docker push $(NAME)/node-chrome-debug:$(VERSION)
	docker push $(NAME)/node-firefox-debug:$(VERSION)
	docker push $(NAME)/standalone-chrome:$(VERSION)
	docker push $(NAME)/standalone-firefox:$(VERSION)
	docker push $(NAME)/standalone-chrome-debug:$(VERSION)
	docker push $(NAME)/standalone-firefox-debug:$(VERSION)
	docker push $(NAME)/base:$(MAJOR)
	docker push $(NAME)/hub:$(MAJOR)
	docker push $(NAME)/node-base:$(MAJOR)
	docker push $(NAME)/node-chrome:$(MAJOR)
	docker push $(NAME)/node-firefox:$(MAJOR)
	docker push $(NAME)/node-chrome-debug:$(MAJOR)
	docker push $(NAME)/node-firefox-debug:$(MAJOR)
	docker push $(NAME)/standalone-chrome:$(MAJOR)
	docker push $(NAME)/standalone-firefox:$(MAJOR)
	docker push $(NAME)/standalone-chrome-debug:$(MAJOR)
	docker push $(NAME)/standalone-firefox-debug:$(MAJOR)
	docker push $(NAME)/base:$(MAJOR).$(MINOR)
	docker push $(NAME)/hub:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-base:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-chrome:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-firefox:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-chrome-debug:$(MAJOR).$(MINOR)
	docker push $(NAME)/node-firefox-debug:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-chrome:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-firefox:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-chrome-debug:$(MAJOR).$(MINOR)
	docker push $(NAME)/standalone-firefox-debug:$(MAJOR).$(MINOR)
	docker push $(NAME)/base:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/hub:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-base:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-chrome:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-firefox:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-chrome-debug:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/node-firefox-debug:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-chrome:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-firefox:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-chrome-debug:$(MAJOR_MINOR_PATCH)
	docker push $(NAME)/standalone-firefox-debug:$(MAJOR_MINOR_PATCH)

test: test_chrome \
 test_firefox \
 test_chrome_debug \
 test_firefox_debug \
 test_chrome_standalone \
 test_firefox_standalone \
 test_chrome_standalone_debug \
 test_firefox_standalone_debug


test_chrome:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeChrome

test_chrome_debug:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeChromeDebug

test_chrome_standalone:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneChrome

test_chrome_standalone_debug:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneChromeDebug

test_firefox:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeFirefox

test_firefox_debug:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeFirefoxDebug

test_firefox_standalone:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneFirefox

test_firefox_standalone_debug:
	VERSION=$(VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneFirefoxDebug


.PHONY: \
	all \
	base \
	build \
	chrome \
	chrome_debug \
	ci \
	firefox \
	firefox_debug \
	generate_all \
	generate_hub \
	generate_nodebase \
	generate_chrome \
	generate_firefox \
	generate_chrome_debug \
	generate_firefox_debug \
	generate_standalone_chrome \
	generate_standalone_firefox \
	generate_standalone_chrome_debug \
	generate_standalone_firefox_debug \
	hub \
	nodebase \
	release \
	standalone_chrome \
	standalone_firefox \
	standalone_chrome_debug \
	standalone_firefox_debug \
	tag_latest \
	test
