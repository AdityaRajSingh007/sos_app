import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../utils/error_handler.dart';
import '../utils/ui_helpers.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contactController = TextEditingController();
  final _guardianContactController = TextEditingController();
  final _enrollmentController = TextEditingController();
  final _hostelWingRoomController = TextEditingController();
  final _addressController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _otherDetailsController = TextEditingController();
  String _accommodationType = 'Hosteller';
  bool _loading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _contactController.dispose();
    _guardianContactController.dispose();
    _enrollmentController.dispose();
    _hostelWingRoomController.dispose();
    _addressController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _otherDetailsController.dispose();
    super.dispose();
  }

  String _formatE164(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91')) {
      return '+$digits';
    }
    if (digits.startsWith('0')) {
      return '+91${digits.substring(1)}';
    }
    if (digits.length >= 10) {
      return '+91$digits';
    }
    return '+91$digits';
  }

  bool _isValidE164(String input) {
    final value = _formatE164(input);
    return RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(value);
  }

  Future<bool> _isEnrollmentUnique(String enrollment) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('enrollmentNumber', isEqualTo: enrollment)
        .limit(1)
        .get();
    return snap.docs.isEmpty;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final fullName = _fullNameController.text.trim();
      final enrollment = _enrollmentController.text.trim();
      final contact = _formatE164(_contactController.text);
      final guardian = _formatE164(_guardianContactController.text);
      final hostelWingRoom = _accommodationType == 'Hosteller' ? _hostelWingRoomController.text.trim() : '';

      // Enforce unique enrollment number
      final unique = await _isEnrollmentUnique(enrollment);
      if (!unique) {
        showErrorSnackBar(context, 'Enrollment number already exists.');
        return;
      }

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;
      final fcmToken = await FirebaseMessaging.instance.getToken();

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'contact': contact,
        'guardianContact': guardian,
        'enrollmentNumber': enrollment,
        'accommodationType': _accommodationType,
        'hostelWingAndRoom': hostelWingRoom.isEmpty ? null : hostelWingRoom,
        'permanentHomeAddress': _addressController.text.trim(),
        'role': 'Student',
        'medicalInfo': {
          'bloodType': _bloodTypeController.text.trim(),
          'allergies': _allergiesController.text.trim(),
          'otherDetails': _otherDetailsController.text.trim(),
        },
        'assignedResponders': <String>[],
        'fcmToken': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      showErrorSnackBar(context, getFirebaseAuthErrorMessage(e));
    } catch (_) {
      showErrorSnackBar(context, 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.length < 3 || value.length > 32) return 'Name must be 3-32 chars';
                  if (RegExp(r'\d').hasMatch(value)) return 'Name cannot contain digits';
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v ?? '') ? null : 'Enter a valid email',
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => (v != null && v.length >= 6) ? null : 'Min 6 characters',
              ),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact (+91...)'),
                keyboardType: TextInputType.phone,
                validator: (v) => _isValidE164(v ?? '') ? null : 'Enter valid phone number',
              ),
              TextFormField(
                controller: _guardianContactController,
                decoration: const InputDecoration(labelText: 'Guardian Contact (+91...)'),
                keyboardType: TextInputType.phone,
                validator: (v) => _isValidE164(v ?? '') ? null : 'Enter valid phone number',
              ),
              TextFormField(
                controller: _enrollmentController,
                decoration: const InputDecoration(labelText: 'Enrollment Number'),
                validator: (v) => (v != null && v.isNotEmpty) ? null : 'Required',
              ),
              const SizedBox(height: 8),
              const Text('Accommodation Type'),
              Row(
                children: [
                  Radio<String>(
                    value: 'Hosteller',
                    groupValue: _accommodationType,
                    onChanged: (v) => setState(() => _accommodationType = v!),
                  ),
                  const Text('Hosteller'),
                  Radio<String>(
                    value: 'Dayscholar',
                    groupValue: _accommodationType,
                    onChanged: (v) => setState(() => _accommodationType = v!),
                  ),
                  const Text('Dayscholar'),
                ],
              ),
              if (_accommodationType == 'Hosteller')
                TextFormField(
                  controller: _hostelWingRoomController,
                  decoration: const InputDecoration(labelText: 'Hostel, Wing, Room'),
                  validator: (v) => (v != null && v.trim().isNotEmpty) ? null : 'Required for hostellers',
                ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Permanent Home Address'),
              ),
              const SizedBox(height: 8),
              const Text('Medical Info'),
              TextFormField(
                controller: _bloodTypeController,
                decoration: const InputDecoration(labelText: 'Blood Type (e.g., O+)'),
              ),
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(labelText: 'Allergies'),
              ),
              TextFormField(
                controller: _otherDetailsController,
                decoration: const InputDecoration(labelText: 'Other Details'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading ? const CircularProgressIndicator() : const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


