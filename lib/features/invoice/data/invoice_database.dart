import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/invoice.dart';

class InvoiceDatabase {
  InvoiceDatabase._(this._database);

  final Database _database;

  static Future<InvoiceDatabase> open() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'mi_comprobante_rd.db');

    final database = await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${Invoice.tableName} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rnc TEXT NOT NULL,
            issuer_name TEXT NOT NULL,
            ecf_number TEXT NOT NULL,
            amount REAL NOT NULL,
            issued_at TEXT NOT NULL,
            type TEXT NOT NULL,
            status TEXT,
            buyer_rnc TEXT,
            buyer_name TEXT,
            total_itbis REAL,
            signature_date TEXT,
            security_code TEXT,
            validation_status TEXT,
            validated_at TEXT,
            raw_data TEXT NOT NULL,
            created_at TEXT NOT NULL,
            remote_id TEXT,
            user_id TEXT
          )
        ''');
        // Crear índice único para ecf_number + user_id (solo para invoices con userId)
        // SQLite permite NULLs en índices únicos, pero los trata como únicos
        await db.execute('''
          CREATE UNIQUE INDEX idx_ecf_user ON ${Invoice.tableName}(ecf_number, user_id)
        ''');
        // Crear tabla para eliminaciones pendientes
        await db.execute('''
          CREATE TABLE pending_deletions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            remote_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(remote_id, user_id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE ${Invoice.tableName} ADD COLUMN buyer_rnc TEXT');
          await db.execute(
              'ALTER TABLE ${Invoice.tableName} ADD COLUMN buyer_name TEXT');
          await db.execute(
              'ALTER TABLE ${Invoice.tableName} ADD COLUMN total_itbis REAL');
          await db.execute(
              'ALTER TABLE ${Invoice.tableName} ADD COLUMN signature_date TEXT');
          await db.execute(
              'ALTER TABLE ${Invoice.tableName} ADD COLUMN security_code TEXT');
          await db.execute(
              'ALTER TABLE ${Invoice.tableName} ADD COLUMN validation_status TEXT');
          await db.execute(
              'ALTER TABLE ${Invoice.tableName} ADD COLUMN validated_at TEXT');
        }
        if (oldVersion < 3) {
          await db.execute(
              'ALTER TABLE ${Invoice.tableName} ADD COLUMN remote_id TEXT');
        }
        if (oldVersion < 4) {
          // Agregar columna user_id
          await db.execute(
              'ALTER TABLE ${Invoice.tableName} ADD COLUMN user_id TEXT');
          // Eliminar el índice único anterior de ecf_number si existe
          try {
            await db.execute('DROP INDEX IF EXISTS idx_ecf_unique');
          } catch (_) {}
          // Crear nuevo índice único para ecf_number + user_id
          await db.execute('''
            CREATE UNIQUE INDEX IF NOT EXISTS idx_ecf_user ON ${Invoice.tableName}(ecf_number, user_id)
          ''');
        }
        if (oldVersion < 5) {
          // Crear tabla para eliminaciones pendientes
          await db.execute('''
            CREATE TABLE IF NOT EXISTS pending_deletions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              remote_id TEXT NOT NULL,
              user_id TEXT NOT NULL,
              created_at TEXT NOT NULL,
              UNIQUE(remote_id, user_id)
            )
          ''');
        }
      },
    );

    return InvoiceDatabase._(database);
  }

  Database get database => _database;
}
