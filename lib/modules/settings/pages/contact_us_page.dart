import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class ContactUsPage extends StatelessWidget {
  final String content;
  const ContactUsPage({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contact Us")),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(child: Html(data: content)),
            ),
          ],
        ),
      ),
    );
  }
}
