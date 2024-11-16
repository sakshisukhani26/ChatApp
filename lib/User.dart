import 'package:cloud_firestore/cloud_firestore.dart';

class Users{
  final String id;
  final String name;
  Users({required this.id,required this.name});
  factory Users.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Users(
      id: doc.id,
      name: data['name'] ?? '',
    );
  }
}