import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> uploadStopsToFirestore() async {
  List<String> universities = ['상명대학교', '호서대학교', '백석대학교','백석문화대학교','단국대학교','국립공주대학교','한국기술교육대학교','남서울대학교','선문대학교','순천향대학교','나사렛대학교'];

  for (final univ in universities) {
    await _upload(univ);
  }
}

Future<void> _upload(String university) async {
  try {
    final filePath = 'asset/stop/stops_${university}.json';
    final jsonString = await rootBundle.loadString(filePath);
    final List<dynamic> stopsData = json.decode(jsonString);

    await FirebaseFirestore.instance
        .collection('university')
        .doc(university)
        .set({'stops': stopsData});

    print('✅ $university 업로드 성공');
  } catch (e) {
    print('❌ $university 업로드 실패: $e');
  }
}

