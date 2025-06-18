import 'package:flutter/material.dart';
import 'package:geofinalapp/widgets/custom_app_bar.dart';
import 'package:geofinalapp/widgets/drawer_menu.dart';

class BasePage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const BasePage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: title, actions: actions),
      drawer: const DrawerMenu(),
      body: body,
    );
  }
}