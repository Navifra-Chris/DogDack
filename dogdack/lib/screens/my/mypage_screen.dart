import 'package:flutter/material.dart';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// GetX
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

// Controller
import 'controller/mypage_controller.dart';

// models
import 'package:dogdack/models/walk_data.dart';
import 'package:dogdack/models/dog_data.dart';

// Widgets
import 'package:carousel_slider/carousel_slider.dart';
import 'package:transparent_image/transparent_image.dart';

// Screen
import 'editinfo_screen.dart';

class MyPage extends StatefulWidget {
  MyPage({super.key, required this.tabIndex});

  final int tabIndex;
  final inputController = TextEditingController();

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  // Firebase : 반려견 테이블 참조 값
  final petsRef = FirebaseFirestore.instance.collection('Users/${FirebaseAuth.instance.currentUser!.email.toString()}/Pets')
  .withConverter(fromFirestore: (snapshot, _) => DogData.fromJson(snapshot.data()!), toFirestore: (dogData, _) => dogData.toJson());

  // Firebase : 산책 테이블 참조 값
  final walkRef = FirebaseFirestore.instance.collection('Users/${FirebaseAuth.instance.currentUser!.email.toString()}/Walk')
      .withConverter(fromFirestore: (snapshot, _) => WalkData.fromJson(snapshot.data()!), toFirestore: (walkData, _) => walkData.toJson());

  // GetX
  final petController = Get.put(PetController()); // 슬라이더에서 선택된 반려견 정보를 위젯간 공유
  final mypageStateController = Get.put(MyPageStateController()); // 현재 mypage 의 상태 표시

