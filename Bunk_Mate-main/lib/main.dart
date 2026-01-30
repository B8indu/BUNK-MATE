import 'package:bunk_mate/screens/auth/login_screen.dart';
import 'package:bunk_mate/utils/Navigation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qiziknlansjusuaboqfb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFpemlrbmxhbnNqdXN1YWJvcWZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNTQyMTcsImV4cCI6MjA4MDkzMDIxN30.ftCh3T7CP8WtsbU8a0i1LVXlvHrZxZ-xsdIiLp8SMKw',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(Duration.zero, () => Supabase.instance.client.auth.currentSession != null),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        } else {
          if (snapshot.data == true) {
            return GetMaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Flutter Demo',
              theme: ThemeData(
                colorScheme:
                    ColorScheme.fromSeed(seedColor: Colors.greenAccent),
                useMaterial3: true,
              ),
              home: const Navigation(),
            );
          } else {
            return GetMaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Flutter Demo',
              theme: ThemeData(
                fontFamily: GoogleFonts.lexend().fontFamily,
                colorScheme:
                    ColorScheme.fromSeed(seedColor: Colors.greenAccent),
                useMaterial3: true,
              ),
              home: const AuthScreen(),
            );
          }
        }
      },
    );
  }
}
