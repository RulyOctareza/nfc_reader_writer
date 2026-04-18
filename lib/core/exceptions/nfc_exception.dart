/// Hierarchy exception untuk semua error yang berkaitan dengan NFC.
///
/// Menggunakan [sealed] agar switch di UI bisa exhaustive dan
/// setiap kasus error bisa ditangani secara spesifik.
sealed class NfcException implements Exception {
  const NfcException(this.message);

  final String message;

  @override
  String toString() => 'NfcException: $message';
}

/// Device tidak mendukung NFC sama sekali.
final class NfcNotSupportedException extends NfcException {
  const NfcNotSupportedException()
    : super('Perangkat ini tidak mendukung NFC.');
}

/// NFC ada tapi dimatikan oleh pengguna di Settings.
final class NfcDisabledException extends NfcException {
  const NfcDisabledException()
    : super('NFC tidak aktif. Silakan aktifkan NFC di Settings.');
}

/// Tag yang ditempelkan tidak mendukung format NDEF.
final class NdefNotSupportedException extends NfcException {
  const NdefNotSupportedException()
    : super('Tag ini tidak mendukung format NDEF.');
}

/// Tag NDEF bersifat read-only, tidak bisa ditulisi.
final class NdefReadOnlyException extends NfcException {
  const NdefReadOnlyException()
    : super('Tag ini bersifat read-only dan tidak dapat ditulis.');
}

/// Kapasitas tag tidak cukup untuk menampung data yang ingin ditulis.
final class NdefInsufficientCapacityException extends NfcException {
  const NdefInsufficientCapacityException()
    : super('Kapasitas tag NFC tidak cukup untuk menyimpan data ini.');
}

/// Tag terbaca tapi tidak memiliki data NDEF (kosong).
final class NdefEmptyException extends NfcException {
  const NdefEmptyException() : super('Tag tidak memiliki data NDEF.');
}

/// Tag terdeteksi sebagai NdefFormatable tapi belum diformat.
final class NdefFormatRequiredException extends NfcException {
  const NdefFormatRequiredException()
    : super(
        'Tag belum terformat. Silakan gunakan menu "Tulis NFC" untuk menginisialisasi tag ini.',
      );
}

/// Tag berhasil diformat NDEF, tapi perlu scan ulang agar bisa ditulis.
final class NdefFormattedRescanRequiredException extends NfcException {
  const NdefFormattedRescanRequiredException()
    : super(
        'Tag berhasil diformat! Tempelkan kartu lagi untuk menulis data.',
      );
}

/// Error komunikasi (kartu terputus, I/O error).
final class NfcCommunicationException extends NfcException {
  const NfcCommunicationException([String? detail])
    : super(
        detail ??
            'Komunikasi terputus. Pastikan kartu menempel stabil dan tidak digeser.',
      );
}

/// Error tak terduga yang tidak masuk ke kategori di atas.
final class NfcUnknownException extends NfcException {
  const NfcUnknownException(super.message);
}
