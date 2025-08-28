import 'package:campign_project/database/data_providers/firebase_remote.data_provider.dart';
import 'package:campign_project/features/sites/repository/site.repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';

import '../../firebase_options.dart';

final locator = GetIt.instance;
typedef NavigatorKey = GlobalKey<NavigatorState>;
Future<void> setUpLocator() async {
  locator.registerLazySingleton<NavigatorKey>(GlobalKey<NavigatorState>.new);
  locator.registerSingletonAsync<FirebaseApp>(
    () => Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  );
  locator.registerLazySingleton<SiteRepository>(() => SiteRepository(remoteDataProvider: FirebaseRemoteDataProvider()));
  await locator.isReady<FirebaseApp>();
}
