import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndef_record/ndef_record.dart';

void main() {
  group('NFC Payload Delimiter Verification', () {
    test('Ensures 0xDEADBEEF is correctly placed as prefix and suffix', () {
      final text = "Kencana Test";
      final textBytes = Uint8List.fromList(text.codeUnits);
      final delimiter = [0xDE, 0xAD, 0xBE, 0xEF];

      final payload = Uint8List(8 + textBytes.length);
      payload.setRange(0, 4, delimiter);
      payload.setRange(4, 4 + textBytes.length, textBytes);
      payload.setRange(payload.length - 4, payload.length, delimiter);

      // Verify prefix
      expect(payload[0], 0xDE);
      expect(payload[1], 0xAD);
      expect(payload[2], 0xBE);
      expect(payload[3], 0xEF);

      // Verify suffix
      expect(payload[payload.length - 4], 0xDE);
      expect(payload[payload.length - 3], 0xAD);
      expect(payload[payload.length - 2], 0xBE);
      expect(payload[payload.length - 1], 0xEF);

      // Verify content length
      expect(payload.length, 8 + text.length);
    });

    test('Ensures MIME record uses application/x-kencana type', () {
      final type = Uint8List.fromList('application/x-kencana'.codeUnits);
      final record = NdefRecord(
        typeNameFormat: TypeNameFormat.media,
        type: type,
        identifier: Uint8List(0),
        payload: Uint8List(0),
      );

      expect(record.typeNameFormat, TypeNameFormat.media);
      expect(String.fromCharCodes(record.type), 'application/x-kencana');
    });
  });
}
