import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String _userName = '로딩 중...';
  String _userEmail = '로딩 중...';
  String _profilePicUrl = '';
  String _selectedUniversity = '정보 없음';
  DateTime? _createdAt;

  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  XFile? _pickedImage;
  bool _isUploading = false;

  final List<String> _universities = [
    "국립공주대학교",
    "단국대학교",
    "상명대학교",
    "선문대학교",
    "순천향대학교",
    "나사렛대학교",
    "남서울대학교",
    "백석대학교",
    "한국기술교육대학교",
    "호서대학교",
    "백석문화대학교",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    firebase_auth.User? user = _firebaseAuth.currentUser;
    if (user != null) {
      String email = user.email ?? '이메일 없음';

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;

          Timestamp? timestamp = data['createdAt'] as Timestamp?;
          DateTime? createdAtDate = timestamp?.toDate();

          setState(() {
            _userName = data['name'] ?? '사용자 이름 없음';
            _profilePicUrl = data['profilePicUrl'] ?? '';
            _userEmail = email;
            _selectedUniversity = data['university'] ?? '대학교 정보 없음';
            _createdAt = createdAtDate;
          });
        } else {
          setState(() {
            _userName = user.displayName ?? '사용자 이름 없음';
            _profilePicUrl = user.photoURL ?? '';
            _userEmail = email;
            _selectedUniversity = '대학교 정보 없음';
            _createdAt = null;
          });
        }
      } catch (e) {
        print('사용자 정보 불러오기 실패: $e');
        setState(() {
          _userName = '정보 불러오기 실패';
          _userEmail = email;
          _selectedUniversity = '정보 불러오기 실패';
          _profilePicUrl = '';
          _createdAt = null;
        });
      }
    } else {
      setState(() {
        _userName = '로그인 필요';
        _userEmail = '-';
        _selectedUniversity = '-';
        _profilePicUrl = '';
        _createdAt = null;
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _pickedImage = pickedFile;
      _isUploading = true;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      await storageRef.putFile(File(pickedFile.path));

      String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profilePicUrl': downloadUrl,
      });

      setState(() {
        _profilePicUrl = downloadUrl;
        _isUploading = false;
        _pickedImage = null; // 업로드 후 로컬 임시 이미지 초기화
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 사진이 변경되었습니다')),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 업로드 실패: $e')),
      );
    }
  }

  Future<void> _changePassword() async {
    _currentPasswordController.clear();
    _newPasswordController.clear();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('비밀번호 변경'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '현재 비밀번호 입력',
                ),
              ),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호 입력',
                  hintText: '최소 6자 이상',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentPassword = _currentPasswordController.text;
                final newPassword = _newPasswordController.text;

                if (currentPassword.isEmpty || newPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('모든 필드를 입력하세요')),
                  );
                  return;
                }
                if (newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('새 비밀번호는 최소 6자 이상이어야 합니다')),
                  );
                  return;
                }

                try {
                  final user = _firebaseAuth.currentUser;
                  if (user == null) throw Exception('로그인 정보가 없습니다.');

                  final credential = firebase_auth.EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPassword,
                  );
                  await user.reauthenticateWithCredential(credential);

                  await user.updatePassword(newPassword);
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다')),
                  );
                } catch (e) {
                  print('비밀번호 변경 실패: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('비밀번호 변경 실패: $e')),
                  );
                }
              },
              child: const Text('변경'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeUniversity() async {
    String? selected = await showDialog<String>(
      context: context,
      builder: (context) {
        String tempSelected = _selectedUniversity == '정보 없음' ? _universities[0] : _selectedUniversity;
        return AlertDialog(
          title: const Text('대학교 선택'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _universities.length,
                  itemBuilder: (context, index) {
                    return RadioListTile<String>(
                      title: Text(_universities[index]),
                      value: _universities[index],
                      groupValue: tempSelected,
                      onChanged: (value) {
                        setState(() {
                          tempSelected = value!;
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(tempSelected),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (selected != null && selected != _selectedUniversity) {
      try {
        final user = _firebaseAuth.currentUser;
        if (user == null) throw Exception('로그인 정보가 없습니다.');

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'university': selected,
        });

        setState(() {
          _selectedUniversity = selected;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('대학교가 성공적으로 변경되었습니다')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('대학교 변경 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
        backgroundColor: const Color(0xFF948BFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_profilePicUrl.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImagePreviewPage(imageUrl: _profilePicUrl),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 70,
                    backgroundImage: _pickedImage != null
                        ? FileImage(File(_pickedImage!.path))
                        : (_profilePicUrl.isNotEmpty
                        ? NetworkImage(_profilePicUrl)
                        : const AssetImage('asset/img/상명대학교.png') as ImageProvider),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: InkWell(
                    onTap: _isUploading ? null : _pickAndUploadImage,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: _isUploading
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.camera_alt, color: Color(0xFF948BFF)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _userName,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.email, color: Color(0xFF948BFF)),
                title: const Text('이메일'),
                subtitle: Text(_userEmail),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.lock, color: Color(0xFF948BFF)),
                title: const Text('비밀번호'),
                subtitle: const Text('보안상 표시 불가'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF948BFF)),
                  onPressed: _changePassword,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.school, color: Color(0xFF948BFF)),
                title: const Text('대학교'),
                subtitle: Text(_selectedUniversity),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF948BFF)),
                  onPressed: _changeUniversity,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Color(0xFF948BFF)),
                title: const Text('가입일'),
                subtitle: Text(
                  _createdAt != null
                      ? DateFormat('yyyy년 MM월 dd일').format(_createdAt!)
                      : '가입일 정보 없음',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFF948BFF)),
                title: const Text('로그아웃'),
                onTap: () async {
                  await firebase_auth.FirebaseAuth.instance.signOut();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// 사진 확대/축소 페이지
class ImagePreviewPage extends StatelessWidget {
  final String imageUrl;

  const ImagePreviewPage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('프로필 사진'),
        backgroundColor: const Color(0xFF948BFF),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 4.0,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
