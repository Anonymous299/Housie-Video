import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
//TODO implement google sign in
abstract class BaseAuth {
  Future<FirebaseUser> getCurrentUser();
}

class Auth implements BaseAuth{
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  Future<FirebaseUser> getCurrentUser() async{
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user;
  }
}

