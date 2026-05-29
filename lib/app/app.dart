import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/presentation/home_screen.dart';
import 'providers.dart';
import 'theme.dart';

class MixelithApp extends ConsumerWidget {
  const MixelithApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(appTitleProvider);

    return MaterialApp(
      title: title,
      theme: buildMixelithTheme(),
      home: const HomeScreen(),
    );
  }
}
