import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_constants.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_signer.dart';

/// Hasil siap tulis ke tag NDEF.
class KencanaNfcBlob {
  const KencanaNfcBlob({
    required this.jsonUtf8,
    required this.blob,
  });

  final Uint8List jsonUtf8;
  final Uint8List blob;

  int get byteLength => blob.length;
}

/// `json + DE AD BE EF + ed25519_sign(json)` — sama dengan `kencana-nfc` main.
class KencanaNfcBlobBuilder {
  const KencanaNfcBlobBuilder();

  Future<KencanaNfcBlob> build({
    required String compactJson,
    required KencanaNfcSigner signer,
  }) async {
    final Uint8List jsonUtf8 = Uint8List.fromList(utf8.encode(compactJson));
    final Uint8List signature = await signer.sign(jsonUtf8);

    final Uint8List blob = Uint8List(
      jsonUtf8.length +
          KencanaNfcConstants.signatureDelimiter.length +
          signature.length,
    );
    var offset = 0;
    blob.setRange(offset, offset + jsonUtf8.length, jsonUtf8);
    offset += jsonUtf8.length;
    blob.setRange(
      offset,
      offset + KencanaNfcConstants.signatureDelimiter.length,
      KencanaNfcConstants.signatureDelimiter,
    );
    offset += KencanaNfcConstants.signatureDelimiter.length;
    blob.setRange(offset, offset + signature.length, signature);

    return KencanaNfcBlob(jsonUtf8: jsonUtf8, blob: blob);
  }
}
