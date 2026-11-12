import 'package:flutter/material.dart';

import '../features/chapters/home_shell.dart';
import '../l10n/app_localizations.dart';
import 'dependencies.dart';
import 'theme.dart';

class TukiApp extends StatelessWidget {
  const TukiApp({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      deps: deps,
      // Cambiar el idioma reconstruye textos y contenido sin reiniciar el
      // navegador: se conservan la pantalla actual y la obra abierta.
      child: ListenableBuilder(
        listenable: deps.preferences,
        builder: (context, _) => MaterialApp(
          title: kBrandName,
          debugShowCheckedModeBanner: false,
          theme: buildTukiTheme(),
          locale: Locale(deps.preferences.languageCode),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const HomeShell(),
        ),
      ),
    );
  }
}
