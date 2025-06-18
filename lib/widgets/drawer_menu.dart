import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  void _navigate(BuildContext context, String route) {
    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.pushReplacementNamed(context, route);
    } else {
      Navigator.pop(context);
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Çıkış'),
          content: const Text('Çıkmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Evet'),
              onPressed: () {
                // Firebase'den çıkış yap
                FirebaseAuth.instance.signOut();
                // Kullanıcıyı giriş sayfasına yönlendir
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kullanıcı bilgilerini Firebase'den anlık olarak alalım
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? user?.email ?? 'Kullanıcı Adı'),
            accountEmail: Text(user?.email ?? 'kullanici@email.com'),
            currentAccountPicture: CircleAvatar(
              // Kullanıcının profil fotoğrafı varsa onu, yoksa standart bir ikon göster
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null ? const Icon(Icons.person, size: 50) : null,
            ),
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Ana Sayfa'),
            onTap: () => _navigate(context, '/main'),
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Bayrak Yarışı'),
            onTap: () => _navigate(context, '/game'),
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Bayrakları Öğren'),
            onTap: () => _navigate(context, '/learn'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            onTap: () => _navigate(context, '/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            onTap: () => _navigate(context, '/settings'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Çıkış'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}