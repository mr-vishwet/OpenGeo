import 'package:flutter/material.dart';

import '../models/map_mode.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shell_screen.dart';

/// "Select a Mode" — the five OpenGeo map modes from the reference.
class SelectModeScreen extends StatelessWidget {
  const SelectModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(S.lg, 0, S.lg, S.xl),
          children: [
            Text('Select a Mode', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: S.xs),
            Text(
              'Choose how you want to explore maps',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: S.lg),
            for (final mode in MapMode.values)
              Padding(
                padding: const EdgeInsets.only(bottom: S.md),
                child: _ModeCard(
                  mode: mode,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ShellScreen(mode: mode),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.onTap});

  final MapMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(R.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(R.card),
        child: Container(
          padding: const EdgeInsets.all(S.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(R.card),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            children: [
              ModeBadge(icon: mode.icon, color: mode.color),
              const SizedBox(width: S.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mode.label, style: text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      mode.subtitle,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
