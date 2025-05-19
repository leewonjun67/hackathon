import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hackathon/screen/home.dart';

class UniversitySearch extends StatefulWidget {
  @override
  _UniversitySearchState createState() => _UniversitySearchState();
}

class _UniversitySearchState extends State<UniversitySearch> {
  final List<String> universities = [
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

  final Map<String, String> universityImages = {
    "국립공주대학교": "asset/img/국립공주대학교.png",
    "단국대학교": "asset/img/단국대학교.png",
    "상명대학교": "asset/img/상명대학교.png",
    "선문대학교": "asset/img/선문대학교.png",
    "순천향대학교": "asset/img/순천향대학교.png",
    "나사렛대학교": "asset/img/나사렛대학교.png",
    "남서울대학교": "asset/img/남서울대학교.png",
    "백석대학교": "asset/img/백석대학교.png",
    "한국기술교육대학교": "asset/img/한국기술교육대학교.png",
    "호서대학교": "asset/img/호서대학교.png",
    "백석문화대학교": "asset/img/백석문화대학교.png",
  };

  final Map<String, String> universityurl = {
    "국립공주대학교": "https://www.utic.go.kr/jsp/map/cctvStream.jsp?cctvid=L360054&cctvname=%25EC%2586%25A1%25EC%259C%25A0%25EA%25B4%2580%25EC%259E%2585%25EA%25B5%25AC&kind=Z&cctvip=210.99.70.120&cctvch=undefined&id=cctv061&cctvpasswd=undefined&cctvport=undefined&minX=127.13487072988353&minY=36.836041647661986&maxX=127.17954600952454&maxY=36.86044950852655",
    "단국대학교": "https://www.utic.go.kr/jsp/map/cctvStream.jsp?cctvid=L360014&cctvname=%25EB%258B%25A8%25EB%258C%2580%25EC%259E%2585%25EA%25B5%25AC%2520%25EC%2582%25AC%25EA%25B1%25B0%25EB%25A6%25AC&kind=Z&cctvip=210.99.70.120&cctvch=undefined&id=cctv038&cctvpasswd=undefined&cctvport=undefined&minX=127.03223959384204&minY=36.769999035643345&maxX=127.31961324710771&maxY=36.89521852991185",
    "상명대학교": "https://www.utic.go.kr/jsp/map/cctvStream.jsp?cctvid=L360014&cctvname=%25EB%258B%25A8%25EB%258C%2580%25EC%259E%2585%25EA%25B5%25AC%2520%25EC%2582%25AC%25EA%25B1%25B0%25EB%25A6%25AC&kind=Z&cctvip=210.99.70.120&cctvch=undefined&id=cctv038&cctvpasswd=undefined&cctvport=undefined&minX=127.03223959384204&minY=36.769999035643345&maxX=127.31961324710771&maxY=36.89521852991185",
    "선문대학교": "https://www.utic.go.kr/jsp/map/cctvStream.jsp?cctvid=L360083&cctvname=%25EC%25B2%25AD%25EC%2582%25BC%25EA%25B5%2590%25EC%25B0%25A8%25EB%25A1%259C&kind=Z&cctvip=210.99.70.120&cctvch=undefined&id=cctv010&cctvpasswd=undefined&cctvport=undefined&minX=127.14088788805081&minY=36.76935672251755&maxX=127.18553620325463&maxY=36.79462813114407",
    "순천향대학교": "https://www.utic.go.kr/jsp/map/cctvStream.jsp?cctvid=E901386&cctvname=%255B%25EA%25B5%25AD%25EB%258F%258421%255D%25EC%2595%2584%25EC%2582%25B0%25EC%2588%259C%25EC%25B2%259C%25ED%2596%25A5%25EB%258C%2580%25EC%2582%25BC%25EA%25B1%25B0%25EB%25A6%25AC&kind=Z3&cctvip=undefined&cctvch=undefined&id=71825/RbspYg4mJdF564F78DLduCnYFrXWNGFjr/Nodnkk2Z2hJz%2BDy%2BtOG4FplYfHT9RRZ9UHXl%2BDS9pUBpjRDE99v3vIGUi2HJhIQ2JBTgJVTno=&cctvpasswd=undefined&cctvport=undefined&minX=126.90600969244527&minY=36.755031053878035&maxX=126.98521400473591&maxY=36.79570064882271",
    "나사렛대학교": "https://www.utic.go.kr/jsp/map/cctvStream.jsp?cctvid=L360075&cctvname=%25EC%259D%25BC%25EB%25B4%2589%25EC%2582%25B0%25EC%2582%25AC%25EA%25B1%25B0%25EB%25A6%25AC&kind=Z&cctvip=210.99.70.120&cctvch=undefined&id=cctv052&cctvpasswd=undefined&cctvport=undefined&minX=127.09059929583803&minY=36.77416565378589&maxX=127.16212924305047&maxY=36.80987212887108",
    "남서울대학교": "https://www.utic.go.kr/jsp/map/cctvStream.jsp?cctvid=L360029&cctvname=%25EB%25B3%25B5%25EC%25A7%2580%25EA%25B4%2580%25EC%2582%25AC%25EA%25B1%25B0%25EB%25A6%25AC&kind=Z&cctvip=210.99.70.120&cctvch=undefined&id=cctv083&cctvpasswd=undefined&cctvport=undefined&minX=127.10776500417055&minY=36.89906193263836&maxX=127.15246542798808&maxY=36.92434254602971",
    "백석대학교": "https://www.utic.go.kr/jsp/map/cctvStream.jsp?cctvid=L360014&cctvname=%25EB%258B%25A8%25EB%258C%2580%25EC%259E%2585%25EA%25B5%25AC%2520%25EC%2582%25AC%25EA%25B1%25B0%25EB%25A6%25AC&kind=Z&cctvip=210.99.70.120&cctvch=undefined&id=cctv038&cctvpasswd=undefined&cctvport=undefined&minX=127.03223959384204&minY=36.769999035643345&maxX=127.31961324710771&maxY=36.89521852991185",
    "한국기술교육대학교": "https://www.utic.go.kr/jsp/map/cctvStream.jsp?cctvid=L360083&cctvname=%25EC%25B2%25AD%25EC%2582%25BC%25EA%25B5%2590%25EC%25B0%25A8%25EB%25A1%259C&kind=Z&cctvip=210.99.70.120&cctvch=undefined&id=cctv010&cctvpasswd=undefined&cctvport=undefined&minX=127.14088788805081&minY=36.76935672251755&maxX=127.18553620325463&maxY=36.79462813114407",
    "호서대학교": "https://www.utic.go.kr/jsp/map/cctvStream.jsp?cctvid=L360014&cctvname=%25EB%258B%25A8%25EB%258C%2580%25EC%259E%2585%25EA%25B5%25AC%2520%25EC%2582%25AC%25EA%25B1%25B0%25EB%25A6%25AC&kind=Z&cctvip=210.99.70.120&cctvch=undefined&id=cctv038&cctvpasswd=undefined&cctvport=undefined&minX=127.03223959384204&minY=36.769999035643345&maxX=127.31961324710771&maxY=36.89521852991185",
    "백석문화대학교": "https://www.utic.go.kr/jsp/map/cctvStream.jsp?cctvid=L360014&cctvname=%25EB%258B%25A8%25EB%258C%2580%25EC%259E%2585%25EA%25B5%25AC%2520%25EC%2582%25AC%25EA%25B1%25B0%25EB%25A6%25AC&kind=Z&cctvip=210.99.70.120&cctvch=undefined&id=cctv038&cctvpasswd=undefined&cctvport=undefined&minX=127.03223959384204&minY=36.769999035643345&maxX=127.31961324710771&maxY=36.89521852991185",

  };
  List<String> filteredUniversities = [];
  TextEditingController searchController = TextEditingController();
  String? selectedUniversity;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterUniversities);
  }

  void _filterUniversities() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredUniversities = [];
      } else {
        filteredUniversities =
            universities.where((univ) => univ.toLowerCase().contains(query)).toList();
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _saveSelectedUniversity(String university) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'selectedUniversity': university,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('대학교 선택'),
        backgroundColor: const Color(0xFF948BFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 상단 이미지 (선택된 대학 이미지)
            selectedUniversity != null
                ? Image.asset(
              universityImages[selectedUniversity!]!,
              height: 200,
              width: double.maxFinite,
              fit: BoxFit.fill,
            )
                : Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Center(
                child: Text("대학을 선택하세요.", style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 5),

            // 검색창
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "대학교 검색",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),

            // 검색 결과 리스트
            Expanded(
              child: filteredUniversities.isNotEmpty
                  ? ListView.builder(
                itemCount: filteredUniversities.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(filteredUniversities[index]),
                    onTap: () {
                      setState(() {
                        selectedUniversity = filteredUniversities[index];
                      });
                    },
                  );
                },
              )
                  : const Center(child: Text("검색 결과가 없습니다.")),
            ),
            const SizedBox(height: 20),

            // 다음 버튼
            ElevatedButton(
              onPressed: selectedUniversity != null
                  ? () async {
                await _saveSelectedUniversity(selectedUniversity!);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeScreen(
                        university: selectedUniversity!,
                        url: universityurl[selectedUniversity!]!

                  ),
                  ),
                );
              }
                  : null,
              child: const Text("다음"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
