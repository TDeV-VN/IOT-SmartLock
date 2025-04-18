import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:app/constant.dart' as constants; // Thêm alias 'constants'
import 'signupScreen.dart';
import 'package:app/widgets/custom_button.dart';

class Signin extends StatefulWidget {
  const Signin({Key? key}) : super(key: key);

  @override
  _SigninState createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  Future<void> _signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'Email không tồn tại';
            break;
          case 'wrong-password':
            _errorMessage = 'Sai mật khẩu';
            break;
          case 'invalid-email':
            _errorMessage = 'Email không đúng định dạng';
            break;
          default:
            _errorMessage = 'Đã có lỗi xảy ra: ${e.message}';
        }
      });
    }
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
            Positioned(
              top: MediaQuery.of(context).size.height * 0.10,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: constants.whiteshade, // Sử dụng constants.whiteshade
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
                          left: MediaQuery.of(context).size.width * 0.09,
                        ),
                        child: Image.asset("assets/images/android_logo2.png"),
                      ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top:10, right: 20,),
                            child: InkWell(
                              onTap: () {},
                              child: Text(
                                "Quên mật khẩu?",
                                style: TextStyle(
                                  color: constants.blue.withOpacity(
                                      0.7), // Sử dụng constants.blue
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20), // Thêm padding ở đây nếu không dùng margin trong CustomButton
                        child: CustomButton(
                          text: "Đăng nhập",
                          onPressed: _signIn,
                          // Có thể thêm margin ở đây nếu CustomButton đã hỗ trợ
                          // margin: EdgeInsets.symmetric(horizontal: 20),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.149,
                          top: MediaQuery.of(context).size.height * 0.08,
                        ),
                        child: Text.rich(
                          TextSpan(
                            text: "Bạn chưa có tài khoản? ",
                            style: TextStyle(
                              color: constants.grayshade.withOpacity(
                                  0.8), // Sử dụng constants.grayshade
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: "Đăng ký",
                                style: TextStyle(
                                  color:
                                      constants.blue, // Sử dụng constants.blue
                                  fontSize: 16,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SignUp(),
                                      ),
                                    );
                                  },
                              ),
                            ],
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
          child: const Text(
            "Email",
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 20, right: 20),
          decoration: BoxDecoration(
            color: constants.grayshade
                .withOpacity(0.5), // Sử dụng constants.grayshade
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
            color: constants.grayshade
                .withOpacity(0.5), // Sử dụng constants.grayshade
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
