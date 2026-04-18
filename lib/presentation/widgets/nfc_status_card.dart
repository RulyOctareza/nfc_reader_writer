import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_record.dart';
import 'package:nfc_reader_writer/domain/entities/nfc_tag_info.dart';

/// Card yang menampilkan status dan hasil baca NFC.
///
/// Menampilkan metadata tag (UID, Tech) dan hasil baca teks jika tersedia.
class NfcStatusCard extends StatelessWidget {
  const NfcStatusCard({super.key, this.tagInfo, this.errorMessage});

  final NfcTagInfo? tagInfo;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (tagInfo != null) {
      return _ResultCard(tagInfo: tagInfo!, colorScheme: colorScheme);
    }
    if (errorMessage != null) {
      return _ErrorCard(message: errorMessage!, colorScheme: colorScheme);
    }
    return _EmptyCard(colorScheme: colorScheme);
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.colorScheme});
  final ColorScheme colorScheme;

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
            'Belum ada data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hasil bacaan tag NFC akan muncul di sini.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.tagInfo, required this.colorScheme});
  final NfcTagInfo tagInfo;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final record = tagInfo.record;

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  tagInfo.isNdefFormatted
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: tagInfo.isNdefFormatted
                      ? const Color(0xFF2E7D32)
                      : colorScheme.tertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  tagInfo.isNdefFormatted
                      ? 'Tag Terformat NDEF'
                      : 'Tag Belum Terformat NDEF',
                  style: textTheme.labelMedium?.copyWith(
                    color: tagInfo.isNdefFormatted
                        ? const Color(0xFF2E7D32)
                        : colorScheme.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Metadata Section
            _MetadataRow(
              label: 'ID Kartu (UID)',
              value: tagInfo.uid,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _MetadataRow(
              label: 'Teknologi',
              value: tagInfo.techList.join(', '),
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
            if (tagInfo.ndefType != null) ...[
              const SizedBox(height: 12),
              _MetadataRow(
                label: 'Jenis NDEF',
                value: tagInfo.ndefType!,
                textTheme: textTheme,
                colorScheme: colorScheme,
              ),
            ],
            if (tagInfo.capacity != null) ...[
              const SizedBox(height: 12),
              _MetadataRow(
                label: 'Kapasitas',
                value: '${tagInfo.capacity} bytes',
                textTheme: textTheme,
                colorScheme: colorScheme,
              ),
            ],

            // Chip Technical Metadata Section
            if (tagInfo.rawTechData.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                'Metadata Teknis (Chip)',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...tagInfo.rawTechData.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MetadataRow(
                      label: e.key,
                      value: e.value.toString(),
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                  )),
            ],

            const Divider(height: 32),

            // Content Section
            if (record != null) ...[
              ...switch (record) {
                NfcTextRecord(text: final text, languageCode: final lang) => [
                    Text(
                      'Konten Teks',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      text,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MetaChip(
                      label: 'Bahasa: ${lang.toUpperCase()}',
                      colorScheme: colorScheme,
                    ),
                  ],
                NfcUriRecord(fullUri: final uri) => [
                    Text(
                      'Tautan (URL)',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      uri,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MetaChip(
                      label: 'Tipe: URI',
                      colorScheme: colorScheme,
                    ),
                  ],
                NfcMimeRecord(
                  mimeType: final type,
                  payload: final payload,
                  payloadAsString: final text
                ) =>
                  [
                    Text(
                      'MIME Media',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tipe: $type',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (text.isNotEmpty)
                      SelectableText(
                        text,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontFamily: 'monospace',
                        ),
                      )
                    else
                      Text(
                        'Binary Data (${payload.length} bytes)',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 12),
                    _MetaChip(
                      label: 'Tipe: NDEF MIME',
                      colorScheme: colorScheme,
                    ),
                  ],
              },
            ] else if (tagInfo.isNdefFormatted) ...[
              Text(
                'Tag terformat NDEF tapi kosong.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              Text(
                'Gunakan menu "Tulis NFC" untuk menginisialisasi tag ini agar bisa menyimpan data.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.colorScheme});
  final String message;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Card(
    color: colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_rounded, color: colorScheme.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.colorScheme});
  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: colorScheme.primary.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
