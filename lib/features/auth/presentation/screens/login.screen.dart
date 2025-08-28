import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../../repository/auth.repository.dart';
import '../../../home/presentation/screens/home.screen.dart';
import 'otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {

  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  String phoneNumber = '';
  bool _isLoading = false;
  String? error;

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  void _setError(String? message) {
    setState(() {
      error = message;
    });
  }

  Future<void> login() async {
    if (phoneNumber.isEmpty) {
      _setError('Please enter a valid phone number');
      return;
    }
    _setLoading(true);
    _setError(null);

    final auth = context.read<AuthRepository>();
    await auth.signInWithPhone(
      phoneNumber: phoneNumber,
      codeSent: (verificationId, token) {
        Navigator.push(
          context,
          OtpVerificationScreen.route(
            verificationId: verificationId,
            phoneNumber: phoneNumber,
            potentialCode: null,
          ),
        );
      },
      verificationFailed: (e) {
        _setLoading(false);
        _setError(e.toString());
      },
      verificationCompleted: (credential) async {
        if(credential.smsCode!=null && mounted){
          Navigator.push(
            context,
            OtpVerificationScreen.route(
              verificationId:credential.verificationId!,
              phoneNumber: phoneNumber,
              potentialCode: credential.smsCode,
            ),
          );
        }
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (!mounted) return;
        Navigator.push(context, HomeScreen.route());
      },
      codeAutoRetrievalTimeout: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Phone Login")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome Back!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Enter your phone number to continue"),
            const SizedBox(height: 30),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            IntlPhoneField(
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              initialCountryCode: 'IN',
              onChanged: (phone) {
                phoneNumber = phone.completeNumber;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                        onPressed: login,
                        child: const Text("Continue"),
                      ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
