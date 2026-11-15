import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:app/features/dashboard/presentation/widgets/food_filters.dart';
import 'package:app/features/food/domain/food_item.dart';
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

  test('plural picks the form the language uses for the count', () {
    final polish = AppLocalizations(const Locale('pl'), {
      'days.one': '{count} dzień',
      'days.few': '{count} dni (few)',
      'days.many': '{count} dni (many)',
      'days.other': '{count} dnia',
    });
    expect(polish.plural('days', 1), '1 dzień');
    expect(polish.plural('days', 3), '3 dni (few)');
    expect(polish.plural('days', 5), '5 dni (many)');
    expect(polish.plural('days', 22), '22 dni (few)');

    final english = AppLocalizations(const Locale('en'), {
      'days.one': '{count} day',
      'days.other': '{count} days',
    });
    expect(english.plural('days', 1), '1 day');
    expect(english.plural('days', 5), '5 days');
  });

  test('loads en.json from assets', () async {
    final l10n = await AppLocalizations.load(AppLocalizations.defaultLocale);
    expect(l10n.tr('app.title'), 'FridgeFriend');
  });

  Map<String, String> read(String code) => AppLocalizations.flatten(
    jsonDecode(File('assets/l10n/$code.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final english = read('en');

  // Plural forms differ between languages, so `x.few` in Polish is fine when
  // English has `x.one` and `x.other`.
  String withoutPluralForm(String key) =>
      key.replaceFirst(RegExp(r'\.(zero|one|two|few|many|other)$'), '');

  test('every supported locale has a file with only keys from en.json', () {
    final englishKeys = english.keys.map(withoutPluralForm).toSet();
    for (final locale in AppLocalizations.supportedLocales) {
      final extraKeys = read(
        locale.languageCode,
      ).keys.map(withoutPluralForm).toSet()..removeAll(englishKeys);
      expect(extraKeys, isEmpty, reason: '${locale.languageCode}.json');
    }
  });

  test('every key used in lib/ is in en.json', () {
    final namespaces = english.keys.map((key) => key.split('.').first).toSet();
    // A quoted, dotted name whose first part is one of en.json's sections,
    // e.g. 'login.email' or 'storage.${location.name}'.
    final keyLiteral = RegExp(
      r"'([a-z][a-zA-Z]*(?:\.(?:[a-zA-Z]+|\$\{[^}]+\}))+)'",
    );
    final missing = <String>[];
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      if (!source.contains('app_localizations.dart')) continue;
      for (final match in keyLiteral.allMatches(source)) {
        final key = match.group(1)!;
        if (!namespaces.contains(key.split('.').first)) continue;
        // `${...}` parts stand for any one segment.
        final pattern = RegExp(
          '^${key.split(RegExp(r'\$\{[^}]+\}')).map(RegExp.escape).join('[^.]+')}'
          r'(\.(zero|one|two|few|many|other))?$',
        );
        if (!english.keys.any(pattern.hasMatch)) {
          missing.add('$key (${file.path})');
        }
      }
    }
    expect(missing, isEmpty);
  });

  test('en.json has a string for each storage location and filter', () {
    for (final storage in StorageLocation.values) {
      for (final prefix in [
        'storage',
        'addFood.addTo',
        'addFood.typeNotKeptIn',
        'typePicker.keepsIn',
      ]) {
        expect(english, contains('$prefix.${storage.name}'));
      }
    }
    for (final filter in FoodFilter.values) {
      expect(english, contains('dashboard.filter.${filter.name}'));
    }
  });
}
