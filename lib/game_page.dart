import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geofinalapp/main.dart';
import 'package:geofinalapp/widgets/base_page.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  // Oyun boyunca değişecek olan değerleri burada tutuyoruz.
  int dogruSayisi = 0;
  int yanlisSayisi = 0;
  int soruSayaci = 0;
  final int toplamSoruSayisi = 10; // Her oyun 10 sorudan oluşsun.

  // O an ekranda gösterilen sorunun bilgilerini (bayrak, şıklar vs.) tutan bir map.
  // Başlangıçta null olabilir, o yüzden '?' işareti var.
  Map<String, dynamic>? soru;

  // Bu metot sayfa ilk açıldığında bir kereliğine çalışır.
  @override
  void initState() {
    super.initState();
    // Hadi ilk sorumuzu getirerek oyunu başlatalım.
    yeniSoruGetir();
  }

  // Bu fonksiyon, oyun bittiğinde skoru Supabase'e kaydeder.
  Future<void> _saveScore(int correct, int incorrect) async {
    // Önce giriş yapmış bir kullanıcı var mı diye bakalım. Yoksa kaydetmenin anlamı yok.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Supabase'deki 'scores' tablomuza yeni bir satır ekliyoruz.
      await supabase.from('scores').insert({
        'user_id': user.uid,
        'correct_answers': correct,
        'incorrect_answers': incorrect,
      });
    } catch (e) {
      // İnternet olmayabilir, Supabase'e ulaşılamayabilir.
      // Bu durumda oyunun akışını bozmuyoruz, sadece geliştirici olarak hatayı konsolda görüyoruz.
      debugPrint('Skor kaydedilemedi: $e');
    }
  }

  // Bir sonraki soruyu hazırlayan ve ekranı güncelleyen fonksiyon.
  Future<void> yeniSoruGetir() async {
    // Oyun bitti mi? (10 soruyu tamamladık mı?)
    if (soruSayaci >= toplamSoruSayisi) {
      // Cevap evetse, önce skoru kaydedelim.
      await _saveScore(dogruSayisi, yanlisSayisi);
      // Sonra da "Oyun Bitti" diyalogunu gösterelim.
      if(mounted) oyunSonucuPopUp();
      return; // Bu return önemli, çünkü oyun bitmişken yeni soru getirmeye çalışmasın.
    }

    // Eğer oyun bitmediyse, yeni bir soru ve şıklar hazırlayalım.
    Map<String, dynamic> yeniSoru = await rastgeleBayrakVeSeceneklerGetir();

    // Soru hazır, şimdi setState ile ekranı güncelleyelim ki kullanıcı yeni soruyu görsün.
    if (mounted) {
      setState(() {
        soru = yeniSoru;
        soruSayaci++;
      });
    }
  }

  // Oyun bitince çıkan diyalog penceresi.
  void oyunSonucuPopUp() {
    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcının dışarı tıklayarak kapatmasını engelle.
      builder: (context) => AlertDialog(
        title: const Text("Oyun Bitti!"),
        content: Text("Doğru: $dogruSayisi, Yanlış: $yanlisSayisi"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Önce diyalogu kapat
              Navigator.pushReplacementNamed(context, '/main'); // Sonra ana sayfaya dön
            },
            child: const Text("Ana sayfaya dön"),
          ),
          TextButton(
            onPressed: () {
              // Tekrar oynamak için tüm sayaçları sıfırlamamız lazım.
              setState(() {
                soruSayaci = 0;
                dogruSayisi = 0;
                yanlisSayisi = 0;
              });
              Navigator.pop(context); // Diyalogu kapat
              yeniSoruGetir();       // Ve ilk soruyu getirerek yeni oyunu başlat
            },
            child: const Text("Tekrar oyna"),
          ),
        ],
      ),
    );
  }

  // Bu fonksiyon, asset'lerdeki json dosyasından rastgele bir bayrak ve 3 yanlış şık seçer.
  Future<Map<String, dynamic>> rastgeleBayrakVeSeceneklerGetir() async {
    // Bütün ülkeleri JSON dosyasından okuyup bir liste yapalım.
    String jsonString = await rootBundle.loadString('assets/flags.json');
    List<dynamic> tumUlkeler = jsonDecode(jsonString);

    // Listeden rastgele bir ülke seçelim, bu bizim doğru cevabımız olacak.
    int randomId = Random().nextInt(tumUlkeler.length);
    var secilenUlke = tumUlkeler[randomId];

    String dogruAd = secilenUlke['name'];
    String bayrakUrl = secilenUlke['flag'];

    // Şimdi bu doğru cevabın yanına 3 tane de alakasız, yanlış şık bulmamız lazım.
    List<String> digerAdlar = [];
    // while döngüsü, 3 tane benzersiz ve doğru cevaptan farklı isim bulana kadar çalışacak.
    while (digerAdlar.length < 3) {
      int rastgeleIndex = Random().nextInt(tumUlkeler.length);
      String ad = tumUlkeler[rastgeleIndex]['name'];

      // Eğer seçilen ad, doğru cevap değilse VE daha önce yanlış şıklara eklenmemişse...
      if (ad != dogruAd && !digerAdlar.contains(ad)) {
        digerAdlar.add(ad); // ... o zaman listeye ekle.
      }
    }

    // Tüm şıkları (3 yanlış + 1 doğru) bir araya getirip...
    List<String> tumSecenekler = [...digerAdlar, dogruAd];
    // ...güzelce bir karıştıralım ki doğru cevap hep aynı yerde olmasın.
    tumSecenekler.shuffle();

    // Son olarak, soruyu oluşturacak tüm bilgileri bir map olarak geri döndürelim.
    return {
      'bayrak': bayrakUrl,
      'dogruAd': dogruAd,
      'secenekler': tumSecenekler,
    };
  }


  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Doğru: $dogruSayisi / Yanlış: $yanlisSayisi',
      body: soru == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Image.network(soru!['bayrak'], height: 150)),
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                for (var secenek in soru!['secenekler'])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 40),
                    child: ElevatedButton(
                      onPressed: () {
                        // Cevap butonuna basıldığında...
                        setState(() {
                          // Cevap doğru mu diye kontrol et.
                          if (secenek == soru!['dogruAd']) {
                            dogruSayisi++;
                          } else {
                            yanlisSayisi++; // Değilse yanlışı artır.
                          }
                        });
                        // Kontrol bitti, hemen yeni soruyu getir.
                        yeniSoruGetir();
                      },
                      child: Text(secenek),
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