import 'dart:async';

import 'package:chatapp/Inbox.dart';
import 'package:chatapp/Signup.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class splashScreen extends StatefulWidget {
  const splashScreen({super.key});

  @override
  State<splashScreen> createState() => _splashScreenState();
}

class _splashScreenState extends State<splashScreen> {
  @override
  void initState(){
    Timer (Duration(seconds: 3),()async {
      SharedPreferences prefs=await SharedPreferences.getInstance();
      bool? check = prefs.getBool("islogin");
      String? userId = prefs.getString('userId');
      if(check!=null)
      {
        if(check){
          Navigator.push(context, MaterialPageRoute(builder: (context)=>Inbox(currentUserid: userId!)));
        }
        else{
          Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUp()));
        }
      }
      else
      {
        Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUp()));
      }
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircleAvatar(
          radius: 100,
          backgroundImage: NetworkImage("https://cdn-icons-png.freepik.com/256/9866/9866080.png?semt=ais_hybrid"),
        ),
      ),
      backgroundColor: Colors.black38,
    );
  }
}
