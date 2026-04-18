import 'package:nfc_reader_writer/domain/entities/nfc_tag_info.dart';
import 'package:nfc_reader_writer/domain/repositories/nfc_repository.dart';

/// Use case: memulai sesi baca NFC.
///
/// Mendelegasikan langsung ke [NfcRepository.startReadSession].
/// ViewModel tidak perlu tahu detail implementasi data layer.
class ReadNfcUseCase {
  const ReadNfcUseCase(this._repository);

  final NfcRepository _repository;

  Future<void> call({
    required void Function(NfcTagInfo tagInfo) onRead,
    required void Function(String errorMessage) onError,
  }) => _repository.startReadSession(onRead: onRead, onError: onError);
}
