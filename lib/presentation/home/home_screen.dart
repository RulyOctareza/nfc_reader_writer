import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Layar utama (landing) dengan dua opsi: Baca atau Tulis NFC.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              _Header(colorScheme: colorScheme, textTheme: textTheme),
              const SizedBox(height: 56),
              _FeatureCard(
                icon: Icons.contactless_rounded,
                title: 'Baca NFC',
                description: 'Pindai dan baca konten teks dari tag NFC apapun.',
                color: colorScheme.primary,
                onTap: () => context.push('/read'),
              ),
              const SizedBox(height: 16),
              _FeatureCard(
                icon: Icons.edit_note_rounded,
                title: 'Tulis NFC',
                description:
                    'Tulis teks kustom Anda ke tag NFC yang dapat ditulis.',
                color: colorScheme.tertiary,
                onTap: () => context.push('/write'),
              ),
              const Spacer(flex: 2),
              _Footer(colorScheme: colorScheme),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.colorScheme, required this.textTheme});

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.nfc_rounded, size: 48, color: Colors.white),
      ),
      const SizedBox(height: 24),
      Text(
        'NFC Reader & Writer',
        textAlign: TextAlign.center,
        style: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 8),
      // Text(
      //   'Baca dan tulis tag NFC dengan mudah\nmenggunakan Samsung Galaxy S22',
      //   textAlign: TextAlign.center,
      //   style: textTheme.bodyMedium?.copyWith(
      //     color: colorScheme.onSurfaceVariant,
      //     height: 1.5,
      //   ),
      // ),
    ],
  );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // Icon(
      //   Icons.phone_android_rounded,
      //   size: 14,
      //   color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      // ),
      const SizedBox(width: 4),
      // Text(
      //   'Dioptimalkan untuk Samsung Galaxy S22',
      //   style: Theme.of(context).textTheme.labelSmall?.copyWith(
      //     color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      //   ),
      // ),
    ],
  );
}
