
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:personality_test/sub/question_page.dart';

import 'package:connectivity_plus/connectivity_plus.dart';// 인터넷 연결 되지 않을때 사용하는 패키지

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() => _MainPage();
}

class _MainPage extends State<MainPage> {
  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
  final FirebaseDatabase database = FirebaseDatabase.instance;
  late DatabaseReference _testRef;

  String welcomeTitle = '';
  bool bannerUse = false;
  int itemHeight = 50;

  @override
  void initState() {
    super.initState();
    _testRef = database.ref('test');
    initRemoteConfig();
  }

  Future<void> initRemoteConfig() async {
    await remoteConfig.fetchAndActivate();
    setState(() {
      welcomeTitle = remoteConfig.getString("welcome");
      bannerUse = remoteConfig.getBool("banner");
      itemHeight = remoteConfig.getInt("item_height");
    });
  }

  Future<List<Map<String, dynamic>>> loadAsset() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    List<Map<String, dynamic>> localList = [];

    final snapshot = await _testRef.get();

    if((connectivityResult == ConnectivityResult.mobile) || (connectivityResult == ConnectivityResult.wifi)) {
      for (var element in snapshot.children) {
        final value = element.value;

        if (value == null) continue;

        if (value is Map) {
          final mapValue = Map<String, dynamic>.from(value);

          if (mapValue['selects'] is! List) {
            mapValue['selects'] = [];
          }
          if (mapValue['answer'] is! List) {
            mapValue['answer'] = [];
          }

          localList.add(mapValue);
        }
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("두근두근 심리테스트"),
              content: Text(
                  "현재 인터넷에 연결 되어있지 않습니다.\n "
                      "나중에 다시 시도해주세요"
              ),
            );
          },
        );
      }
    }

    return localList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: bannerUse ? AppBar(title: Text(welcomeTitle)) : null,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: loadAsset(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('No data found'));
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return InkWell(
                onTap: () async {
                  await FirebaseAnalytics.instance.logEvent(
                    name: "test_click",
                    parameters: {"test_name": item['title'] ?? ''},
                  );
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => QuestionPage(question: item),
                  ));
                },
                child: SizedBox(
                  height: itemHeight.toDouble(),
                  child: Card(
                    color: Colors.white70,
                    child: Center(
                      child: Text(
                        item['title'] ?? 'No Title',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          _testRef.push().set({
            "title": "당신이 좋아하는 애완동물은?",
            "question": "무인도에 도착했는데, 상자 안에 보인 것은?",
            "selects": ["생존 키트", "휴대폰", "텐트", "만화책"],
            "answer": [
              "당신은 현실주의! 동물은 안키운다!",
              "늘 함께 있는 강아지!",
              "같은 공간을 공유하는 고양이!",
              "낭만을 좋아하는 앵무새!"
            ]
          });

          _testRef.push().set({
            "title": "당신은 어떤 사랑을 하고 싶나요?",
            "question": "목욕할 때 가장 먼저 비누칠하는 곳은?",
            "selects": ["머리", "상체", "하체"],
            "answer": [
              "자만추를 추구해요",
              "소개팅을 좋아해요",
              "우연한 만남을 선호해요"
            ]
          });
          _testRef.push().set({
            "title": "5초 MBTI I/E 편",
            "question": "친구와 함께 간 미술관 당신이라면",
            "selects": ["말이 많아짐", "생각이 많아짐"],
            "answer": [
              "당신의 성향은 E",
              "당신의 성향은 I"
            ]
          });
        },
      ),
    );
  }
}
