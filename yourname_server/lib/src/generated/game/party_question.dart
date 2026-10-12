/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:serverpod/serverpod.dart' as _i1;
import 'package:yourname_server/src/generated/protocol.dart' as _i2;

abstract class PartyQuestion
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  PartyQuestion._({
    this.id,
    required this.slug,
    required this.category,
    required this.prompt,
    required this.choices,
    bool? enabled,
  }) : enabled = enabled ?? true;

  factory PartyQuestion({
    int? id,
    required String slug,
    required String category,
    required String prompt,
    required List<String> choices,
    bool? enabled,
  }) = _PartyQuestionImpl;

  factory PartyQuestion.fromJson(Map<String, dynamic> jsonSerialization) {
    return PartyQuestion(
      id: jsonSerialization['id'] as int?,
      slug: jsonSerialization['slug'] as String,
      category: jsonSerialization['category'] as String,
      prompt: jsonSerialization['prompt'] as String,
      choices: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['choices'],
      ),
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
    );
  }

  static final t = PartyQuestionTable();

  static const db = PartyQuestionRepository._();

  @override
  int? id;

  String slug;

  String category;

  String prompt;

  List<String> choices;

  bool enabled;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [PartyQuestion]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PartyQuestion copyWith({
    int? id,
    String? slug,
    String? category,
    String? prompt,
    List<String>? choices,
    bool? enabled,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PartyQuestion',
      if (id != null) 'id': id,
      'slug': slug,
      'category': category,
      'prompt': prompt,
      'choices': choices.toJson(),
      'enabled': enabled,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PartyQuestionInclude include() {
    return PartyQuestionInclude._();
  }

  static PartyQuestionIncludeList includeList({
    _i1.WhereExpressionBuilder<PartyQuestionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PartyQuestionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PartyQuestionTable>? orderByList,
    PartyQuestionInclude? include,
  }) {
    return PartyQuestionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PartyQuestion.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(PartyQuestion.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PartyQuestionImpl extends PartyQuestion {
  _PartyQuestionImpl({
    int? id,
    required String slug,
    required String category,
    required String prompt,
    required List<String> choices,
    bool? enabled,
  }) : super._(
         id: id,
         slug: slug,
         category: category,
         prompt: prompt,
         choices: choices,
         enabled: enabled,
       );

  /// Returns a shallow copy of this [PartyQuestion]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PartyQuestion copyWith({
    Object? id = _Undefined,
    String? slug,
    String? category,
    String? prompt,
    List<String>? choices,
    bool? enabled,
  }) {
    return PartyQuestion(
      id: id is int? ? id : this.id,
      slug: slug ?? this.slug,
      category: category ?? this.category,
      prompt: prompt ?? this.prompt,
      choices: choices ?? this.choices.map((e0) => e0).toList(),
      enabled: enabled ?? this.enabled,
    );
  }
}

class PartyQuestionUpdateTable extends _i1.UpdateTable<PartyQuestionTable> {
  PartyQuestionUpdateTable(super.table);

  _i1.ColumnValue<String, String> slug(String value) => _i1.ColumnValue(
    table.slug,
    value,
  );

  _i1.ColumnValue<String, String> category(String value) => _i1.ColumnValue(
    table.category,
    value,
  );

  _i1.ColumnValue<String, String> prompt(String value) => _i1.ColumnValue(
    table.prompt,
    value,
  );

  _i1.ColumnValue<List<String>, List<String>> choices(List<String> value) =>
      _i1.ColumnValue(
        table.choices,
        value,
      );

  _i1.ColumnValue<bool, bool> enabled(bool value) => _i1.ColumnValue(
    table.enabled,
    value,
  );
}

class PartyQuestionTable extends _i1.Table<int?> {
  PartyQuestionTable({super.tableRelation})
    : super(tableName: 'party_question') {
    updateTable = PartyQuestionUpdateTable(this);
    slug = _i1.ColumnString(
      'slug',
      this,
    );
    category = _i1.ColumnString(
      'category',
      this,
    );
    prompt = _i1.ColumnString(
      'prompt',
      this,
    );
    choices = _i1.ColumnSerializable<List<String>>(
      'choices',
      this,
    );
    enabled = _i1.ColumnBool(
      'enabled',
      this,
      hasDefault: true,
    );
  }

  late final PartyQuestionUpdateTable updateTable;

  late final _i1.ColumnString slug;

  late final _i1.ColumnString category;

  late final _i1.ColumnString prompt;

  late final _i1.ColumnSerializable<List<String>> choices;

  late final _i1.ColumnBool enabled;

  @override
  List<_i1.Column> get columns => [
    id,
    slug,
    category,
    prompt,
    choices,
    enabled,
  ];
}

class PartyQuestionInclude extends _i1.IncludeObject {
  PartyQuestionInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => PartyQuestion.t;
}

class PartyQuestionIncludeList extends _i1.IncludeList {
  PartyQuestionIncludeList._({
    _i1.WhereExpressionBuilder<PartyQuestionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PartyQuestion.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => PartyQuestion.t;
}

class PartyQuestionRepository {
  const PartyQuestionRepository._();

  /// Returns a list of [PartyQuestion]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<PartyQuestion>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PartyQuestionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PartyQuestionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PartyQuestionTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PartyQuestion>(
      where: where?.call(PartyQuestion.t),
      orderBy: orderBy?.call(PartyQuestion.t),
      orderByList: orderByList?.call(PartyQuestion.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [PartyQuestion] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<PartyQuestion?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PartyQuestionTable>? where,
    int? offset,
    _i1.OrderByBuilder<PartyQuestionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<PartyQuestionTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PartyQuestion>(
      where: where?.call(PartyQuestion.t),
      orderBy: orderBy?.call(PartyQuestion.t),
      orderByList: orderByList?.call(PartyQuestion.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PartyQuestion] by its [id] or null if no such row exists.
  Future<PartyQuestion?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PartyQuestion>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PartyQuestion]s in the list and returns the inserted rows.
  ///
  /// The returned [PartyQuestion]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<PartyQuestion>> insert(
    _i1.DatabaseSession session,
    List<PartyQuestion> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<PartyQuestion>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [PartyQuestion] and returns the inserted row.
  ///
  /// The returned [PartyQuestion] will have its `id` field set.
  Future<PartyQuestion> insertRow(
    _i1.DatabaseSession session,
    PartyQuestion row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<PartyQuestion>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [PartyQuestion]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<PartyQuestion>> update(
    _i1.DatabaseSession session,
    List<PartyQuestion> rows, {
    _i1.ColumnSelections<PartyQuestionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<PartyQuestion>(
      rows,
      columns: columns?.call(PartyQuestion.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PartyQuestion]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PartyQuestion> updateRow(
    _i1.DatabaseSession session,
    PartyQuestion row, {
    _i1.ColumnSelections<PartyQuestionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<PartyQuestion>(
      row,
      columns: columns?.call(PartyQuestion.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PartyQuestion] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PartyQuestion?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<PartyQuestionUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<PartyQuestion>(
      id,
      columnValues: columnValues(PartyQuestion.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PartyQuestion]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<PartyQuestion>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<PartyQuestionUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<PartyQuestionTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<PartyQuestionTable>? orderBy,
    _i1.OrderByListBuilder<PartyQuestionTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<PartyQuestion>(
      columnValues: columnValues(PartyQuestion.t.updateTable),
      where: where(PartyQuestion.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PartyQuestion.t),
      orderByList: orderByList?.call(PartyQuestion.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [PartyQuestion]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<PartyQuestion>> delete(
    _i1.DatabaseSession session,
    List<PartyQuestion> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<PartyQuestion>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [PartyQuestion].
  Future<PartyQuestion> deleteRow(
    _i1.DatabaseSession session,
    PartyQuestion row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PartyQuestion>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<PartyQuestion>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PartyQuestionTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<PartyQuestion>(
      where: where(PartyQuestion.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<PartyQuestionTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<PartyQuestion>(
      where: where?.call(PartyQuestion.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PartyQuestion] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<PartyQuestionTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PartyQuestion>(
      where: where(PartyQuestion.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
