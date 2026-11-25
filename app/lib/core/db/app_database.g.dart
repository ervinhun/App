// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FoodItemsTable extends FoodItems
    with TableInfo<$FoodItemsTable, FoodItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<String> amount = GeneratedColumn<String>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FoodCategory, String> category =
      GeneratedColumn<String>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FoodCategory>($FoodItemsTable.$convertercategory);
  static const VerificationMeta _productCategoryMeta = const VerificationMeta(
    'productCategory',
  );
  @override
  late final GeneratedColumn<String> productCategory = GeneratedColumn<String>(
    'product_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productTypeMeta = const VerificationMeta(
    'productType',
  );
  @override
  late final GeneratedColumn<String> productType = GeneratedColumn<String>(
    'product_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<StorageLocation, String> storage =
      GeneratedColumn<String>(
        'storage',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<StorageLocation>($FoodItemsTable.$converterstorage);
  static const VerificationMeta _bestBeforeMeta = const VerificationMeta(
    'bestBefore',
  );
  @override
  late final GeneratedColumn<DateTime> bestBefore = GeneratedColumn<DateTime>(
    'best_before',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedOnMeta = const VerificationMeta(
    'openedOn',
  );
  @override
  late final GeneratedColumn<DateTime> openedOn = GeneratedColumn<DateTime>(
    'opened_on',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openedExpiresOnMeta = const VerificationMeta(
    'openedExpiresOn',
  );
  @override
  late final GeneratedColumn<DateTime> openedExpiresOn =
      GeneratedColumn<DateTime>(
        'opened_expires_on',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _onServerMeta = const VerificationMeta(
    'onServer',
  );
  @override
  late final GeneratedColumn<bool> onServer = GeneratedColumn<bool>(
    'on_server',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("on_server" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    amount,
    category,
    productCategory,
    productType,
    storage,
    bestBefore,
    openedOn,
    openedExpiresOn,
    onServer,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('product_category')) {
      context.handle(
        _productCategoryMeta,
        productCategory.isAcceptableOrUnknown(
          data['product_category']!,
          _productCategoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productCategoryMeta);
    }
    if (data.containsKey('product_type')) {
      context.handle(
        _productTypeMeta,
        productType.isAcceptableOrUnknown(
          data['product_type']!,
          _productTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productTypeMeta);
    }
    if (data.containsKey('best_before')) {
      context.handle(
        _bestBeforeMeta,
        bestBefore.isAcceptableOrUnknown(data['best_before']!, _bestBeforeMeta),
      );
    } else if (isInserting) {
      context.missing(_bestBeforeMeta);
    }
    if (data.containsKey('opened_on')) {
      context.handle(
        _openedOnMeta,
        openedOn.isAcceptableOrUnknown(data['opened_on']!, _openedOnMeta),
      );
    }
    if (data.containsKey('opened_expires_on')) {
      context.handle(
        _openedExpiresOnMeta,
        openedExpiresOn.isAcceptableOrUnknown(
          data['opened_expires_on']!,
          _openedExpiresOnMeta,
        ),
      );
    }
    if (data.containsKey('on_server')) {
      context.handle(
        _onServerMeta,
        onServer.isAcceptableOrUnknown(data['on_server']!, _onServerMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount'],
      )!,
      category: $FoodItemsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      productCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_category'],
      )!,
      productType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_type'],
      )!,
      storage: $FoodItemsTable.$converterstorage.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}storage'],
        )!,
      ),
      bestBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}best_before'],
      )!,
      openedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_on'],
      ),
      openedExpiresOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_expires_on'],
      ),
      onServer: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}on_server'],
      )!,
    );
  }

  @override
  $FoodItemsTable createAlias(String alias) {
    return $FoodItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FoodCategory, String, String> $convertercategory =
      const EnumNameConverter<FoodCategory>(FoodCategory.values);
  static JsonTypeConverter2<StorageLocation, String, String> $converterstorage =
      const EnumNameConverter<StorageLocation>(StorageLocation.values);
}

class FoodItemRow extends DataClass implements Insertable<FoodItemRow> {
  final String id;
  final String name;
  final String amount;
  final FoodCategory category;
  final String productCategory;
  final String productType;
  final StorageLocation storage;
  final DateTime bestBefore;
  final DateTime? openedOn;
  final DateTime? openedExpiresOn;

