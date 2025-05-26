import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ GOOGLE Sign-In
  Future<bool> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign In aborted');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      print('✅ Google Sign-In successful for ${user.email}');
      final doc = await _firestore.collection('user').doc(user.uid).get();

      if (!doc.exists) {
        // User signed in but no Firestore document — treat as not registered
        await signOut();
        print('❗ User authenticated but not registered in Firestore.');
        return false;
      } else {
        print('✅ User exists in Firestore.');
        return true;
      }
    }
    throw Exception('Something went wrong during Google Sign In.');
  }

  // ✅ Email/Password Sign-In
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        final userDoc = await _firestore.collection('user').doc(user.uid).get();
        if (!userDoc.exists) {
          await signOut();
          throw Exception('UserNotRegistered');
        }
        print('✅ Email-Password User exists in Firestore.');
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Unknown Error');
    }
  }

  // ✅ Email/Password Registration
  Future<void> registerWithEmailAndPassword(String email, String password, String userName) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await _firestore.collection('user').doc(user.uid).set({
          'email': email,
          'user_name': userName,
          'favorites': [],
          'mood': 'neutral',
        });
        print('✅ Firestore user document created!');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('This email is already registered.');
      } else {
        throw Exception(e.message ?? 'Registration failed');
      }
    }
  }

  // ✅ Google Registration
  Future<void> registerWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign In aborted');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      print('✅ Google Register attempt for ${user.email}');

      final doc = await _firestore.collection('user').doc(user.uid).get();
      if (doc.exists) {
        await signOut();
        throw Exception('AlreadyRegistered');
      } else {
        await _firestore.collection('user').doc(user.uid).set({
          'email': user.email,
          'user_name': user.displayName ?? '',
          'favorites': [],
          'mood': 'neutral',
        });
        print('✅ Firestore document created for new Google user.');
      }
    }
  }

  // ✅ Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  // ✅ Current User
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}
