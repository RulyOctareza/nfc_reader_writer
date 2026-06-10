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
import 'package:nfc_reader_writer/core/nfc/nfc_tag_profiler.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_constants.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_payload_decoder.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_verifier.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_record.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_tag_info.dart';

/// Service yang membungkus [NfcManager] untuk operasi baca/tulis NFC.
/// Menggunakan pendekatan dinamis untuk mendukung fungsionalitas cross-platform
/// dan kompatibilitas antar versi nfc_manager (3.x vs 4.x yang menggunakan Pigeon).
class NfcService {
  NfcService({
    NfcManager? nfcManager,
    KencanaNfcPayloadDecoder? kencanaDecoder,
    KencanaNfcVerifier? kencanaVerifier,
  }) : _nfcManager = nfcManager ?? NfcManager.instance,
       _kencanaDecoder = kencanaDecoder ?? const KencanaNfcPayloadDecoder(),
       _kencanaVerifier = kencanaVerifier;

  final NfcManager _nfcManager;
  final KencanaNfcPayloadDecoder _kencanaDecoder;
  final KencanaNfcVerifier? _kencanaVerifier;
  final NfcTagProfiler _tagProfiler = const NfcTagProfiler();

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
          final tagInfo = await _extractTagInfo(tag);
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

  Future<NfcTagInfo> _extractTagInfo(NfcTag tag) async {
    final uid = _getUid(tag);
    final techList = _getTechList(tag);
    final signals = _extractChipSignals(tag);
    final isNdefFormatable = _isNdefFormatable(tag);

    final ndef = Ndef.from(tag);
    if (ndef == null) {
      return _buildTagInfo(
        uid: uid,
        techList: techList,
        signals: signals,
        isNdefFormatted: false,
        isNdefFormatable: isNdefFormatable,
      );
    }

    final ndefType = ndef.additionalData['type']?.toString();
    final capacity = ndef.maxSize;
    final ndefWritable = ndef.additionalData['canMakeReadOnly'] == null
        ? ndef.isWritable
        : ndef.isWritable;

    var message = ndef.cachedMessage;
    if (message == null || message.records.isEmpty) {
      try {
        message = await ndef.read();
      } catch (e, s) {
        developer.log(
          'NDEF read fallback gagal, memakai cached message',
          name: 'NfcService.read',
          error: e,
          stackTrace: s,
        );
      }
    }

    final ndefUsedBytes = message?.byteLength;
    NfcRecord? nfcRecord;
    if (message != null && message.records.isNotEmpty) {
      for (final record in message.records) {
        try {
          if (record.typeNameFormat == TypeNameFormat.media &&
              String.fromCharCodes(record.type) ==
                  KencanaNfcConstants.mimeType) {
            nfcRecord = await _decodeKencanaRecord(record);
            break;
          }
        } catch (_) {}
      }

      if (nfcRecord == null) {
        for (final record in message.records) {
          try {
            nfcRecord = _decodeNdefRecord(record);
            if (nfcRecord != null) break;
          } catch (_) {}
        }
      }
    }

    return _buildTagInfo(
      uid: uid,
      techList: techList,
      signals: signals,
      isNdefFormatted: true,
      isNdefFormatable: false,
      ndefType: ndefType,
      ndefMaxSize: capacity,
      ndefWritable: ndefWritable,
      ndefUsedBytes: ndefUsedBytes,
      record: nfcRecord,
    );
  }

  NfcTagInfo _buildTagInfo({
    required String uid,
    required List<String> techList,
    required _ChipSignals signals,
    required bool isNdefFormatted,
    required bool isNdefFormatable,
    String? ndefType,
    int? ndefMaxSize,
    bool? ndefWritable,
    int? ndefUsedBytes,
    NfcRecord? record,
  }) {
    final profile = _tagProfiler.profile(
      NfcTagProfilerInput(
        techList: techList,
        sak: signals.sak,
        atqa: signals.atqa,
        mifareClassicSize: signals.mifareClassicSize,
        mifareClassicType: signals.mifareClassicType,
        mifareClassicSectors: signals.mifareClassicSectors,
        mifareUltralightType: signals.mifareUltralightType,
        mifareFamily: signals.mifareFamily,
        ndefMaxSize: ndefMaxSize,
        ndefPlatformType: ndefType,
        ndefWritable: ndefWritable,
        ndefMessageSize: ndefUsedBytes,
        nfcVDsfId: signals.nfcVDsfId,
        isNdefFormatted: isNdefFormatted,
        isNdefFormatable: isNdefFormatable,
      ),
    );

    final rawTechData = <String, dynamic>{
      if (signals.sak != null) 'SAK': _formatIntToHex(signals.sak!),
      if (signals.atqa != null) 'ATQA': _formatBytesToHex(
        Uint8List.fromList(signals.atqa!),
      ),
      if (signals.mifareClassicSectors != null)
        'Sektor Mifare': signals.mifareClassicSectors.toString(),
      if (signals.historicalBytes != null)
        'Historical Bytes': _formatBytesToHex(signals.historicalBytes!),
      if (signals.hiLayerResponse != null)
        'HiLayer Response': _formatBytesToHex(signals.hiLayerResponse!),
      ...profile.extraMetadata,
    };

    return NfcTagInfo(
      uid: uid,
      techList: techList,
      chipModel: profile.chipModel,
      ndefType: profile.nfcForumType ?? ndefType,
      capacity: profile.ndefCapacityBytes ?? ndefMaxSize,
      totalMemoryBytes: profile.totalMemoryBytes ?? signals.mifareClassicSize,
      ndefUsedBytes: ndefUsedBytes,
      record: record,
      isNdefFormatted: isNdefFormatted,
      isNdefFormatable: isNdefFormatable,
      rawTechData: rawTechData,
    );
  }

