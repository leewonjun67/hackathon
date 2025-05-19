import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String university;

  ChatPage({required this.university});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userName;
  String? userProfilePicUrl;  // 프로필 사진 URL 변수 추가

  late CollectionReference chatCollection;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _getUserInfo(user.uid);
    } else {
      userName = '익명';
      userProfilePicUrl = null;
    }

    final schoolKey = _convertToSchoolKey(widget.university);
    chatCollection = _firestore.collection('chat_$schoolKey');
  }

  // 사용자 이름과 프로필 사진 URL 같이 가져오기
  Future<void> _getUserInfo(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'] ?? '익명';
          userProfilePicUrl = (userDoc['profilePicUrl'] != '') ? userDoc['profilePicUrl'] : null;
        });
      } else {
        setState(() {
          userName = '익명';
          userProfilePicUrl = null;
        });
      }
    } catch (e) {
      setState(() {
        userName = '익명';
        userProfilePicUrl = null;
      });
      print('Error fetching user info: $e');
    }
  }

  // 학교명 키 변환 함수는 기존과 동일
  String _convertToSchoolKey(String university) {
    switch (university) {
      case '국립공주대학교':
        return 'gongju';
      case '단국대학교':
        return 'dankook';
      case '상명대학교':
        return 'sangmyung';
      case '선문대학교':
        return 'sunmoon';
      case '순천향대학교':
        return 'soonchunyang';
      case '나사렛대학교':
        return 'nasaret';
      case '남서울대학교':
        return 'namseoul';
      case '백석대학교':
        return 'baekseok';
      case '백석문화대학교':
        return 'baekseokculture';
      case '한국기술교육대학교':
        return 'koreatech';
      case '호서대학교':
        return 'hoseo';
      default:
        return 'default';
    }
  }

  // 메시지 전송 시 프로필 사진 URL도 같이 저장
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && userName != null) {
      chatCollection.add({
        'text': text,
        'sender': userName,
        'profilePicUrl': userProfilePicUrl ?? '',  // 빈 문자열이면 기본 이미지 사용
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userName == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("채팅", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFF948BFF),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF0F0FF),
      appBar: AppBar(
        title: Text("채팅", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF948BFF),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatCollection.orderBy('timestamp', descending: false).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final bool isMe = data['sender'] == userName;
                    final time = (data['timestamp'] as Timestamp?)?.toDate();
                    final timeString = time != null ? DateFormat.Hm().format(time) : '';

                    final String senderName = data['sender'] ?? '익명';
                    final String profilePicUrl = (data['profilePicUrl'] != null && data['profilePicUrl'] != '') ? data['profilePicUrl'] : '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // 내 메시지면 프로필 사진 오른쪽에, 남 메시지면 왼쪽에
                            if (!isMe) ...[
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: profilePicUrl.isNotEmpty
                                    ? NetworkImage(profilePicUrl)
                                    : AssetImage('assets/default_avatar.png') as ImageProvider,
                              ),
                              SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? Color(0xFF948BFF) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      senderName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: isMe ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      data['text'] ?? '',
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Colors.black87,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      timeString,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe ? Colors.white70 : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isMe) ...[
                              SizedBox(width: 8),
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: profilePicUrl.isNotEmpty
                                    ? NetworkImage(profilePicUrl)
                                    : AssetImage('assets/default_avatar.png') as ImageProvider,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "메시지를 입력하세요...",
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    backgroundColor: Color(0xFF948BFF),
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}