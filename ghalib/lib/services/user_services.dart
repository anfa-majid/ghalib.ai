import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  String? getCurrentUserEmail() {
    try {
      return _auth.currentUser?.email;
    } catch (e) {
      print('Error getting user email: $e');
      return null;
    }
  }

  Future<String?> getUserName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('user')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return data['user_name'] as String?;
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
    return null;
  }
}