  bool _isNdefFormatable(NfcTag tag) {
    try {
      return NdefFormatableAndroid.from(tag) != null;
    } catch (_) {
      return false;
    }
  }

  /// Mengekstrak sinyal chip untuk identifikasi jenis kartu dan kapasitas.
  _ChipSignals _extractChipSignals(NfcTag tag) {
    // ignore: invalid_use_of_protected_member
    final dynamic data = tag.data;

    int? sak;
    List<int>? atqa;
    int? mifareClassicSize;
    String? mifareClassicType;
    int? mifareClassicSectors;
    String? mifareUltralightType;
    String? mifareFamily;
    int? nfcVDsfId;
    Uint8List? historicalBytes;
    Uint8List? hiLayerResponse;

    try {
      final nfcA = data.nfcA;
      if (nfcA != null) {
        sak = nfcA.sak as int;
        atqa = (nfcA.atqa as Uint8List).toList();
      }
    } catch (_) {}

    try {
      final isoDep = data.isoDep;
      if (isoDep != null) {
        historicalBytes = isoDep.historicalBytes as Uint8List?;
        hiLayerResponse = isoDep.hiLayerResponse as Uint8List?;
      }
    } catch (_) {}

    try {
      final mc = data.mifareClassic;
      if (mc != null) {
        mifareClassicSize = mc.size as int;
        mifareClassicType = mc.type.toString().split('.').last;
        mifareClassicSectors = mc.sectorCount as int;
      }
    } catch (_) {}

    try {
      final mu = data.mifareUltralight;
      if (mu != null) {
        mifareUltralightType = mu.type.toString().split('.').last;
      }
    } catch (_) {}

    try {
      final nfcV = data.nfcV;
      if (nfcV != null) {
        nfcVDsfId = nfcV.dsfId as int;
      }
    } catch (_) {}

    try {
      final miFare = data.miFare;
      if (miFare != null) {
        mifareFamily = miFare.mifareFamily.toString().split('.').last;
      }
    } catch (_) {}

    return _ChipSignals(
      sak: sak,
      atqa: atqa,
      mifareClassicSize: mifareClassicSize,
      mifareClassicType: mifareClassicType,
      mifareClassicSectors: mifareClassicSectors,
      mifareUltralightType: mifareUltralightType,
      mifareFamily: mifareFamily,
      nfcVDsfId: nfcVDsfId,
      historicalBytes: historicalBytes,
      hiLayerResponse: hiLayerResponse,
    );
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

  Future<NfcKencanaRecord> _decodeKencanaRecord(NdefRecord record) async {
    try {
      return await _kencanaDecoder.decode(
        record.payload,
        verifier: _kencanaVerifier,
      );
    } on FormatException catch (e) {
      throw NfcUnknownException('Format kartu Kencana tidak valid: ${e.message}');
    }
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

class _ChipSignals {
  const _ChipSignals({
    this.sak,
    this.atqa,
    this.mifareClassicSize,
    this.mifareClassicType,
    this.mifareClassicSectors,
    this.mifareUltralightType,
    this.mifareFamily,
    this.nfcVDsfId,
    this.historicalBytes,
    this.hiLayerResponse,
  });

  final int? sak;
  final List<int>? atqa;
  final int? mifareClassicSize;
  final String? mifareClassicType;
  final int? mifareClassicSectors;
  final String? mifareUltralightType;
  final String? mifareFamily;
  final int? nfcVDsfId;
  final Uint8List? historicalBytes;
  final Uint8List? hiLayerResponse;
}
