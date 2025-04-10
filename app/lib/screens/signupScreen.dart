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
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
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
              color: constants.blue,
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
                        height: 250,
                        width: MediaQuery.of(context).size.width * 0.8,
                        margin: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.09,
                        ),
                        child: Image.asset("assets/images/login.png"),
                      ),
                      InputField(
                        headerText: "Username",
                        hintTexti: "Username",
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
                        headerText: "Password",
                        hintTexti: "At least 8 Characters",
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
                      CheckerBox(),
                      const SizedBox(height: 20),
                      InkWell(
                        onTap: _signUp,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.07,
                          margin: const EdgeInsets.only(left: 20, right: 20),
                          decoration: BoxDecoration(
                            color: constants.blue,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Center(
                            child: Text(
                              "Sign up",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: constants.whiteshade,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.18,
                          top: MediaQuery.of(context).size.height * 0.08,
                        ),
                        child: Text.rich(
                          TextSpan(
                            text: "I already Have an account ",
                            style: TextStyle(
                              color: constants.grayshade.withOpacity(0.8),
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: "Sign In",
                                style: TextStyle(
                                  color: constants.blue,
                                  fontSize: 16,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const Signin(),
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

class CheckerBox extends StatefulWidget {
  CheckerBox({Key? key}) : super(key: key);

  @override
  State<CheckerBox> createState() => _CheckerBoxState();
}

class _CheckerBoxState extends State<CheckerBox> {
  bool isCheck = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Checkbox(
            value: isCheck,
            checkColor: constants.whiteshade,
            activeColor: constants.blue,
            onChanged: (val) {
              setState(() {
                isCheck = val!;
              });
            },
          ),
          Text.rich(
            TextSpan(
              text: "I agree with ",
              style: TextStyle(
                color: constants.grayshade.withOpacity(0.8),
                fontSize: 16,
              ),
              children: [
                TextSpan(
                  text: "Terms ",
                  style: TextStyle(color: constants.blue, fontSize: 16),
                ),
                const TextSpan(text: "and "),
                TextSpan(
                  text: "Policy",
                  style: TextStyle(color: constants.blue, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
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
              fontSize: 22,
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
              fontSize: 22,
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
      margin: const EdgeInsets.only(top: 15, left: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBackPressed, // Gọi callback khi nhấn
            child: Icon(
              Icons.arrow_back_sharp,
              color: constants.whiteshade,
              size: 40,
            ),
          ),
          const SizedBox(width: 15),
          Text(
            "Sign Up",
            style: TextStyle(
              color: constants.whiteshade,
              fontSize: 25,
            ),
          ),
        ],
      ),
    );
  }
}
