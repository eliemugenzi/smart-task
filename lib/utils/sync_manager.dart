import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:smarttask/utils/database_helper.dart';

class SyncManager {
  static final SyncManager instance = SyncManager._init();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isSyncing = false;
  SyncManager._init() {
    _initConnectivity();
  }

  void _initConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      for (var result in results) {
        _updateConnectionStatus(result);
      }
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) async {
    if (result != ConnectivityResult.none && !_isSyncing) {
      _isSyncing = true;
      await syncTasksToServer();
      _isSyncing = false;
    }
  }

  Future<void> syncTasksToServer() async {
    final tasks = await _databaseHelper.getTasks();
    for (var task in tasks) {
      try {
        //TODO: Sync a single task to the server
      } catch (e) {
        print('Error syncing task: $e');
      }
    }
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }
}
