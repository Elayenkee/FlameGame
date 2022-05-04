//import 'package:firebase_auth/firebase_auth.dart';
//import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/*Future<bool> isSignedIn() async
{
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  return _googleSignIn.isSignedIn();
}*/

Future<String?> signInWithGoogle() async 
{
  return await Future.delayed(Duration(milliseconds: 2000), () {
    return "1";
  });

  
  /*print("SignInWithGoogle");
  final FirebaseAuth _auth = FirebaseAuth.instance;
  if(kIsWeb)
  {
    try 
    {
      print("SignInWithGoogle.web.1 ${GoogleAuthProvider.PROVIDER_ID}");
      final GoogleAuthProvider _authProvider = GoogleAuthProvider();
      
      print("SignInWithGoogle.web.2 ${_authProvider.scopes} - ${_authProvider.parameters}");
      final UserCredential userCredential = await _auth.signInWithPopup(_authProvider);

      print("SignInWithGoogle.web.3");
      if(userCredential.user != null)
      {
        print(userCredential.user!.displayName);
        return userCredential.user!.uid;
      }
      else
      {
        print("Web.noUser");
        return null;
      }
    } 
    catch (e) 
    {
      print(e);
      return e.toString();
    }
  }
  else
  {
    try
    {
      final GoogleSignIn _googleSignIn = GoogleSignIn();
      GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
      if(googleSignInAccount != null)
      {
        GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;
        AuthCredential credential = GoogleAuthProvider.credential(accessToken: googleSignInAuthentication.accessToken, idToken: googleSignInAuthentication.idToken);
        UserCredential authResult = await _auth.signInWithCredential(credential);
        if(authResult.user != null)
          print(authResult.user!.email);
        else
          print("noUser");
      }
      else
      {
        print("googleSignInAccount null");
      }
    }
    on FirebaseAuthException catch(e)
    {
      print(e);
    }
  }
  return null;*/
}