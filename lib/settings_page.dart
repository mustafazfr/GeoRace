import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geofinalapp/main.dart';
import 'package:geofinalapp/services/theme_notifier.dart';
import 'package:geofinalapp/widgets/base_page.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  // Kullanıcının tüm skorlarını Supabase'den silen fonksiyon.
  Future<void> _resetScores() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Giriş yapmış kullanıcı yoksa bir şey yapma.

    // Bu tehlikeli bir işlem olduğu için önce kullanıcıya bir soralım.
    final confirm = await _showConfirmationDialog(
        title: "Skorları Sıfırla",
        content: "Tüm oyun skorlarınız kalıcı olarak silinecektir. Emin misiniz?"
    );

    // Eğer kullanıcı açılan pencerede "Evet, Eminim" butonuna basarsa...
    if (confirm == true) {
      try {
        await supabase.from('scores').delete().eq('user_id', user.uid);
        // İşlem başarılı olursa kullanıcıya yeşil bir mesaj gösterelim.
        if(mounted) _showSuccessSnackBar("Tüm skorlarınız başarıyla sıfırlandı.");
      } catch (e) {
        // Bir hata olursa da kırmızı bir mesajla bildirelim.
        if(mounted) _showErrorSnackBar("Skorlar sıfırlanırken bir hata oluştu: $e");
      }
    }
  }

  // Kullanıcının hesabını ve tüm verilerini kalıcı olarak silen fonksiyon.
  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // BU ÇOK TEHLİKELİ BİR İŞLEM! Kullanıcıya iki kere sordurtsak yeridir :)
    final confirm = await _showConfirmationDialog(
        title: "Hesabı Sil",
        content: "Bu işlem geri alınamaz! Tüm profil bilgileriniz ve skorlarınız kalıcı olarak silinecektir. Devam etmek istediğinize emin misiniz?"
    );

    if (confirm == true) {
      try {
        // Supabase'deki skorları temizle.
        await supabase.from('scores').delete().eq('user_id', user.uid);
        // Supabase'deki profili temizle.
        await supabase.from('profiles').delete().eq('id', user.uid);
        // Firestore'daki kullanıcı dökümanını sil.
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        // Her şey silindikten sonra, en son Firebase Auth'daki asıl kullanıcıyı silelim.
        // Bu işlem hassas olduğu için bazen yeniden giriş yapmayı gerektirebilir.
        await user.delete();

        // Her şey bitti, kullanıcıyı atacak bir yer kalmadığı için giriş sayfasına yönlendirelim.
        if (mounted) {
          // Önceki tüm sayfaları kapatıp giriş sayfasına atıyoruz ki geri gelemesin.
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          _showSuccessSnackBar("Hesabınız başarıyla silindi.");
        }
      } on FirebaseAuthException catch (e) {
        // Firebase'in kendi özel hatalarını (örn: şifre eski, yeniden giriş yap) yakalamak için.
        if(mounted) _showErrorSnackBar("Hesap silinemedi. Lütfen tekrar giriş yapıp deneyin. Hata: ${e.code}");
      } catch (e) {
        // Diğer genel hatalar için.
        if(mounted) _showErrorSnackBar("Hesap silinirken bir hata oluştu: $e");
      }
    }
  }

  // Sürekli aynı diyalog kodunu yazmamak için bir yardımcı metot.
  Future<bool?> _showConfirmationDialog({required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // "false" değeri döndürerek kapat
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // "true" değeri döndürerek kapat
            child: const Text("Evet, Eminim", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Başarı mesajları için yardımcı metot.
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  // Hata mesajları için yardımcı metot.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }


  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Ayarlar',
      body: ListView(
        children: [
          // Tema Değiştirme
          // Consumer widget'ı, ThemeNotifier'daki değişiklikleri dinler ve UI'ı otomatik günceller.
          Consumer<ThemeNotifier>(
            builder: (context, theme, child) {
              return SwitchListTile(
                title: const Text("Koyu Tema"),
                secondary: const Icon(Icons.dark_mode),
                value: theme.darkTheme,
                onChanged: (bool value) {
                  // Switch'e basıldığında ThemeNotifier'daki fonksiyonu çağırıyoruz.
                  theme.toggleTheme();
                },
              );
            },
          ),
          const Divider(), // Ayarlar arasına bir çizgi koyalım, şık dursun.

          // Skorları Sıfırlama
          ListTile(
            leading: const Icon(Icons.replay),
            title: const Text("Tüm Skorları Sıfırla"),
            onTap: _resetScores, // Tıklanınca ilgili fonksiyonu çağır.
          ),
          const Divider(),

          // Hesabı Silme
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Hesabımı Sil", style: TextStyle(color: Colors.red)),
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }
}