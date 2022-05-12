import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<String?> signInWithGoogle() async 
{
  //print("SignInWithGoogle");
  //TODO REMOVE
  return "m7of9fTW0CMjEUNQPUhi3mGKWzd2";
  
  //print("NotSignedIn");
  final FirebaseAuth _auth = FirebaseAuth.instance;
  try 
  {
    //print("SignInWithGoogle.web.1 ${GoogleAuthProvider.PROVIDER_ID}");
    final GoogleAuthProvider _authProvider = GoogleAuthProvider();
    
    //print("SignInWithGoogle.web.2 ${_authProvider.scopes} - ${_authProvider.parameters}");
    final UserCredential userCredential = await _auth.signInWithPopup(_authProvider);

    //print("SignInWithGoogle.web.3");
    if(userCredential.user != null)
    {
      //print(userCredential.user!.displayName);
      return userCredential.user!.uid;
    }
    else
    {
      //print("Web.noUser");
      return null;
    }
  } 
  catch (e) 
  {
    print(e);
    return null;
  }
}