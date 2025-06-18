import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geofinalapp/main.dart';

class RegisterEmailPage extends StatefulWidget {
  const RegisterEmailPage({super.key});

  @override
  createState() => _RegisterEmailPageState();
}

class _RegisterEmailPageState extends State<RegisterEmailPage> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _cityController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _registerWithEmail() async {
    if (_nameController.text.isEmpty ||
        _surnameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _birthDateController.text.isEmpty ||
        _birthPlaceController.text.isEmpty ||
        _cityController.text.isEmpty) {
      if (mounted) _showErrorDialog("Lütfen tüm alanları doldurun.");
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName('${_nameController.text.trim()} ${_surnameController.text.trim()}');

        await _firestore.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'email': _emailController.text.trim(),
          'birthDate': _birthDateController.text.trim(),
          'birthPlace': _birthPlaceController.text.trim(),
          'city': _cityController.text.trim(),
          'createdAt': Timestamp.now(),
        });

        await supabase.from('profiles').insert({
          'id': user.uid,
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'email': _emailController.text.trim(),
        });

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
        }
      }
    } on FirebaseAuthException catch (e) {
      if(mounted) _showErrorDialog(e.message ?? "Bir hata oluştu");
    } catch (e) {
      if(mounted) _showErrorDialog("Beklenmeyen bir hata oluştu: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kayıt Hatası'),
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

  InputDecoration _buildInputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon),
      hintStyle: const TextStyle(color: Colors.white70),
      prefixIconColor: Colors.white70,
      filled: true,
      fillColor: const Color.fromARGB(77, 0, 0, 0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.white54),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.white),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Email ile Kayıt Ol"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(controller: _nameController, style: const TextStyle(color: Colors.white), decoration: _buildInputDecoration("Adınız", Icons.person)),
                  const SizedBox(height: 15),
                  TextField(controller: _surnameController, style: const TextStyle(color: Colors.white), decoration: _buildInputDecoration("Soyadınız", Icons.person_outline)),
                  const SizedBox(height: 15),
                  TextField(controller: _emailController, style: const TextStyle(color: Colors.white), keyboardType: TextInputType.emailAddress, decoration: _buildInputDecoration("Email", Icons.email)),
                  const SizedBox(height: 15),
                  TextField(controller: _passwordController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: _buildInputDecoration("Şifre", Icons.lock)),
                  const SizedBox(height: 15),
                  TextField(controller: _birthDateController, style: const TextStyle(color: Colors.white), decoration: _buildInputDecoration("Doğum Tarihiniz", Icons.calendar_today), readOnly: true, onTap: _selectDate),
                  const SizedBox(height: 15),
                  TextField(controller: _birthPlaceController, style: const TextStyle(color: Colors.white), decoration: _buildInputDecoration("Doğum Yeriniz", Icons.location_on)),
                  const SizedBox(height: 15),
                  TextField(controller: _cityController, style: const TextStyle(color: Colors.white), decoration: _buildInputDecoration("Yaşadığınız İl", Icons.location_city)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _registerWithEmail,
                    child: const Text("Kayıt Ol"),
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