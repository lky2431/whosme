import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_language.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:yourname_client/yourname_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'game/account_controller.dart';
import 'game/game_controller.dart';
import 'game/game_router.dart';
import 'game/paper_theme.dart';
import 'env.dart';

late final Client client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final url = appServerUrl;
  client = Client(url)..connectivityMonitor = FlutterConnectivityMonitor();
  client.authSessionManager = FlutterAuthSessionManager(
    storage: SecureClientAuthSuccessStorage(
      authSuccessStorageKey: 'yourname.auth.$url',
    ),
  );
  final controller = GameController(
    client,
    storageKey: 'yourname.seat.$url',
    account: AccountController(client),
  );
  final language = AppLanguage();
  await language.load();
  runApp(YournameApp(controller: controller, language: language));
  await controller.initialize();
}

class YournameApp extends StatefulWidget {
  const YournameApp({super.key, required this.controller, this.language});
  final GameController controller;
  final AppLanguage? language;
  @override
  State<YournameApp> createState() => _YournameAppState();
}

class _YournameAppState extends State<YournameApp> {
  late final AppLanguage language = widget.language ?? AppLanguage();
  late final GameRouter router = GameRouter(widget.controller);
  @override
  void dispose() {
    router.dispose();
    if (widget.language == null) language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LanguageScope(
    language: language,
    child: ListenableBuilder(
      listenable: language,
      builder: (context, _) => MaterialApp.router(
        title: 'Who’s Me?',
        locale: language.locale,
        supportedLocales: supportedLanguages,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        debugShowCheckedModeBanner: false,
        theme: paperTheme(),
        routerDelegate: router,
        routeInformationParser: const GameRouteParser(),
      ),
    ),
  );
}
