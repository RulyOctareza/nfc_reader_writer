import 'package:nfc_reader_writer/domain/repositories/nfc_repository.dart';

/// Use case: Memulai sesi format NFC (Inisialisasi Tag).
///
/// Mendelegasikan ke [NfcRepository.startFormatSession].
class FormatNfcUseCase {
  const FormatNfcUseCase(this._repository);

  final NfcRepository _repository;

  Future<void> call({
    required void Function() onSuccess,
    required void Function(String errorMessage) onError,
  }) => _repository.startFormatSession(
    onSuccess: onSuccess,
    onError: onError,
  );
}
