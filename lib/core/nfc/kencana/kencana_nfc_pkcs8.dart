import 'dart:convert';
import 'dart:typed_data';

/// Mengekstrak seed Ed25519 (32 byte) dari PKCS#8 PEM.
///
/// Mendukung kunci Ed25519 standar (OID 1.3.101.112) seperti yang
/// dihasilkan OpenSSL / `kencana-nfc`.
Uint8List ed25519SeedFromPkcs8Pem(String pem) {
  final String normalized = pem
      .replaceAll('-----BEGIN PRIVATE KEY-----', '')
      .replaceAll('-----END PRIVATE KEY-----', '')
      .replaceAll(RegExp(r'\s'), '');
  final Uint8List der = base64.decode(normalized);

  if (der.length < 32) {
    throw FormatException('PKCS#8 terlalu pendek (${der.length} byte).');
  }

  // Ed25519 PKCS#8: seed 32 byte berada di OCTET STRING terdalam.
  final int seedStart = der.length - 32;
  return Uint8List.fromList(der.sublist(seedStart));
}
