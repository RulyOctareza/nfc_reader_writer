import 'package:flutter/material.dart';
import 'package:nfc_reader_writer/presentation/widgets/app_snack_bar.dart';
import 'package:nfc_reader_writer/presentation/widgets/pulsing_radar_animation.dart';
import 'package:nfc_reader_writer/presentation/write/write_nfc_viewmodel.dart';

/// Layar untuk menulis teks ke tag NFC.
///
/// User mengetik teks, lalu menempelkan tag untuk ditulis.
/// Animasi muncul saat menunggu tag ditempelkan.
class WriteNfcScreen extends StatefulWidget {
  const WriteNfcScreen({super.key, required this.viewModel});

  final WriteNfcViewModel viewModel;

  @override
  State<WriteNfcScreen> createState() => _WriteNfcScreenState();
}

class _WriteNfcScreenState extends State<WriteNfcScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tulis NFC')),
    body: ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        _handleSideEffects(context);
        return _WriteNfcBody(
          viewModel: widget.viewModel,
          textController: _textController,
          focusNode: _focusNode,
          onWrite: _onWritePressed,
          onFormat: _onFormatPressed,
          onReset: _onReset,
        );
      },
    ),
  );

  void _handleSideEffects(BuildContext context) {
    final vm = widget.viewModel;
    switch (vm.state) {
      case WriteNfcState.success:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final isFormatting = vm.errorMessage == null && _textController.text.isEmpty;
          AppSnackBar.showSuccess(
            context,
            isFormatting ? '✅ Berhasil memformat tag NFC!' : '✅ Berhasil menulis ke tag NFC!',
          );
          _textController.clear();
        });
      case WriteNfcState.error:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackBar.showError(
            context,
            vm.errorMessage ?? 'Terjadi kesalahan yang tidak diketahui.',
          );
        });
      case WriteNfcState.formatted:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppSnackBar.showSuccess(
            context,
            vm.errorMessage ?? 'Tag berhasil diformat! Tempelkan kartu lagi untuk menulis.',
          );
        });
      case WriteNfcState.idle:
      case WriteNfcState.waiting:
        break;
    }
  }

  void _onWritePressed() {
    _focusNode.unfocus();
    widget.viewModel.startWriting(_textController.text);
  }

  void _onFormatPressed() {
    _focusNode.unfocus();
    widget.viewModel.startFormatting();
  }

  void _onReset() {
    _textController.clear();
    widget.viewModel.reset();
  }
}

class _WriteNfcBody extends StatelessWidget {
  const _WriteNfcBody({
    required this.viewModel,
    required this.textController,
    required this.focusNode,
    required this.onWrite,
    required this.onFormat,
    required this.onReset,
  });

  final WriteNfcViewModel viewModel;
  final TextEditingController textController;
  final FocusNode focusNode;
  final VoidCallback onWrite;
  final VoidCallback onFormat;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _WaitingSection(
            isWaiting: viewModel.isWaiting,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: textController,
            focusNode: focusNode,
            enabled: !viewModel.isWaiting,
            maxLines: 5,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Teks yang akan ditulis',
              hintText: 'Masukkan teks...',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 56),
                child: Icon(Icons.edit_rounded),
              ),
              helperText: 'NTAG213 ~90 karakter • NTAG215 ~460 • NTAG216 ~840',
              helperMaxLines: 1,
            ),
            maxLength: 840,
          ),
          const SizedBox(height: 24),
          _WriteStatusInfo(
            state: viewModel.state,
            errorMessage: viewModel.errorMessage,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 24),
          _ActionButtons(
            viewModel: viewModel,
            onWrite: onWrite,
            onFormat: onFormat,
            onReset: onReset,
          ),
        ],
      ),
    );
  }
}

class _WaitingSection extends StatelessWidget {
  const _WaitingSection({
    required this.isWaiting,
    required this.colorScheme,
    required this.textTheme,
  });

  final bool isWaiting;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: isWaiting
            ? PulsingRadarAnimation(
                key: const ValueKey('waiting'),
                size: 70,
                color: colorScheme.tertiary,
              )
            : _WriteIcon(key: const ValueKey('idle'), colorScheme: colorScheme),
      ),
      const SizedBox(height: 16),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          isWaiting
              ? 'Tempelkan tag NFC sekarang\nuntuk menulis data...'
              : 'Ketik teks lalu tempelkan\ntag NFC untuk menulis',
          key: ValueKey(isWaiting),
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

class _WriteIcon extends StatelessWidget {
  const _WriteIcon({super.key, required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Container(
    width: 110,
    height: 110,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: colorScheme.surfaceContainerHighest,
    ),
    child: Icon(
      Icons.edit_note_rounded,
      size: 52,
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
    ),
  );
}

class _WriteStatusInfo extends StatelessWidget {
  const _WriteStatusInfo({
    required this.state,
    required this.errorMessage,
    required this.colorScheme,
    required this.textTheme,
  });

  final WriteNfcState state;
  final String? errorMessage;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    if (state == WriteNfcState.success) {
      return _StatusBanner(
        icon: Icons.check_circle_rounded,
        message: 'Data berhasil ditulis ke tag NFC.',
        color: const Color(0xFF2E7D32),
        bgColor: const Color(0xFFE8F5E9),
        textTheme: textTheme,
      );
    }
    if (state == WriteNfcState.formatted && errorMessage != null) {
      return _StatusBanner(
        icon: Icons.check_circle_outline_rounded,
        message: errorMessage!,
        color: const Color(0xFF1565C0),
        bgColor: const Color(0xFFE3F2FD),
        textTheme: textTheme,
      );
    }
    if (state == WriteNfcState.error && errorMessage != null) {
      return _StatusBanner(
        icon: Icons.error_rounded,
        message: errorMessage!,
        color: colorScheme.error,
        bgColor: colorScheme.errorContainer,
        textTheme: textTheme,
      );
    }
    if (state == WriteNfcState.waiting) {
      return _StatusBanner(
        icon: Icons.info_rounded,
        message: 'Menunggu tag NFC ditempelkan...',
        color: colorScheme.tertiary,
        bgColor: colorScheme.tertiaryContainer,
        textTheme: textTheme,
      );
    }
    return const SizedBox.shrink();
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.message,
    required this.color,
    required this.bgColor,
    required this.textTheme,
  });

  final IconData icon;
  final String message;
  final Color color;
  final Color bgColor;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.viewModel,
    required this.onWrite,
    required this.onFormat,
    required this.onReset,
  });

  final WriteNfcViewModel viewModel;
  final VoidCallback onWrite;
  final VoidCallback onFormat;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ElevatedButton.icon(
        onPressed: viewModel.isWaiting ? null : onWrite,
        icon: Icon(
          viewModel.isWaiting
              ? Icons.hourglass_top_rounded
              : Icons.contactless_rounded,
        ),
        label: Text(
          viewModel.isWaiting ? 'Menunggu Tag...' : 'Tempelkan & Tulis',
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: viewModel.isWaiting ? null : onFormat,
        icon: const Icon(Icons.cleaning_services_rounded),
        label: const Text('Inisialisasi Tag (Format)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      ),
      if (viewModel.state != WriteNfcState.idle) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reset'),
        ),
      ],
    ],
  );
}
