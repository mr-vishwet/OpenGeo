import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/place_tile.dart';
import '../widgets/slippy_map.dart';
import 'place_detail_screen.dart';

/// OpenGeo AI sheet: prompt, answered with parks around Pune.
///
/// The AI endpoint is not part of this build, so the conversation is seeded
/// with a labelled sample answer.
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _input = TextEditingController();
  final _messages = <(String, bool)>[
    ('Find accessible parks within 2 km', true),
    ('Here are 3 accessible parks near you (within 2 km):', false),
    ('Sample answer — the AI endpoint is not connected in this build.', false),
  ];

  static final _parks = placesInCategory('park').toList();
  static final _highlight = _parks.firstWhere((p) => p.name == 'Saras Baug');

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final value = _input.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _messages
        ..add((value, true))
        ..add(('Sample answer — the AI endpoint is not connected in this build.', false));
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(S.sm, S.sm, S.lg, S.sm),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Icon(Icons.auto_awesome, size: 20, color: scheme.primary),
                  const SizedBox(width: S.sm),
                  Expanded(child: Text('OpenGeo AI', style: text.titleLarge)),
                  IconButton(
                    icon: const Icon(Icons.history),
                    tooltip: 'History',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No saved conversations.')),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(S.lg, S.sm, S.lg, S.lg),
                children: [
                  for (final (message, fromUser) in _messages)
                    _Bubble(message: message, fromUser: fromUser),
                  const SizedBox(height: S.md),
                  SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(R.card),
                            child: SlippyMap(
                              center: puneCentre,
                              zoom: 12,
                              markers: [
                                for (final park in _parks)
                                  MapMarker(
                                    point: park.point,
                                    color: AppColors.modeRealtime,
                                    icon: Icons.park,
                                    size: 30,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Center(
                              child: Container(
                                width: 210,
                                height: 210,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.primary.withValues(alpha: 0.07),
                                  border: Border.all(
                                    color: scheme.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: S.md),
                  Material(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(R.card),
                    child: Container(
                      padding: const EdgeInsets.all(S.sm),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(R.card),
                        border: Border.all(color: scheme.outline),
                      ),
                      child: PlaceTile(
                        place: _highlight,
                        artSize: 56,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PlaceDetailScreen(place: _highlight),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: S.md),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: S.sm),
                      Text(
                        '${_parks.length} places found',
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(S.lg, S.sm, S.lg, S.md),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Ask something...',
                      ),
                    ),
                  ),
                  const SizedBox(width: S.sm),
                  IconButton.filled(
                    icon: const Icon(Icons.send, size: 18),
                    tooltip: 'Send',
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.fromUser});

  final String message;
  final bool fromUser;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: S.sm),
      child: Row(
        mainAxisAlignment:
            fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!fromUser) ...[
            const BrandMark(size: 28),
            const SizedBox(width: S.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: S.md,
                vertical: S.sm,
              ),
              decoration: BoxDecoration(
                color: fromUser ? scheme.primaryContainer : scheme.surface,
                borderRadius: BorderRadius.circular(R.card),
                border: Border.all(
                  color: fromUser ? Colors.transparent : scheme.outline,
                ),
              ),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: fromUser ? scheme.onPrimaryContainer : null,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
