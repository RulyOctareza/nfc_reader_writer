import 'package:nfc_reader_writer/domain/repositories/nfc_repository.dart';

/// Use case: memeriksa apakah NFC tersedia dan aktif.
///
/// Digunakan oleh ViewModel sebelum memulai sesi
/// baca maupun tulis untuk memberikan feedback awal ke user.
class CheckNfcAvailabilityUseCase {
  const CheckNfcAvailabilityUseCase(this._repository);

  final NfcRepository _repository;

  /// Mengembalikan `true` jika NFC siap digunakan.
  Future<bool> call() => _repository.isNfcAvailable();
}
