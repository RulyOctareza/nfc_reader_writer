import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_record.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_tag_info.dart';
import 'package:nfc_reader_writer/presentation/widgets/nfc_tag_metadata_section.dart';

/// Menampilkan hasil baca kartu Kencana: metadata tag + JSON + status signature.
class KencanaCardResult extends StatelessWidget {
  const KencanaCardResult({
    super.key,
    required this.tagInfo,
    required this.record,
    this.errorMessage,
  });

  final NfcTagInfo tagInfo;
  final NfcKencanaRecord record;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SignatureBanner(record: record, colorScheme: colorScheme),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              _InlineError(message: errorMessage!, colorScheme: colorScheme),
            ],
            const SizedBox(height: 20),
            NfcTagMetadataSection(tagInfo: tagInfo),
            const Divider(height: 32),
            Text(
              'Payload JSON',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                _prettyJson(record),
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _MetaRow(
              label: 'Signature (hex)',
              value: _formatHex(record.signature),
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
            _MetaRow(
              label: 'Ukuran payload',
              value: '${record.rawPayload.length} bytes',
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  String _prettyJson(NfcKencanaRecord record) {
    if (record.json != null) {
      return const JsonEncoder.withIndent('  ').convert(record.json);
    }
    return record.jsonText;
  }

  String _formatHex(List<int> bytes) => bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join(' ')
      .toUpperCase();
}

class _SignatureBanner extends StatelessWidget {
  const _SignatureBanner({
    required this.record,
    required this.colorScheme,
  });

  final NfcKencanaRecord record;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final bool? valid = record.signatureValid;
    final Color fg;
    final Color bg;
    final IconData icon;
    final String label;

    if (record.isLegacyFormat) {
      fg = colorScheme.tertiary;
      bg = colorScheme.tertiaryContainer;
      icon = Icons.history_rounded;
      label = 'Format lama (tanpa Ed25519)';
    } else if (valid == true) {
      fg = const Color(0xFF2E7D32);
      bg = const Color(0xFFE8F5E9);
      icon = Icons.verified_rounded;
      label = 'Signature Ed25519 valid';
    } else {
      fg = colorScheme.error;
      bg = colorScheme.errorContainer;
      icon = Icons.gpp_bad_rounded;
      label = 'Signature tidak valid';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    required this.textTheme,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
      ),
      const SizedBox(height: 2),
      SelectableText(
        value,
        style: textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.colorScheme});

  final String message;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colorScheme.error,
      height: 1.4,
    ),
  );
}
