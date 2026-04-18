import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_tag_info.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_record.dart';
import 'package:nfc_reader_writer/domain/usecases/check_nfc_availability_usecase.dart';
import 'package:nfc_reader_writer/domain/usecases/read_nfc_usecase.dart';
import 'package:nfc_reader_writer/presentation/read/read_nfc_viewmodel.dart';

class MockReadNfcUseCase extends Mock implements ReadNfcUseCase {}

class MockCheckNfcAvailabilityUseCase extends Mock
    implements CheckNfcAvailabilityUseCase {}

void main() {
  group('ReadNfcViewModel', () {
    late MockReadNfcUseCase mockReadUseCase;
    late MockCheckNfcAvailabilityUseCase mockCheckUseCase;
    late ReadNfcViewModel viewModel;

    setUp(() {
      mockReadUseCase = MockReadNfcUseCase();
      mockCheckUseCase = MockCheckNfcAvailabilityUseCase();
      viewModel = ReadNfcViewModel(
        readNfcUseCase: mockReadUseCase,
        checkNfcAvailabilityUseCase: mockCheckUseCase,
      );
    });

    test('Initial state is idle', () {
      expect(viewModel.state, equals(ReadNfcState.idle));
      expect(viewModel.lastTag, isNull);
      expect(viewModel.errorMessage, isNull);
    });

    test('Memulai scan mengubah state ke scanning lalu success', () async {
      const mockTag = NfcTagInfo(
        uid: 'DE:AD:BE:EF',
        techList: ['NfcA', 'Ndef'],
        record: NfcTextRecord(text: 'Mock Teks', languageCode: 'en'),
        isNdefFormatted: true,
      );

      when(() => mockCheckUseCase()).thenAnswer((_) async => true);
      when(
        () => mockReadUseCase(
          onRead: any(named: 'onRead'),
          onError: any(named: 'onError'),
        ),
      ).thenAnswer((invocation) async {
        final onRead =
            invocation.namedArguments[#onRead] as void Function(NfcTagInfo);
        onRead(mockTag);
      });

      final stateChanges = <ReadNfcState>[];
      viewModel.addListener(() => stateChanges.add(viewModel.state));

      await viewModel.startScanning();

      expect(stateChanges, [ReadNfcState.scanning, ReadNfcState.success]);
      expect(viewModel.lastTag?.uid, 'DE:AD:BE:EF');
      final record = viewModel.lastTag?.record;
      expect(record, isA<NfcTextRecord>());
      expect((record as NfcTextRecord).text, 'Mock Teks');
      expect(viewModel.errorMessage, isNull);
    });

    test(
      'Memulai scan dengan NFC mati mengubah state ke error langsung',
      () async {
        when(() => mockCheckUseCase()).thenAnswer((_) async => false);

        final stateChanges = <ReadNfcState>[];
        viewModel.addListener(() => stateChanges.add(viewModel.state));

        await viewModel.startScanning();

        expect(stateChanges, [ReadNfcState.scanning, ReadNfcState.error]);
        expect(viewModel.errorMessage, contains('tidak aktif'));
        verifyNever(
          () => mockReadUseCase(
            onRead: any(named: 'onRead'),
            onError: any(named: 'onError'),
          ),
        );
      },
    );

    test('Reset mengembalikan state ke idle', () {
      viewModel.reset();
      expect(viewModel.state, ReadNfcState.idle);
      expect(viewModel.lastTag, isNull);
      expect(viewModel.errorMessage, isNull);
    });
  });
}
