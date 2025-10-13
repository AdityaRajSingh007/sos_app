import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const platform = MethodChannel('com.adityarajsingh.sos_app/critical_alert');
  bool _isAlertActive = false;

  Future<void> _triggerCriticalAlert() async {
    try {
      setState(() => _isAlertActive = true);
      final String result = await platform.invokeMethod('startCriticalAlert');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.green),
      );
    } on PlatformException catch (e) {
      setState(() => _isAlertActive = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _stopCriticalAlert() async {
    try {
      final String result = await platform.invokeMethod('stopCriticalAlert');
      setState(() => _isAlertActive = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), backgroundColor: Colors.orange),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isAlertActive)
              ElevatedButton.icon(
                onPressed: _stopCriticalAlert,
                icon: const Icon(Icons.stop),
                label: const Text('Stop Alert'),
              )
            else
              ElevatedButton.icon(
                onPressed: _triggerCriticalAlert,
                icon: const Icon(Icons.warning),
                label: const Text('Trigger Critical Alert'),
              ),
          ],
        ),
      ),
    );
  }
}


