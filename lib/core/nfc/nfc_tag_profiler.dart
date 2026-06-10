/// Input mentah dari platform untuk mengidentifikasi jenis chip dan kapasitas.
class NfcTagProfilerInput {
  const NfcTagProfilerInput({
    required this.techList,
    this.sak,
    this.atqa,
    this.mifareClassicSize,
    this.mifareClassicType,
    this.mifareClassicSectors,
    this.mifareUltralightType,
    this.mifareFamily,
    this.ndefMaxSize,
    this.ndefPlatformType,
    this.ndefWritable,
    this.ndefMessageSize,
    this.nfcVDsfId,
    this.isNdefFormatted = false,
    this.isNdefFormatable = false,
  });

  final List<String> techList;
  final int? sak;
  final List<int>? atqa;
  final int? mifareClassicSize;
  final String? mifareClassicType;
  final int? mifareClassicSectors;
  final String? mifareUltralightType;
  final String? mifareFamily;
  final int? ndefMaxSize;
  final String? ndefPlatformType;
  final bool? ndefWritable;
  final int? ndefMessageSize;
  final int? nfcVDsfId;
  final bool isNdefFormatted;
  final bool isNdefFormatable;
}

/// Hasil identifikasi chip NFC.
class NfcTagProfile {
  const NfcTagProfile({
    this.chipModel,
    this.nfcForumType,
    this.ndefCapacityBytes,
    this.totalMemoryBytes,
    this.ndefUsedBytes,
    this.extraMetadata = const {},
  });

  final String? chipModel;
  final String? nfcForumType;
  final int? ndefCapacityBytes;
  final int? totalMemoryBytes;
  final int? ndefUsedBytes;
  final Map<String, String> extraMetadata;
}

/// Mengidentifikasi jenis chip NFC dan kapasitas memori dari sinyal platform.
class NfcTagProfiler {
  const NfcTagProfiler();

