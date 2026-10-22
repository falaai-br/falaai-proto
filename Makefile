# falaai-proto — pipeline de qualidade.
include mk/hooks.mk

BUF_VERSION ?= v1.57.2
PROTOC_GEN_GO_VERSION ?= v1.36.10
GITLEAKS_VERSION ?= v8.28.0
GOBIN := $(shell go env GOPATH)/bin
BUF ?= $(shell command -v buf || echo $(GOBIN)/buf)
GITLEAKS ?= $(shell command -v gitleaks || echo $(GOBIN)/gitleaks)
HAS_PROTO := $(shell find proto -name '*.proto' 2>/dev/null | head -1)
# Base do buf breaking. Sem .proto na base (primeiro contrato), não há o que quebrar.
BREAKING_BASE ?= origin/main

.PHONY: tools fmt generate lint test test-integration security build check check-fast
tools: hooks ## Instala buf, protoc-gen-go e gitleaks pinados e ativa os hooks
	go install github.com/bufbuild/buf/cmd/buf@$(BUF_VERSION)
	go install google.golang.org/protobuf/cmd/protoc-gen-go@$(PROTOC_GEN_GO_VERSION)
	go install github.com/zricethezav/gitleaks/v8@$(GITLEAKS_VERSION)

fmt: ## Formata
	$(BUF) format -w

generate: ## Regera gen/go do zero (remove arquivos de .proto apagados)
	@if [ -n "$(HAS_PROTO)" ]; then rm -rf gen/go && PATH="$(GOBIN):$$PATH" $(BUF) generate; else echo "sem .proto ainda"; fi

lint: ## buf format check e buf lint
	@if [ -n "$(HAS_PROTO)" ]; then $(BUF) format --diff --exit-code && $(BUF) lint; else echo "sem .proto ainda"; fi

test: ## Retrocompatibilidade com a main (buf breaking)
	@if [ -z "$(HAS_PROTO)" ]; then echo "buf breaking: sem .proto ainda"; \
	elif ! git rev-parse --verify -q $(BREAKING_BASE) >/dev/null; then \
	  echo "buf breaking: base $(BREAKING_BASE) não encontrada; rode 'git fetch origin'" >&2; exit 1; \
	elif [ -z "$$(git ls-tree -r --name-only $(BREAKING_BASE) -- proto | grep '\.proto$$')" ]; then \
	  echo "buf breaking: $(BREAKING_BASE) ainda sem .proto, nada a comparar"; \
	else $(BUF) breaking --against '.git#ref=$(BREAKING_BASE)'; fi

test-integration: ## Sem testes de integração neste repo
	@true

security: ## gitleaks
	$(GITLEAKS) git --no-banner --redact .

build: generate ## Gera e compila gen/go; falha se o código gerado versionado estiver desatualizado
	@if [ -n "$(HAS_PROTO)" ]; then \
	  go build ./... && \
	  if [ -n "$$(git status --porcelain -- gen/)" ]; then \
	    git status --short -- gen/ >&2; \
	    echo "gen/ desatualizado: rode 'make generate' e commite gen/" >&2; exit 1; \
	  fi; \
	fi

check-fast: ## pre-commit
	@if [ -n "$(HAS_PROTO)" ]; then $(BUF) format --diff --exit-code && $(BUF) lint; fi
	$(GITLEAKS) git --no-banner --redact --staged .

check: lint test test-integration security build ## pre-push e gate do Refinery
