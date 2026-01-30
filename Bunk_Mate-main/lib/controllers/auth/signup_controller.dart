import 'package:bunk_mate/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:core';
import 'package:supabase_flutter/supabase_flutter.dart';


class SignupController extends GetxController {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  TextEditingController confirmPasswordController = TextEditingController();

  bool status = false;
    Future<void> signUpFunction() async {
    if (passwordController.value.text == confirmPasswordController.value.text) {
      try {
        final response = await Supabase.instance.client.auth.signUp(
          email: usernameController.value.text, // Assuming username is email
          password: passwordController.value.text,
        );
        if (response.user != null) {
          usernameController.clear();
          passwordController.clear();
          confirmPasswordController.clear();
          Get.off(const AuthScreen());
        } else {
          throw 'Signup failed';
        }
      } catch (error) {
        Get.back();
        showDialog(context: Get.context!, builder: (context){
          return SimpleDialog(
            title: const Text('Error'),
            contentPadding: const EdgeInsets.all(20),
            children: [Text(error.toString())],
          );
        });
      }
    } else {
      Get.snackbar("Error", "The Password doesn't match",backgroundColor: Color(0xFF1E1E1E), colorText: Colors.white);
    }
    
  } 
 }
