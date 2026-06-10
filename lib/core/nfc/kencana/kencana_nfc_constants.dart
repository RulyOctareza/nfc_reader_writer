/// Format kartu WB Kencana — selaras dengan `kencana-nfc` (PC/SC).
abstract final class KencanaNfcConstants {
  static const String mimeType = 'application/x-kencana';

  static const List<int> signatureDelimiter = <int>[
    0xDE,
    0xAD,
    0xBE,
    0xEF,
  ];

  static const int ed25519SignatureLength = 64;

  static const String privateKeyAsset = 'assets/nfc/private.pem';
}
