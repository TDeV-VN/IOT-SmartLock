import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:app/constant.dart' as constants;
import 'loginScreen.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  Future<void> _signUp() async {
    if (_passwordController.text.length < 8) {
      setState(() {
        _errorMessage = 'Mật khẩu phải chứa ít nhất 8 ký tự';
      });
      return;
    }

    try {
      // Tạo tài khoản với email và mật khẩu
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Cập nhật tên người dùng
      await userCredential.user
          ?.updateDisplayName(_usernameController.text.trim());

      // Điều hướng đến màn hình chính
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = 'Email đã được sử dụng';
            break;
          case 'invalid-email':
            _errorMessage = 'Email không đúng định dạng';
            break;
          case 'weak-password':
            _errorMessage = 'Mật khẩu quá yếu';
            break;
          default:
            _errorMessage = 'Đã có lỗi xảy ra: ${e.message}';
        }
      });
    }
  }

  void _goBackToSignin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Signin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              color: constants.primary1,
            ),
            TopSignup(onBackPressed: _goBackToSignin), // Truyền callback
            Positioned(
              top: MediaQuery.of(context).size.height * 0.10,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: constants.whiteshade,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(45),
                    topRight: Radius.circular(45),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 200,
                        width: MediaQuery.of(context).size.width * 0.8,
                        margin: EdgeInsets.only(
                          top: 20,
                          bottom: 20,
                          left: MediaQuery.of(context).size.width * 0.09,
                        ),
                        child: Image.asset("assets/images/android_logo2.png"),
                      ),
                      InputField(
                        headerText: "Tên người dùng",
                        hintTexti: "SLock Team",
                        controller: _usernameController,
                      ),
                      const SizedBox(height: 10),
                      InputField(
                        headerText: "Email",
                        hintTexti: "dion@example.com",
                        controller: _emailController,
                      ),
                      const SizedBox(height: 10),
                      InputFieldPassword(
                        headerText: "Mật khẩu",
                        hintTexti: "Tối thiểu 8 ký tự",
                        controller: _passwordController,
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 20),
                      InkWell(
                        onTap: _signUp,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.07,
                          margin: const EdgeInsets.only(
                              top: 20, left: 20, right: 20),
                          decoration: BoxDecoration(
                            color: constants.primary1,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Center(
                            child: Text(
                              "Đăng ký",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: constants.whiteshade,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InputField extends StatelessWidget {
  final String headerText;
  final String hintTexti;
  final TextEditingController? controller;

  const InputField({
    Key? key,
    required this.headerText,
    required this.hintTexti,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
          child: Text(
            headerText,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 20, right: 20),
          decoration: BoxDecoration(
            color: constants.grayshade.withOpacity(0.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintTexti,
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class InputFieldPassword extends StatefulWidget {
  final String headerText;
  final String hintTexti;
  final TextEditingController? controller;

  const InputFieldPassword({
    Key? key,
    required this.headerText,
    required this.hintTexti,
    this.controller,
  }) : super(key: key);

  @override
  State<InputFieldPassword> createState() => _InputFieldPasswordState();
}

class _InputFieldPasswordState extends State<InputFieldPassword> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
          child: Text(
            widget.headerText,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 20, right: 20),
          decoration: BoxDecoration(
            color: constants.grayshade.withOpacity(0.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              controller: widget.controller,
              obscureText: _visible,
              decoration: InputDecoration(
                hintText: widget.hintTexti,
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: Icon(
                    _visible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _visible = !_visible;
                    });
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TopSignup extends StatelessWidget {
  final VoidCallback onBackPressed; // Thêm callback để xử lý nút Back

  TopSignup({Key? key, required this.onBackPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 30, left: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBackPressed, // Gọi callback khi nhấn
            child: Icon(
              Icons.arrow_back_sharp,
              color: constants.whiteshade,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Text(
            "Đăng nhập",
            style: TextStyle(
              color: constants.whiteshade,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