  @override
  Widget build(BuildContext context) {
    // 디바이스 사이즈 크기 정의
    final Size size = MediaQuery.of(context).size;

    // 스크린 상태 갱신
    mypageStateController.myPageStateType = MyPageStateType.View;

    return GestureDetector(
      onTap: () {
        // 포커스를 벗어나면 키보드를 해제함
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'DOGDACK',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        floatingActionButton: Container(
          padding: EdgeInsets.fromLTRB(0, 0, size.width * 0.05, size.width * 0.05),
          child: FloatingActionButton(
            onPressed: () {
              // 생성 모드
              mypageStateController.myPageStateType = MyPageStateType.Create;
              // 반려견 정보 추가 페이지로 이동
              Navigator.push(context, MaterialPageRoute(builder: (context) => EditDogInfoPage()));
            },
            child: Icon(Icons.add),
            backgroundColor: Colors.deepPurple,
          ),
        ),
        // 키보드 등장 시 화면 오버플로우가 발생하지 않도록 함.
        body: SingleChildScrollView(
          child: Padding(
            // body 내 모든 위젯의 padding 설정
            padding: EdgeInsets.fromLTRB(0, size.height * 0.03, 0, 0),
            child: Column(
              children: [
                // 사용자 정보
                StreamBuilder(
                  stream: petsRef.snapshots(),
                  builder: (petContext, petSnapshot) {
                    //데이터를 불러오지 못했으면 로딩
                    if (!petSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    return StreamBuilder(
                      stream: walkRef.snapshots(),
                      builder: (walkContext, walkSnapshot) {
                        //데이터를 불러오지 못했으면 로딩
                        if (!walkSnapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        // 총 산책 시간 계산
                        num totalWalkHour = 0;
                        walkSnapshot.data!.docs.forEach((element) {
                          totalWalkHour = totalWalkHour + element.get('totalTimeMin');
                        });

                        // 사용자 정보
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                // 사용자 계정 이미지
                                CircleAvatar(
                                  backgroundColor: Colors.white,
                                  radius: size.width * 0.10,
                                  child: ClipOval(
                                    child: Image.network(FirebaseAuth.instance.currentUser!.photoURL.toString()),
                                  ),
                                ),
                                SizedBox(
                                  height: size.height * 0.01,
                                ),
                                // 사용자 닉네임
                                Container(
                                  width: size.width * 0.2,
                                  child: Text(
                                    FirebaseAuth.instance.currentUser!.displayName.toString(),
                                    style: TextStyle(
                                      fontSize: size.width * 0.04,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            // 산책 횟수
                            Column(
                              children: [
                                Text(walkSnapshot.data!.docs.length.toString()),
                                SizedBox(height: size.height * 0.01),
                                Text('산책 카운트'),
                              ],
                            ),
                            // 산책 시간
                            Column(
                              children: [
                                Text(totalWalkHour.toString()),
                                SizedBox(height: size.height * 0.01),
                                Text('산책 시간'),
                              ],
                            ),
                            // 반려견 수
                            Column(
                              children: [
                                Text(petSnapshot.data!.docs.length.toString()),
                                SizedBox(height: size.height * 0.01),
                                Text('댕댕이'),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                // 반려견 정보
                StreamBuilder(
                  stream: petsRef.orderBy('createdAt').snapshots(),
                  builder: (context, snapshot) {
                    // 데이터를 아직 불러오지 못했으면 로딩
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    // 불러온 데이터가 없을 경우 등록 안내
                    if (snapshot.data!.docs.length == 0) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(0, size.height * 0.3, 0, 0),
                        child: Text('댕댕이를 등록해주세요!'),
                      );
                    }

                    // 여기서 부터는 등록된 반려견이 1마리 이상 존재함.

                    // 마지막으로 저장된 스크롤 인덱스에 맞춰 정보 갱신함
                    PetController().updateSelectedPetInfo(snapshot, petController, petController.selectedPetScrollIndex);

                    return Column(
                      children: [
                        // 좌우 스크롤 슬라이더
                        CarouselSlider.builder(
                          options: CarouselOptions(
                            viewportFraction: 0.5,
                            enableInfiniteScroll: false,
                            onPageChanged: (index, reason) {
                              setState(() {
                                PetController().updateSelectedPetInfo(snapshot, petController, index);
                              });
                            },
                          ),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, itemIndex, pageViewIndex) {
                            return CircleAvatar(
                              radius: 80,
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
                        SizedBox(height: size.height * 0.001),
                        Center(
                          child: Container(
                            height: size.height * 0.45,
                            width: size.width * 0.8,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.7),
                                  blurRadius: 5.0,
                                  spreadRadius: 0.0,
                                  offset: const Offset(0, 7),
                                )
                              ],
                            ),
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(size.width * 0.05, size.width * 0.05, size.width * 0.05, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          '이름',
                                          style: TextStyle(
                                            color: Colors.deepPurpleAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: size.width * 0.04,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: size.height * 0.01,
                                    ),
                                    Text(
                                      snapshot.data!.docs[petController.selectedPetScrollIndex].get('name'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: size.width * 0.05,
                                      ),
                                    ),
                                    SizedBox(
                                      height: size.height * 0.01,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          '성별',
                                          style: TextStyle(
                                            color: Colors.deepPurpleAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: size.width * 0.04,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: size.width * 0.01,
                                    ),
                                    snapshot.data!.docs[petController.selectedPetScrollIndex].get('gender') == 'Male'
                                        ? Icon(Icons.male, color: Colors.blueAccent,)
                                        : Icon(Icons.female, color: Colors.pink,),
                                    SizedBox(
                                      height: size.width * 0.01,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          '생일',
                                          style: TextStyle(
                                            color: Colors.deepPurpleAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: size.width * 0.04,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: size.width * 0.01,
                                    ),
                                    Text(
                                      snapshot.data!.docs[petController.selectedPetScrollIndex].get('birth'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: size.width * 0.05,
                                      ),
                                    ),
                                    SizedBox(
                                      height: size.width * 0.01,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          '견종',
                                          style: TextStyle(
                                            color: Colors.deepPurpleAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: size.width * 0.04,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: size.width * 0.01,
                                    ),
                                    Text(
                                      snapshot.data!.docs[petController.selectedPetScrollIndex].get('breed'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: size.width * 0.05,
                                      ),
                                    ),
                                    SizedBox(
                                      height: size.width * 0.07,
                                    ),
                                    Center(
                                      child: ElevatedButton(
                                          onPressed: () {
                                            // 편집 상태
                                            mypageStateController.myPageStateType = MyPageStateType.Edit;

                                            // 편집 페이지로 이동
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => EditDogInfoPage()));
                                          },
                                          child: Text('편집하기')),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}