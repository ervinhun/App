import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:app/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('flatten', () {
    test('turns nested objects into dot-separated keys', () {
      expect(
        AppLocalizations.flatten({
          'app': {'title': 'Title'},
          'home': {
            'counter': {'label': 'Label'},
          },
          'top': 'Top',
        }),
        {'app.title': 'Title', 'home.counter.label': 'Label', 'top': 'Top'},
      );
    });

    test('rejects non-string values', () {
      expect(
        () => AppLocalizations.flatten({
          'home': {'count': 1},
        }),
        throwsFormatException,
      );
    });
  });

  group('tr', () {
    final l10n = AppLocalizations(
      const Locale('pl'),
      {'greeting': 'Cześć {name}'},
      {'greeting': 'Hello {name}', 'onlyInEnglish': 'English'},
    );

    test('fills in placeholders', () {
      expect(l10n.tr('greeting', args: {'name': 'Ala'}), 'Cześć Ala');
    });

    test('falls back to English for keys missing in the locale', () {
      expect(l10n.tr('onlyInEnglish'), 'English');
    });

    test('returns the key itself when it is missing everywhere', () {
      expect(l10n.tr('does.not.exist'), 'does.not.exist');
    });
  });

  test('loads en.json from assets', () async {
    final l10n = await AppLocalizations.load(AppLocalizations.defaultLocale);
    expect(l10n.tr('app.title'), 'FridgeFriend');
  });

  test('every supported locale has a file with only keys from en.json', () {
    Map<String, String> read(String code) => AppLocalizations.flatten(
      jsonDecode(File('assets/l10n/$code.json').readAsStringSync())
          as Map<String, dynamic>,
    );

    final englishKeys = read('en').keys.toSet();
    for (final locale in AppLocalizations.supportedLocales) {
      final extraKeys = read(locale.languageCode).keys.toSet()
        ..removeAll(englishKeys);
      expect(extraKeys, isEmpty, reason: '${locale.languageCode}.json');
    }
  });
}
