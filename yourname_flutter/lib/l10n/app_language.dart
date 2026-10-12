import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'zh_hant.dart';

const supportedLanguages = [
  Locale('en'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
];

/// A device preference only: it never changes room state or answer indices.
class AppLanguage extends ChangeNotifier {
  AppLanguage({Locale? locale}) : _locale = locale;
  Locale? _locale;
  Locale get locale =>
      resolve(_locale ?? WidgetsBinding.instance.platformDispatcher.locale);
  static Locale resolve(Locale locale) => locale.languageCode == 'zh'
      ? supportedLanguages[1]
      : supportedLanguages[0];
  Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(
        'yourname.language',
      );
      if (saved != null) {
        _locale = saved == 'zh-Hant'
            ? supportedLanguages[1]
            : supportedLanguages[0];
      }
    } catch (_) {
      /* Device language remains available if storage is blocked. */
    }
    notifyListeners();
  }

  Future<void> select(Locale value) async {
    _locale = resolve(value);
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(
        'yourname.language',
        locale.languageCode == 'zh' ? 'zh-Hant' : 'en',
      );
    } catch (_) {
      /* Selection still works for this session. */
    }
  }
}

class LanguageScope extends InheritedNotifier<AppLanguage> {
  const LanguageScope({
    super.key,
    required AppLanguage language,
    required super.child,
  }) : super(notifier: language);
  static AppLanguage? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()?.notifier;
}

/// Explicit source messages keep names, room codes and identifiers untouched.
String translate(
  Locale locale,
  String source, [
  List<Object?> arguments = const [],
]) {
  final pattern = locale.languageCode == 'zh'
      ? traditionalChinese[source] ?? source
      : source;
  return pattern.replaceAllMapped(RegExp(r'\{(\d+)\}'), (match) {
    final index = int.parse(match[1]!);
    return index < arguments.length ? '${arguments[index]}' : match[0]!;
  });
}

extension LocalizedContext on BuildContext {
  String tr(String source, [List<Object?> arguments = const []]) =>
      translate(Localizations.localeOf(this), source, arguments);
}

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});
  @override
  Widget build(BuildContext context) => PopupMenuButton<Locale>(
    tooltip: context.tr('Language'),
    onSelected: (locale) => LanguageScope.of(context)?.select(locale),
    itemBuilder: (_) => [
      for (final locale in supportedLanguages)
        CheckedPopupMenuItem(
          value: locale,
          checked:
              Localizations.localeOf(context).languageCode ==
              locale.languageCode,
          child: Text(locale.languageCode == 'zh' ? '繁體中文' : 'English'),
        ),
    ],
    icon: const Icon(Icons.language),
  );
}
