import 'dart:async';
import '../../domain/entities/loan.dart';
import '../../domain/repositories/loan_repository.dart';
import '../datasources/loan_local_datasource.dart';
import '../datasources/loan_remote_datasource.dart';
import '../../../../core/network/network_info.dart';

class LoanRepositoryImpl implements LoanRepository {
  final LoanLocalDataSource _local;
  final LoanRemoteDataSource _remote;
  final NetworkInfo _network;

  // Single controller — all writes push here immediately via SQLite
  final _controller = StreamController<List<Loan>>.broadcast();

  LoanRepositoryImpl(this._local, this._remote, this._network) {
    _init();
  }

  bool _suppressNextRemoteEmit = false;

  void _init() {
    if (_remote.watchLoans() == const Stream<List<Loan>>.empty()) return;

    _local.getLoans().then(_emit);

    _remote.watchLoans().listen((loans) async {
      await _local.upsertAll(loans);
      if (_suppressNextRemoteEmit) {
        _suppressNextRemoteEmit = false;
        return; // skip — _pushLocal already emitted this write
      }
      _emit(loans);
    }, onError: (_) {});
  }

  void _emit(List<Loan> loans) {
    if (!_controller.isClosed) _controller.add(loans);
  }

  /// Re-reads SQLite and pushes immediately — used after every write
  Future<void> _pushLocal() async {
    final loans = await _local.getLoans();
    _emit(loans);
  }

  @override
  Stream<List<Loan>> watchLoans() => _controller.stream;

  void dispose() => _controller.close();

  @override
  Future<List<Loan>> getLoans() async {
    if (await _network.isConnected) {
      final loans = await _remote.getLoans();
      await _local.upsertAll(loans);
      return loans;
    }
    return _local.getLoans();
  }

  @override
  Future<Loan> getLoan(String id) async {
    final loan = await _local.getLoan(id);
    return loan!;
  }

  @override
  Future<void> addLoan(Loan loan) async {
    await _local.upsertLoan(loan);
    await _pushLocal();
    if (await _network.isConnected) {
      _suppressNextRemoteEmit = true;
      await _remote.setLoan(loan);
    }
  }

  @override
  Future<void> updateLoan(Loan loan) async {
    await _local.upsertLoan(loan);
    await _pushLocal();
    if (await _network.isConnected) {
      _suppressNextRemoteEmit = true;
      await _remote.setLoan(loan);
    }
  }

  @override
  Future<void> deleteLoan(String id) async {
    await _local.deleteLoan(id);
    await _pushLocal();
    if (await _network.isConnected) {
      _suppressNextRemoteEmit = true;
      await _remote.deleteLoan(id);
    }
  }

  @override
  Future<void> syncFromFirestore() async {
    if (await _network.isConnected) {
      final loans = await _remote.getLoans();
      await _local.upsertAll(loans);
      _emit(loans);
    }
  }
}
