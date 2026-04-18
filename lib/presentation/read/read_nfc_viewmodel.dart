import 'package:flutter/foundation.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_tag_info.dart';
import 'package:nfc_reader_writer/domain/usecases/check_nfc_availability_usecase.dart';
import 'package:nfc_reader_writer/domain/usecases/read_nfc_usecase.dart';

/// Status sesi baca NFC.
enum ReadNfcState {
  /// Belum ada aksi, menunggu user memulai.
  idle,

  /// Sesi aktif, menunggu tag ditempelkan.
  scanning,

  /// Tag berhasil dibaca.
  success,

  /// Terjadi error selama sesi.
  error,
}

/// ViewModel untuk [ReadNfcScreen].
///
/// Mengelola state sesi baca NFC dan mengekspos data hasil
/// bacaan ke UI. Menggunakan [ChangeNotifier] agar UI
/// dapat bereaksi dengan [ListenableBuilder].
class ReadNfcViewModel extends ChangeNotifier {
  ReadNfcViewModel({
    required ReadNfcUseCase readNfcUseCase,
    required CheckNfcAvailabilityUseCase checkNfcAvailabilityUseCase,
  }) : _readUseCase = readNfcUseCase,
       _checkUseCase = checkNfcAvailabilityUseCase;

  final ReadNfcUseCase _readUseCase;
  final CheckNfcAvailabilityUseCase _checkUseCase;

  ReadNfcState _state = ReadNfcState.idle;
  NfcTagInfo? _lastTag;
  String? _errorMessage;

  ReadNfcState get state => _state;
  NfcTagInfo? get lastTag => _lastTag;
  String? get errorMessage => _errorMessage;

  bool get isScanning => _state == ReadNfcState.scanning;

  /// Memulai sesi baca NFC.
  ///
  /// Mengecek ketersediaan NFC sebelum memulai sesi.
  Future<void> startScanning() async {
    _updateState(ReadNfcState.scanning);

    final isAvailable = await _checkUseCase();
    if (!isAvailable) {
      _errorMessage = 'NFC tidak aktif. Silakan aktifkan NFC di Settings.';
      _updateState(ReadNfcState.error);
      return;
    }

    await _readUseCase(
      onRead: (tagInfo) {
        _lastTag = tagInfo;
        _errorMessage = null;
        _updateState(ReadNfcState.success);
      },
      onError: (error) {
        _errorMessage = error;
        _updateState(ReadNfcState.error);
      },
    );
  }

  /// Mereset state ke [ReadNfcState.idle] dan menghapus hasil baca.
  void reset() {
    _lastTag = null;
    _errorMessage = null;
    _updateState(ReadNfcState.idle);
  }

  void _updateState(ReadNfcState newState) {
    _state = newState;
    notifyListeners();
  }
}
