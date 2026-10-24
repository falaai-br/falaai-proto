//! Tipos Rust (prost) gerados de `proto/` por `make generate`.
//!
//! Consumir como dependência git pinada por commit:
//! `falaai-proto = { git = "https://github.com/falaai-br/falaai-proto", rev = "<commit>" }`.
//! Só este arquivo é escrito à mão; `src/generated/` sai do `buf generate`.

pub mod falaai {
    pub mod v1 {
        include!("generated/falaai.v1.rs");
    }
}
