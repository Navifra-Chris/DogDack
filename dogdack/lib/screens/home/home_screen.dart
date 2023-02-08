import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dogdack/controllers/mypage_controller.dart';
import 'package:dogdack/screens/home/bar_char.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dogdack/commons/logo_widget.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../models/dog_data.dart';


class HomePage extends StatefulWidget {
  HomePage({super.key});

  final inputController = TextEditingController();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Firebase : 반려견 테이블 참조 값
  final petsRef = FirebaseFirestore.instance.collection('Users/${FirebaseAuth.instance.currentUser!.email.toString()}/Pets')
      .withConverter(fromFirestore: (snapshot, _) => DogData.fromJson(snapshot.data()!), toFirestore: (dogData, _) => dogData.toJson());

  final sliderController = Get.put(HomePageSliderController());

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double width = size.width;
    double height = size.height;

    return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(height * 0.12),
          child: const LogoWidget(),
        ),
        body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, size.height * 0.02, 0, 0),
              child: Column(
                children: [
                  StreamBuilder(
                    stream: petsRef.orderBy('createdAt').snapshots(),
                    builder: (context, snapshot) {
                      // 데이터를 아직 불러오지 못했으면 로딩
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      // 불러온 데이터가 없을 경우 등록 안내
                      if (snapshot.data!.docs.length == 0) {
                        return Center(
                          child: Text('마이 페이지에서 댕댕이를 등록해주세요!'),
                        );
                      }

                      // 여기서 부터는 등록된 반려견이 1마리 이상 존재함.

                      //오늘 날짜 구하기
                      var _today = DateTime.now();
                      //현재 선택된 반려견 생일 문자열 파싱
                      String _petBirthYearOrigin = snapshot.data!.docs[sliderController.sliderIdx].get('birth');
                      String _petBirth = '';
                      List<String> birthList = _petBirthYearOrigin.split('.');
                      for(int liIdx = 0; liIdx < birthList.length; liIdx++) {
                        _petBirth += birthList.elementAt(liIdx);
                      }
                      int displayBirth = int.parse(_today.difference(DateTime.parse(_petBirth)).inDays.toString());

                      return Column(
                        children: [
                          Text(
                            '오늘 목표 산책 달성량',
                            style: TextStyle(
                              color: Color(0xff504E5B),
                            ),
                          ),
                          SizedBox(
                            height: height * 0.02,
                          ),
                          Text(
                            '%',
                            style: TextStyle(
                              color: Color(0xff644CAA),
                              fontSize: width * 0.07
                            ),
                          ),
                          SizedBox(
                            height: height * 0.01,
                          ),
                          // 좌우 스크롤 슬라이더
                          CarouselSlider.builder(
                            options: CarouselOptions(
                              viewportFraction: 0.5,
                              enlargeCenterPage : true,
                              enlargeFactor : 0.4,
                              enableInfiniteScroll: true,
                              onPageChanged: (index, reason) {
                                setState(() {
                                  sliderController.sliderIdx = index;
                                });
                              },
                              autoPlay: true,
                            ),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, itemIndex, pageViewIndex) {
                              return CircleAvatar(
                                radius: size.width * 0.25,
                                child: ClipOval(
                                  child: FadeInImage.memoryNetwork(
                                    fit: BoxFit.cover,
                                    placeholder: kTransparentImage,
                                    image: snapshot.data!.docs[itemIndex].get('imageUrl'),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: size.height * 0.02),
                          Center(
                            child: Text(
                              snapshot.data!.docs[sliderController.sliderIdx].get('name'),
                              style: TextStyle(
                                color: Color(0xff644CAA),
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.02),
                          Center(
                            child: Text(
                              '함께한지 ${displayBirth}일',
                              style: TextStyle(
                                color: Color(0xff504E5B),
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                  Container(
                    child: BarChartSample1(),
                  ),
                ],
              ),
            ),
        )
    );
  }
}
