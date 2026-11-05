import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Login Error: ${e.message}");
      return null;
    }
  }

  // UPDATED: Sign up function now accepts a role
  Future<User?> signUp(String email, String password, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save the role to Firestore
      if (result.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
          'email': email,
          'role': role, // 'teacher' or 'parent'
        });
      }
      
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Sign Up Error: ${e.message}");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}