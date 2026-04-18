import 'package:flutter/foundation.dart';
import 'package:nfc_reader_writer/core/exceptions/nfc_exception.dart';
import 'package:nfc_reader_writer/domain/usecases/check_nfc_availability_usecase.dart';
import 'package:nfc_reader_writer/domain/usecases/format_nfc_usecase.dart';
import 'package:nfc_reader_writer/domain/usecases/write_nfc_usecase.dart';

/// Status sesi tulis NFC.
enum WriteNfcState {
  /// Menunggu user mengisi teks dan memulai.
  idle,

  /// Sesi aktif, menunggu tag ditempelkan untuk ditulis.
  waiting,

  /// Penulisan ke tag berhasil.
  success,

  /// Terjadi error selama sesi.
  error,

  /// Tag berhasil diformat, user perlu tempelkan kartu lagi untuk menulis.
  formatted,
}

/// ViewModel untuk [WriteNfcScreen].
///
/// Mengelola state sesi tulis NFC. Validasi input teks
/// dilakukan di sini sebelum mengoper ke use case.
class WriteNfcViewModel extends ChangeNotifier {
  WriteNfcViewModel({
    required WriteNfcUseCase writeNfcUseCase,
    required FormatNfcUseCase formatNfcUseCase,
    required CheckNfcAvailabilityUseCase checkNfcAvailabilityUseCase,
  }) : _writeUseCase = writeNfcUseCase,
       _formatUseCase = formatNfcUseCase,
       _checkUseCase = checkNfcAvailabilityUseCase;

  final WriteNfcUseCase _writeUseCase;
  final FormatNfcUseCase _formatUseCase;
  final CheckNfcAvailabilityUseCase _checkUseCase;

  WriteNfcState _state = WriteNfcState.idle;
  String? _errorMessage;

  WriteNfcState get state => _state;
  String? get errorMessage => _errorMessage;

  bool get isWaiting => _state == WriteNfcState.waiting;

  /// Memulai sesi tulis NFC dengan konten [text].
  ///
  /// Memvalidasi [text] terlebih dahulu. Jika kosong, langsung
  /// mengeset state error tanpa membuka sesi hardware NFC.
  Future<void> startWriting(String text) async {
    if (text.trim().isEmpty) {
      _errorMessage = 'Teks tidak boleh kosong sebelum menulis ke tag.';
      _updateState(WriteNfcState.error);
      return;
    }

    _updateState(WriteNfcState.waiting);

    final isAvailable = await _checkUseCase();
    if (!isAvailable) {
      _errorMessage = 'NFC tidak aktif. Silakan aktifkan NFC di Settings.';
      _updateState(WriteNfcState.error);
      return;
    }

    await _writeUseCase(
      text: text.trim(),
      onSuccess: () {
        _errorMessage = null;
        _updateState(WriteNfcState.success);
      },
      onError: (error) {
        if (error == const NdefFormattedRescanRequiredException().message) {
          _errorMessage = error;
          _updateState(WriteNfcState.formatted);
        } else {
          _errorMessage = error;
          _updateState(WriteNfcState.error);
        }
      },
    );
  }

  /// Memulai sesi format NFC (Inisialisasi).
  Future<void> startFormatting() async {
    _updateState(WriteNfcState.waiting);

    final isAvailable = await _checkUseCase();
    if (!isAvailable) {
      _errorMessage = 'NFC tidak aktif. Silakan aktifkan NFC di Settings.';
      _updateState(WriteNfcState.error);
      return;
    }

    await _formatUseCase(
      onSuccess: () {
        _errorMessage = null;
        _updateState(WriteNfcState.success);
      },
      onError: (error) {
        _errorMessage = error;
        _updateState(WriteNfcState.error);
      },
    );
  }

  /// Mereset state ke [WriteNfcState.idle].
  void reset() {
    _errorMessage = null;
    _updateState(WriteNfcState.idle);
  }

  void _updateState(WriteNfcState newState) {
    _state = newState;
    notifyListeners();
  }
}
