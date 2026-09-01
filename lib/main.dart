import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:pressing_opropre/connexion/login.dart';
import 'package:pressing_opropre/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
void main() async{
 WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    DevicePreview(
      enabled: true,
      tools: [...DevicePreview.defaultTools],
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
     
      debugShowCheckedModeBanner: false,
      home: const Login(),
    );
  }
}