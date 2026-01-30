import 'package:bunk_mate/models/course_summary_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'dart:core';
import 'package:bunk_mate/screens/OnBoardView.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CourseSummaryController extends GetxController {
  var courseSummary = <CourseSummary>[].obs;
  final storage = const FlutterSecureStorage();

  Future<void> fetchCourseSummary() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        courseSummary.clear();
        Get.offAll(const TimetableView());
        return;
      }

      final response = await supabase
          .from('courses')
          .select()
          .eq('user_id', user.id);

      courseSummary.value = response.map((course) => CourseSummary.fromJson(course)).toList();
    } catch (error) {
      print(error);
      courseSummary.clear();
    }
  }
}
