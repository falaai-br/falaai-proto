package contract_test

import (
	"bytes"
	"encoding/hex"
	"os"
	"path/filepath"
	"strings"
	"testing"

	falaaiv1 "github.com/falaai-br/falaai-proto/gen/go/falaai/v1"
	"google.golang.org/protobuf/proto"
)

// Os mesmos vetores são conferidos pelo crate Rust (gen/rust/tests/wire.rs): os dois códigos
// gerados precisam produzir e ler os mesmos bytes.
func TestWireVectors(t *testing.T) {
	envelope := &falaaiv1.Envelope{
		Type:            falaaiv1.EnvelopeType_ENVELOPE_TYPE_MESSAGE,
		ClientMessageId: bytes.Repeat([]byte{0x02}, 16),
		Content:         []byte("ciphertext"),
	}
	cases := map[string]*falaaiv1.Frame{
		"frame_send": {Payload: &falaaiv1.Frame_Send{Send: &falaaiv1.Send{
			DestinationAci:        bytes.Repeat([]byte{0x01}, 16),
			DestinationDeviceId:   2,
			Envelope:              envelope,
			UnidentifiedAccessKey: bytes.Repeat([]byte{0x03}, 16),
		}}},
		"frame_deliver": {Payload: &falaaiv1.Frame_Deliver{Deliver: &falaaiv1.Deliver{
			Seq:             7,
			ServerTimestamp: 1_767_225_600_000,
			Envelope:        envelope,
		}}},
	}
	for name, frame := range cases {
		t.Run(name, func(t *testing.T) {
			raw, err := os.ReadFile(filepath.Join("..", "testdata", "wire", name+".hex"))
			if err != nil {
				t.Fatal(err)
			}
			want, err := hex.DecodeString(strings.TrimSpace(string(raw)))
			if err != nil {
				t.Fatal(err)
			}
			got, err := proto.MarshalOptions{Deterministic: true}.Marshal(frame)
			if err != nil {
				t.Fatal(err)
			}
			if !bytes.Equal(got, want) {
				t.Errorf("Marshal = %x, esperado %x", got, want)
			}
			var decoded falaaiv1.Frame
			if err := proto.Unmarshal(want, &decoded); err != nil {
				t.Fatal(err)
			}
			if !proto.Equal(&decoded, frame) {
				t.Errorf("Unmarshal = %v, esperado %v", &decoded, frame)
			}
		})
	}
}
