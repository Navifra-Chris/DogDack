import 'package:get/get.dart';

class UserController extends GetxController {
  bool initFlag = false;
  bool isHost = false;
  String loginEmail = '';

  void updateUserInfo() {
    update();
  }
}