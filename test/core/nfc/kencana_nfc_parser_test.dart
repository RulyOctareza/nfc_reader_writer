import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_blob_builder.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_constants.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_parser.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_signer.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_verifier.dart';

void main() {
  const pem = '''
-----BEGIN PRIVATE KEY-----
MC4CAQAwBQYDK2VwBCIEIHE/ETIbz8Cgn3n6X2Jioz5y237tMV7ROOUiS7gr3Fuo
-----END PRIVATE KEY-----''';

  group('KencanaNfcParser', () {
    test('parses signed blob json + delimiter + signature', () async {
      const json = '{"wb":"12345","name":"Test"}';
      final signer = await KencanaNfcSigner.fromPkcs8Pem(pem);
      final blob = await const KencanaNfcBlobBuilder().build(
        compactJson: json,
        signer: signer,
      );

      final parsed = const KencanaNfcParser().parse(blob.blob);
      expect(parsed.isLegacyFormat, isFalse);
      expect(parsed.jsonText, json);
      expect(parsed.json?['wb'], '12345');
      expect(
        parsed.signature.length,
        KencanaNfcConstants.ed25519SignatureLength,
      );

      final verifier = await KencanaNfcVerifier.fromPkcs8Pem(pem);
      final valid = await verifier.verify(
        message: parsed.jsonUtf8,
        signatureBytes: parsed.signature,
      );
      expect(valid, isTrue);
    });

    test('parses legacy DEADBEEF-wrapped payload', () {
      const text = 'legacy-content';
      final bytes = utf8.encode(text);
      final payload = Uint8List(8 + bytes.length);
      payload.setRange(0, 4, KencanaNfcConstants.signatureDelimiter);
      payload.setRange(4, 4 + bytes.length, bytes);
      payload.setRange(
        payload.length - 4,
        payload.length,
        KencanaNfcConstants.signatureDelimiter,
      );

      final parsed = const KencanaNfcParser().parse(payload);
      expect(parsed.isLegacyFormat, isTrue);
      expect(parsed.jsonText, text);
    });
  });
}
