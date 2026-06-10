import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_constants.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_pkcs8.dart';

/// Menandatangani byte payload JSON dengan Ed25519 (`crypt.Sign` di kencana-nfc).
class KencanaNfcSigner {
  KencanaNfcSigner._(this._keyPair);

  final SimpleKeyPair _keyPair;
  static final Ed25519 _algorithm = Ed25519();

  static Future<KencanaNfcSigner> fromPkcs8Pem(String pem) async {
    final Uint8List seed = ed25519SeedFromPkcs8Pem(pem);
    final SimpleKeyPair keyPair = await _algorithm.newKeyPairFromSeed(seed);
    return KencanaNfcSigner._(keyPair);
  }

  static Future<KencanaNfcSigner> fromAsset([
    String assetPath = KencanaNfcConstants.privateKeyAsset,
  ]) async {
    final String pem = await rootBundle.loadString(assetPath);
    return fromPkcs8Pem(pem);
  }

  Future<Uint8List> sign(Uint8List message) async {
    final Signature signature = await _algorithm.sign(
      message,
      keyPair: _keyPair,
    );
    final Uint8List bytes = Uint8List.fromList(signature.bytes);
    if (bytes.length != KencanaNfcConstants.ed25519SignatureLength) {
      throw StateError(
        'Panjang signature Ed25519 tidak valid: ${bytes.length}',
      );
    }
    return bytes;
  }
}
