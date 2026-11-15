import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

/// Translated UI strings, loaded from `assets/l10n/<languageCode>.json`.
///
/// English (`en.json`) is the source of truth: every key must exist there, and
/// any key missing from another language falls back to its English value.
///
/// Keys are dot-separated paths into the (nested) JSON, e.g. `home.title`.
/// Values may contain `{name}` placeholders filled in via [tr]'s `args`.
/// Text that depends on a number is an object of plural forms, read with
/// [plural]: `{"one": "{count} day", "other": "{count} days"}`.
///
/// To add a language: create `assets/l10n/<code>.json` and add its [Locale]
/// to [supportedLocales].
class AppLocalizations {
  AppLocalizations(this.locale, this._strings, [this._fallback = const {}]);

  static const defaultLocale = Locale('en');

  static const supportedLocales = [defaultLocale];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Our strings plus Flutter's own (date pickers, back buttons, ...), for
  /// `MaterialApp.localizationsDelegates`.
  static const localizationsDelegates = <LocalizationsDelegate<Object>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  final Locale locale;
  final Map<String, String> _strings;
  final Map<String, String> _fallback;

  static AppLocalizations of(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(l10n != null, 'No AppLocalizations found in context');
    return l10n!;
  }

  static final _cache = <String, Map<String, String>>{};

  /// Reads every supported language's file. Call it before `runApp` so [load]
  /// can hand out strings synchronously; otherwise the first frames render
  /// before any text is available.
  static Future<void> preload() async {
    for (final locale in supportedLocales) {
      _cache[locale.languageCode] ??= await _loadStrings(locale.languageCode);
    }
  }

  static Future<AppLocalizations> load(Locale locale) {
    final strings = _cache[locale.languageCode];
    final fallback = _cache[defaultLocale.languageCode];
    if (strings == null || fallback == null) {
      return preload().then((_) => load(locale));
    }
    // So DateFormat and NumberFormat follow the app's language.
    Intl.defaultLocale = locale.toLanguageTag();
    return SynchronousFuture(AppLocalizations(locale, strings, fallback));
  }

  static Future<Map<String, String>> _loadStrings(String languageCode) async {
    final source = await rootBundle.loadString(
      'assets/l10n/$languageCode.json',
    );
    return flatten(jsonDecode(source) as Map<String, dynamic>);
  }

  /// Flattens nested JSON into dot-separated keys:
  /// `{"home": {"title": "Hi"}}` becomes `{"home.title": "Hi"}`.
  @visibleForTesting
  static Map<String, String> flatten(
    Map<String, dynamic> json, [
    String prefix = '',
  ]) {
    final result = <String, String>{};
    json.forEach((key, value) {
      final path = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        result.addAll(flatten(value, path));
      } else if (value is String) {
        result[path] = value;
      } else {
        throw FormatException('Translation "$path" must be a string or object');
      }
    });
    return result;
  }

  /// Returns the string for [key], with each `{name}` placeholder replaced by
  /// `args[name]`. A missing key returns the key itself so it is easy to spot
  /// in the UI.
  String tr(String key, {Map<String, Object> args = const {}}) {
    final template = _strings[key] ?? _fallback[key];
    if (template == null) {
      debugPrint('AppLocalizations: missing key "$key" for $locale');
      return key;
    }
    var value = template;
    for (final MapEntry(key: name, value: arg) in args.entries) {
      value = value.replaceAll('{$name}', '$arg');
    }
    return value;
  }

  /// Returns the plural form of [key] that suits [count] in this language:
  /// `key.one`, `key.other` and, where the language has them, `key.zero`,
  /// `key.two`, `key.few` or `key.many`. `{count}` is filled in with [count].
  String plural(String key, num count, {Map<String, Object> args = const {}}) {
    String? form(String name) {
      final formKey = '$key.$name';
      final exists =
          _strings.containsKey(formKey) || _fallback.containsKey(formKey);
      return exists ? formKey : null;
    }

    final formKey = Intl.pluralLogic(
      count,
      locale: locale.toLanguageTag(),
      zero: form('zero'),
      one: form('one'),
      two: form('two'),
      few: form('few'),
      many: form('many'),
      other: '$key.other',
    );
    return tr(formKey, args: {'count': count, ...args});
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
