import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nfc_reader_writer/domain/usecases/check_nfc_availability_usecase.dart';
import 'package:nfc_reader_writer/domain/usecases/format_nfc_usecase.dart';
import 'package:nfc_reader_writer/domain/usecases/write_nfc_usecase.dart';
import 'package:nfc_reader_writer/presentation/write/write_nfc_viewmodel.dart';

class MockWriteNfcUseCase extends Mock implements WriteNfcUseCase {}

class MockFormatNfcUseCase extends Mock implements FormatNfcUseCase {}

class MockCheckNfcAvailabilityUseCase extends Mock
    implements CheckNfcAvailabilityUseCase {}

void main() {
  group('WriteNfcViewModel', () {
    late MockWriteNfcUseCase mockWriteUseCase;
    late MockFormatNfcUseCase mockFormatUseCase;
    late MockCheckNfcAvailabilityUseCase mockCheckUseCase;
    late WriteNfcViewModel viewModel;

    setUp(() {
      mockWriteUseCase = MockWriteNfcUseCase();
      mockFormatUseCase = MockFormatNfcUseCase();
      mockCheckUseCase = MockCheckNfcAvailabilityUseCase();
      viewModel = WriteNfcViewModel(
        writeNfcUseCase: mockWriteUseCase,
        formatNfcUseCase: mockFormatUseCase,
        checkNfcAvailabilityUseCase: mockCheckUseCase,
      );
    });

    test('Initial state is idle', () {
      expect(viewModel.state, equals(WriteNfcState.idle));
      expect(viewModel.errorMessage, isNull);
    });

    test('Input teks kosong langsung error tanpa memanggil use case', () async {
      var stateChanges = <WriteNfcState>[];
      viewModel.addListener(() => stateChanges.add(viewModel.state));

      await viewModel.startWriting('   '); // Hanya spasi

      expect(stateChanges, [WriteNfcState.error]);
      expect(
        viewModel.errorMessage,
        equals('Teks tidak boleh kosong sebelum menulis ke tag.'),
      );
      verifyNever(() => mockCheckUseCase());
    });

    test('Menulissukses mengubah state menjadi success', () async {
      when(() => mockCheckUseCase()).thenAnswer((_) async => true);
      when(
        () => mockWriteUseCase(
          text: any(named: 'text'),
          onSuccess: any(named: 'onSuccess'),
          onError: any(named: 'onError'),
        ),
      ).thenAnswer((invocation) async {
        final onSuccess =
            invocation.namedArguments[#onSuccess] as void Function();
        onSuccess();
      });

      var stateChanges = <WriteNfcState>[];
      viewModel.addListener(() => stateChanges.add(viewModel.state));

      await viewModel.startWriting('Hello NFC');

      expect(stateChanges, [WriteNfcState.waiting, WriteNfcState.success]);
      expect(viewModel.errorMessage, isNull);
    });

    test('Memulai tulis dengan NFC mati menghasilkan error', () async {
      when(() => mockCheckUseCase()).thenAnswer((_) async => false);

      var stateChanges = <WriteNfcState>[];
      viewModel.addListener(() => stateChanges.add(viewModel.state));

      await viewModel.startWriting('Valid Text');

      expect(stateChanges, [WriteNfcState.waiting, WriteNfcState.error]);
      expect(viewModel.errorMessage, contains('tidak aktif'));
      verifyNever(
        () => mockWriteUseCase(
          text: any(named: 'text'),
          onSuccess: any(named: 'onSuccess'),
          onError: any(named: 'onError'),
        ),
      );
    });
  });
}
