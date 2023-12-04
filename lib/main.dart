import 'package:flutter/material.dart';
import 'package:py/views/login.dart';
import 'package:flutter/services.dart';
import 'package:py/utils/const.dart' as cons;



 void main() {
  //SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      //.then((_) {
    runApp(const MyApp());
  //});
}
 
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E1E1E)),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}
 
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _mockCheckForSession(), // Función que simula la carga inicial
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Muestra la pantalla de bienvenida mientras espera
          return Scaffold(
            backgroundColor: cons.black,
            body: Center(
              child: Image.asset('assets/logo.png'),
            ),
          );
        } else {
          // Navega a la pantalla de inicio de sesión después de la carga
          return const Login();
        }
      },
    );
  }
 
  Future<void> _mockCheckForSession() async {
    // Simula la carga inicial
    await Future.delayed(const Duration(seconds: 3));
  }
}
