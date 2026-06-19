import 'package:flutter/material.dart';

import '../../app/theme.dart';

class MixelithScreenScaffold extends StatelessWidget {
  const MixelithScreenScaffold({required this.child, this.appBar, super.key});

  final PreferredSizeWidget? appBar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: MixelithColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [MixelithColors.backgroundDeep, MixelithColors.background],
          ),
        ),
        child: child,
      ),
    );
  }
}
