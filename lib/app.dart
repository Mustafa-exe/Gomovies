import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'ui/screens/home_screen.dart';
import 'ui/widgets/app_backdrop.dart';

class MediaApp extends StatelessWidget {
  const MediaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Media Hub',
      theme: AppTheme.dark(),
      builder: (context, child) {
        return AppBackdrop(
          child: child ?? const SizedBox.shrink(),
        );
      },
      themeAnimationDuration: const Duration(milliseconds: 450),
      themeAnimationCurve: Curves.easeOutCubic,
      home: const HomeScreen(),
      
    );
  }
}
