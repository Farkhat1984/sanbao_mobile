/// Root application widget.
///
/// Configures [MaterialApp.router] with the Sanbao theme,
/// localization, and GoRouter navigation. This is the single
/// entry point for the widget tree, wrapped by [ProviderScope]
/// in main.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/routes.dart';
import 'package:sanbao_flutter/core/storage/preferences.dart';
import 'package:sanbao_flutter/core/theme/app_theme.dart';

/// The root widget of the Sanbao application.
///
/// Watches:
/// - [routerProvider] for navigation configuration
/// - [preferencesProvider] for theme mode, locale, and text scale
///
/// Provides:
/// - Light and dark [ThemeData] from [SanbaoTheme]
/// - Russian and English locale support
/// - Global text scaling via [MediaQuery]
class SanbaoApp extends ConsumerWidget {
  const SanbaoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final prefs = ref.watch(preferencesProvider);

    final themeMode = prefs.themeMode;
    final locale = Locale(prefs.locale);

    return MaterialApp.router(
      title: 'Sanbao',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: SanbaoTheme.light,
      darkTheme: SanbaoTheme.dark,
      themeMode: themeMode,

      // Router
      routerConfig: router,

      // Localization
      locale: locale,
      supportedLocales: const [
        Locale('ru'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Builder for global overlays, text scaling, and visual adjustments
      builder: (context, child) {
        // Apply custom text scale from user preferences
        final textScale = prefs.textScale;

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
