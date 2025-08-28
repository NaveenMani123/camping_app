import 'dart:async';
import 'dart:ui';
import 'package:campign_project/features/profile/presentation/screens/profile.screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../repository/auth.repository.dart';
import '../../../home/presentation/screens/home.screen.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String? phoneNumber;
  final String? potentialCode;

  static Route route({required String verificationId, String? phoneNumber, String? potentialCode}) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: 'otp_screen'),
      builder:
          (context) => OtpVerificationScreen(
            verificationId: verificationId,
            phoneNumber: phoneNumber,
            potentialCode: potentialCode,
          ),
    );
  }

  const OtpVerificationScreen({super.key, required this.verificationId, this.phoneNumber, this.potentialCode});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  Timer? _timer;
  int _remainingTime = 60;
  String? error;
  String? otpCode;
  late String _currentVerificationId;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    if (widget.potentialCode != null) {
      _otpController.text = widget.potentialCode!;
    }
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingTime = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    if (widget.phoneNumber == null) return;
    setState(() {
      _isLoading = true;
      error = null;
    });
    try {
      final auth = context.read<AuthRepository>();
      auth.signInWithPhone(
        phoneNumber: widget.phoneNumber!,
        codeSent: (verificationId, token) {
          setState(() {
            _currentVerificationId = verificationId;
            _isLoading = false;
            _startTimer();
          });
        },
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() {
            error = e.toString();
            _isLoading = false;
          });
        },
        verificationCompleted: (credential) async {
          await auth.firebaseAuth.signInWithCredential(credential);
          if (!mounted) return;
          Navigator.push(context, HomeScreen.route());
        },
        codeAutoRetrievalTimeout: () {},
      );
    } catch (e) {
      setState(() {
        error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _verify() async {
    _showLoadingDialog();
    try {
      final authRepo = context.read<AuthRepository>();
      final userCred = await authRepo.verifyOtp(
        verificationId: _currentVerificationId,
        smsCode: _otpController.text.trim(),
      );

      if (userCred.user == null) {
        throw Exception('Verification failed. Please try again.');
      }

      final uid = userCred.user!.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mounted) return;

      final target = doc.exists ? const HomeScreen() : ProfileScreen();
      Navigator.of(context).pop();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => target), (_) => false);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => error = e.toString());
    }
  }

  void _showLoadingDialog() {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Dialog(
              backgroundColor: Colors.black.withOpacity(0.6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text("Please wait...", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text("Verify OTP", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (widget.phoneNumber != null)
                Text("Code sent to ${widget.phoneNumber}", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Enter 6-digit OTP'),
                maxLength: 6,
                onChanged: (value) {
                  if (value.length == 6) _verify();
                },
              ),
              const SizedBox(height: 20),
              if (error != null) Text(error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
              const SizedBox(height: 20),
              _remainingTime > 0
                  ? Text("Resend OTP in $_remainingTime s", style: const TextStyle(color: Colors.grey))
                  : TextButton(onPressed: _resendOtp, child: const Text("Resend OTP")),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
