import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geofinalapp/widgets/base_page.dart';

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});
  @override
  createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  List<dynamic> ulkeler = [];

  @override
  void initState() {
    super.initState();
    verileriYukle();
  }

  Future<void> verileriYukle() async {
    String jsonData = await rootBundle.loadString("assets/flags.json");
    // Sayfa ekrandan kaldırıldıysa setState çağırmayı engelle
    if (mounted) {
      setState(() {
        ulkeler = jsonDecode(jsonData);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Bayrakları Öğren',
      body:
          ulkeler.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: ulkeler.length,
                itemBuilder: (context, index) {
                  final ulke = ulkeler[index];
                  return ListTile(
                    leading: Image.network(
                      ulke['flag'],
                      width: 50,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error, color: Colors.red);
                      },
                    ),
                    title: Text(ulke['name']),
                  );
                },
              ),
    );
  }
}
