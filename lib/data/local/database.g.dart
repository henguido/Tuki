// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DrawingsTable extends Drawings
    with TableInfo<$DrawingsTable, DrawingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DrawingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _drawingIdMeta = const VerificationMeta(
    'drawingId',
  );
  @override
  late final GeneratedColumn<String> drawingId = GeneratedColumn<String>(
    'drawing_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateRevisionMeta = const VerificationMeta(
    'templateRevision',
  );
  @override
  late final GeneratedColumn<int> templateRevision = GeneratedColumn<int>(
    'template_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentVersionMeta = const VerificationMeta(
    'documentVersion',
  );
  @override
  late final GeneratedColumn<int> documentVersion = GeneratedColumn<int>(
    'document_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saveRevisionMeta = const VerificationMeta(
    'saveRevision',
  );
  @override
  late final GeneratedColumn<int> saveRevision = GeneratedColumn<int>(
    'save_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fillsJsonMeta = const VerificationMeta(
    'fillsJson',
  );
  @override
  late final GeneratedColumn<String> fillsJson = GeneratedColumn<String>(
    'fills_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strokesJsonMeta = const VerificationMeta(
    'strokesJson',
  );
  @override
  late final GeneratedColumn<String> strokesJson = GeneratedColumn<String>(
    'strokes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    drawingId,
    chapterId,
    pageId,
    templateRevision,
    documentVersion,
    saveRevision,
    fillsJson,
    strokesJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drawings';
  @override
  VerificationContext validateIntegrity(
    Insertable<DrawingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('drawing_id')) {
      context.handle(
        _drawingIdMeta,
        drawingId.isAcceptableOrUnknown(data['drawing_id']!, _drawingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_drawingIdMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('template_revision')) {
      context.handle(
        _templateRevisionMeta,
        templateRevision.isAcceptableOrUnknown(
          data['template_revision']!,
          _templateRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateRevisionMeta);
    }
    if (data.containsKey('document_version')) {
      context.handle(
        _documentVersionMeta,
        documentVersion.isAcceptableOrUnknown(
          data['document_version']!,
          _documentVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_documentVersionMeta);
    }
    if (data.containsKey('save_revision')) {
      context.handle(
        _saveRevisionMeta,
        saveRevision.isAcceptableOrUnknown(
          data['save_revision']!,
          _saveRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saveRevisionMeta);
    }
    if (data.containsKey('fills_json')) {
      context.handle(
        _fillsJsonMeta,
        fillsJson.isAcceptableOrUnknown(data['fills_json']!, _fillsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_fillsJsonMeta);
    }
    if (data.containsKey('strokes_json')) {
      context.handle(
        _strokesJsonMeta,
        strokesJson.isAcceptableOrUnknown(
          data['strokes_json']!,
          _strokesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_strokesJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {drawingId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {chapterId, pageId},
  ];
  @override
  DrawingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DrawingRow(
      drawingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}drawing_id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_id'],
      )!,
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      )!,
      templateRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_revision'],
      )!,
      documentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}document_version'],
      )!,
      saveRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}save_revision'],
      )!,
      fillsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fills_json'],
      )!,
      strokesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strokes_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DrawingsTable createAlias(String alias) {
    return $DrawingsTable(attachedDatabase, alias);
  }
}

class DrawingRow extends DataClass implements Insertable<DrawingRow> {
  final String drawingId;
  final String chapterId;
  final String pageId;
  final int templateRevision;

  /// Formato de fillsJson / strokesJson.
  final int documentVersion;

  /// Aumenta con cada edición confirmada.
  final int saveRevision;

  /// `{ "regionId": "#RRGGBB" }`
  final String fillsJson;

  /// Operaciones ordenadas de pincel y borrador.
  final String strokesJson;

  /// Microsegundos desde la época Unix, en UTC.
  final int updatedAt;
  const DrawingRow({
    required this.drawingId,
    required this.chapterId,
    required this.pageId,
    required this.templateRevision,
    required this.documentVersion,
    required this.saveRevision,
    required this.fillsJson,
    required this.strokesJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['drawing_id'] = Variable<String>(drawingId);
    map['chapter_id'] = Variable<String>(chapterId);
    map['page_id'] = Variable<String>(pageId);
    map['template_revision'] = Variable<int>(templateRevision);
    map['document_version'] = Variable<int>(documentVersion);
    map['save_revision'] = Variable<int>(saveRevision);
    map['fills_json'] = Variable<String>(fillsJson);
    map['strokes_json'] = Variable<String>(strokesJson);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DrawingsCompanion toCompanion(bool nullToAbsent) {
    return DrawingsCompanion(
      drawingId: Value(drawingId),
      chapterId: Value(chapterId),
      pageId: Value(pageId),
      templateRevision: Value(templateRevision),
      documentVersion: Value(documentVersion),
      saveRevision: Value(saveRevision),
      fillsJson: Value(fillsJson),
      strokesJson: Value(strokesJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory DrawingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DrawingRow(
      drawingId: serializer.fromJson<String>(json['drawingId']),
      chapterId: serializer.fromJson<String>(json['chapterId']),
      pageId: serializer.fromJson<String>(json['pageId']),
      templateRevision: serializer.fromJson<int>(json['templateRevision']),
      documentVersion: serializer.fromJson<int>(json['documentVersion']),
      saveRevision: serializer.fromJson<int>(json['saveRevision']),
      fillsJson: serializer.fromJson<String>(json['fillsJson']),
      strokesJson: serializer.fromJson<String>(json['strokesJson']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'drawingId': serializer.toJson<String>(drawingId),
      'chapterId': serializer.toJson<String>(chapterId),
      'pageId': serializer.toJson<String>(pageId),
      'templateRevision': serializer.toJson<int>(templateRevision),
      'documentVersion': serializer.toJson<int>(documentVersion),
      'saveRevision': serializer.toJson<int>(saveRevision),
      'fillsJson': serializer.toJson<String>(fillsJson),
      'strokesJson': serializer.toJson<String>(strokesJson),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  DrawingRow copyWith({
    String? drawingId,
    String? chapterId,
    String? pageId,
    int? templateRevision,
    int? documentVersion,
    int? saveRevision,
    String? fillsJson,
    String? strokesJson,
    int? updatedAt,
  }) => DrawingRow(
    drawingId: drawingId ?? this.drawingId,
    chapterId: chapterId ?? this.chapterId,
    pageId: pageId ?? this.pageId,
    templateRevision: templateRevision ?? this.templateRevision,
    documentVersion: documentVersion ?? this.documentVersion,
    saveRevision: saveRevision ?? this.saveRevision,
    fillsJson: fillsJson ?? this.fillsJson,
    strokesJson: strokesJson ?? this.strokesJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DrawingRow copyWithCompanion(DrawingsCompanion data) {
    return DrawingRow(
      drawingId: data.drawingId.present ? data.drawingId.value : this.drawingId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      templateRevision: data.templateRevision.present
          ? data.templateRevision.value
          : this.templateRevision,
      documentVersion: data.documentVersion.present
          ? data.documentVersion.value
          : this.documentVersion,
      saveRevision: data.saveRevision.present
          ? data.saveRevision.value
          : this.saveRevision,
      fillsJson: data.fillsJson.present ? data.fillsJson.value : this.fillsJson,
      strokesJson: data.strokesJson.present
          ? data.strokesJson.value
          : this.strokesJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DrawingRow(')
          ..write('drawingId: $drawingId, ')
          ..write('chapterId: $chapterId, ')
          ..write('pageId: $pageId, ')
          ..write('templateRevision: $templateRevision, ')
          ..write('documentVersion: $documentVersion, ')
          ..write('saveRevision: $saveRevision, ')
          ..write('fillsJson: $fillsJson, ')
          ..write('strokesJson: $strokesJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    drawingId,
    chapterId,
    pageId,
    templateRevision,
    documentVersion,
    saveRevision,
    fillsJson,
    strokesJson,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DrawingRow &&
          other.drawingId == this.drawingId &&
          other.chapterId == this.chapterId &&
          other.pageId == this.pageId &&
          other.templateRevision == this.templateRevision &&
          other.documentVersion == this.documentVersion &&
          other.saveRevision == this.saveRevision &&
          other.fillsJson == this.fillsJson &&
          other.strokesJson == this.strokesJson &&
          other.updatedAt == this.updatedAt);
}

class DrawingsCompanion extends UpdateCompanion<DrawingRow> {
  final Value<String> drawingId;
  final Value<String> chapterId;
  final Value<String> pageId;
  final Value<int> templateRevision;
  final Value<int> documentVersion;
  final Value<int> saveRevision;
  final Value<String> fillsJson;
  final Value<String> strokesJson;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DrawingsCompanion({
    this.drawingId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.pageId = const Value.absent(),
    this.templateRevision = const Value.absent(),
    this.documentVersion = const Value.absent(),
    this.saveRevision = const Value.absent(),
    this.fillsJson = const Value.absent(),
    this.strokesJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DrawingsCompanion.insert({
    required String drawingId,
    required String chapterId,
    required String pageId,
    required int templateRevision,
    required int documentVersion,
    required int saveRevision,
    required String fillsJson,
    required String strokesJson,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : drawingId = Value(drawingId),
       chapterId = Value(chapterId),
       pageId = Value(pageId),
       templateRevision = Value(templateRevision),
       documentVersion = Value(documentVersion),
       saveRevision = Value(saveRevision),
       fillsJson = Value(fillsJson),
       strokesJson = Value(strokesJson),
       updatedAt = Value(updatedAt);
  static Insertable<DrawingRow> custom({
    Expression<String>? drawingId,
    Expression<String>? chapterId,
    Expression<String>? pageId,
    Expression<int>? templateRevision,
    Expression<int>? documentVersion,
    Expression<int>? saveRevision,
    Expression<String>? fillsJson,
    Expression<String>? strokesJson,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (drawingId != null) 'drawing_id': drawingId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (pageId != null) 'page_id': pageId,
      if (templateRevision != null) 'template_revision': templateRevision,
      if (documentVersion != null) 'document_version': documentVersion,
      if (saveRevision != null) 'save_revision': saveRevision,
      if (fillsJson != null) 'fills_json': fillsJson,
      if (strokesJson != null) 'strokes_json': strokesJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DrawingsCompanion copyWith({
    Value<String>? drawingId,
    Value<String>? chapterId,
    Value<String>? pageId,
    Value<int>? templateRevision,
    Value<int>? documentVersion,
    Value<int>? saveRevision,
    Value<String>? fillsJson,
    Value<String>? strokesJson,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return DrawingsCompanion(
      drawingId: drawingId ?? this.drawingId,
      chapterId: chapterId ?? this.chapterId,
      pageId: pageId ?? this.pageId,
      templateRevision: templateRevision ?? this.templateRevision,
      documentVersion: documentVersion ?? this.documentVersion,
      saveRevision: saveRevision ?? this.saveRevision,
      fillsJson: fillsJson ?? this.fillsJson,
      strokesJson: strokesJson ?? this.strokesJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (drawingId.present) {
      map['drawing_id'] = Variable<String>(drawingId.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (templateRevision.present) {
      map['template_revision'] = Variable<int>(templateRevision.value);
    }
    if (documentVersion.present) {
      map['document_version'] = Variable<int>(documentVersion.value);
    }
    if (saveRevision.present) {
      map['save_revision'] = Variable<int>(saveRevision.value);
    }
    if (fillsJson.present) {
      map['fills_json'] = Variable<String>(fillsJson.value);
    }
    if (strokesJson.present) {
      map['strokes_json'] = Variable<String>(strokesJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DrawingsCompanion(')
          ..write('drawingId: $drawingId, ')
          ..write('chapterId: $chapterId, ')
          ..write('pageId: $pageId, ')
          ..write('templateRevision: $templateRevision, ')
          ..write('documentVersion: $documentVersion, ')
          ..write('saveRevision: $saveRevision, ')
          ..write('fillsJson: $fillsJson, ')
          ..write('strokesJson: $strokesJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$TukiDatabase extends GeneratedDatabase {
  _$TukiDatabase(QueryExecutor e) : super(e);
  $TukiDatabaseManager get managers => $TukiDatabaseManager(this);
  late final $DrawingsTable drawings = $DrawingsTable(this);
  late final Index drawingsUpdatedAt = Index(
    'drawings_updated_at',
    'CREATE INDEX drawings_updated_at ON drawings (updated_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    drawings,
    drawingsUpdatedAt,
  ];
}

typedef $$DrawingsTableCreateCompanionBuilder = DrawingsCompanion Function({
  required String drawingId,
  required String chapterId,
  required String pageId,
  required int templateRevision,
  required int documentVersion,
  required int saveRevision,
  required String fillsJson,
  required String strokesJson,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$DrawingsTableUpdateCompanionBuilder = DrawingsCompanion Function({
  Value<String> drawingId,
  Value<String> chapterId,
  Value<String> pageId,
  Value<int> templateRevision,
  Value<int> documentVersion,
  Value<int> saveRevision,
  Value<String> fillsJson,
  Value<String> strokesJson,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$DrawingsTableFilterComposer
    extends Composer<_$TukiDatabase, $DrawingsTable> {
  $$DrawingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get drawingId => $composableBuilder(
    column: $table.drawingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chapterId => $composableBuilder(
    column: $table.chapterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get templateRevision => $composableBuilder(
    column: $table.templateRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get documentVersion => $composableBuilder(
    column: $table.documentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get saveRevision => $composableBuilder(
    column: $table.saveRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fillsJson => $composableBuilder(
    column: $table.fillsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strokesJson => $composableBuilder(
    column: $table.strokesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DrawingsTableOrderingComposer
    extends Composer<_$TukiDatabase, $DrawingsTable> {
  $$DrawingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get drawingId => $composableBuilder(
    column: $table.drawingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chapterId => $composableBuilder(
    column: $table.chapterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get templateRevision => $composableBuilder(
    column: $table.templateRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get documentVersion => $composableBuilder(
    column: $table.documentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get saveRevision => $composableBuilder(
    column: $table.saveRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fillsJson => $composableBuilder(
    column: $table.fillsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strokesJson => $composableBuilder(
    column: $table.strokesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DrawingsTableAnnotationComposer
    extends Composer<_$TukiDatabase, $DrawingsTable> {
  $$DrawingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get drawingId =>
      $composableBuilder(column: $table.drawingId, builder: (column) => column);

  GeneratedColumn<String> get chapterId =>
      $composableBuilder(column: $table.chapterId, builder: (column) => column);

  GeneratedColumn<String> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<int> get templateRevision => $composableBuilder(
    column: $table.templateRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get documentVersion => $composableBuilder(
    column: $table.documentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get saveRevision => $composableBuilder(
    column: $table.saveRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fillsJson =>
      $composableBuilder(column: $table.fillsJson, builder: (column) => column);

  GeneratedColumn<String> get strokesJson => $composableBuilder(
    column: $table.strokesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DrawingsTableTableManager
    extends
        RootTableManager<
          _$TukiDatabase,
          $DrawingsTable,
          DrawingRow,
          $$DrawingsTableFilterComposer,
          $$DrawingsTableOrderingComposer,
          $$DrawingsTableAnnotationComposer,
          $$DrawingsTableCreateCompanionBuilder,
          $$DrawingsTableUpdateCompanionBuilder,
          (
            DrawingRow,
            BaseReferences<_$TukiDatabase, $DrawingsTable, DrawingRow>,
          ),
          DrawingRow,
          PrefetchHooks Function()
        > {
  $$DrawingsTableTableManager(_$TukiDatabase db, $DrawingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DrawingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DrawingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DrawingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> drawingId = const Value.absent(),
                Value<String> chapterId = const Value.absent(),
                Value<String> pageId = const Value.absent(),
                Value<int> templateRevision = const Value.absent(),
                Value<int> documentVersion = const Value.absent(),
                Value<int> saveRevision = const Value.absent(),
                Value<String> fillsJson = const Value.absent(),
                Value<String> strokesJson = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DrawingsCompanion(
                drawingId: drawingId,
                chapterId: chapterId,
                pageId: pageId,
                templateRevision: templateRevision,
                documentVersion: documentVersion,
                saveRevision: saveRevision,
                fillsJson: fillsJson,
                strokesJson: strokesJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String drawingId,
                required String chapterId,
                required String pageId,
                required int templateRevision,
                required int documentVersion,
                required int saveRevision,
                required String fillsJson,
                required String strokesJson,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DrawingsCompanion.insert(
                drawingId: drawingId,
                chapterId: chapterId,
                pageId: pageId,
                templateRevision: templateRevision,
                documentVersion: documentVersion,
                saveRevision: saveRevision,
                fillsJson: fillsJson,
                strokesJson: strokesJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DrawingsTable, DrawingRow>(table),
                  BaseReferences<_$TukiDatabase, $DrawingsTable, DrawingRow>(
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

typedef $$DrawingsTableProcessedTableManager =
    ProcessedTableManager<
      _$TukiDatabase,
      $DrawingsTable,
      DrawingRow,
      $$DrawingsTableFilterComposer,
      $$DrawingsTableOrderingComposer,
      $$DrawingsTableAnnotationComposer,
      $$DrawingsTableCreateCompanionBuilder,
      $$DrawingsTableUpdateCompanionBuilder,
      (DrawingRow, BaseReferences<_$TukiDatabase, $DrawingsTable, DrawingRow>),
      DrawingRow,
      PrefetchHooks Function()
    >;

class $TukiDatabaseManager {
  final _$TukiDatabase _db;
  $TukiDatabaseManager(this._db);
  $$DrawingsTableTableManager get drawings =>
      $$DrawingsTableTableManager(_db, _db.drawings);
}
