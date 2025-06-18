# Bayrak Yarışı (GeoFinalApp)

## Projenin Amacı

Bayrak Yarışı, kullanıcıların dünya ülkelerine ait bayrakları eğlenceli bir bilgi yarışması formatında öğrenmelerini ve bilgilerini test etmelerini amaçlayan bir uygulamadır. Proje, modern bir mobil uygulama geliştirme sürecinin tüm adımlarını (çoklu platform desteği, bulut veritabanları, local depolama, çoklu kimlik doğrulama yöntemleri, durum yönetimi) kapsamaktadır.

## Öne Çıkan Özellikler

- **Çoklu Platform:** Tek bir kod tabanı ile Android, Windows ve Web üzerinde sorunsuz çalışır.
- **Kapsamlı Kimlik Doğrulama:**
    - E-posta / Şifre ile klasik kayıt ve giriş.
    - Google ile tek tıkla hızlı giriş.
    - GitHub ile geliştiricilere yönelik hızlı giriş.
- **Gelişmiş Veri Yönetimi:**
    - Kullanıcı detayları için **Firebase Firestore**.
    - Profil ve skor verileri için **Supabase (PostgreSQL)**.
    - Hızlı erişim verileri için **SharedPreferences**.
    - Çevrimdışı veri kopyası için **SQLite**.
- **Dinamik Profil Sayfası:**
    - Tüm oyunlardan elde edilen toplam skoru (`Doğru Sayısı - Yanlış Sayısı`) profil ekranında görebilir.
    - Kullanıcı bilgilerini (Doğum Tarihi, Doğum Yeri, Yaşadığı İl vb.) düzenleme imkanı sunar.
- **Esnek Ayarlar Menüsü:**
    - Uygulama genelinde **Açık/Koyu Tema** değiştirme.
    - Tüm skor geçmişini sıfırlama.
    - Hesabı tüm veritabanlarından kalıcı olarak silme.
- **Standart ve Genişletilebilir Arayüz:**
    - Hocanın verdiği `BasePage` şablonu temel alınarak tüm sayfalarda tutarlı bir `AppBar` ve `Drawer` menü yapısı oluşturulmuştur.
    - Şablon, `actions` gibi yeni özellikleri destekleyecek şekilde esnetilmiştir.

## Kullanılan Teknolojiler

- **Framework:** Flutter
- **Dil:** Dart
- **Bulut Servisleri:**
    - **Firebase:** Authentication, Firestore Database
    - **Supabase:** PostgreSQL Database
- **Local Depolama:**
    - SharedPreferences
    - SQLite
- **Durum Yönetimi (State Management):**
    - `StatefulWidget` (setState)
    - `Provider` (Tema yönetimi için)

## Test İçin Hazır Kullanıcı

Uygulamayı ve profil özelliklerini hızlıca test etmek için, veritabanında önceden oluşturulmuş aşağıdaki test hesabını kullanarak doğrudan **giriş yapabilirsiniz.**

- **E-posta:** `testt@ornek.com`
- **Şifre:** `test12345`

---
*Not: Google ve GitHub ile giriş özelliklerini test etmek için kendi kişisel hesaplarınızı kullanabilirsiniz. Bu hesaplarla ilk kez giriş yaptığınızda, sizin için de yeni bir profil otomatik olarak oluşturulacaktır.*
---

## Sayfaların Görevleri ve İçerikleri

1.  **Giriş Sayfası (`login_page.dart`)**
    * Kullanıcının E-posta/Şifre, Google veya GitHub ile giriş yapmasını sağlar.
    * Kayıt sayfasına yönlendirme yapar.

2.  **Kayıt Yöntemi Sayfası (`register_method_page.dart`)**
    * Kullanıcıya E-posta, Google veya GitHub ile kayıt olma seçeneklerini sunar.

3.  **Email ile Kayıt Sayfası (`register_email_page.dart`)**
    * Kullanıcıdan ad, soyad, email, şifre, doğum tarihi, doğum yeri ve yaşadığı il bilgilerini alarak tam bir kayıt işlemi gerçekleştirir.
    * Verileri Firebase Auth, Firestore ve Supabase'e aynı anda kaydeder.

