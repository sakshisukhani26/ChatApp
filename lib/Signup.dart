import 'dart:developer';
import 'package:chatapp/Login.dart';
import 'package:chatapp/UiHelper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  TextEditingController emailController=TextEditingController();
  TextEditingController pwdController=TextEditingController();
  TextEditingController cfmController=TextEditingController();
  TextEditingController nameController=TextEditingController();
  bool passwordVisible=true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 70,horizontal: 20),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(child: Image.network("https://cdn-icons-png.freepik.com/256/9866/9866080.png?semt=ais_hybrid",height: 100,width: 100,)),
                SizedBox(height: 60,),
                UiHelper.customTextField(emailController,"Enter your Email",borderradius: 12.0),
                SizedBox(height: 20,),
                UiHelper.customTextField(nameController,"Enter your username",borderradius: 12.0),
                SizedBox(height: 20,),
                UiHelper.custompwd(pwdController,"Enter your Password","password",passwordVisible,() {
                  setState(
                        () {
                      passwordVisible = !passwordVisible;
                      log(passwordVisible.toString());
                    },
                  );
                },),
                SizedBox(height: 20,),
                TextField(controller: cfmController,obscureText: true,decoration: InputDecoration(focusColor: Colors.grey,hintText: "Confirm Password",border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                )),),
                SizedBox(height: 40,),
                UiHelper.customButton("Register",forecolor: Colors.white,bgcolor: Colors.blue,borderradius: 12.0,fontsize: 20,height: 60,width: 150,callback: (){
                  signUp(emailController.text.toString(), pwdController.text.toString(),cfmController.text.toString());
                }),
                SizedBox(height: 20,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    UiHelper.customText("Already have an account?"),
                    UiHelper.customTextButton("Login",callback: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>Login()));
                    }),
                  ],
                ),

              ],
            ),
          ),
        ),
    );
  }
  signUp(String email, String password,String cfmpass) async {
    if (email == "" && password == ""&&cfmpass=="") {
      log(email+" "+password);
      return UiHelper.CustomAlertBox(context,"Enter Required Field's");
    }else if(password!=cfmpass){
      return UiHelper.CustomAlertBox(context, "Password and Confirm password does not match");
    }
    else {
      UserCredential? userCredential;
      try {
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

            // .then((value) {
          // return
          //   Navigator.push(context,MaterialPageRoute(builder: (context)=>Login()));
        // });
        User? user= userCredential.user;
        if(user!=null){
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'name':nameController.text,
            'created_at': FieldValue.serverTimestamp(),
          });
          print('User registered and saved to Firestore');
          Navigator.push(context,MaterialPageRoute(builder: (context)=>Login()));
        }
        // FirebaseAuth.instance.authStateChanges().listen((User? user) {
        //   if (user != null) {
        //     FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        //       'email': user.email,
        //       'uid': user.uid,
        //     }, SetOptions(merge: true));
        //   }
        // });
      } on FirebaseAuthException catch (ex) {
        return UiHelper.CustomAlertBox( context,ex.code.toString());
      }
    }
  }
}
