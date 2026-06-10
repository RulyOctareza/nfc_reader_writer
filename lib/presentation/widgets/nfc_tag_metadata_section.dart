import 'package:flutter/material.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_tag_info.dart';

/// Menampilkan metadata teknis tag NFC: jenis chip, kapasitas, dan sinyal chip.
class NfcTagMetadataSection extends StatelessWidget {
  const NfcTagMetadataSection({
    super.key,
    required this.tagInfo,
    this.showDivider = false,
  });

  final NfcTagInfo tagInfo;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDivider) const Divider(height: 32),
        _MetadataRow(
          label: 'ID Kartu (UID)',
          value: tagInfo.uid,
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        if (tagInfo.chipModel != null) ...[
          _MetadataRow(
            label: 'Jenis Chip',
            value: tagInfo.chipModel!,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
        ],
        _MetadataRow(
          label: 'Teknologi',
          value: tagInfo.techList.join(', '),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        if (tagInfo.ndefType != null) ...[
          const SizedBox(height: 12),
          _MetadataRow(
            label: 'Standar NFC',
            value: tagInfo.ndefType!,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
        ],
        if (tagInfo.totalMemoryBytes != null) ...[
          const SizedBox(height: 12),
          _MetadataRow(
            label: 'Memori Chip',
            value: '${tagInfo.totalMemoryBytes} bytes',
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
        ],
        if (tagInfo.capacity != null) ...[
          const SizedBox(height: 12),
          _MetadataRow(
            label: 'Kapasitas NDEF',
            value: _formatNdefCapacity(tagInfo),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
        ],
        if (tagInfo.rawTechData.isNotEmpty) ...[
          const Divider(height: 32),
          Text(
            'Sinyal Teknis Chip',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...tagInfo.rawTechData.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MetadataRow(
                label: e.key,
                value: e.value.toString(),
                textTheme: textTheme,
                colorScheme: colorScheme,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatNdefCapacity(NfcTagInfo info) {
    final used = info.ndefUsedBytes;
    if (used != null && used > 0) {
      return '$used / ${info.capacity} bytes terpakai';
    }
    return '${info.capacity} bytes';
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
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
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontFamily: 'monospace',
        ),
      ),
    ],
  );
}
