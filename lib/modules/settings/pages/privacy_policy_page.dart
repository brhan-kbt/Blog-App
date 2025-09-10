import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class PrivacyPolicyPage extends StatelessWidget {
  final String content;
  const PrivacyPolicyPage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Policy")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Html(data: content),
      ),
    );
  }
}
