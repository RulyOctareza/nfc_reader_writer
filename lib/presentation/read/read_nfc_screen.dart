import 'package:flutter/material.dart';
import 'package:nfc_reader_writer/presentation/read/read_nfc_viewmodel.dart';
import 'package:nfc_reader_writer/presentation/widgets/app_snack_bar.dart';
import 'package:nfc_reader_writer/presentation/widgets/nfc_status_card.dart';
import 'package:nfc_reader_writer/presentation/widgets/pulsing_radar_animation.dart';

/// Layar untuk membaca tag NFC.
///
/// Menampilkan animasi radar saat sesi aktif, dan card hasil
/// bacaan setelah tag berhasil dideteksi. ViewModel di-inject
/// melalui konstruktor (manual DI).
class ReadNfcScreen extends StatefulWidget {
  const ReadNfcScreen({super.key, required this.viewModel});

  final ReadNfcViewModel viewModel;

  @override
  State<ReadNfcScreen> createState() => _ReadNfcScreenState();
}

class _ReadNfcScreenState extends State<ReadNfcScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Baca NFC')),
    body: ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        _handleSideEffects(context);
        return _ReadNfcBody(viewModel: widget.viewModel);
      },
    ),
  );

  /// Menampilkan SnackBar berdasarkan transisi state.
  ///
  /// Hanya dipanggil saat state berubah ke success atau error.
  void _handleSideEffects(BuildContext context) {
    final vm = widget.viewModel;
    switch (vm.state) {
      case ReadNfcState.success:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackBar.showSuccess(context, '✅ Tag NFC berhasil dibaca!');
        });
      case ReadNfcState.error:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackBar.showError(
            context,
            vm.errorMessage ?? 'Terjadi kesalahan yang tidak diketahui.',
          );
        });
      case ReadNfcState.idle:
      case ReadNfcState.scanning:
        break;
    }
  }
}

class _ReadNfcBody extends StatelessWidget {
  const _ReadNfcBody({required this.viewModel});

  final ReadNfcViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _ScanningSection(
            isScanning: viewModel.isScanning,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 32),
          NfcStatusCard(
            tagInfo: viewModel.lastTag,
            errorMessage: viewModel.state == ReadNfcState.error
                ? viewModel.errorMessage
                : null,
          ),
          const SizedBox(height: 24),
          _ActionButtons(viewModel: viewModel),
        ],
      ),
    );
  }
}

class _ScanningSection extends StatelessWidget {
  const _ScanningSection({
    required this.isScanning,
    required this.colorScheme,
    required this.textTheme,
  });

  final bool isScanning;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: isScanning
            ? PulsingRadarAnimation(
                key: const ValueKey('scanning'),
                size: 80,
                color: colorScheme.primary,
              )
            : _IdleNfcIcon(
                key: const ValueKey('idle'),
                colorScheme: colorScheme,
              ),
      ),
      const SizedBox(height: 20),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          isScanning
              ? 'Tempelkan tag NFC ke bagian\nbelakang ponsel Anda...'
              : 'Tekan tombol di bawah untuk\nmemulai pemindaian NFC',
          key: ValueKey(isScanning),
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}

class _IdleNfcIcon extends StatelessWidget {
  const _IdleNfcIcon({super.key, required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Container(
    width: 120,
    height: 120,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: colorScheme.surfaceContainerHighest,
    ),
    child: Icon(
      Icons.nfc_rounded,
      size: 60,
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
    ),
  );
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.viewModel});

  final ReadNfcViewModel viewModel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ElevatedButton.icon(
        onPressed: viewModel.isScanning ? null : viewModel.startScanning,
        icon: Icon(
          viewModel.isScanning
              ? Icons.radar_rounded
              : Icons.play_circle_rounded,
        ),
        label: Text(viewModel.isScanning ? 'Memindai...' : 'Mulai Scan'),
      ),
      if (viewModel.state != ReadNfcState.idle) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: viewModel.reset,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reset'),
        ),
      ],
    ],
  );
}
