import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morph_orbs/morph_orbs.dart';

void main() => runApp(const GalleryApp());

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'morph_orbs',
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const GalleryPage(),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  MorphOrbState _state = MorphOrbState.idle;
  MorphOrbVariant? _variant;
  Timer? _timer;

  static const _flow = [
    (MorphOrbState.thinking, Duration(milliseconds: 1600)),
    (MorphOrbState.processing, Duration(milliseconds: 1800)),
    (MorphOrbState.generating, Duration(milliseconds: 2200)),
    (MorphOrbState.success, Duration(milliseconds: 1800)),
    (MorphOrbState.idle, Duration.zero),
  ];

  void _play([int step = 0]) {
    _timer?.cancel();
    if (step >= _flow.length) {
      return;
    }
    final (next, hold) = _flow[step];
    setState(() => _state = next);
    if (step + 1 < _flow.length) {
      _timer = Timer(hold, () => _play(step + 1));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('morph_orbs')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: MorphOrb(
              state: _state,
              variant: _variant,
              size: 120,
              style: MorphOrbStyle(
                successColor: Colors.greenAccent,
                errorColor: scheme.error,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in MorphOrbState.values)
                ChoiceChip(
                  label: Text(s.name),
                  selected: s == _state,
                  onSelected: (_) {
                    _timer?.cancel();
                    setState(() => _state = s);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('default'),
                selected: _variant == null,
                onSelected: (_) => setState(() => _variant = null),
              ),
              for (final v in MorphOrbVariant.values)
                ChoiceChip(
                  label: Text(v.name),
                  selected: v == _variant,
                  onSelected: (_) => setState(() => _variant = v),
                ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _play,
            child: const Text('Play reply flow'),
          ),
          const SizedBox(height: 32),
          Text('All variants', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final v in MorphOrbVariant.values)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MorphOrb(variant: v, size: 56),
                    const SizedBox(height: 4),
                    Text(v.name, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Sizes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MorphOrb(size: 24),
              MorphOrb(size: 40),
              MorphOrb(size: 64),
            ],
          ),
        ],
      ),
    );
  }
}
