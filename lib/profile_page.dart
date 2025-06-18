import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geofinalapp/main.dart';
import 'package:geofinalapp/widgets/base_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Sayfa ilk açıldığında veriler yüklenirken bir bekleme animasyonu göstermek için bu değişkeni kullanacağız.
  bool _isLoading = true;

  // Supabase'den gelen skorları hesaplayıp bu değişkende tutacağız.
  int _totalScore = 0;

  // Her seferinde çağırmamak için giriş yapmış kullanıcıyı en başta alalım.
  final User? _user = FirebaseAuth.instance.currentUser;

  // Firestore'dan gelen doğum yeri, yaşadığı il gibi ek bilgileri tutacağımız bir map.
  Map<String, dynamic> _firestoreData = {};

  // Bu metot, sayfa ilk oluşturulduğunda sadece bir kez çalışır.
  @override
  void initState() {
    super.initState();
    // Sayfa ilk açıldığında kullanıcı verilerini ve skorunu çekmeye başlayalım.
    _loadAllUserData();
  }

  // Burası profil sayfası için gereken tüm verileri farklı kaynaklardan toplayan ana fonksiyonumuz.
  Future<void> _loadAllUserData() async {
    // Veri yüklemeye başlarken loading animasyonunu başlatalım.
    // if (!_isLoading) kontrolü, sayfa yenilendiğinde gereksiz yere tekrar build olmasını engeller.
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }

    // Önce bir kontrol edelim, kullanıcı gerçekten giriş yapmış mı?
    if (_user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // try-catch bloğu önemli, çünkü internet yoksa veya bir servis çökerse uygulama patlamasın.
    try {
      // Supabase'den bu kullanıcıya ait tüm skor kayıtlarını çekiyoruz.
      final List<dynamic> allScores = await supabase
          .from('scores')
          .select('correct_answers, incorrect_answers')
          .eq('user_id', _user.uid);

      // Şimdi bu skor listesini tek tek gezip toplam doğru ve yanlışı bulalım.
      int correct = 0;
      int incorrect = 0;
      for (var game in allScores) {
        correct += game['correct_answers'] as int;
        incorrect += game['incorrect_answers'] as int;
      }
      // Toplam skoru hesaplayalım: Doğrular - Yanlışlar
      _totalScore = correct - incorrect;

      // Firestore'dan doğum yeri gibi ek bilgileri çekelim.
      final firestoreDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user.uid)
              .get();
      if (firestoreDoc.exists) {
        _firestoreData = firestoreDoc.data()!;
      }
    } catch (e) {
      // Bir hata olursa, en azından geliştirme aşamasında konsolda görelim.
      debugPrint("Veri yükleme hatası: $e");
    }

    // Her şey bitti, artık loading animasyonunu kapatıp sayfayı güncelleyebiliriz.
    // 'mounted' kontrolü, veri yüklenirken kullanıcı sayfadan çıkarsa hata vermemizi engeller.
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Profil düzenleme butonuna basıldığında açılacak olan diyalog penceresi.
  Future<void> _showEditProfileDialog() async {
    // Diyalogdaki text alanlarının, kullanıcının mevcut bilgileriyle dolu gelmesi lazım.
    final birthDateController = TextEditingController(
      text: _firestoreData['birthDate'],
    );
    final birthPlaceController = TextEditingController(
      text: _firestoreData['birthPlace'],
    );
    final cityController = TextEditingController(text: _firestoreData['city']);

    // Kullanıcıya tarih seçtirmek için bir takvim açan yardımcı fonksiyon.
    Future<void> selectDate(BuildContext context) async {
      DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1920),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      }
    }

    final navigator = Navigator.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Bilgileri Düzenle"),
          content: Column(
            mainAxisSize: MainAxisSize.min, // İçerik kadar yer kaplasın.
            children: [
              TextField(
                controller: birthDateController,
                decoration: const InputDecoration(labelText: "Doğum Tarihi"),
                readOnly:
                    true, // Klavyeyle yazmayı engelle, sadece takvimle seçilsin.
                onTap: () => selectDate(dialogContext),
              ),
              TextField(
                controller: birthPlaceController,
                decoration: const InputDecoration(labelText: "Doğum Yeri"),
              ),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(labelText: "Yaşadığı İl"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(false),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Kaydet'e basılınca Firestore'daki verileri güncelleyelim.
                await _updateProfileData(
                  birthDate: birthDateController.text,
                  birthPlace: birthPlaceController.text,
                  city: cityController.text,
                );
                // İşlem başarılı, dialog'u kapatalım.
                navigator.pop(true);
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );

    // Eğer kullanıcı "Kaydet" butonuna bastıysa (result == true),
    // ekrandaki bilgilerin güncellenmesi için verileri yeniden yükleyelim.
    if (result == true) {
      _loadAllUserData();
    }
  }

  // Firestore'daki veriyi güncelleyen fonksiyon.
  Future<void> _updateProfileData({
    required String birthDate,
    required String birthPlace,
    required String city,
  }) async {
    if (_user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .update({
            'birthDate': birthDate,
            'birthPlace': birthPlace,
            'city': city,
          });
      // Kullanıcıya işlemin başarılı olduğuna dair bir geri bildirim verelim.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bilgiler güncellendi!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Bir hata olursa da bildirelim.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Profil',
      body: Stack(
        children: [
          // Yükleme devam ediyorsa ortada dönen bir yuvarlak gösterelim.
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              // Yükleme bittiyse asıl içeriği gösterelim.
              : RefreshIndicator(
                // Sayfayı aşağı çekince verileri yeniden yüklemek güzel bir özellik.
                onRefresh: _loadAllUserData,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 60.0,
                      left: 24.0,
                      right: 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Toplam Skor',
                          style: TextStyle(fontSize: 24, color: Colors.grey),
                        ),
                        Text(
                          '$_totalScore',
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _user?.displayName ?? 'İsim Bilgisi Yok',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _user?.email ?? 'Email Bilgisi Yok',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Column(
                            children: [
                              // Her bir bilgi satırını ayrı bir widget ile çizdiriyoruz.
                              _InfoRow(
                                icon: Icons.cake,
                                label: "Doğum Tarihi",
                                value: _firestoreData['birthDate'],
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.location_on,
                                label: "Doğum Yeri",
                                value: _firestoreData['birthPlace'],
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.location_city,
                                label: "Yaşadığı İl",
                                value: _firestoreData['city'],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

          // Düzenleme butonunu sağ üste konumlandırmak için kullandığımız katman.
          Positioned(
            top: 0,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.edit),
              // Veriler yüklenirken butona basılmasın diye kontrol ediyoruz.
              onPressed: _isLoading ? null : _showEditProfileDialog,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              "$label:",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Flexible(
          child: Text(
            value != null && value!.isNotEmpty ? value! : 'Belirtilmemiş',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
