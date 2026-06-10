import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_constants.dart';

/// Hasil parsing payload `application/x-kencana`.
class KencanaNfcParsed {
  const KencanaNfcParsed({
    required this.jsonUtf8,
    required this.jsonText,
    required this.signature,
    required this.isLegacyFormat,
    this.json,
  });

  final Uint8List jsonUtf8;
  final String jsonText;
  final Uint8List signature;
  final bool isLegacyFormat;
  final Map<String, dynamic>? json;
}

/// Memecah blob NDEF Kencana: `json + DEADBEEF + signature`.
class KencanaNfcParser {
  const KencanaNfcParser();

  static const int _delimiterLength = 4;
  static const int _minSignedLength =
      1 + _delimiterLength + KencanaNfcConstants.ed25519SignatureLength;

  KencanaNfcParsed parse(Uint8List payload) {
    if (_isLegacyWrapped(payload)) {
      return _parseLegacy(payload);
    }
    return _parseSigned(payload);
  }

  bool _isLegacyWrapped(Uint8List payload) {
    if (payload.length < 8) return false;
    return _matchesDelimiter(payload, 0) &&
        _matchesDelimiter(payload, payload.length - _delimiterLength);
  }

  KencanaNfcParsed _parseLegacy(Uint8List payload) {
    final Uint8List inner = Uint8List.fromList(
      payload.sublist(_delimiterLength, payload.length - _delimiterLength),
    );
    final String text = utf8.decode(inner, allowMalformed: true);
    return KencanaNfcParsed(
      jsonUtf8: inner,
      jsonText: text,
      signature: Uint8List(0),
      isLegacyFormat: true,
      json: _tryDecodeJson(text),
    );
  }

  KencanaNfcParsed _parseSigned(Uint8List payload) {
    if (payload.length < _minSignedLength) {
      throw const FormatException('Payload Kencana terlalu pendek.');
    }

    final int delimIndex = _findDelimiterIndex(payload);
    if (delimIndex < 1) {
      throw const FormatException('Delimiter signature tidak ditemukan.');
    }

    final Uint8List jsonUtf8 = Uint8List.fromList(payload.sublist(0, delimIndex));
    final int sigStart = delimIndex + _delimiterLength;
    final Uint8List signature = Uint8List.fromList(
      payload.sublist(sigStart),
    );

    if (signature.length != KencanaNfcConstants.ed25519SignatureLength) {
      throw FormatException(
        'Panjang signature tidak valid: ${signature.length} byte '
        '(diharapkan ${KencanaNfcConstants.ed25519SignatureLength}).',
      );
    }

    final String jsonText = utf8.decode(jsonUtf8, allowMalformed: true);
    return KencanaNfcParsed(
      jsonUtf8: jsonUtf8,
      jsonText: jsonText,
      signature: signature,
      isLegacyFormat: false,
      json: _tryDecodeJson(jsonText),
    );
  }

  int _findDelimiterIndex(Uint8List payload) {
    final int lastPossible = payload.length -
        _delimiterLength -
        KencanaNfcConstants.ed25519SignatureLength;
    for (var i = lastPossible; i >= 1; i--) {
      if (_matchesDelimiter(payload, i)) return i;
    }
    return -1;
  }

  bool _matchesDelimiter(Uint8List bytes, int offset) {
    const delim = KencanaNfcConstants.signatureDelimiter;
    if (offset + delim.length > bytes.length) return false;
    for (var i = 0; i < delim.length; i++) {
      if (bytes[offset + i] != delim[i]) return false;
    }
    return true;
  }

  Map<String, dynamic>? _tryDecodeJson(String text) {
    try {
      final dynamic decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }
}
