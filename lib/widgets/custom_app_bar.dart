import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    // Standart olarak gösterilecek logo butonu
    final List<Widget> defaultActions = [
      Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/settings'),
          child: Image.asset('assets/logo.png', height: 30),
        ),
      ),
    ];

    return AppBar(
      title: Text(title),
      // Eğer dışarıdan özel bir `actions` listesi gelirse onu kullan,
      // gelmezse bizim standart logomuzu kullan.
      actions: actions ?? defaultActions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}