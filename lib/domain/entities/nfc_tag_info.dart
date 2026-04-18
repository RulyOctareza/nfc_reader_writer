import 'package:flutter/foundation.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_record.dart';

/// Entity yang menampung informasi teknis (metadata) dari sebuah tag NFC.
///
/// Digunakan untuk memberikan preview sebelum atau sesudah data NDEF dibaca.
@immutable
class NfcTagInfo {
  const NfcTagInfo({
    required this.uid,
    required this.techList,
    this.ndefType,
    this.capacity,
    this.record,
    this.isNdefFormatted = false,
    this.rawTechData = const {},
  });

  /// Unique Identifier (UID) kartu dalam format Hex (contoh: DE:AD:BE:EF).
  final String uid;

  /// Daftar teknologi yang didukung kartu (contoh: [NfcA, Ndef, NdefFormatable]).
  final List<String> techList;

  /// Tipe NDEF (contoh: 'NFC Forum Type 2').
  final String? ndefType;

  /// Estimasi kapasitas memori dalam byte.
  final int? capacity;

  /// Data record yang berhasil dibaca (jika ada).
  final NfcRecord? record;

  /// Flag apakah kartu sudah terformat NDEF.
  final bool isNdefFormatted;

  /// Data teknis tambahan (metadata) dari chip kartu (contoh: SAK, ATQA).
  final Map<String, dynamic> rawTechData;

  @override
  String toString() =>
      'NfcTagInfo(uid: $uid, isNdefFormatted: $isNdefFormatted, record: $record, rawTechData: $rawTechData)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NfcTagInfo &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          techList.length == other.techList.length &&
          isNdefFormatted == other.isNdefFormatted &&
          record == other.record &&
          mapEquals(rawTechData, other.rawTechData);

  @override
  int get hashCode =>
      Object.hash(uid, techList, isNdefFormatted, record, rawTechData);
}
