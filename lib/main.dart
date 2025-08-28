import 'dart:async';
import 'package:campign_project/features/sites/repository/site.repository.dart';
import 'package:campign_project/core/utils/locator.dart';
import 'package:campign_project/upload_task.dart';
import 'package:campign_project/features/profile/presentation/providers/user.provider.dart';
import 'package:campign_project/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'features/auth/presentation/screens/login.screen.dart';
import 'features/sites/provider/site.provider.dart';
import 'features/auth/repository/auth.repository.dart';
import 'features/auth/service/firebase_api.dart';
import 'features/home/presentation/screens/home.screen.dart';
import 'features/sites/presentation/models/site.model.dart';
import 'features/users/repository/user.repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setUpLocator();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  final androidPlugin =
      FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.requestNotificationsPermission();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});


  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }



  Future<SiteModel?> fetchBySiteId(String siteId) async {
    final doc = await FirebaseFirestore.instance.collection('sites').doc(siteId).get();
    if (doc.exists) {
      final data = doc.data()!;
      return SiteModelMapper.fromMap(data);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<UserRepository>(create: (_) => UserRepository()),
        ChangeNotifierProvider<SiteProvider>(create: (_) => SiteProvider(siteRepository: locator<SiteRepository>())),
        ChangeNotifierProvider<UserProvider>(create: (context) => UserProvider(userRepository: context.read<UserRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Firebase Auth App',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: ThemeData(
          fontFamily: 'PlusJakartaSans',
          textTheme: TextTheme(
            bodyLarge: TextStyle(fontWeight: FontWeight.w700),
            bodyMedium: TextStyle(fontWeight: FontWeight.w500),
            titleLarge: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();
    return StreamBuilder<User?>(
      stream: auth.authStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return const HomeScreen();
        } else {
          return const PhoneLoginScreen();
        }
      },
    );
  }
}
