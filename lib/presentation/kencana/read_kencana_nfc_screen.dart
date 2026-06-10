import 'package:flutter/material.dart';
import 'package:nfc_reader_writer/presentation/kencana/read_kencana_nfc_viewmodel.dart';
import 'package:nfc_reader_writer/presentation/kencana/widgets/kencana_card_result.dart';
import 'package:nfc_reader_writer/presentation/widgets/app_snack_bar.dart';
import 'package:nfc_reader_writer/presentation/widgets/pulsing_radar_animation.dart';

/// Layar khusus membaca kartu WB Kencana (`application/x-kencana`).
///
/// Memverifikasi format `json + DEADBEEF + ed25519_sign(json)` dan
/// menampilkan payload JSON beserta status signature.
class ReadKencanaNfcScreen extends StatefulWidget {
  const ReadKencanaNfcScreen({super.key, required this.viewModel});

  final ReadKencanaNfcViewModel viewModel;

  @override
  State<ReadKencanaNfcScreen> createState() => _ReadKencanaNfcScreenState();
}

class _ReadKencanaNfcScreenState extends State<ReadKencanaNfcScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Baca Kartu Kencana'),
    ),
    body: ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        _handleSideEffects(context);
        return _ReadKencanaBody(viewModel: widget.viewModel);
      },
    ),
  );

  void _handleSideEffects(BuildContext context) {
    final vm = widget.viewModel;
    switch (vm.state) {
      case ReadKencanaNfcState.success:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackBar.showSuccess(
            context,
            'Kartu Kencana valid — signature diverifikasi.',
          );
        });
      case ReadKencanaNfcState.error:
        if (vm.kencanaRecord == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppSnackBar.showError(
              context,
              vm.errorMessage ?? 'Gagal membaca kartu.',
            );
          });
        }
      case ReadKencanaNfcState.idle:
      case ReadKencanaNfcState.scanning:
        break;
    }
  }
}

class _ReadKencanaBody extends StatelessWidget {
  const _ReadKencanaBody({required this.viewModel});

  final ReadKencanaNfcViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Format: application/x-kencana\n'
            'json + DE AD BE EF + Ed25519 (64 byte)',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _ScanSection(
            isScanning: viewModel.isScanning,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 28),
          if (viewModel.kencanaRecord != null && viewModel.lastTag != null)
            KencanaCardResult(
              tagInfo: viewModel.lastTag!,
              record: viewModel.kencanaRecord!,
              errorMessage: viewModel.state == ReadKencanaNfcState.error
                  ? viewModel.errorMessage
                  : null,
            )
          else if (viewModel.errorMessage != null &&
              viewModel.state == ReadKencanaNfcState.error)
            _ErrorPanel(
              message: viewModel.errorMessage!,
              colorScheme: colorScheme,
            )
          else
            _EmptyHint(colorScheme: colorScheme, textTheme: textTheme),
          const SizedBox(height: 24),
          _Actions(viewModel: viewModel),
        ],
      ),
    );
  }
}

class _ScanSection extends StatelessWidget {
  const _ScanSection({
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
                key: const ValueKey('kencana-scan'),
                size: 80,
                color: colorScheme.secondary,
              )
            : Icon(
                key: const ValueKey('kencana-idle'),
                Icons.badge_rounded,
                size: 72,
                color: colorScheme.secondary.withValues(alpha: 0.45),
              ),
      ),
      const SizedBox(height: 16),
      Text(
        isScanning
            ? 'Tempelkan kartu Kencana ke belakang ponsel...'
            : 'Tekan Mulai Scan untuk membaca kartu WB',
        textAlign: TextAlign.center,
        style: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    ],
  );
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.colorScheme, required this.textTheme});

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.contactless_rounded,
            size: 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada kartu terbaca',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hasil JSON dan verifikasi signature akan tampil di sini.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.colorScheme});

  final String message;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Card(
    color: colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Actions extends StatelessWidget {
  const _Actions({required this.viewModel});

  final ReadKencanaNfcViewModel viewModel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton.icon(
        onPressed: viewModel.isScanning ? null : viewModel.startScanning,
        icon: Icon(
          viewModel.isScanning
              ? Icons.radar_rounded
              : Icons.play_circle_rounded,
        ),
        label: Text(viewModel.isScanning ? 'Memindai...' : 'Mulai Scan'),
      ),
      if (viewModel.state != ReadKencanaNfcState.idle) ...[
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
