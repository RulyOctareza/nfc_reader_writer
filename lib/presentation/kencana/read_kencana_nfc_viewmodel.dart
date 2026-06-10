import 'package:flutter/foundation.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_constants.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_record.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_tag_info.dart';
import 'package:nfc_reader_writer/domain/usecases/check_nfc_availability_usecase.dart';
import 'package:nfc_reader_writer/domain/usecases/read_nfc_usecase.dart';

/// Status sesi baca kartu Kencana.
enum ReadKencanaNfcState {
  idle,
  scanning,
  success,
  error,
}

/// ViewModel untuk [ReadKencanaNfcScreen].
class ReadKencanaNfcViewModel extends ChangeNotifier {
  ReadKencanaNfcViewModel({
    required ReadNfcUseCase readNfcUseCase,
    required CheckNfcAvailabilityUseCase checkNfcAvailabilityUseCase,
  }) : _readUseCase = readNfcUseCase,
       _checkUseCase = checkNfcAvailabilityUseCase;

  final ReadNfcUseCase _readUseCase;
  final CheckNfcAvailabilityUseCase _checkUseCase;

  ReadKencanaNfcState _state = ReadKencanaNfcState.idle;
  NfcTagInfo? _lastTag;
  NfcKencanaRecord? _kencanaRecord;
  String? _errorMessage;

  ReadKencanaNfcState get state => _state;
  NfcTagInfo? get lastTag => _lastTag;
  NfcKencanaRecord? get kencanaRecord => _kencanaRecord;
  String? get errorMessage => _errorMessage;
  bool get isScanning => _state == ReadKencanaNfcState.scanning;

  Future<void> startScanning() async {
    _updateState(ReadKencanaNfcState.scanning);

    final isAvailable = await _checkUseCase();
    if (!isAvailable) {
      _errorMessage = 'NFC tidak aktif. Silakan aktifkan NFC di Settings.';
      _updateState(ReadKencanaNfcState.error);
      return;
    }

    await _readUseCase(
      onRead: (tagInfo) {
        final record = tagInfo.record;
        if (record is! NfcKencanaRecord) {
          _lastTag = tagInfo;
          _kencanaRecord = null;
          _errorMessage =
              'Tag bukan kartu Kencana.\n'
              'Harus berisi record MIME '
              '"${KencanaNfcConstants.mimeType}".';
          _updateState(ReadKencanaNfcState.error);
          return;
        }

        if (!record.isSignedFormat) {
          _lastTag = tagInfo;
          _kencanaRecord = record;
          _errorMessage =
              'Format kartu lama (tanpa signature Ed25519). '
              'Gunakan kartu yang ditulis dengan kencana-nfc terbaru.';
          _updateState(ReadKencanaNfcState.error);
          return;
        }

        if (record.signatureValid != true) {
          _lastTag = tagInfo;
          _kencanaRecord = record;
          _errorMessage = 'Signature Ed25519 tidak valid atau tidak cocok.';
          _updateState(ReadKencanaNfcState.error);
          return;
        }

        _lastTag = tagInfo;
        _kencanaRecord = record;
        _errorMessage = null;
        _updateState(ReadKencanaNfcState.success);
      },
      onError: (error) {
        _errorMessage = error;
        _updateState(ReadKencanaNfcState.error);
      },
    );
  }

  void reset() {
    _lastTag = null;
    _kencanaRecord = null;
    _errorMessage = null;
    _updateState(ReadKencanaNfcState.idle);
  }

  void _updateState(ReadKencanaNfcState newState) {
    _state = newState;
    notifyListeners();
  }
}
