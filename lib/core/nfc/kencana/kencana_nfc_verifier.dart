import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_constants.dart';
import 'package:nfc_reader_writer/core/nfc/kencana/kencana_nfc_pkcs8.dart';

/// Memverifikasi signature Ed25519 pada payload kartu Kencana.
class KencanaNfcVerifier {
  KencanaNfcVerifier._(this._publicKey);

  final SimplePublicKey _publicKey;
  static final Ed25519 _algorithm = Ed25519();

  static Future<KencanaNfcVerifier> fromPkcs8Pem(String pem) async {
    final Uint8List seed = ed25519SeedFromPkcs8Pem(pem);
    final SimpleKeyPair keyPair = await _algorithm.newKeyPairFromSeed(seed);
    final SimplePublicKey publicKey = await keyPair.extractPublicKey();
    return KencanaNfcVerifier._(publicKey);
  }

  static Future<KencanaNfcVerifier> fromAsset([
    String assetPath = KencanaNfcConstants.privateKeyAsset,
  ]) async {
    final String pem = await rootBundle.loadString(assetPath);
    return fromPkcs8Pem(pem);
  }

  Future<bool> verify({
    required Uint8List message,
    required Uint8List signatureBytes,
  }) async {
    if (signatureBytes.length != KencanaNfcConstants.ed25519SignatureLength) {
      return false;
    }
    return _algorithm.verify(
      message,
      signature: Signature(signatureBytes, publicKey: _publicKey),
    );
  }
}
