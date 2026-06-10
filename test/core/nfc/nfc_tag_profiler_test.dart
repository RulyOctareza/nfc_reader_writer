import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_reader_writer/core/nfc/nfc_tag_profiler.dart';

void main() {
  const profiler = NfcTagProfiler();

  group('NfcTagProfiler', () {
    test('mendeteksi Mifare Classic 1K dari ukuran chip', () {
      final profile = profiler.profile(
        const NfcTagProfilerInput(
          techList: ['NfcA', 'MifareClassic', 'Ndef'],
          mifareClassicSize: 1024,
          mifareClassicType: 'classic',
          mifareClassicSectors: 16,
          ndefMaxSize: 716,
          isNdefFormatted: true,
        ),
      );

      expect(profile.chipModel, contains('1K'));
      expect(profile.totalMemoryBytes, 1024);
      expect(profile.ndefCapacityBytes, 716);
    });

    test('mendeteksi NTAG216 dari kapasitas NDEF', () {
      final profile = profiler.profile(
        const NfcTagProfilerInput(
          techList: ['NfcA', 'MifareUltralight', 'Ndef'],
          mifareUltralightType: 'ultralight',
          ndefMaxSize: 888,
          ndefPlatformType: 'NFC Forum Type 2',
          isNdefFormatted: true,
        ),
      );

      expect(profile.chipModel, contains('NTAG216'));
      expect(profile.nfcForumType, 'NFC Forum Type 2');
      expect(profile.totalMemoryBytes, 924);
    });

    test('mendeteksi NTAG213 dari kapasitas NDEF', () {
      final profile = profiler.profile(
        const NfcTagProfilerInput(
          techList: ['NfcA', 'Ndef'],
          ndefMaxSize: 137,
          isNdefFormatted: true,
        ),
      );

      expect(profile.chipModel, contains('NTAG213'));
      expect(profile.ndefCapacityBytes, 137);
    });

    test('mengestimasi kapasitas untuk tag belum format NDEF', () {
      final profile = profiler.profile(
        const NfcTagProfilerInput(
          techList: ['NfcA', 'MifareUltralight', 'NdefFormatable'],
          mifareUltralightType: 'ultralightC',
          isNdefFormatable: true,
        ),
      );

      expect(profile.chipModel, contains('Ultralight C'));
      expect(profile.ndefCapacityBytes, 144);
      expect(profile.totalMemoryBytes, 192);
      expect(profile.extraMetadata['NDEF Formatable'], 'Ya');
    });

    test('mendeteksi kartu dari SAK saat metadata chip terbatas', () {
      final profile = profiler.profile(
        const NfcTagProfilerInput(
          techList: ['NfcA', 'NdefFormatable'],
          sak: 0x18,
          isNdefFormatable: true,
        ),
      );

      expect(profile.chipModel, contains('Classic 4K'));
    });

    test('mendeteksi ISO 15693', () {
      final profile = profiler.profile(
        const NfcTagProfilerInput(
          techList: ['NfcV', 'Ndef'],
          nfcVDsfId: 0x2A,
          isNdefFormatted: true,
        ),
      );

      expect(profile.chipModel, contains('ISO 15693'));
      expect(profile.nfcForumType, contains('Type 5'));
    });
  });
}
