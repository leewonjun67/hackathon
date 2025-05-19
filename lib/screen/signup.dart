import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hackathon/screen/login.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  XFile? _pickedImage;

  // 이미지 선택 함수
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
      });
    }
  }

  // 이미지 업로드 함수 (개선된 버전)
  Future<String?> _uploadImage(String uid) async {
    if (_pickedImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      final uploadTask = await storageRef.putFile(File(_pickedImage!.path));

      // 업로드 완료 후 다운로드 URL 받기
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('프로필 사진 업로드 성공 URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('프로필 사진 업로드 실패: $e');
      return null;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // 키보드 올라올 때 overflow 방지
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '회원가입',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 프로필 사진 선택 위젯
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _pickedImage != null
                      ? FileImage(File(_pickedImage!.path))
                      : const AssetImage('asset/img/google_logo.png')
                  as ImageProvider,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(child: Text('프로필 사진 선택 (클릭)')),

            const SizedBox(height: 30),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    // Firebase Auth 회원가입
                    UserCredential userCredential =
                    await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );

                    String uid = userCredential.user?.uid ?? '';

                    // 이미지 업로드 및 URL 받기
                    String? profilePicUrl = await _uploadImage(uid);

                    // Firestore에 유저 정보 저장
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .set({
                      'firebaseUserId': uid,
                      'name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'roles': ["admin", "user"],
                      'profilePicUrl': profilePicUrl ?? '',
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    // 회원가입 완료 후 로그인 화면으로 이동
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginSignupScreen()),
                    );
                  } catch (e) {
                    print('회원가입 실패: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('회원가입 실패: ${e.toString()}')),
                    );
                  }
                },
                child: const Text('회원가입 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
