import 'package:nfc_reader_writer/data/services/nfc_service.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_tag_info.dart';
import 'package:nfc_reader_writer/domain/repositories/nfc_repository.dart';

/// Implementasi konkret dari [NfcRepository] menggunakan [NfcService].
///
/// Class ini menjembatani domain layer dengan data source (hardware NFC).
class NfcRepositoryImpl implements NfcRepository {
  const NfcRepositoryImpl(this._service);

  final NfcService _service;

  @override
  Future<bool> isNfcAvailable() => _service.isNfcAvailable();

  @override
  Future<void> startReadSession({
    required void Function(NfcTagInfo tagInfo) onRead,
    required void Function(String errorMessage) onError,
  }) => _service.startReadSession(onRead: onRead, onError: onError);

  @override
  Future<void> startWriteSession({
    required String text,
    required void Function() onSuccess,
    required void Function(String errorMessage) onError,
  }) => _service.startWriteSession(
    text: text,
    onSuccess: onSuccess,
    onError: onError,
  );

  @override
  Future<void> startFormatSession({
    required void Function() onSuccess,
    required void Function(String errorMessage) onError,
  }) => _service.startFormatSession(onSuccess: onSuccess, onError: onError);

  @override
  Future<void> stopSession() => _service.stopSession();
}
