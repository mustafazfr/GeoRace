import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geofinalapp/services/database_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  // Kullanıcının email ve şifre gireceği alanları kontrol etmek için.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Firebase Authentication servisine erişim için bir kısayol.
  final _auth = FirebaseAuth.instance;


  // Bu fonksiyon, herhangi bir yöntemle (email, google, github) giriş başarılı olduğunda
  // çağrılan ortak merkezimiz. Bütün veri kaydetme işlemleri burada yapılıyor.
  Future<void> _onLoginSuccess(User user) async {
    // Kullanıcının Firestore'daki ek bilgilerini (doğum yeri vs.) çekelim.
    final firestoreDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    // Bu map, en son SQLite'a ve SharedPreferences'a kaydedilecek olan verileri tutacak.
    Map<String, dynamic> userData = {};

    // Firestore'da bu kullanıcı için bir kayıt var mı diye bakıyoruz.
    if (firestoreDoc.exists) {
      // Varsa oradaki verileri alalım.
      userData = firestoreDoc.data()!;
    } else {
      // Eğer yoksa (muhtemelen Google/GitHub ile ilk kez giriyor),
      // temel bilgileriyle bir kayıt oluşturalım ki profil sayfası boş görünmesin.
      final displayName = user.displayName?.split(' ') ?? ['Bilinmiyor'];
      userData = {
        'name': displayName.first,
        'surname': displayName.length > 1 ? displayName.sublist(1).join(' ') : '',
        'email': user.email,
        'birthDate': '',
        'birthPlace': '',
        'city': '',
      };
      // Bu yeni oluşturduğumuz veriyi de ileride düzenleyebilmesi için Firestore'a kaydedelim.
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(userData, SetOptions(merge: true));
    }

    // SharedPreferences'a temel bilgileri kaydedelim.
    // Bu, uygulamayı tekrar açtığında hızlı erişim için harika.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', user.uid);
    await prefs.setString('email', userData['email'] ?? '');
    await prefs.setString('name', userData['name'] ?? '');
    await prefs.setString('surname', userData['surname'] ?? '');

    // SQLite veritabanına da bilgilerin bir kopyasını kaydedelim.
    final userMapForSqlite = {
      'id': user.uid,
      'email': userData['email'],
      'name': userData['name'],
      'surname': userData['surname'],
      'birthDate': userData['birthDate'],
      'birthPlace': userData['birthPlace'],
      'city': userData['city'],
    };
    await DatabaseHelper.instance.saveUser(userMapForSqlite);

    // Her şey hazır, artık kullanıcıyı ana sayfaya yönlendirebiliriz.
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
    }
  }


  // Standart email ve şifre ile giriş denemesi.
  Future<void> _signInWithEmailAndPassword() async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (userCredential.user != null) {
        // Giriş başarılıysa, ortak merkezimizi çağıralım.
        await _onLoginSuccess(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? "Bir hata oluştu");
    } catch (e) {
      _showErrorDialog("Beklenmeyen bir hata oluştu: $e");
    }
  }

  // Google ile giriş denemesi.
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _onLoginSuccess(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? "Bir hata oluştu");
    } catch (e) {
      _showErrorDialog("Beklenmeyen bir hata oluştu: $e");
    }
  }

  // GitHub ile giriş denemesi.
  Future<void> _signInWithGitHub() async {
    try {
      final githubProvider = GithubAuthProvider();
      final userCredential = await _auth.signInWithProvider(githubProvider);

      if (userCredential.user != null) {
        await _onLoginSuccess(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential' || e.code == 'cancelled-by-user') {
        _showErrorDialog('İşlem iptal edildi veya bu email başka bir yöntemle kayıtlı.');
        return;
      }
      _showErrorDialog(e.message ?? "Bir GitHub hatası oluştu");
    } catch (e) {
      _showErrorDialog("Beklenmeyen bir hata oluştu: $e");
    }
  }


  // Hata durumunda kullanıcıya bir diyalog penceresi göstermek için yardımcı fonksiyon.
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Giriş Hatası'),
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
      appBar: AppBar(title: const Text("Giriş yapınız.")),
      body: Stack(
        children: [
          // Arka plan resmi
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
          // Ortadaki giriş formu ve butonlar
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Email için text alanı
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        hintText: "Email adresiniz",
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.email),
                        prefixIconColor: Colors.white70,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.white),
                        )),
                  ),
                  const SizedBox(height: 15),
                  // Şifre için text alanı
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        hintText: "Şifreniz",
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock),
                        prefixIconColor: Colors.white70,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.white),
                        )),
                  ),
                  const SizedBox(height: 20),

                  // Giriş Butonları
                  ElevatedButton(
                    onPressed: _signInWithEmailAndPassword,
                    child: const Text("Giriş Yap"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: Image.asset('assets/google_logo.png', height: 24.0),
                    label: const Text("Google ile Giriş Yap"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _signInWithGitHub,
                    icon: Image.asset('assets/github_logo.png', height: 24.0),
                    label: const Text("GitHub ile Giriş Yap"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Kayıt sayfasına yönlendirme
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/registerMethod');
                    },
                    child: const Text("Hesabın yok mu? Kayıt Ol"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}