4.  **Ana Sayfa (`main_page.dart`)**
    * Giriş sonrası karşılaşılan ana ekrandır.
    * "Bayrak Yarışı" ve "Bayrakları Öğren" sayfalarına yönlendirme butonları içerir.

5.  **Oyun Sayfası (`game_page.dart`)**
    * Rastgele bir ülke bayrağı ve 4 şıktan oluşan yarışma ekranıdır.
    * 10 soru sorar, doğru/yanlış sayısını takip eder.
    * Oyun sonunda skoru Supabase veritabanına kaydeder.

6.  **Öğrenme Sayfası (`learn_page.dart`)**
    * Tüm ülke bayraklarını ve isimlerini listeleyerek kullanıcının pratik yapmasını sağlar.

7.  **Profil Sayfası (`profile_page.dart`)**
    * Kullanıcının Supabase'deki tüm skorlarından hesaplanan toplam puanını gösterir.
    * Kullanıcının ad, soyad ve email bilgilerini gösterir.
    * Kullanıcının Firestore'daki ek bilgilerini (doğum yeri, il) gösterir ve bunları düzenlemesine olanak tanır.

8.  **Ayarlar Sayfası (`settings_page.dart`)**
    * Açık/Koyu tema değiştirme anahtarı içerir.
    * Tüm skorları sıfırlama fonksiyonu içerir.
    * Hesabı kalıcı olarak silme fonksiyonu içerir.

## Veri Yönetimi ve Saklama

Uygulama, birkaç farklı veri saklama yöntemlerini aktif olarak kullanmaktadır:

* **Firebase Authentication:** Kullanıcıların kimlik doğrulama bilgileri (UID, email, parola hash'i vb.) burada yönetilir.
* **Firebase Firestore:** Detaylı ve esnek kullanıcı verileri (örn: `dogumYeri`, `yasadigiIl`) `users` koleksiyonu altında her kullanıcı için ayrı bir dökümanda saklanır.
* **Supabase:**
    * **`profiles` Tablosu:** Kullanıcının temel profil bilgileri (`id`, `ad`, `soyad`, `email`) burada tutulur.
    * **`scores` Tablosu:** Her oyun sonunda kullanıcının `user_id`'si ile birlikte doğru ve yanlış cevap sayıları bu tabloya kaydedilir.
* **Local Depolama:**
    * **SharedPreferences:** Giriş yapıldıktan sonra `uid`, `email`, `ad` gibi sık kullanılacak veriler, uygulamayı yeniden açınca hızlı erişim için anahtar-değer olarak saklanır.
    * **SQLite:** Giriş yapıldıktan sonra kullanıcının tüm profil verilerinin bir kopyası, çevrimdışı kullanım senaryoları için cihazdaki local veritabanına kaydedilir.

## Kod Yapısı ve Modüller

Proje, yönetilebilirliği artırmak için modüler bir yapıda organize edilmiştir:

* **`lib/widgets`:** `BasePage`, `CustomAppBar` gibi uygulama genelinde kullanılan standart ve yeniden kullanılabilir arayüz bileşenlerini içerir.
* **`lib/services`:** `database_helper.dart` (SQLite işlemleri) ve `theme_notifier.dart` (Tema yönetimi) gibi arka plan servislerini ve iş mantığını içerir.
* **`lib/` (kök dizin):** Uygulamanın ana sayfalarını (`login_page.dart`, `profile_page.dart` vb.) içerir.

## Geliştirme Ortamı

Bu uygulama geliştirilirken aşağıdaki araçlar kullanılmıştır:
* Flutter SDK
* Dart SDK
* Visual Studio Code / Android Studio
* Firebase CLI
* Supabase Platformu

## Ekran Görüntüleri

(Buraya uygulamanın Giriş, Ana Sayfa, Oyun, Profil ve Ayarlar ekranlarından alınmış ekran görüntüleri eklenecek.)
