import 'package:flutter/material.dart';

import '../models/map_mode.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'select_mode_screen.dart';

/// Profile tab: current mode, app info, data attribution.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.mode});

  final MapMode mode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: S.xl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(S.lg, S.sm, S.lg, S.lg),
              child: Text('Profile', style: text.displaySmall),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: S.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.person, size: 28, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: S.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OpenGeo User', style: text.titleLarge),
                        const SizedBox(height: 2),
                        Text('Example profile · Pune, India', style: text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: S.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: S.lg),
              child: Material(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(R.card),
                child: InkWell(
                  borderRadius: BorderRadius.circular(R.card),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SelectModeScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(S.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(R.card),
                      border: Border.all(color: scheme.outline),
                    ),
                    child: Row(
                      children: [
                        ModeBadge(icon: mode.icon, color: mode.color),
                        const SizedBox(width: S.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Map mode', style: text.labelSmall),
                              const SizedBox(height: 2),
                              Text(mode.label, style: text.titleMedium),
                            ],
                          ),
                        ),
                        Text(
                          'Change',
                          style: text.labelLarge?.copyWith(color: scheme.primary),
                        ),
                        Icon(Icons.chevron_right, size: 18, color: scheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: S.lg),
            _Section(
              title: 'App',
              children: [
                _InfoRow(
                  icon: Icons.brightness_auto_outlined,
                  label: 'Appearance',
                  value: 'Follows system',
                ),
                _InfoRow(
                  icon: Icons.translate,
                  label: 'Language',
                  value: 'English',
                ),
                _InfoRow(
                  icon: Icons.cloud_outlined,
                  label: 'API endpoint',
                  value: 'localhost:8000',
                ),
              ],
            ),
            _Section(
              title: 'Data & attribution',
              children: const [
                _InfoRow(
                  icon: Icons.public,
                  label: 'Map data',
                  value: 'OpenStreetMap contributors',
                ),
                _InfoRow(
                  icon: Icons.layers_outlined,
                  label: 'Base tiles',
                  value: 'Esri World Street Map & Imagery',
                ),
                _InfoRow(
                  icon: Icons.star_outline,
                  label: 'Ratings & distances',
                  value: 'Sample values, not served by the API',
                ),
              ],
            ),
            _Section(
              title: 'About',
              children: [
                _InfoRow(
                  icon: Icons.info_outline,
                  label: 'OpenGeo Flutter client',
                  value: 'v1.0.0',
                ),
                _InfoRow(
                  icon: Icons.code,
                  label: 'Open source',
                  value: 'github.com/mr-vishwet/OpenGeo',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(S.lg, S.sm, S.lg, S.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: S.sm),
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(R.card),
              border: Border.all(color: scheme.outline),
            ),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(height: 1, indent: S.lg, color: scheme.outline),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: S.md, vertical: S.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: S.md),
          Expanded(child: Text(label, style: text.bodyMedium)),
          const SizedBox(width: S.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
