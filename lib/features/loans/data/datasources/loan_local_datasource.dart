import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/entities/loan.dart';

class LoanLocalDataSource {
  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'repayiq.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE loans (
            id TEXT PRIMARY KEY,
            loanName TEXT NOT NULL,
            loanType TEXT NOT NULL,
            principal REAL NOT NULL,
            interestRate REAL NOT NULL,
            tenureMonths INTEGER NOT NULL,
            startDate TEXT NOT NULL,
            dueDay INTEGER NOT NULL,
            reminderDays INTEGER NOT NULL,
            monthlyEmi REAL NOT NULL,
            calculationMethod TEXT NOT NULL,
            memberId TEXT,
            status TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<Loan>> getLoans() async {
    final database = await db;
    final maps = await database.query('loans', orderBy: 'createdAt DESC');
    return maps.map(Loan.fromMap).toList();
  }

  Future<Loan?> getLoan(String id) async {
    final database = await db;
    final maps = await database.query('loans', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Loan.fromMap(maps.first);
  }

  Future<void> upsertLoan(Loan loan) async {
    final database = await db;
    await database.insert(
      'loans',
      loan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteLoan(String id) async {
    final database = await db;
    await database.delete('loans', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> upsertAll(List<Loan> loans) async {
    final database = await db;
    final batch = database.batch();
    for (final loan in loans) {
      batch.insert('loans', loan.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
