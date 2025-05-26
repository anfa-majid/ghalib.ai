import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/user_services.dart';
import 'user_state.dart';
import 'user_event.dart';

class HomeUserBloc extends Bloc<HomeUserEvent, HomeUserState> {
  final UserService userService;

  HomeUserBloc({required this.userService}) : super(HomeUserInitial()) {
    on<FetchUserName>((event, emit) async {
      emit(HomeUserLoading());
      try {
        final name = await userService.getUserName();
        if (name != null) {
          emit(HomeUserLoaded(name));
        } else {
          emit(HomeUserError("Username not found"));
        }
      } catch (e) {
        emit(HomeUserError("Error: $e"));
      }
    });
  }
}
