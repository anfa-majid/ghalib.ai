import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Bloc/connectivity_bloc.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, state) {
        print("OfflineBanner build: isOnline = ${state.isOnline}");
        if (state.isOnline) return const SizedBox.shrink();

        print("Showing RED BANNER");
        return Container(
          width: double.infinity,
          color: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Center(
            child: Text(
              "You're offline",
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