  NfcTagProfile profile(NfcTagProfilerInput input) {
    final extra = <String, String>{};

    if (input.ndefWritable != null) {
      extra['NDEF Writable'] = input.ndefWritable! ? 'Ya' : 'Tidak';
    }
    if (input.isNdefFormatable && !input.isNdefFormatted) {
      extra['NDEF Formatable'] = 'Ya';
    }
    if (input.mifareClassicType != null) {
      extra['Mifare Variant'] = input.mifareClassicType!;
    }
    if (input.mifareUltralightType != null) {
      extra['Ultralight Variant'] = input.mifareUltralightType!;
    }
    if (input.nfcVDsfId != null) {
      extra['DSFID'] = '0x${input.nfcVDsfId!.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    }

    final chip = _detectChipModel(input);
    final forumType = _resolveNfcForumType(input);
    final totalMemory = _resolveTotalMemory(input, chip);
    final ndefCapacity = input.ndefMaxSize ?? _estimateNdefCapacity(input, chip);

    return NfcTagProfile(
      chipModel: chip,
      nfcForumType: forumType,
      ndefCapacityBytes: ndefCapacity,
      totalMemoryBytes: totalMemory,
      ndefUsedBytes: input.ndefMessageSize,
      extraMetadata: extra,
    );
  }

  String? _detectChipModel(NfcTagProfilerInput input) {
    final classic = _fromMifareClassic(input);
    if (classic != null) return classic;

    final ultralight = _fromMifareUltralight(input);
    if (ultralight != null) return ultralight;

    final ntag = _fromNdefCapacity(input.ndefMaxSize);
    if (ntag != null) return ntag;

    final iosFamily = _fromIosMifareFamily(input.mifareFamily);
    if (iosFamily != null) return iosFamily;

    final sakModel = input.sak != null ? _fromSak(input.sak!) : null;
    if (sakModel != null) return sakModel;

    if (_hasTech(input, 'nfcV')) {
      return 'ISO 15693 (NfcV)';
    }
    if (_hasTech(input, 'nfcF')) {
      return 'FeliCa (NfcF)';
    }
    if (_hasTech(input, 'isoDep') && !_hasTech(input, 'ndef')) {
      return 'ISO-DEP (kemungkinan DESFire / smart card)';
    }

    return null;
  }

  String? _fromMifareClassic(NfcTagProfilerInput input) {
    final size = input.mifareClassicSize;
    if (size == null) return null;

    final variant = switch (input.mifareClassicType?.toLowerCase()) {
      'plus' => 'Plus',
      'pro' => 'Pro',
      _ => 'Classic',
    };

  return switch (size) {
      <= 320 => 'Mifare $variant Mini (320 bytes)',
      <= 1024 => 'Mifare $variant 1K (1024 bytes)',
      <= 2048 => 'Mifare $variant 2K (2048 bytes)',
      _ => 'Mifare $variant 4K (4096 bytes)',
    };
  }

  String? _fromMifareUltralight(NfcTagProfilerInput input) {
    final type = input.mifareUltralightType?.toLowerCase();
    if (type == null) return null;

    if (type == 'ultralightc') {
      final ntag = _fromNdefCapacity(input.ndefMaxSize);
      return ntag ?? 'Mifare Ultralight C (192 bytes)';
    }
    if (type == 'ultralight') {
      final ntag = _fromNdefCapacity(input.ndefMaxSize);
      if (ntag != null) return ntag;
      if (input.ndefMaxSize != null && input.ndefMaxSize! <= 64) {
        return 'Mifare Ultralight (64 bytes)';
      }
      return 'Mifare Ultralight / NTAG';
    }
    return null;
  }

  String? _fromNdefCapacity(int? maxSize) {
    if (maxSize == null) return null;

    const known = <int, String>{
      48: 'Mifare Ultralight (48 bytes NDEF)',
      137: 'NTAG213 (137 bytes NDEF)',
      144: 'NTAG213 (144 bytes NDEF)',
      492: 'NTAG215 (492 bytes NDEF)',
      504: 'NTAG215 (504 bytes NDEF)',
      716: 'Mifare Classic 1K (716 bytes NDEF)',
      872: 'NTAG216 (872 bytes NDEF)',
      888: 'NTAG216 (888 bytes NDEF)',
      1732: 'Mifare Classic 2K (1732 bytes NDEF)',
      1912: 'NTAG I2C Plus 2K',
      3440: 'Mifare Classic 4K (3440 bytes NDEF)',
      7936: 'NTAG I2C Plus 8K',
    };

    if (known.containsKey(maxSize)) return known[maxSize];

    // Toleransi kecil karena perbedaan laporan platform.
    for (final entry in known.entries) {
      if ((maxSize - entry.key).abs() <= 8) return entry.value;
    }
    return null;
  }

  String? _fromIosMifareFamily(String? family) {
    return switch (family?.toLowerCase()) {
      'ultralight' => 'MiFare Ultralight (iOS)',
      'plus' => 'MiFare Plus (iOS)',
      'desfire' => 'MiFare DESFire (iOS)',
      _ => null,
    };
  }

  String? _fromSak(int sak) {
    return switch (sak) {
      0x08 => 'Mifare Classic 1K (SAK 0x08)',
      0x09 => 'Mifare Mini (SAK 0x09)',
      0x10 => 'Mifare Plus 2K (SAK 0x10)',
      0x11 => 'Mifare Plus 4K (SAK 0x11)',
      0x18 => 'Mifare Classic 4K (SAK 0x18)',
      0x20 => 'Mifare DESFire (SAK 0x20)',
      0x24 => 'Mifare DESFire EV1 (SAK 0x24)',
      0x00 => 'Mifare Ultralight / NTAG (SAK 0x00)',
      _ => null,
    };
  }

  String? _resolveNfcForumType(NfcTagProfilerInput input) {
    final platform = input.ndefPlatformType?.trim();
    if (platform != null && platform.isNotEmpty) return platform;

    if (_hasTech(input, 'nfcF')) return 'NFC Forum Type 3 (FeliCa)';
    if (_hasTech(input, 'isoDep') &&
        (_hasTech(input, 'ndef') || input.isNdefFormatted)) {
      return 'NFC Forum Type 4 (ISO-DEP)';
    }
    if (_hasTech(input, 'mifareUltralight') ||
        (_hasTech(input, 'nfcA') &&
            (input.sak == 0x00) &&
            !_hasTech(input, 'mifareClassic'))) {
      return 'NFC Forum Type 2 (Mifare Ultralight / NTAG)';
    }
    if (_hasTech(input, 'mifareClassic')) {
      return 'NFC Forum Type 2 (Mifare Classic via NDEF)';
    }
    if (_hasTech(input, 'nfcV')) return 'ISO 15693 (Type 5 / Vicinity)';
    return null;
  }

  int? _resolveTotalMemory(NfcTagProfilerInput input, String? chipModel) {
    if (input.mifareClassicSize != null) return input.mifareClassicSize;

    final fromModel = _totalMemoryFromChipModel(chipModel);
    if (fromModel != null) return fromModel;

    final ultralight = input.mifareUltralightType?.toLowerCase();
    if (ultralight == 'ultralight') return 64;
    if (ultralight == 'ultralightc') return 192;

    return null;
  }

  int? _totalMemoryFromChipModel(String? chipModel) {
    if (chipModel == null) return null;
    if (chipModel.contains('NTAG213')) return 180;
    if (chipModel.contains('NTAG215')) return 540;
    if (chipModel.contains('NTAG216')) return 924;
    if (chipModel.contains('Classic 1K')) return 1024;
    if (chipModel.contains('Classic 4K')) return 4096;
    if (chipModel.contains('Mini')) return 320;
    return null;
  }

  int? _estimateNdefCapacity(NfcTagProfilerInput input, String? chipModel) {
    if (input.mifareClassicSize != null) {
      return switch (input.mifareClassicSize!) {
        <= 320 => 48,
        <= 1024 => 716,
        <= 2048 => 1732,
        _ => 3440,
      };
    }

    final ultralight = input.mifareUltralightType?.toLowerCase();
    if (ultralight == 'ultralight') return 48;
    if (ultralight == 'ultralightc') return 144;

    if (chipModel != null) {
      if (chipModel.contains('NTAG213')) return 137;
      if (chipModel.contains('NTAG215')) return 504;
      if (chipModel.contains('NTAG216')) return 888;
    }
    return null;
  }

  bool _hasTech(NfcTagProfilerInput input, String tech) =>
      input.techList.any((t) => t.toLowerCase() == tech.toLowerCase());
}
