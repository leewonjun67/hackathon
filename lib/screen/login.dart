import 'package:flutter/material.dart';
import 'package:hackathon/screen/signup.dart';
import 'package:hackathon/screen/uni_select.dart'; // 대학 선택 스크린
import 'package:hackathon/screen/home.dart'; // 홈 스크린
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hackathon/login/google_service.dart';
import 'package:hackathon/login/kakao_service.dart';
import 'package:hackathon/config/login_platform.dart';
import 'package:hackathon/config/login_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({Key? key}) : super(key: key);

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginPlatform _loginPlatform = LoginPlatform.none;
  final _auth = firebase_auth.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  //  공통: 로그인 후 분기
  Future<void> _handleLoginNavigation() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final university = userDoc.data()?['university'];

    if (university != null && university.toString().isNotEmpty) {
      //  대학 정보 있으면 바로 홈으로
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(university: university,url: university,)),
      );
    } else {
      //  대학 정보 없으면 선택 화면으로
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UniversitySearch()),
      );
    }
  }

  // 카카오 로그인
  Future<void> _loginWithKakao() async {
    bool success = await KakaoService().login();
    if (success) {
      setState(() => _loginPlatform = LoginPlatform.kakao);
      await _handleLoginNavigation();
    }
  }

  // 구글 로그인
  Future<void> _loginWithGoogle() async {
    bool success = await GoogleService().login();
    if (success) {
      setState(() => _loginPlatform = LoginPlatform.google);
      await _handleLoginNavigation();
    }
  }

  // 이메일 로그인
  Future<void> _loginWithEmail() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      setState(() => _loginPlatform = LoginPlatform.email);
      await _handleLoginNavigation();
    } catch (error) {
      print('이메일 로그인 실패: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: ${error.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF948BFF),
      body: Stack(
        children: [
          // 상단 빈 공간
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 90, left: 20),
              height: 300,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            ),
          ),
          // 로그인 카드
          Positioned(
            top: 250,
            left: 20,
            right: 20,
            child: Container(
              height: 480.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 이메일 입력
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 비밀번호 입력
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 로그인 버튼
                  ElevatedButton(
                    onPressed: _loginWithEmail,
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 20),
                  // SNS 로그인
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: LoginButton(
                          imagePath: 'asset/img/kakao_logo.png',
                          onPressed: _loginWithKakao,
                        ),
                      ),
                      Flexible(
                        child: LoginButton(
                          imagePath: 'asset/img/google_logo.png',
                          onPressed: _loginWithGoogle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
