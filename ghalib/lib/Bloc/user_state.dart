abstract class HomeUserState {}

class HomeUserInitial extends HomeUserState {}

class HomeUserLoading extends HomeUserState {}

class HomeUserLoaded extends HomeUserState {
  final String userName;
  HomeUserLoaded(this.userName);
}

class HomeUserError extends HomeUserState {
  final String message;
  HomeUserError(this.message);
}