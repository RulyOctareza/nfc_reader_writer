import 'package:flutter/foundation.dart';

/// Base class untuk semua jenis record NDEF.
///
/// Menggunakan Dart 3 sealed class untuk memastikan penanganan
/// yang menyeluruh (exhaustive) di sisi UI.
sealed class NfcRecord {
  const NfcRecord();
}

/// Record NDEF bertipe Text ('T').
class NfcTextRecord extends NfcRecord {
  const NfcTextRecord({
    required this.text,
    required this.languageCode,
  });

  final String text;
  final String languageCode;

  @override
  String toString() =>
      'NfcTextRecord(languageCode: $languageCode, text: $text)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NfcTextRecord &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          languageCode == other.languageCode;

  @override
  int get hashCode => Object.hash(text, languageCode);
}

/// Record NDEF bertipe URI ('U').
class NfcUriRecord extends NfcRecord {
  const NfcUriRecord({
    required this.uri,
    this.protocol = '',
  });

  final String uri;
  final String protocol;

  String get fullUri => '$protocol$uri';

  @override
  String toString() => 'NfcUriRecord(uri: $fullUri)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NfcUriRecord &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          protocol == other.protocol;

  @override
  int get hashCode => Object.hash(uri, protocol);
}

/// Record NDEF bertipe MIME / Media.
class NfcMimeRecord extends NfcRecord {
  const NfcMimeRecord({
    required this.mimeType,
    required this.payload,
  });

  final String mimeType;
  final Uint8List payload;

  /// Mencoba mendekode payload sebagai string UTF-8.
  String get payloadAsString {
    try {
      return String.fromCharCodes(payload);
    } catch (_) {
      return '';
    }
  }

  @override
  String toString() => 'NfcMimeRecord(mimeType: $mimeType, size: ${payload.length}b)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NfcMimeRecord &&
          runtimeType == other.runtimeType &&
          mimeType == other.mimeType &&
          listEquals(payload, other.payload);

  @override
  int get hashCode => Object.hash(mimeType, payload);
}
