import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_reader_writer/data/services/nfc_service.dart';

class MockNfcManager extends Mock implements NfcManager {}

void main() {
  group('NfcService', () {
    late MockNfcManager mockNfcManager;
    late NfcService service;

    setUp(() {
      mockNfcManager = MockNfcManager();
      service = NfcService(nfcManager: mockNfcManager);
    });

    test('isNfcAvailable returns true when NFC is active', () async {
      when(() => mockNfcManager.isAvailable()).thenAnswer((_) async => true);

      final result = await service.isNfcAvailable();

      expect(result, isTrue);
      verify(() => mockNfcManager.isAvailable()).called(1);
    });

    test('startReadSession memanggil onError saat NFC tidak aktif '
        '(Error Handling)', () async {
      when(() => mockNfcManager.isAvailable()).thenAnswer((_) async => false);

      String? errorArg;
      await service.startReadSession(
        onRead: (_) => fail('Seharusnya tidak memanggil onRead'),
        onError: (err) => errorArg = err,
      );

      expect(errorArg, 'NFC tidak aktif. Silakan aktifkan NFC di Settings.');
      verify(() => mockNfcManager.isAvailable()).called(1);
      verifyNever(
        () => mockNfcManager.startSession(
          onDiscovered: any(named: 'onDiscovered'),
          pollingOptions: any(named: 'pollingOptions'),
        ),
      );
    });

    test('startWriteSession memanggil onError saat NFC tidak aktif '
        '(Error Handling)', () async {
      when(() => mockNfcManager.isAvailable()).thenAnswer((_) async => false);

      String? errorArg;
      await service.startWriteSession(
        text: 'hello',
        onSuccess: () => fail('Seharusnya tidak memanggil onSuccess'),
        onError: (err) => errorArg = err,
      );

      expect(errorArg, 'NFC tidak aktif. Silakan aktifkan NFC di Settings.');
      verify(() => mockNfcManager.isAvailable()).called(1);
    });

    test('stopSession memanggil NfcManager.stopSession()', () async {
      when(() => mockNfcManager.stopSession()).thenAnswer((_) async {});

      await service.stopSession();

      verify(() => mockNfcManager.stopSession()).called(1);
    });

    // Catatan: Menguji aliran sukses hingga `onDiscovered` secara penuh
    // untuk MockNfcTag + NDEF membutuhkan instansiasi tipe internal platform
    // channel Flutter. Test case ini memfokuskan validasi state manager.
  });
}
