# Vetores de wire

Bytes esperados de `Frame`s fixos, em hex. O teste Go (`contract/wire_test.go`) e o teste Rust (`gen/rust/tests/wire.rs`) montam as mesmas mensagens e exigem estes bytes, nos dois sentidos (codificar e decodificar). Garante que o código gerado nas duas linguagens fala o mesmo formato.

Não regere a partir da saída de um dos testes: um vetor novo é conferido à mão (tag, tamanho e valor de cada campo).
