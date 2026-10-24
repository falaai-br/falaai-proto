# falaai-proto

Contratos em Protocol Buffers entre o app e o servidor do **FalaAí**: envelopes, mensagens do WebSocket, ACKs e bundles de chaves públicas. Público para que qualquer pessoa possa auditar o que trafega.

## Uso

- Go: `github.com/falaai-br/falaai-proto/gen/go/falaai/v1`.
- Rust: crate `falaai-proto` em `gen/rust`, tipos em `falaai_proto::falaai::v1`. Dependência git pinada por commit:

  ```toml
  falaai-proto = { git = "https://github.com/falaai-br/falaai-proto", rev = "<commit>" }
  ```

O código gerado é versionado; `make generate` o refaz e `make build` falha se estiver desatualizado.

## Licença

Apache-2.0. Ver [LICENSE](LICENSE).
