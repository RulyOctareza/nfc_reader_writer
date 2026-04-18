import 'package:nfc_reader_writer/domain/repositories/nfc_repository.dart';

/// Use case: memulai sesi tulis NFC.
///
/// Mendelegasikan ke [NfcRepository.startWriteSession].
/// Validasi konten teks dilakukan di ViewModel sebelum use case ini
/// dipanggil.
class WriteNfcUseCase {
  const WriteNfcUseCase(this._repository);

  final NfcRepository _repository;

  Future<void> call({
    required String text,
    required void Function() onSuccess,
    required void Function(String errorMessage) onError,
  }) => _repository.startWriteSession(
    text: text,
    onSuccess: onSuccess,
    onError: onError,
  );
}
