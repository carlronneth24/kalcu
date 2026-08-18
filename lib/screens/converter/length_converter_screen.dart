import 'package:flutter/material.dart';

/// Placeholder screen for the Length converter feature.
/// Replace this with the full converter UI when ready.
class LengthConverterScreen extends StatelessWidget {
  const LengthConverterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Length Converter',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Length converter coming soon',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}