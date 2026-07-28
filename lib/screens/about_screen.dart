import 'package:flutter/material.dart';

/// "Hakkında" screen shown from Settings: app status and developer contact.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hakkında')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Uygulama geliştirilme aşamasındadır. Düşünce ve fikirlerinizi '
          '[baykal246@gmail.com] mail adresine iletebilirsiniz. '
          'Geliştirici ve Yayınlayıcı Mete Baykal',
        ),
      ),
    );
  }
}
