import 'package:chatapp/Signup.dart';
import 'package:flutter/material.dart';

class GetStarted extends StatefulWidget {
  const GetStarted({super.key});

  @override
  State<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends State<GetStarted> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Padding(
        padding: const EdgeInsets.symmetric(vertical: 200,horizontal: 15),
        child: Column(
          children: [
            Image.network("https://cdn-icons-png.freepik.com/256/9866/9866080.png?semt=ais_hybrid",height: 150,width: 150,),
            SizedBox(height: 10,),
            Text("Enjoy the new experience of chatting with global friends",style: TextStyle(fontSize:25,fontWeight: FontWeight.bold),),
            SizedBox(height: 20,),
            ElevatedButton(child:Text("GetStarted",style: TextStyle(color: Colors.white,fontSize: 20),),onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUp()));
            },style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(20.0)),backgroundColor: Colors.blue),),
          ],
        ),
      ),
    );
  }
}
