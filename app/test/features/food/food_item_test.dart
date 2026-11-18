import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/food/domain/food_item.dart';

FoodItem _item({DateTime? addedOn, required DateTime bestBefore}) => FoodItem(
  id: 'a',
  name: 'Bread',
  amount: '1',
  category: FoodCategory.other,
  productCategory: 'Bakery',
  productType: 'Bread',
  storage: StorageLocation.pantry,
  bestBefore: bestBefore,
  addedOn: addedOn,
);

void main() {
  group('FoodItem.skipsWarning', () {
    final added = DateTime(2026, 11, 16, 14);

    test('a shelf life within the warning period skips it', () {
      expect(
        _item(
          addedOn: added,
          bestBefore: DateTime(2026, 11, 19),
        ).skipsWarning(7),
        isTrue,
      );
      expect(
        _item(
          addedOn: added,
          bestBefore: DateTime(2026, 11, 23),
        ).skipsWarning(7),
        isTrue,
      );
    });

    test('a longer shelf life does not', () {
      expect(
        _item(
          addedOn: added,
          bestBefore: DateTime(2026, 11, 24),
        ).skipsWarning(7),
        isFalse,
      );
    });

    test('an unknown added date does not', () {
      expect(
        _item(bestBefore: DateTime(2026, 11, 19)).skipsWarning(7),
        isFalse,
      );
    });

    test('an opened item is measured to the date it must be eaten by', () {
      // Best before in 10 days, but opened today it must be eaten within 4.
      final opened = _item(
        addedOn: added,
        bestBefore: DateTime(2026, 11, 26),
      ).opened(added);
      expect(opened.skipsWarning(7), isTrue);
      expect(
        _item(
          addedOn: added,
          bestBefore: DateTime(2026, 11, 26),
        ).skipsWarning(7),
        isFalse,
      );
    });

    test('opening it keeps the added date', () {
      final opened = _item(
        addedOn: added,
        bestBefore: DateTime(2026, 12, 30),
      ).opened(added);
      expect(opened.addedOn, added);
    });
  });
}
