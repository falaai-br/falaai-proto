// Package contract_test verifica regras do contrato que o buf lint não cobre.
package contract_test

import (
	"slices"
	"strings"
	"testing"

	falaaiv1 "github.com/falaai-br/falaai-proto/gen/go/falaai/v1"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protoreflect"
	"google.golang.org/protobuf/reflect/protoregistry"
)

// Mudar estas listas exige revisar se o campo novo identifica o remetente.
var (
	envelopeFields = []string{"type", "client_message_id", "content"}
	// Send trafega no socket não autenticado.
	sendFields = []string{"destination_aci", "destination_device_id", "envelope", "unidentified_access_key"}
)

func TestEnvelopeHasOnlyAllowedFields(t *testing.T) {
	if got := fieldNames(&falaaiv1.Envelope{}); !slices.Equal(got, envelopeFields) {
		t.Errorf("campos de Envelope = %v, esperado %v (sealed sender: nada de remetente em claro)", got, envelopeFields)
	}
}

func TestSendHasOnlyAllowedFields(t *testing.T) {
	if got := fieldNames(&falaaiv1.Send{}); !slices.Equal(got, sendFields) {
		t.Errorf("campos de Send = %v, esperado %v (socket não autenticado: nada que identifique o remetente)", got, sendFields)
	}
}

func fieldNames(m proto.Message) []string {
	fields := m.ProtoReflect().Descriptor().Fields()
	var names []string
	for i := range fields.Len() {
		names = append(names, string(fields.Get(i).Name()))
	}
	return names
}

func TestNoFieldCarriesSender(t *testing.T) {
	forbidden := []string{"sender", "source", "origin"}
	protoregistry.GlobalFiles.RangeFilesByPackage("falaai.v1", func(fd protoreflect.FileDescriptor) bool {
		checkMessages(t, fd.Messages(), forbidden)
		return true
	})
}

func checkMessages(t *testing.T, msgs protoreflect.MessageDescriptors, forbidden []string) {
	t.Helper()
	for i := range msgs.Len() {
		md := msgs.Get(i)
		fields := md.Fields()
		for j := range fields.Len() {
			name := string(fields.Get(j).Name())
			for _, f := range forbidden {
				if strings.Contains(name, f) {
					t.Errorf("%s.%s parece carregar remetente em claro", md.FullName(), name)
				}
			}
		}
		checkMessages(t, md.Messages(), forbidden)
	}
}
