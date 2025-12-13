import 'package:sqflite/sqflite.dart';

import '../domain/invoice.dart';
import 'invoice_database.dart';

class InvoiceRepository {
  InvoiceRepository(this._database);

  final InvoiceDatabase _database;

  Future<List<Invoice>> getAll({
    required String? userId,
    String? searchQuery,
    String? typeFilter,
    String? rncFilter,
    String? buyerRncFilter,
    bool includeBuyerRncIsNull = false,
    DateTime? issuedFrom,
    DateTime? issuedTo,
    SortOption sortOption = SortOption.createdAtDesc,
  }) async {
    final db = _database.database;
    final where = <String>[];
    final whereArgs = <Object?>[];

    // Siempre filtrar por userId
    if (userId != null && userId.isNotEmpty) {
      where.add('user_id = ?');
      whereArgs.add(userId);
    } else {
      // Si no hay userId, no devolver nada (por seguridad)
      where.add('user_id IS NULL');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      where.add(
        '(issuer_name LIKE ? OR ecf_number LIKE ? OR rnc LIKE ?)',
      );
      final pattern = '%${searchQuery.trim()}%';
      whereArgs.addAll([pattern, pattern, pattern]);
    }

    if (typeFilter != null && typeFilter.isNotEmpty) {
      where.add('type = ?');
      whereArgs.add(typeFilter);
    }

    if (rncFilter != null && rncFilter.isNotEmpty) {
      where.add('rnc = ?');
      whereArgs.add(rncFilter);
    }

    if (buyerRncFilter != null && buyerRncFilter.isNotEmpty) {
      where.add('buyer_rnc = ?');
      whereArgs.add(buyerRncFilter);
    } else if (includeBuyerRncIsNull) {
      where.add('(buyer_rnc IS NULL OR buyer_rnc = "")');
    }

    if (issuedFrom != null) {
      where.add('issued_at >= ?');
      whereArgs.add(issuedFrom.toIso8601String());
    }

    if (issuedTo != null) {
      where.add('issued_at <= ?');
      whereArgs.add(issuedTo.toIso8601String());
    }

    final orderBy = switch (sortOption) {
      SortOption.createdAtAsc => 'created_at ASC',
      SortOption.createdAtDesc => 'created_at DESC',
      SortOption.issueDateAsc => 'issued_at ASC',
      SortOption.issueDateDesc => 'issued_at DESC',
      SortOption.amountAsc => 'amount ASC',
      SortOption.amountDesc => 'amount DESC',
    };

    final maps = await db.query(
      Invoice.tableName,
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );

    return maps.map(Invoice.fromMap).toList();
  }

  Future<Invoice?> getByEcf(String ecfNumber, {required String? userId}) async {
    final db = _database.database;
    final where = <String>['ecf_number = ?'];
    final whereArgs = <Object?>[ecfNumber];

    // Filtrar por userId
    if (userId != null && userId.isNotEmpty) {
      where.add('user_id = ?');
      whereArgs.add(userId);
    } else {
      where.add('user_id IS NULL');
    }

    final maps = await db.query(
      Invoice.tableName,
      where: where.join(' AND '),
      whereArgs: whereArgs,
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Invoice.fromMap(maps.first);
  }

  Future<Invoice?> getByRemoteId(String remoteId,
      {required String? userId}) async {
    final db = _database.database;
    final where = <String>['remote_id = ?'];
    final whereArgs = <Object?>[remoteId];

    // Filtrar por userId
    if (userId != null && userId.isNotEmpty) {
      where.add('user_id = ?');
      whereArgs.add(userId);
    } else {
      where.add('user_id IS NULL');
    }

    final maps = await db.query(
      Invoice.tableName,
      where: where.join(' AND '),
      whereArgs: whereArgs,
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Invoice.fromMap(maps.first);
  }

  Future<Invoice> insert(Invoice invoice) async {
    if (invoice.userId == null || invoice.userId!.isEmpty) {
      throw Exception('Invoice must have a userId');
    }

    final db = _database.database;
    final id = await db.insert(
      Invoice.tableName,
      invoice.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return invoice.copyWith(id: id);
  }

  Future<Invoice> upsert(Invoice invoice) async {
    final db = _database.database;
    if (invoice.userId == null || invoice.userId!.isEmpty) {
      throw Exception('Invoice must have a userId');
    }

    final existing = await getByEcf(invoice.ecfNumber, userId: invoice.userId);

    if (existing == null) {
      return insert(invoice);
    }

    final updated = invoice.copyWith(id: existing.id);

    await db.update(
      Invoice.tableName,
      updated.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [existing.id, invoice.userId],
    );

    return updated;
  }

  Future<void> delete(int id, {required String? userId}) async {
    final db = _database.database;
    final where = <String>['id = ?'];
    final whereArgs = <Object?>[id];

    // Filtrar por userId para seguridad
    if (userId != null && userId.isNotEmpty) {
      where.add('user_id = ?');
      whereArgs.add(userId);
    } else {
      where.add('user_id IS NULL');
    }

    await db.delete(
      Invoice.tableName,
      where: where.join(' AND '),
      whereArgs: whereArgs,
    );
  }

  Future<void> deleteByRemoteId(String remoteId,
      {required String? userId}) async {
    final db = _database.database;
    final where = <String>['remote_id = ?'];
    final whereArgs = <Object?>[remoteId];

    // Filtrar por userId
    if (userId != null && userId.isNotEmpty) {
      where.add('user_id = ?');
      whereArgs.add(userId);
    } else {
      where.add('user_id IS NULL');
    }

    await db.delete(
      Invoice.tableName,
      where: where.join(' AND '),
      whereArgs: whereArgs,
    );
  }

  Future<void> attachRemoteId(int id, String remoteId,
      {required String? userId}) async {
    final db = _database.database;
    final where = <String>['id = ?'];
    final whereArgs = <Object?>[id];

    // Filtrar por userId
    if (userId != null && userId.isNotEmpty) {
      where.add('user_id = ?');
      whereArgs.add(userId);
    } else {
      where.add('user_id IS NULL');
    }

    await db.update(
      Invoice.tableName,
      {'remote_id': remoteId},
      where: where.join(' AND '),
      whereArgs: whereArgs,
    );
  }

  /// Agrega una eliminación pendiente a la cola
  Future<void> addPendingDeletion(String remoteId,
      {required String? userId}) async {
    if (userId == null || userId.isEmpty) {
      return;
    }

    final db = _database.database;
    await db.insert(
      'pending_deletions',
      {
        'remote_id': remoteId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene todas las eliminaciones pendientes para un usuario
  Future<List<String>> getPendingDeletions({required String? userId}) async {
    if (userId == null || userId.isEmpty) {
      return [];
    }

    final db = _database.database;
    final maps = await db.query(
      'pending_deletions',
      where: 'user_id = ?',
      whereArgs: [userId],
      columns: ['remote_id'],
    );

    return maps.map((map) => map['remote_id'] as String).toList();
  }

  /// Elimina una eliminación pendiente de la cola
  Future<void> removePendingDeletion(String remoteId,
      {required String? userId}) async {
    if (userId == null || userId.isEmpty) {
      return;
    }

    final db = _database.database;
    await db.delete(
      'pending_deletions',
      where: 'remote_id = ? AND user_id = ?',
      whereArgs: [remoteId, userId],
    );
  }
}

enum SortOption {
  createdAtAsc,
  createdAtDesc,
  issueDateAsc,
  issueDateDesc,
  amountAsc,
  amountDesc,
}
