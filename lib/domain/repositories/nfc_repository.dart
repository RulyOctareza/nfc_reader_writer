import 'package:nfc_reader_writer/domain/entities/nfc_tag_info.dart';

/// Kontrak abstrak untuk operasi NFC.
///
/// Domain layer hanya bergantung pada interface ini, bukan pada
/// implementasi konkret. Ini memungkinkan dependency inversion
/// dan memudahkan pengujian dengan mock.
abstract interface class NfcRepository {
  /// Mengembalikan `true` jika NFC tersedia dan aktif di perangkat ini.
  Future<bool> isNfcAvailable();

  /// Memulai sesi baca NFC.
  ///
  /// [onRead] dipanggil saat sebuah tag berhasil dibaca, baik terformat
  /// NDEF maupun kartu "mentah" (raw) dengan minimal info metadata.
  Future<void> startReadSession({
    required void Function(NfcTagInfo tagInfo) onRead,
    required void Function(String errorMessage) onError,
  });

  /// Memulai sesi tulis NFC dengan konten [text].
  ///
  /// [onSuccess] dipanggil setelah berhasil menulis ke tag.
  /// [onError] dipanggil jika terjadi error (tag read-only,
  /// kapasitas penuh, dll).
  Future<void> startWriteSession({
    required String text,
    required void Function() onSuccess,
    required void Function(String errorMessage) onError,
  });

  /// Memulai sesi format NFC (Inisialisasi).
  ///
  /// [onSuccess] dipanggil setelah berhasil memformat tag.
  /// [onError] dipanggil jika terjadi error.
  Future<void> startFormatSession({
    required void Function() onSuccess,
    required void Function(String errorMessage) onError,
  });

  /// Menghentikan sesi NFC yang sedang aktif.
  Future<void> stopSession();
}
