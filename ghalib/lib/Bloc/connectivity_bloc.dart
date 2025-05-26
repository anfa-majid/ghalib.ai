import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Events
abstract class ConnectivityEvent {}

class CheckConnectivity extends ConnectivityEvent {}

class ConnectivityChanged extends ConnectivityEvent {
  final bool isOnline;
  ConnectivityChanged(this.isOnline);
}

/// State
class ConnectivityState {
  final bool isOnline;
  ConnectivityState({required this.isOnline});
}

/// BLoC
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity? _connectivity;

  ConnectivityBloc({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(ConnectivityState(isOnline: true)) {
    _init();
  }

  /// Silent constructor (used in golden tests to avoid platform channels)
  ConnectivityBloc.silent()
      : _connectivity = null,
        super(ConnectivityState(isOnline: true));

  void _init() {
    _connectivity?.onConnectivityChanged.listen((result) async {
      final resolvedResult = result is List
          ? (result.isNotEmpty ? result.first : ConnectivityResult.none)
          : result;

      final isOnline = await _hasInternetAccess();
      print("📡 Connectivity Changed: ${resolvedResult.toString()} → Real Internet: $isOnline");
      add(ConnectivityChanged(isOnline));
    });

    on<ConnectivityChanged>((event, emit) {
      print("🚦 Emitting ConnectivityState: isOnline = ${event.isOnline}");
      emit(ConnectivityState(isOnline: event.isOnline));
    });

    on<CheckConnectivity>((event, emit) async {
      final isOnline = await _hasInternetAccess();
      print("🔍 Manual Connectivity Check → Real Internet: $isOnline");
      emit(ConnectivityState(isOnline: isOnline));
    });

    _checkInitialConnectivity();
  }

  void _checkInitialConnectivity() async {
    final isOnline = await _hasInternetAccess();
    print("🚀 Initial Connectivity Check → Real Internet: $isOnline");
    add(ConnectivityChanged(isOnline));
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      print("❌ No internet access (DNS lookup failed)");
      return false;
    }
  }
}
