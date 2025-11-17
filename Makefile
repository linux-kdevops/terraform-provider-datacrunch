export GO111MODULE=on
.PHONY: clean deps fmt generate lint test unit install release

ARCH ?= amd64
OS ?= linux
PROJECT := terraform-provider-datacrunch
PKG := github.com/squat/$(PROJECT)

TAG := $(shell git describe --abbrev=0 --tags HEAD 2>/dev/null)
COMMIT := $(shell git rev-parse HEAD)
VERSION := $(COMMIT)
ifneq ($(TAG),)
    ifeq ($(COMMIT), $(shell git rev-list -n1 $(TAG)))
        VERSION := $(TAG)
    endif
endif
DIRTY := $(shell test -z "$$(git diff --shortstat 2>/dev/null)" || echo -dirty)
VERSION := $(VERSION)$(DIRTY)
LD_FLAGS := -ldflags "-X main.Version=$(VERSION) -extldflags -static"
GO_FILES := $(shell find . -name '*.go')
GO_PKGS := $(shell go list ./...)
SPEAKEASY_FILES := $(shell cat files.gen)
DOCS := $(shell find docs -type f -name '*.md')
ifeq ($(DOCS),)
DOCS := docs/index.md
endif
GENERATED := $(SPEAKEASY_FILES) $(DOCS) files.gen

STATICCHECK_BINARY := go run honnef.co/go/tools/cmd/staticcheck@2023.1.6
SPEAKEASY_BINARY := bin/speakeasy

GO_VERSION ?= 1.21.3
BUILD_IMAGE ?= golang:$(GO_VERSION)-alpine

# Default target - build and install without Speakeasy
.DEFAULT_GOAL := install

fmt:
	@echo $(GO_PKGS)
	gofmt -w -s $(GO_FILES)

lint:
	@echo 'go vet $(GO_PKGS)'
	@vet_res=$$(GO111MODULE=on go vet $(GO_PKGS) 2>&1); if [ -n "$$vet_res" ]; then \
		echo ""; \
		echo "Go vet found issues. Please check the reported issues"; \
		echo "and fix them if necessary before submitting the code for review:"; \
		echo "$$vet_res"; \
		exit 1; \
	fi
	@echo '$(STATICCHECK_BINARY) $(GO_PKGS)'
	@lint_res=$$($(STATICCHECK_BINARY) $(GO_PKGS)); if [ -n "$$lint_res" ]; then \
		echo ""; \
		echo "Staticcheck found style issues. Please check the reported issues"; \
		echo "and fix them if necessary before submitting the code for review:"; \
		echo "$$lint_res"; \
		exit 1; \
	fi
	@echo 'gofmt -d -s $(GO_FILES)'
	@fmt_res=$$(gofmt -d -s $(GO_FILES)); if [ -n "$$fmt_res" ]; then \
		echo ""; \
		echo "Gofmt found style issues. Please check the reported issues"; \
		echo "and fix them if necessary before submitting the code for review:"; \
		echo "$$fmt_res"; \
		exit 1; \
	fi

unit:
	go test --race ./...

test: lint unit

bin-clean:
	rm -rf bin

deps:
	go mod tidy
	go get go@$(GO_VERSION) toolchain@go$(GO_VERSION)

$(SPEAKEASY_BINARY):
	mkdir -p $(@D)
	cd $(@D) && curl https://github.com/speakeasy-api/speakeasy/releases/download/v1.129.1/speakeasy_$(OS)_$(ARCH).zip -L -o speakeasy.zip && unzip -o speakeasy.zip $(@F) && rm speakeasy.zip ; chmod +x $(@F)

datacrunch.yaml: patch.sh
	curl https://stoplight.io/api/v1/projects/datacrunch/datacrunch-public/nodes/public-api.yml | sh patch.sh > $@

$(SPEAKEASY_FILES) files.gen &: datacrunch.yaml $(SPEAKEASY_BINARY)
	$(SPEAKEASY_BINARY) generate sdk --lang terraform --schema $< --out .
	$(MAKE) fmt
	$(MAKE) deps

$(DOCS) &: $(SPEAKEASY_FILES) | files.gen
	go generate
	sed -i 's/datacrunch Provider/DataCrunch Provider/' docs/index.md

generate: $(GENERATED)

# Build provider binary without SDK regeneration (skips Speakeasy dependency)
# Use this for day-to-day development when SDK is already generated
install:
	@echo "Building and installing provider binary to ~/.terraform.d/plugins..."
	@mkdir -p ~/.terraform.d/plugins/registry.terraform.io/linux-kdevops/datacrunch/0.0.3/linux_amd64
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(LD_FLAGS) -o ~/.terraform.d/plugins/registry.terraform.io/linux-kdevops/datacrunch/0.0.3/linux_amd64/terraform-provider-datacrunch .
	@echo "Provider installed successfully"

# Create a new release with GoReleaser
# Usage: make release VERSION=v0.0.4
# or just: make release (will prompt for version)
GPG_FINGERPRINT ?= E4053F8D0E7C4B9A0A20AB27DC553250F8FE7407

release:
	@if [ -z "$(VERSION)" ]; then \
		echo "Current version: $(TAG)"; \
		read -p "Enter new version (e.g., v0.0.4): " new_version; \
		$(MAKE) release VERSION=$$new_version; \
		exit 0; \
	fi
	@echo "Checking git status..."
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "Error: Git working directory is not clean. Commit or stash changes first."; \
		exit 1; \
	fi
	@echo "Creating and pushing git tag $(VERSION)..."
	git tag -a $(VERSION) -m "Release $(VERSION)"
	git push kdevops $(VERSION)
	@echo "Caching GPG passphrase..."
	@echo "test" | gpg --armor --detach-sign --local-user $(GPG_FINGERPRINT) --output /tmp/test.sig 2>&1 || true
	@rm -f /tmp/test.sig
	@echo "Running GoReleaser..."
	GITHUB_TOKEN=$$(gh auth token) goreleaser release --clean
	@echo ""
	@echo "Release $(VERSION) complete!"
	@echo "Check: https://github.com/linux-kdevops/terraform-provider-datacrunch/releases"

-include datacrunch.mk
