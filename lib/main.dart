import 'package:flutter/material.dart';
import '../login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'firebase_options.dart';
import 'camera.dart';

late List<CameraDescription> cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: 'login',
      routes: {
        'login': (context) => MyLogin(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/camera'){
          return PageRouteBuilder(pageBuilder: (_,__,___) => MyCam(cameras:cameras, model: settings.arguments as String,), transitionsBuilder: (_,__,___,child)=>child);
        }
      },
    );
  }
}