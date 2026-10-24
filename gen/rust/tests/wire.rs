//! Mesmos vetores que `contract/wire_test.go` confere com o código Go gerado.

use falaai_proto::falaai::v1::{Deliver, Envelope, EnvelopeType, Frame, Send, frame::Payload};
use prost::Message as _;

fn envelope() -> Envelope {
    Envelope {
        r#type: EnvelopeType::Message.into(),
        client_message_id: vec![0x02; 16],
        content: b"ciphertext".to_vec(),
    }
}

fn vector(name: &str) -> Vec<u8> {
    let path = format!(
        "{}/../../testdata/wire/{name}.hex",
        env!("CARGO_MANIFEST_DIR")
    );
    let hex = std::fs::read_to_string(&path).unwrap_or_else(|e| panic!("{path}: {e}"));
    let hex = hex.trim();
    (0..hex.len())
        .step_by(2)
        .map(|i| u8::from_str_radix(&hex[i..i + 2], 16).unwrap())
        .collect()
}

fn check(name: &str, frame: &Frame) {
    let want = vector(name);
    assert_eq!(frame.encode_to_vec(), want, "{name}: encode");
    assert_eq!(
        &Frame::decode(want.as_slice()).unwrap(),
        frame,
        "{name}: decode"
    );
}

#[test]
fn frame_send() {
    check(
        "frame_send",
        &Frame {
            payload: Some(Payload::Send(Send {
                destination_aci: vec![0x01; 16],
                destination_device_id: 2,
                envelope: Some(envelope()),
                unidentified_access_key: vec![0x03; 16],
            })),
        },
    );
}

#[test]
fn frame_deliver() {
    check(
        "frame_deliver",
        &Frame {
            payload: Some(Payload::Deliver(Deliver {
                seq: 7,
                server_timestamp: 1_767_225_600_000,
                envelope: Some(envelope()),
            })),
        },
    );
}
