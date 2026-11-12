import 'package:drift/drift.dart';

part 'database.g.dart';

/// Obras guardadas. Una fila por lámina `(chapterId, pageId)`.
@DataClassName('DrawingRow')
@TableIndex(name: 'drawings_updated_at', columns: {#updatedAt})
class Drawings extends Table {
  TextColumn get drawingId => text()();
  TextColumn get chapterId => text()();
  TextColumn get pageId => text()();
  IntColumn get templateRevision => integer()();

  /// Formato de fillsJson / strokesJson.
  IntColumn get documentVersion => integer()();

  /// Aumenta con cada edición confirmada.
  IntColumn get saveRevision => integer()();

  /// `{ "regionId": "#RRGGBB" }`
  TextColumn get fillsJson => text()();

  /// Operaciones ordenadas de pincel y borrador.
  TextColumn get strokesJson => text()();

  /// Microsegundos desde la época Unix, en UTC.
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {drawingId};

  @override
  List<Set<Column>> get uniqueKeys => [
    {chapterId, pageId},
  ];
}

@DriftDatabase(tables: [Drawings])
class TukiDatabase extends _$TukiDatabase {
  TukiDatabase(super.e);

  /// Al subir esta versión: volcar el esquema con
  /// `dart run drift_dev schema dump lib/data/local/database.dart drift_schemas/`,
  /// añadir el paso en [migration] y una prueba de migración.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Sin migraciones todavía: el esquema publicado es la versión 1.
    },
  );
}
