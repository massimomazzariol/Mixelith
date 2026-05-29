import 'package:flutter/material.dart';

import '../../app/theme.dart';

class MixelithLoadingOverlay extends StatelessWidget {
  const MixelithLoadingOverlay({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.56),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: MixelithColors.surfaceElevated,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 14),
                  Text(message, style: Theme.of(context).textTheme.labelLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
