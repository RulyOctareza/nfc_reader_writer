import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:nfc_manager/nfc_manager.dart';
// NdefFormatableAndroid diperlukan untuk menginisialisasi tag yang belum terformat NDEF.
// ignore: implementation_imports
import 'package:nfc_manager/src/nfc_manager_android/tags/ndef_formatable.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_reader_writer/core/exceptions/nfc_exception.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_record.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_tag_info.dart';

/// Service yang membungkus [NfcManager] untuk operasi baca/tulis NFC.
/// Menggunakan pendekatan dinamis untuk mendukung fungsionalitas cross-platform
/// dan kompatibilitas antar versi nfc_manager (3.x vs 4.x yang menggunakan Pigeon).
class NfcService {
  NfcService({NfcManager? nfcManager})
    : _nfcManager = nfcManager ?? NfcManager.instance;

  final NfcManager _nfcManager;

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> isNfcAvailable() => _nfcManager.isAvailable();

  Future<void> startReadSession({
    required void Function(NfcTagInfo tagInfo) onRead,
    required void Function(String errorMessage) onError,
  }) async {
    final isAvailable = await isNfcAvailable();
    if (!isAvailable) {
      onError(const NfcDisabledException().message);
      return;
    }

    await _nfcManager.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
      onDiscovered: (NfcTag tag) async {
        try {
          final tagInfo = _extractTagInfo(tag);
          onRead(tagInfo);
        } on NfcException catch (e) {
          onError(e.message);
        } catch (e, s) {
          developer.log(
            'Unexpected error during NFC read',
            name: 'NfcService.read',
            level: 1000,
            error: e,
            stackTrace: s,
          );
          onError('Gagal membaca tag NFC (${e.toString()})');
        }
      },
    );
  }

  Future<void> startWriteSession({
    required String text,
    required void Function() onSuccess,
    required void Function(String errorMessage) onError,
  }) async {
    final isAvailable = await isNfcAvailable();
    if (!isAvailable) {
      onError(const NfcDisabledException().message);
      return;
    }

    await _nfcManager.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
      onDiscovered: (NfcTag tag) async {
        try {
          await _writeTextRecord(tag, text);
          onSuccess();
        } on NfcException catch (e) {
          onError(e.message);
        } catch (e, s) {
          developer.log(
            'Unexpected error during NFC write',
            name: 'NfcService.write',
            level: 1000,
            error: e,
            stackTrace: s,
          );
          onError('Gagal menulis ke tag NFC (${e.toString()})');
        }
      },
    );
  }

  Future<void> startFormatSession({
    required void Function() onSuccess,
    required void Function(String errorMessage) onError,
  }) async {
    final isAvailable = await isNfcAvailable();
    if (!isAvailable) {
      onError(const NfcDisabledException().message);
      return;
    }

    await _nfcManager.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
      onDiscovered: (NfcTag tag) async {
        try {
          await _formatTag(tag);
          onSuccess();
        } on NfcException catch (e) {
          onError(e.message);
        } catch (e, s) {
          developer.log(
            'Unexpected error during NFC format',
            name: 'NfcService.format',
            level: 1000,
            error: e,
            stackTrace: s,
          );
          onError('Gagal memformat tag NFC (${e.toString()})');
        }
      },
    );
  }

  Future<void> stopSession() => _nfcManager.stopSession();

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  NfcTagInfo _extractTagInfo(NfcTag tag) {
    final uid = _getUid(tag);
    final techList = _getTechList(tag);
    final rawTechData = _getRawTechData(tag);

    final ndef = Ndef.from(tag);
    if (ndef == null) {
      return NfcTagInfo(
        uid: uid,
        techList: techList,
        isNdefFormatted: false,
        rawTechData: rawTechData,
      );
    }

    final ndefType = ndef.additionalData['type']?.toString();
    final capacity = ndef.maxSize;

    // Enrich metadata dengan model chip jika bisa dideteksi dari kapasitas NDEF.
    final enrichedTechData = Map<String, dynamic>.from(rawTechData);
    final chipModel = _detectChipModel(capacity, techList);
    if (chipModel != null) enrichedTechData['Chip Model'] = chipModel;

    final cachedMessage = ndef.cachedMessage;
    if (cachedMessage == null || cachedMessage.records.isEmpty) {
      return NfcTagInfo(
        uid: uid,
        techList: techList,
        ndefType: ndefType,
        capacity: capacity,
        isNdefFormatted: true,
        rawTechData: enrichedTechData,
      );
    }

    // Coba temukan record Kencana dulu, jika tidak ada cari Text/URI/MIME apa saja.
    NfcRecord? nfcRecord;
    for (final record in cachedMessage.records) {
      try {
        if (record.typeNameFormat == TypeNameFormat.media &&
            String.fromCharCodes(record.type) == 'application/x-kencana') {
          nfcRecord = _decodeKencanaRecord(record);
          break; // Prioritas utama: Kencana
        }
      } catch (_) {}
    }

    // Balikkan ke record NDEF umum jika Kencana tidak ada.
    if (nfcRecord == null) {
      for (final record in cachedMessage.records) {
        try {
          nfcRecord = _decodeNdefRecord(record);
          if (nfcRecord != null) break;
        } catch (_) {}
      }
    }

    return NfcTagInfo(
      uid: uid,
      techList: techList,
      ndefType: ndefType,
      capacity: capacity,
      record: nfcRecord,
      isNdefFormatted: true,
      rawTechData: enrichedTechData,
    );
  }

  /// Mendeteksi model chip dari kapasitas NDEF dan daftar teknologi.
  String? _detectChipModel(int maxSize, List<String> techList) {
    final hasMifare = techList.any((t) => t.toLowerCase().contains('mifare'));
    if (hasMifare) {
      // Mifare Classic / Plus berdasarkan kapasitas setelah format NDEF
      if (maxSize <= 716) return 'Mifare Classic 1K';
      if (maxSize <= 1732) return 'Mifare Classic 2K';
      if (maxSize <= 3440) return 'Mifare Classic 4K';
    }
    // NTAG series (NFC Forum Type 2)
    if (maxSize <= 137) return 'NTAG213 (~200b)';
    if (maxSize <= 492) return 'NTAG215 (~600b)';
    if (maxSize <= 872) return 'NTAG216 (888b)';
    if (maxSize <= 1912) return 'NTAG I2C 2K';
    if (maxSize <= 7936) return 'NTAG I2C 8K';
    return null;
  }

  /// Mengekstrak metadata teknis spesifik chip secara dinamis.
  Map<String, dynamic> _getRawTechData(NfcTag tag) {
    final Map<String, dynamic> metadata = {};
    // ignore: invalid_use_of_protected_member
    final dynamic data = tag.data;

    try {
      // NfcA (SAK, ATQA)
      final nfcA = data.nfcA;
      if (nfcA != null) {
        metadata['SAK'] = _formatIntToHex(nfcA.sak as int);
        metadata['ATQA'] = _formatBytesToHex(nfcA.atqa as Uint8List);
      }
    } catch (_) {}

    try {
      // IsoDep (Historical Bytes, dsb)
      final isoDep = data.isoDep;
      if (isoDep != null) {
        if (isoDep.historicalBytes != null) {
          metadata['Historical Bytes'] = _formatBytesToHex(
            isoDep.historicalBytes as Uint8List,
          );
        }
        if (isoDep.hiLayerResponse != null) {
          metadata['HiLayer Response'] = _formatBytesToHex(
            isoDep.hiLayerResponse as Uint8List,
          );
        }
      }
    } catch (_) {}

    try {
      // Mifare Classic
      final mc = data.mifareClassic;
      if (mc != null) {
        metadata['Card Type'] = mc.type.toString().split('.').last;
        metadata['Size'] = '${mc.size} bytes';
        metadata['Sectors'] = mc.sectorCount.toString();
      }
    } catch (_) {}

    return metadata;
  }

  String _formatIntToHex(int val) => '0x${val.toRadixString(16).toUpperCase()}';

  String _formatBytesToHex(Uint8List bytes) => bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');

  /// Helper untuk mengambil UID dalam format Hex (DE:AD:BE:EF).
  /// Menggunakan akses dinamis agar kompatibel dengan TagPigeon (nfc_manager 4.x)
  /// dan Map (nfc_manager 3.x) tanpa import class yang tidak diekspor.
  String _getUid(NfcTag tag) {
    try {
      List<int>? idBytes;
      // ignore: invalid_use_of_protected_member
      final dynamic data = tag.data;

      // 1. Coba cara nfc_manager v3 (Map)
      if (data is Map) {
        idBytes = data['id'] as List<int>?;
      }

      // 2. Coba cara nfc_manager v4 (Pigeon object) secara dinamis
      // Di v4, UID ada di field 'id' pada objek TagPigeon.
      if (idBytes == null || idBytes.isEmpty) {
        try {
          idBytes = (data.id as List<dynamic>?)?.cast<int>();
        } catch (_) {}
      }

      if (idBytes == null || idBytes.isEmpty) return 'Unknown';

      return idBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(':');
    } catch (e) {
      debugPrint('[NFC DEBUG] Uid Extraction Error: $e');
      return 'Unknown';
    }
  }

  /// Helper dinamis untuk mendapatkan daftar teknologi.
  List<String> _getTechList(NfcTag tag) {
    try {
      // ignore: invalid_use_of_protected_member
      final dynamic data = tag.data;

      // v3 & v4 format (Map or Pigeon) biasanya punya field techList
      if (data is Map && data.containsKey('techList')) {
        final List<dynamic>? techs = data['techList'] as List<dynamic>?;
        if (techs != null) {
          return techs
              .map((e) => e.toString().split('.').last)
              .toSet()
              .toList();
        }
      }

      // v4 Pigeon direct access
      try {
        final List<dynamic>? techs = data.techList as List<dynamic>?;
        if (techs != null) {
          return techs
              .map((e) => e.toString().split('.').last)
              .toSet()
              .toList();
        }
      } catch (_) {}

      return [];
    } catch (_) {
      return [];
    }
  }

  NfcTextRecord _decodeKencanaRecord(NdefRecord record) {
    final payload = record.payload;
    if (payload.length < 8) {
      throw const NfcUnknownException('Payload Kencana terlalu pendek.');
    }
    final startValid =
        payload[0] == 0xDE &&
        payload[1] == 0xAD &&
        payload[2] == 0xBE &&
        payload[3] == 0xEF;
    final endValid =
        payload[payload.length - 4] == 0xDE &&
        payload[payload.length - 3] == 0xAD &&
        payload[payload.length - 2] == 0xBE &&
        payload[payload.length - 1] == 0xEF;

    if (!startValid || !endValid) {
      throw const NfcUnknownException('Format Delimiter Kencana tidak valid.');
    }
    return NfcTextRecord(
      text: String.fromCharCodes(payload.sublist(4, payload.length - 4)),
      languageCode: 'Dart',
    );
  }

  NfcRecord? _decodeNdefRecord(NdefRecord record) {
    final payload = record.payload;
    if (payload.isEmpty) return null;

    // 1. Handle Text Record (Type 'T')
    if (record.typeNameFormat == TypeNameFormat.wellKnown &&
        listEquals(record.type, Uint8List.fromList([0x54]))) {
      final statusByte = payload[0];
      final languageLength = statusByte & 0x3F;
      if (payload.length < 1 + languageLength) return null;

      return NfcTextRecord(
        text: utf8.decode(payload.sublist(1 + languageLength)),
        languageCode: utf8.decode(payload.sublist(1, 1 + languageLength)),
      );
    }

    // 2. Handle URI Record (Type 'U')
    if (record.typeNameFormat == TypeNameFormat.wellKnown &&
        listEquals(record.type, Uint8List.fromList([0x55]))) {
      final prefixCode = payload[0];
      final prefix = _getUriPrefix(prefixCode);
      final uriBody = utf8.decode(payload.sublist(1));

      return NfcUriRecord(uri: uriBody, protocol: prefix);
    }

    // 3. Handle MIME/Media Record
    if (record.typeNameFormat == TypeNameFormat.media) {
      final mimeType = String.fromCharCodes(record.type);
      return NfcMimeRecord(mimeType: mimeType, payload: payload);
    }

    return null;
  }

  String _getUriPrefix(int code) {
    switch (code) {
      case 0x01:
        return 'http://www.';
      case 0x02:
        return 'https://www.';
      case 0x03:
        return 'http://';
      case 0x04:
        return 'https://';
      case 0x05:
        return 'tel:';
      case 0x06:
        return 'mailto:';
      default:
        return '';
    }
  }

  Future<void> _writeTextRecord(NfcTag tag, String text) async {
    debugPrint('[NFC] _writeTextRecord: start, text="$text"');
    final ndef = Ndef.from(tag);
    debugPrint(
      '[NFC] _writeTextRecord: Ndef.from(tag) = ${ndef != null ? "OK (writable=${ndef.isWritable}, maxSize=${ndef.maxSize})" : "null"}',
    );
    final message = _buildKencanaNdefMessage(text);

    if (ndef == null) {
      debugPrint(
        '[NFC] _writeTextRecord: tag belum NDEF, cek NdefFormatable...',
      );
      // ignore: invalid_use_of_protected_member
      debugPrint('[NFC] tag.data = ${tag.data}');

      final formatable = NdefFormatableAndroid.from(tag);
      debugPrint(
        '[NFC] _writeTextRecord: NdefFormatableAndroid = ${formatable != null ? "OK" : "null"}',
      );

      if (formatable == null) {
        debugPrint(
          '[NFC] _writeTextRecord: tag tidak support NdefFormatable → NdefNotSupportedException',
        );
        throw const NdefNotSupportedException();
      }

      // Coba inisialisasi menggunakan NdefFormatable (Android).
      try {
        debugPrint('[NFC] _writeTextRecord: delay 1s sebelum format...');
        await Future.delayed(const Duration(milliseconds: 1000));
        debugPrint('[NFC] _writeTextRecord: memanggil formatable.format()...');
        await formatable.format(
          NdefMessage(
            records: [
              NdefRecord(
                typeNameFormat: TypeNameFormat.wellKnown,
                type: Uint8List.fromList([0x54]), // 'T' (Text)
                identifier: Uint8List(0),
                payload: Uint8List.fromList([0x02, 0x65, 0x6E]),
              ),
            ],
          ),
        );
        debugPrint(
          '[NFC] _writeTextRecord: format() berhasil → minta scan ulang',
        );
        // Setelah format, Android memerlukan koneksi baru ke tag.
        // Minta user scan ulang kartu — sesi berikutnya Ndef.from(tag) akan berhasil.
        throw const NdefFormattedRescanRequiredException();
      } on NfcException {
        // NfcException (termasuk NdefFormattedRescanRequiredException) harus diteruskan apa adanya.
        rethrow;
      } catch (e, s) {
        debugPrint('[NFC] _writeTextRecord: format() GAGAL → $e');
        debugPrint('[NFC] stacktrace: $s');
        throw _handleException(e as Exception, context: 'inisialisasi');
      }
    }

    if (!ndef.isWritable) {
      debugPrint('[NFC] _writeTextRecord: tag read-only!');
      throw const NdefReadOnlyException();
    }
    if (message.byteLength > ndef.maxSize) {
      debugPrint(
        '[NFC] _writeTextRecord: pesan ${message.byteLength}b > kapasitas ${ndef.maxSize}b',
      );
      throw NfcUnknownException(
        'Teks terlalu panjang untuk kartu ini.\n'
        'Dibutuhkan: ${message.byteLength} bytes, '
        'kapasitas kartu: ${ndef.maxSize} bytes.\n'
        'Kurangi teks atau gunakan kartu yang lebih besar.',
      );
    }

    try {
      debugPrint(
        '[NFC] _writeTextRecord: menulis ${message.byteLength} bytes ke tag...',
      );
      await ndef.write(message: message);
      debugPrint('[NFC] _writeTextRecord: tulis berhasil!');
    } catch (e, s) {
      debugPrint('[NFC] _writeTextRecord: tulis GAGAL → $e');
      debugPrint('[NFC] stacktrace: $s');
      if (e is! Exception) rethrow;
      throw _handleException(e, context: 'menulis');
    }
  }

  Future<void> _formatTag(NfcTag tag) async {
    debugPrint('[NFC] _formatTag: start');
    final ndef = Ndef.from(tag);
    debugPrint(
      '[NFC] _formatTag: Ndef.from(tag) = ${ndef != null ? "OK (writable=${ndef.isWritable})" : "null"}',
    );

    if (ndef == null) {
      final formatable = NdefFormatableAndroid.from(tag);
      debugPrint(
        '[NFC] _formatTag: NdefFormatableAndroid = ${formatable != null ? "OK" : "null"}',
      );

      if (formatable == null) {
        debugPrint(
          '[NFC] _formatTag: tidak support NdefFormatable → NdefNotSupportedException',
        );
        throw const NdefNotSupportedException();
      }

      try {
        debugPrint('[NFC] _formatTag: delay 1s lalu format...');
        await Future.delayed(const Duration(milliseconds: 1000));
        await formatable.format(
          NdefMessage(
            records: [
              NdefRecord(
                typeNameFormat: TypeNameFormat.wellKnown,
                type: Uint8List.fromList([0x54]), // 'T'
                identifier: Uint8List(0),
                payload: Uint8List.fromList([0x02, 0x65, 0x6E]),
              ),
            ],
          ),
        );
        debugPrint('[NFC] _formatTag: format() berhasil');
        return;
      } catch (e, s) {
        debugPrint('[NFC] _formatTag: format() GAGAL → $e');
        debugPrint('[NFC] stacktrace: $s');
        if (e is! Exception) rethrow;
        throw _handleException(e, context: 'reset');
      }
    }

    if (!ndef.isWritable) {
      debugPrint('[NFC] _formatTag: tag read-only!');
      throw const NdefReadOnlyException();
    }

    try {
      debugPrint('[NFC] _formatTag: tag sudah NDEF, tulis pesan kosong...');
      final emptyMessage = _buildKencanaNdefMessage("");
      await ndef.write(message: emptyMessage);
      debugPrint('[NFC] _formatTag: format berhasil');
    } catch (e, s) {
      debugPrint('[NFC] _formatTag: tulis GAGAL → $e');
      debugPrint('[NFC] stacktrace: $s');
      if (e is! Exception) rethrow;
      throw _handleException(e, context: 'format');
    }
  }

  /// Mapper error yang lebih user-friendly.
  Exception _handleException(Exception e, {required String context}) {
    final errorStr = e.toString();
    debugPrint('[NFC] _handleException [$context]: $errorStr');

    final isIoError = errorStr.contains('IOException');
    final isTagLost =
        errorStr.contains('Tag lost') || errorStr.contains('tag lost');

    // Kartu tergeser / sinyal putus saat operasi sedang berjalan
    if (isTagLost) {
      return const NfcCommunicationException(
        'Kartu terlepas saat proses berlangsung. Tempelkan lagi dengan stabil.',
      );
    }

    // IOException saat format/inisialisasi = hampir selalu autentikasi sektor gagal
    // (key default FF:FF:FF:FF:FF:FF ditolak oleh kartu)
    if (isIoError && (context == 'inisialisasi' || context == 'reset')) {
      return const NfcCommunicationException(
        'Gagal memformat kartu. Sektor kartu ini dilindungi key non-default '
        '(bukan FF:FF:FF:FF:FF:FF). Kartu tidak dapat diformat via aplikasi ini.',
      );
    }

    // IOException pada operasi lain (menulis, baca)
    if (isIoError) {
      return const NfcCommunicationException();
    }

    return NfcUnknownException('Gagal $context: ${e.toString()}');
  }

  NdefMessage _buildKencanaNdefMessage(String text) {
    final textBytes = Uint8List.fromList(text.codeUnits);
    final delimiter = [0xDE, 0xAD, 0xBE, 0xEF];
    final payload = Uint8List(8 + textBytes.length);
    payload.setRange(0, 4, delimiter);
    payload.setRange(4, 4 + textBytes.length, textBytes);
    payload.setRange(payload.length - 4, payload.length, delimiter);

    return NdefMessage(
      records: [
        NdefRecord(
          typeNameFormat: TypeNameFormat.media,
          type: Uint8List.fromList('application/x-kencana'.codeUnits),
          identifier: Uint8List(0),
          payload: payload,
        ),
      ],
    );
  }
}