  /// Whether the backend has this item, so removing it needs a request.
  final bool onServer;
  const FoodItemRow({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.productCategory,
    required this.productType,
    required this.storage,
    required this.bestBefore,
    this.openedOn,
    this.openedExpiresOn,
    required this.onServer,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<String>(amount);
    {
      map['category'] = Variable<String>(
        $FoodItemsTable.$convertercategory.toSql(category),
      );
    }
    map['product_category'] = Variable<String>(productCategory);
    map['product_type'] = Variable<String>(productType);
    {
      map['storage'] = Variable<String>(
        $FoodItemsTable.$converterstorage.toSql(storage),
      );
    }
    map['best_before'] = Variable<DateTime>(bestBefore);
    if (!nullToAbsent || openedOn != null) {
      map['opened_on'] = Variable<DateTime>(openedOn);
    }
    if (!nullToAbsent || openedExpiresOn != null) {
      map['opened_expires_on'] = Variable<DateTime>(openedExpiresOn);
    }
    map['on_server'] = Variable<bool>(onServer);
    return map;
  }

  FoodItemsCompanion toCompanion(bool nullToAbsent) {
    return FoodItemsCompanion(
      id: Value(id),
      name: Value(name),
      amount: Value(amount),
      category: Value(category),
      productCategory: Value(productCategory),
      productType: Value(productType),
      storage: Value(storage),
      bestBefore: Value(bestBefore),
      openedOn: openedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(openedOn),
      openedExpiresOn: openedExpiresOn == null && nullToAbsent
          ? const Value.absent()
          : Value(openedExpiresOn),
      onServer: Value(onServer),
    );
  }

  factory FoodItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodItemRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<String>(json['amount']),
      category: $FoodItemsTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
      productCategory: serializer.fromJson<String>(json['productCategory']),
      productType: serializer.fromJson<String>(json['productType']),
      storage: $FoodItemsTable.$converterstorage.fromJson(
        serializer.fromJson<String>(json['storage']),
      ),
      bestBefore: serializer.fromJson<DateTime>(json['bestBefore']),
      openedOn: serializer.fromJson<DateTime?>(json['openedOn']),
      openedExpiresOn: serializer.fromJson<DateTime?>(json['openedExpiresOn']),
      onServer: serializer.fromJson<bool>(json['onServer']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<String>(amount),
      'category': serializer.toJson<String>(
        $FoodItemsTable.$convertercategory.toJson(category),
      ),
      'productCategory': serializer.toJson<String>(productCategory),
      'productType': serializer.toJson<String>(productType),
      'storage': serializer.toJson<String>(
        $FoodItemsTable.$converterstorage.toJson(storage),
      ),
      'bestBefore': serializer.toJson<DateTime>(bestBefore),
      'openedOn': serializer.toJson<DateTime?>(openedOn),
      'openedExpiresOn': serializer.toJson<DateTime?>(openedExpiresOn),
      'onServer': serializer.toJson<bool>(onServer),
    };
  }

  FoodItemRow copyWith({
    String? id,
    String? name,
    String? amount,
    FoodCategory? category,
    String? productCategory,
    String? productType,
    StorageLocation? storage,
    DateTime? bestBefore,
    Value<DateTime?> openedOn = const Value.absent(),
    Value<DateTime?> openedExpiresOn = const Value.absent(),
    bool? onServer,
  }) => FoodItemRow(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    productCategory: productCategory ?? this.productCategory,
    productType: productType ?? this.productType,
    storage: storage ?? this.storage,
    bestBefore: bestBefore ?? this.bestBefore,
    openedOn: openedOn.present ? openedOn.value : this.openedOn,
    openedExpiresOn: openedExpiresOn.present
        ? openedExpiresOn.value
        : this.openedExpiresOn,
    onServer: onServer ?? this.onServer,
  );
  FoodItemRow copyWithCompanion(FoodItemsCompanion data) {
    return FoodItemRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      productCategory: data.productCategory.present
          ? data.productCategory.value
          : this.productCategory,
      productType: data.productType.present
          ? data.productType.value
          : this.productType,
      storage: data.storage.present ? data.storage.value : this.storage,
      bestBefore: data.bestBefore.present
          ? data.bestBefore.value
          : this.bestBefore,
      openedOn: data.openedOn.present ? data.openedOn.value : this.openedOn,
      openedExpiresOn: data.openedExpiresOn.present
          ? data.openedExpiresOn.value
          : this.openedExpiresOn,
      onServer: data.onServer.present ? data.onServer.value : this.onServer,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodItemRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('productCategory: $productCategory, ')
          ..write('productType: $productType, ')
          ..write('storage: $storage, ')
          ..write('bestBefore: $bestBefore, ')
          ..write('openedOn: $openedOn, ')
          ..write('openedExpiresOn: $openedExpiresOn, ')
          ..write('onServer: $onServer')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amount,
    category,
    productCategory,
    productType,
    storage,
    bestBefore,
    openedOn,
    openedExpiresOn,
    onServer,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodItemRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.productCategory == this.productCategory &&
          other.productType == this.productType &&
          other.storage == this.storage &&
          other.bestBefore == this.bestBefore &&
          other.openedOn == this.openedOn &&
          other.openedExpiresOn == this.openedExpiresOn &&
          other.onServer == this.onServer);
}

