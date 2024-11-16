import 'dart:developer';

import 'package:chatapp/ChatScreen.dart';
import 'package:chatapp/Inbox.dart';
import 'package:chatapp/Signup.dart';
import 'package:chatapp/UiHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController emailController=TextEditingController();
  TextEditingController pwdController=TextEditingController();
  bool passwordVisible=true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 70,horizontal: 20),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(child: Image.network("https://cdn-icons-png.freepik.com/256/9866/9866080.png?semt=ais_hybrid",height: 100,width: 100,)),
            SizedBox(height: 60,),
            UiHelper.customTextField(emailController,"Enter your Email",borderradius: 12.0),
            SizedBox(height: 20,),
            UiHelper.custompwd(pwdController,"Enter your Password","password",passwordVisible,() {
              setState(
                    () {
                  passwordVisible = !passwordVisible;
                  log(passwordVisible.toString());
                },
              );
            },),
            SizedBox(height: 40,),
            UiHelper.customButton("Login",forecolor: Colors.white,bgcolor: Colors.blue,borderradius: 12.0,fontsize: 20,height: 60,width: 150,callback: (){
              signIn(emailController.text.toString(), pwdController.text.toString());
            }),
            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                UiHelper.customText("Don't have an account?"),
                UiHelper.customTextButton("Register",callback: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUp()));
                }),
              ],
            ),

          ],
        ),
      ),
    );
  }
  signIn(String email,String password)async{
    if(email=="" && password==""){
      return UiHelper.CustomAlertBox(context,"Enter Required Fields");
    }
    else{
      UserCredential? usercredential;
      try{
        usercredential=await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', usercredential.user!.uid);
          User? user = usercredential.user;
          if (user != null) {
            String currentUserId = user.uid;

            // Navigate to CreateChatPage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Inbox(currentUserid: currentUserId),
              ),
            );
          }
          // Navigator.push(context, MaterialPageRoute(builder: (context)=>Inbox(currentUserid: usercredential['uid'],)));
      }
      on FirebaseAuthException catch(ex){
        return UiHelper.CustomAlertBox(context,ex.code.toString());
      }

    }
  }
}
