import 'package:flutter/material.dart';

class TextSizePage extends StatefulWidget {
  const TextSizePage({super.key});

  @override
  State<TextSizePage> createState() => _TextSizePageState();
}

class _TextSizePageState extends State<TextSizePage> {
  double _size = 16;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Text Size")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Adjust preferred text size"),
            Slider(
              value: _size,
              min: 12,
              max: 24,
              divisions: 6,
              label: _size.toStringAsFixed(0),
              onChanged: (v) => setState(() => _size = v),
            ),
            Text("Preview text", style: TextStyle(fontSize: _size)),
          ],
        ),
      ),
    );
  }
}
