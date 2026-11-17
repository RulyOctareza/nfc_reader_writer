<p align="center">
  <img src="docs/preview/hero.svg" alt="NFC Reader Writer — ilustrasi aplikasi baca tulis NFC" width="100%">
</p>

<h1 align="center">NFC Reader / Writer</h1>

<p align="center">
  <b>Baca, tulis, dan kelola tag NFC dari ponsel.</b><br>
  NDEF records · GoRouter · Clean Architecture
</p>

<p align="center">
  <a href="https://flutter.dev"><img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white"></a>
  <img alt="NFC" src="https://img.shields.io/badge/NFC-nfc__manager-6E56CF">
  <img alt="Arch" src="https://img.shields.io/badge/Architecture-Clean-0D9488">
</p>

---

## ✨ Preview

<p align="center">
  <img src="docs/preview/hero.png" alt="Mockup gelap NFC Reader Writer" width="90%">
</p>

> **Catatan:** gambar di atas adalah *ilustrasi konsep*, bukan screenshot asli.

---

## 📖 Tentang

Aplikasi utilitas NFC: tempelkan tag ke ponsel untuk membaca isinya, lalu tulis data baru
dalam format NDEF (teks, URI, dan record lain). Dibangun dengan pemisahan
data/domain/presentation dan `go_router` untuk navigasi.

---

## 🌟 Fitur

- 📖 **Baca tag NFC** dan tampilkan isi NDEF record
- ✍️ **Tulis NDEF** ke tag yang kompatibel
- 🧩 **Dukungan berbagai record** lewat `ndef_record`
- 🔒 **Utilitas kriptografi** (`cryptography`) untuk kebutuhan pengamanan data
- 🧭 Navigasi halaman dengan GoRouter
- 🎨 Ikon SVG dan Google Fonts

---

## 🛠️ Tech Stack

| Area | Pilihan |
|---|---|
| Framework | Flutter |
| NFC | `nfc_manager`, `nfc_manager_ndef`, `ndef_record` |
| Kriptografi | `cryptography` |
| Routing | GoRouter |
| UI | `flutter_svg`, Google Fonts |

---

## 🧱 Struktur

```text
lib/
├── app/           # Inisialisasi, router, tema
├── core/          # Konstanta, error, utilitas
├── data/          # Datasource & repository
├── domain/        # Entity & use case
├── presentation/  # Halaman dan widget
└── main.dart
```

---

## 🚀 Menjalankan

```bash
flutter pub get
flutter run
```

Butuh perangkat Android fisik dengan NFC aktif. iOS butuh entitlement NFC yang sesuai.

> ⚠️ File `private.pem` di root repo hanya contoh untuk pengembangan — jangan pakai di produksi.

---

## 🧪 Testing

```bash
flutter analyze
flutter test
```
