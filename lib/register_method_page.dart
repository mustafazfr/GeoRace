// lib/register_method_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterMethodPage extends StatelessWidget {
  const RegisterMethodPage({super.key});

  Future<void> _processGoogleSignIn(BuildContext context) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final FirebaseAuth auth = FirebaseAuth.instance;
    final navigator = Navigator.of(context);

    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (!context.mounted || googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (!context.mounted) return;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await auth.signInWithCredential(credential);
      if (!context.mounted) return;

      navigator.pushReplacementNamed('/main');

    } catch (e) {
      if (context.mounted) _showErrorDialog(context, 'Google ile giriş başarısız oldu: $e');
    }
  }

  Future<void> _processGitHubSignIn(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final navigator = Navigator.of(context);

    try {
      final githubProvider = GithubAuthProvider();
      await auth.signInWithProvider(githubProvider);
      if (!context.mounted) return;

      navigator.pushReplacementNamed('/main');

    } on FirebaseAuthException catch (e) {
      if (context.mounted) _showErrorDialog(context, 'GitHub ile giriş başarısız oldu: ${e.message}');
    } catch (e) {
      if (context.mounted) _showErrorDialog(context, 'Beklenmeyen bir hata oluştu: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Tamam'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kayıt Yöntemi Seçiniz"),
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/registerEmail');
                  },
                  icon: const Icon(Icons.email, size: 24),
                  label: const Text("Email ile Kayıt Ol", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _processGoogleSignIn(context),
                  icon: Image.asset('assets/google_logo.png', height: 24.0),
                  label: const Text("Google ile Kayıt Ol", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _processGitHubSignIn(context),
                  icon: Image.asset('assets/github_logo.png', height: 24.0),
                  label: const Text("GitHub ile Kayıt Ol", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}