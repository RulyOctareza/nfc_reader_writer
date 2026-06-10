import 'dart:typed_data';

import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_parser.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_verifier.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_record.dart';

/// Mendekode dan memverifikasi payload MIME Kencana.
class KencanaNfcPayloadDecoder {
  const KencanaNfcPayloadDecoder({KencanaNfcParser? parser})
    : _parser = parser ?? const KencanaNfcParser();

  final KencanaNfcParser _parser;

  Future<NfcKencanaRecord> decode(
    Uint8List payload, {
    KencanaNfcVerifier? verifier,
  }) async {
    final KencanaNfcParsed parsed = _parser.parse(payload);

    bool? signatureValid;
    if (!parsed.isLegacyFormat && verifier != null) {
      signatureValid = await verifier.verify(
        message: parsed.jsonUtf8,
        signatureBytes: parsed.signature,
      );
    }

    return NfcKencanaRecord(
      jsonText: parsed.jsonText,
      json: parsed.json,
      signature: parsed.signature,
      isLegacyFormat: parsed.isLegacyFormat,
      signatureValid: signatureValid,
      rawPayload: payload,
    );
  }
}
