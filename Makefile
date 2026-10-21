# falaai-proto — pipeline de qualidade.
include mk/hooks.mk

BUF_VERSION ?= v1.57.2
GOBIN := $(shell go env GOPATH)/bin
BUF ?= $(shell command -v buf || echo $(GOBIN)/buf)
GITLEAKS ?= $(shell command -v gitleaks || echo $(GOBIN)/gitleaks)
HAS_PROTO := $(shell find proto -name '*.proto' 2>/dev/null | head -1)

.PHONY: tools fmt lint test test-integration security build check check-fast
tools: hooks ## Instala buf e protoc-gen-go pinados e ativa os hooks
	go install github.com/bufbuild/buf/cmd/buf@$(BUF_VERSION)
	go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.10

fmt: ## Formata
	$(BUF) format -w

lint: ## buf format check e buf lint
	@if [ -n "$(HAS_PROTO)" ]; then $(BUF) format --diff --exit-code && $(BUF) lint; else echo "sem .proto ainda"; fi

test: ## Retrocompatibilidade com a main (buf breaking)
	@if [ -n "$(HAS_PROTO)" ] && git rev-parse --verify -q origin/main >/dev/null; then \
	  $(BUF) breaking --against '.git#branch=origin/main'; else echo "buf breaking: sem base para comparar"; fi

test-integration: ## Sem testes de integração neste repo
	@true

security: ## gitleaks
	$(GITLEAKS) git --no-banner --redact .

build: ## Gera código e falha se o código gerado versionado estiver desatualizado
	@if [ -n "$(HAS_PROTO)" ]; then PATH="$(GOBIN):$$PATH" $(BUF) generate && git diff --exit-code -- gen/; else echo "sem .proto ainda"; fi

check-fast: ## pre-commit
	@if [ -n "$(HAS_PROTO)" ]; then $(BUF) format --diff --exit-code && $(BUF) lint; fi
	$(GITLEAKS) git --no-banner --redact --staged .

check: lint test test-integration security build ## pre-push e gate do Refinery