class FoodItemsCompanion extends UpdateCompanion<FoodItemRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> amount;
  final Value<FoodCategory> category;
  final Value<String> productCategory;
  final Value<String> productType;
  final Value<StorageLocation> storage;
  final Value<DateTime> bestBefore;
  final Value<DateTime?> openedOn;
  final Value<DateTime?> openedExpiresOn;
  final Value<bool> onServer;
  final Value<int> rowid;
  const FoodItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.productCategory = const Value.absent(),
    this.productType = const Value.absent(),
    this.storage = const Value.absent(),
    this.bestBefore = const Value.absent(),
    this.openedOn = const Value.absent(),
    this.openedExpiresOn = const Value.absent(),
    this.onServer = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodItemsCompanion.insert({
    required String id,
    required String name,
    required String amount,
    required FoodCategory category,
    required String productCategory,
    required String productType,
    required StorageLocation storage,
    required DateTime bestBefore,
    this.openedOn = const Value.absent(),
    this.openedExpiresOn = const Value.absent(),
    this.onServer = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       amount = Value(amount),
       category = Value(category),
       productCategory = Value(productCategory),
       productType = Value(productType),
       storage = Value(storage),
       bestBefore = Value(bestBefore);
  static Insertable<FoodItemRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? amount,
    Expression<String>? category,
    Expression<String>? productCategory,
    Expression<String>? productType,
    Expression<String>? storage,
    Expression<DateTime>? bestBefore,
    Expression<DateTime>? openedOn,
    Expression<DateTime>? openedExpiresOn,
    Expression<bool>? onServer,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (productCategory != null) 'product_category': productCategory,
      if (productType != null) 'product_type': productType,
      if (storage != null) 'storage': storage,
      if (bestBefore != null) 'best_before': bestBefore,
      if (openedOn != null) 'opened_on': openedOn,
      if (openedExpiresOn != null) 'opened_expires_on': openedExpiresOn,
      if (onServer != null) 'on_server': onServer,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? amount,
    Value<FoodCategory>? category,
    Value<String>? productCategory,
    Value<String>? productType,
    Value<StorageLocation>? storage,
    Value<DateTime>? bestBefore,
    Value<DateTime?>? openedOn,
    Value<DateTime?>? openedExpiresOn,
    Value<bool>? onServer,
    Value<int>? rowid,
  }) {
    return FoodItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      productCategory: productCategory ?? this.productCategory,
      productType: productType ?? this.productType,
      storage: storage ?? this.storage,
      bestBefore: bestBefore ?? this.bestBefore,
      openedOn: openedOn ?? this.openedOn,
      openedExpiresOn: openedExpiresOn ?? this.openedExpiresOn,
      onServer: onServer ?? this.onServer,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $FoodItemsTable.$convertercategory.toSql(category.value),
      );
    }
    if (productCategory.present) {
      map['product_category'] = Variable<String>(productCategory.value);
    }
    if (productType.present) {
      map['product_type'] = Variable<String>(productType.value);
    }
    if (storage.present) {
      map['storage'] = Variable<String>(
        $FoodItemsTable.$converterstorage.toSql(storage.value),
      );
    }
    if (bestBefore.present) {
      map['best_before'] = Variable<DateTime>(bestBefore.value);
    }
    if (openedOn.present) {
      map['opened_on'] = Variable<DateTime>(openedOn.value);
    }
    if (openedExpiresOn.present) {
      map['opened_expires_on'] = Variable<DateTime>(openedExpiresOn.value);
    }
    if (onServer.present) {
      map['on_server'] = Variable<bool>(onServer.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('productCategory: $productCategory, ')
          ..write('productType: $productType, ')
          ..write('storage: $storage, ')
          ..write('bestBefore: $bestBefore, ')
          ..write('openedOn: $openedOn, ')
          ..write('openedExpiresOn: $openedExpiresOn, ')
          ..write('onServer: $onServer, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingChangesTable extends PendingChanges
    with TableInfo<$PendingChangesTable, PendingChange> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingChangesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ChangeKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ChangeKind>($PendingChangesTable.$converterkind);
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [seq, itemId, kind, changedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_changes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingChange> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_changedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  PendingChange map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingChange(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      kind: $PendingChangesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
    );
  }

  @override
  $PendingChangesTable createAlias(String alias) {
    return $PendingChangesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ChangeKind, String, String> $converterkind =
      const EnumNameConverter<ChangeKind>(ChangeKind.values);
}

class PendingChange extends DataClass implements Insertable<PendingChange> {
  final int seq;
  final String itemId;
  final ChangeKind kind;

  /// When the user made the change, which decides who wins when someone else
  /// changed the same item meanwhile.
  final DateTime changedAt;
  const PendingChange({
    required this.seq,
    required this.itemId,
    required this.kind,
    required this.changedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['item_id'] = Variable<String>(itemId);
    {
      map['kind'] = Variable<String>(
        $PendingChangesTable.$converterkind.toSql(kind),
      );
    }
    map['changed_at'] = Variable<DateTime>(changedAt);
    return map;
  }

  PendingChangesCompanion toCompanion(bool nullToAbsent) {
    return PendingChangesCompanion(
      seq: Value(seq),
      itemId: Value(itemId),
      kind: Value(kind),
      changedAt: Value(changedAt),
    );
  }

  factory PendingChange.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingChange(
      seq: serializer.fromJson<int>(json['seq']),
      itemId: serializer.fromJson<String>(json['itemId']),
      kind: $PendingChangesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'itemId': serializer.toJson<String>(itemId),
      'kind': serializer.toJson<String>(
        $PendingChangesTable.$converterkind.toJson(kind),
      ),
      'changedAt': serializer.toJson<DateTime>(changedAt),
    };
  }

  PendingChange copyWith({
    int? seq,
    String? itemId,
    ChangeKind? kind,
    DateTime? changedAt,
  }) => PendingChange(
    seq: seq ?? this.seq,
    itemId: itemId ?? this.itemId,
    kind: kind ?? this.kind,
    changedAt: changedAt ?? this.changedAt,
  );
  PendingChange copyWithCompanion(PendingChangesCompanion data) {
    return PendingChange(
      seq: data.seq.present ? data.seq.value : this.seq,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      kind: data.kind.present ? data.kind.value : this.kind,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingChange(')
          ..write('seq: $seq, ')
          ..write('itemId: $itemId, ')
          ..write('kind: $kind, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(seq, itemId, kind, changedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingChange &&
          other.seq == this.seq &&
          other.itemId == this.itemId &&
          other.kind == this.kind &&
          other.changedAt == this.changedAt);
}

class PendingChangesCompanion extends UpdateCompanion<PendingChange> {
  final Value<int> seq;
  final Value<String> itemId;
  final Value<ChangeKind> kind;
  final Value<DateTime> changedAt;
  const PendingChangesCompanion({
    this.seq = const Value.absent(),
    this.itemId = const Value.absent(),
    this.kind = const Value.absent(),
    this.changedAt = const Value.absent(),
  });
  PendingChangesCompanion.insert({
    this.seq = const Value.absent(),
    required String itemId,
    required ChangeKind kind,
    required DateTime changedAt,
  }) : itemId = Value(itemId),
       kind = Value(kind),
       changedAt = Value(changedAt);
  static Insertable<PendingChange> custom({
    Expression<int>? seq,
    Expression<String>? itemId,
    Expression<String>? kind,
    Expression<DateTime>? changedAt,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (itemId != null) 'item_id': itemId,
      if (kind != null) 'kind': kind,
      if (changedAt != null) 'changed_at': changedAt,
    });
  }

  PendingChangesCompanion copyWith({
    Value<int>? seq,
    Value<String>? itemId,
    Value<ChangeKind>? kind,
    Value<DateTime>? changedAt,
  }) {
    return PendingChangesCompanion(
      seq: seq ?? this.seq,
      itemId: itemId ?? this.itemId,
      kind: kind ?? this.kind,
      changedAt: changedAt ?? this.changedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $PendingChangesTable.$converterkind.toSql(kind.value),
      );
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingChangesCompanion(')
          ..write('seq: $seq, ')
          ..write('itemId: $itemId, ')
          ..write('kind: $kind, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaData extends DataClass implements Insertable<AppMetaData> {
  final String key;
  final String value;
  const AppMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(key: Value(key), value: Value(value));
  }

  factory AppMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppMetaData copyWith({String? key, String? value}) =>
      AppMetaData(key: key ?? this.key, value: value ?? this.value);
  AppMetaData copyWithCompanion(AppMetaCompanion data) {
    return AppMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoodItemsTable foodItems = $FoodItemsTable(this);
  late final $PendingChangesTable pendingChanges = $PendingChangesTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    foodItems,
    pendingChanges,
    appMeta,
  ];
}

typedef $$FoodItemsTableCreateCompanionBuilder = FoodItemsCompanion Function({
  required String id,
  required String name,
  required String amount,
  required FoodCategory category,
  required String productCategory,
  required String productType,
  required StorageLocation storage,
  required DateTime bestBefore,
  Value<DateTime?> openedOn,
  Value<DateTime?> openedExpiresOn,
  Value<bool> onServer,
  Value<int> rowid,
});
typedef $$FoodItemsTableUpdateCompanionBuilder = FoodItemsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> amount,
  Value<FoodCategory> category,
  Value<String> productCategory,
  Value<String> productType,
  Value<StorageLocation> storage,
  Value<DateTime> bestBefore,
  Value<DateTime?> openedOn,
  Value<DateTime?> openedExpiresOn,
  Value<bool> onServer,
  Value<int> rowid,
});

class $$FoodItemsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FoodCategory, FoodCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get productCategory => $composableBuilder(
    column: $table.productCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productType => $composableBuilder(
    column: $table.productType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<StorageLocation, StorageLocation, String>
  get storage => $composableBuilder(
    column: $table.storage,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get bestBefore => $composableBuilder(
    column: $table.bestBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedOn => $composableBuilder(
    column: $table.openedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedExpiresOn => $composableBuilder(
    column: $table.openedExpiresOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onServer => $composableBuilder(
    column: $table.onServer,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productCategory => $composableBuilder(
    column: $table.productCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productType => $composableBuilder(
    column: $table.productType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storage => $composableBuilder(
    column: $table.storage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get bestBefore => $composableBuilder(
    column: $table.bestBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedOn => $composableBuilder(
    column: $table.openedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedExpiresOn => $composableBuilder(
    column: $table.openedExpiresOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onServer => $composableBuilder(
    column: $table.onServer,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FoodCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get productCategory => $composableBuilder(
    column: $table.productCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productType => $composableBuilder(
    column: $table.productType,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<StorageLocation, String> get storage =>
      $composableBuilder(column: $table.storage, builder: (column) => column);

  GeneratedColumn<DateTime> get bestBefore => $composableBuilder(
    column: $table.bestBefore,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get openedOn =>
      $composableBuilder(column: $table.openedOn, builder: (column) => column);

  GeneratedColumn<DateTime> get openedExpiresOn => $composableBuilder(
    column: $table.openedExpiresOn,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onServer =>
      $composableBuilder(column: $table.onServer, builder: (column) => column);
}

class $$FoodItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodItemsTable,
          FoodItemRow,
          $$FoodItemsTableFilterComposer,
          $$FoodItemsTableOrderingComposer,
          $$FoodItemsTableAnnotationComposer,
          $$FoodItemsTableCreateCompanionBuilder,
          $$FoodItemsTableUpdateCompanionBuilder,
          (
            FoodItemRow,
            BaseReferences<_$AppDatabase, $FoodItemsTable, FoodItemRow>,
          ),
          FoodItemRow,
          PrefetchHooks Function()
        > {
  $$FoodItemsTableTableManager(_$AppDatabase db, $FoodItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> amount = const Value.absent(),
                Value<FoodCategory> category = const Value.absent(),
                Value<String> productCategory = const Value.absent(),
                Value<String> productType = const Value.absent(),
                Value<StorageLocation> storage = const Value.absent(),
                Value<DateTime> bestBefore = const Value.absent(),
                Value<DateTime?> openedOn = const Value.absent(),
                Value<DateTime?> openedExpiresOn = const Value.absent(),
                Value<bool> onServer = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodItemsCompanion(
                id: id,
                name: name,
                amount: amount,
                category: category,
                productCategory: productCategory,
                productType: productType,
                storage: storage,
                bestBefore: bestBefore,
                openedOn: openedOn,
                openedExpiresOn: openedExpiresOn,
                onServer: onServer,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String amount,
                required FoodCategory category,
                required String productCategory,
                required String productType,
                required StorageLocation storage,
                required DateTime bestBefore,
                Value<DateTime?> openedOn = const Value.absent(),
                Value<DateTime?> openedExpiresOn = const Value.absent(),
                Value<bool> onServer = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodItemsCompanion.insert(
                id: id,
                name: name,
                amount: amount,
                category: category,
                productCategory: productCategory,
                productType: productType,
                storage: storage,
                bestBefore: bestBefore,
                openedOn: openedOn,
                openedExpiresOn: openedExpiresOn,
                onServer: onServer,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoodItemsTable, FoodItemRow>(table),
                  BaseReferences<_$AppDatabase, $FoodItemsTable, FoodItemRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodItemsTable,
      FoodItemRow,
      $$FoodItemsTableFilterComposer,
      $$FoodItemsTableOrderingComposer,
      $$FoodItemsTableAnnotationComposer,
      $$FoodItemsTableCreateCompanionBuilder,
      $$FoodItemsTableUpdateCompanionBuilder,
      (
        FoodItemRow,
        BaseReferences<_$AppDatabase, $FoodItemsTable, FoodItemRow>,
      ),
      FoodItemRow,
      PrefetchHooks Function()
    >;
typedef $$PendingChangesTableCreateCompanionBuilder =
    PendingChangesCompanion Function({
      Value<int> seq,
      required String itemId,
      required ChangeKind kind,
      required DateTime changedAt,
    });
typedef $$PendingChangesTableUpdateCompanionBuilder =
    PendingChangesCompanion Function({
      Value<int> seq,
      Value<String> itemId,
      Value<ChangeKind> kind,
      Value<DateTime> changedAt,
    });

class $$PendingChangesTableFilterComposer
    extends Composer<_$AppDatabase, $PendingChangesTable> {
  $$PendingChangesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ChangeKind, ChangeKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingChangesTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingChangesTable> {
  $$PendingChangesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingChangesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingChangesTable> {
  $$PendingChangesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ChangeKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);
}

class $$PendingChangesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingChangesTable,
          PendingChange,
          $$PendingChangesTableFilterComposer,
          $$PendingChangesTableOrderingComposer,
          $$PendingChangesTableAnnotationComposer,
          $$PendingChangesTableCreateCompanionBuilder,
          $$PendingChangesTableUpdateCompanionBuilder,
          (
            PendingChange,
            BaseReferences<_$AppDatabase, $PendingChangesTable, PendingChange>,
          ),
          PendingChange,
          PrefetchHooks Function()
        > {
  $$PendingChangesTableTableManager(
    _$AppDatabase db,
    $PendingChangesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingChangesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingChangesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingChangesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<ChangeKind> kind = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
              }) => PendingChangesCompanion(
                seq: seq,
                itemId: itemId,
                kind: kind,
                changedAt: changedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String itemId,
                required ChangeKind kind,
                required DateTime changedAt,
              }) => PendingChangesCompanion.insert(
                seq: seq,
                itemId: itemId,
                kind: kind,
                changedAt: changedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingChangesTable, PendingChange>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingChangesTable,
                    PendingChange
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingChangesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingChangesTable,
      PendingChange,
      $$PendingChangesTableFilterComposer,
      $$PendingChangesTableOrderingComposer,
      $$PendingChangesTableAnnotationComposer,
      $$PendingChangesTableCreateCompanionBuilder,
      $$PendingChangesTableUpdateCompanionBuilder,
      (
        PendingChange,
        BaseReferences<_$AppDatabase, $PendingChangesTable, PendingChange>,
      ),
      PendingChange,
      PrefetchHooks Function()
    >;
typedef $$AppMetaTableCreateCompanionBuilder = AppMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppMetaTableUpdateCompanionBuilder = AppMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaTable,
          AppMetaData,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaData,
            BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>,
          ),
          AppMetaData,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => AppMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppMetaTable, AppMetaData>(table),
                  BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaTable,
      AppMetaData,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (AppMetaData, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaData>),
      AppMetaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoodItemsTableTableManager get foodItems =>
      $$FoodItemsTableTableManager(_db, _db.foodItems);
  $$PendingChangesTableTableManager get pendingChanges =>
      $$PendingChangesTableTableManager(_db, _db.pendingChanges);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
}
