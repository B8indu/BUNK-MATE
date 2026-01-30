import 'package:bunk_mate/controllers/homepage/course_summary_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginController extends GetxController {
  final CourseSummaryController courseSummaryController = Get.put(CourseSummaryController());
  final _storage = const FlutterSecureStorage();
  var isLogged = false.obs;

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }
Future<bool> logoutfunction() async {
      try {
        await Supabase.instance.client.auth.signOut();
        await _storage.delete(key: 'token');
        isLogged.value = false;
      } catch (error) {
        Get.back();
        showDialog(
            context: Get.context!,
            builder: (context) {
              return SimpleDialog(
                title: const Text('Error'),
                contentPadding: const EdgeInsets.all(20),
                children: [Text(error.toString())],
              );
            });
      }
    return isLogged.value;
    }
  Future<bool> loginFunction() async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: usernameController.value.text, // Assuming username is email, or adjust if needed
        password: passwordController.value.text,
      );
      if (response.session != null) {
        // Store token for compatibility
        await _storage.write(key: 'token', value: response.session!.accessToken);
        usernameController.clear();
        passwordController.clear();
        isLogged.value = true;
      } else {
        isLogged.value = false;
        throw 'Login failed';
      }
    } catch (error) {
      isLogged.value = false;
      String errorMessage = 'An error occurred during login';

      // Parse Supabase auth errors for user-friendly messages
      if (error.toString().contains('Invalid login credentials')) {
        errorMessage = 'Invalid email or password. Please check your credentials and try again.';
      } else if (error.toString().contains('Email not confirmed')) {
        errorMessage = 'Please check your email and confirm your account before logging in.';
      } else if (error.toString().contains('Too many requests')) {
        errorMessage = 'Too many login attempts. Please wait a few minutes before trying again.';
      } else if (error.toString().contains('User not found')) {
        errorMessage = 'No account found with this email address.';
      } else if (error.toString().contains('Invalid email')) {
        errorMessage = 'Please enter a valid email address.';
      }

      Get.back();
      showDialog(
          context: Get.context!,
          builder: (context) {
            return SimpleDialog(
              title: const Text('Login Error'),
              contentPadding: const EdgeInsets.all(20),
              children: [Text(errorMessage)],
            );
          });
    }
    return isLogged.value;
  }
}