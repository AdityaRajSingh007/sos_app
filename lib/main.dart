import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS App - Critical Alert PoC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

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
      setState(() {
        _isAlertActive = true;
      });
      
      final String result = await platform.invokeMethod('startCriticalAlert');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on PlatformException catch (e) {
      setState(() {
        _isAlertActive = false;
      });
      
      if (mounted) {
        String errorMessage = "Failed to trigger alert: ${e.message}";
        
        if (e.code == "PERMISSION_DENIED") {
          errorMessage = "Permission denied. Please grant notification policy access in settings.";
        } else if (e.code == "AUDIO_PERMISSION_DENIED") {
          errorMessage = "Audio permission required. Please grant 'Modify Audio Settings' permission for volume control.";
        } else if (e.code == "SERVICE_ERROR") {
          errorMessage = "Service error: ${e.message}";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () {
                // Could open settings here if needed
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAlertActive = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Unexpected error: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _stopCriticalAlert() async {
    try {
      final String result = await platform.invokeMethod('stopCriticalAlert');
      
      setState(() {
        _isAlertActive = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to stop alert: ${e.message}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS App - Critical Alert PoC'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.red.shade600,
              ),
              const SizedBox(height: 24),
              Text(
                'Critical Alert Test',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This will trigger a critical alert that bypasses Do Not Disturb and plays at maximum volume.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (_isAlertActive) ...[
                ElevatedButton.icon(
                  onPressed: _stopCriticalAlert,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Alert'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Alert is active! It will auto-stop in 1 minute.',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _triggerCriticalAlert,
                  icon: const Icon(Icons.warning),
                  label: const Text('Trigger Critical Alert'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Instructions:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('1. Put your device in Do Not Disturb mode'),
                      const Text('2. Set volume to minimum'),
                      const Text('3. Grant "Modify Audio Settings" permission when prompted'),
                      const Text('4. Press the button above'),
                      const Text('5. Alert should play at max volume and show full-screen notification'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
