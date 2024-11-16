import 'package:chatapp/ChatScreen.dart';
import 'package:chatapp/Login.dart';
import 'package:chatapp/UiHelper.dart';
import 'package:chatapp/User.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Inbox extends StatefulWidget {
  final String currentUserid;
  Inbox({required this.currentUserid});

  @override
  State<Inbox> createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final String currentUserId;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentUserId = widget.currentUserid;
    print("Initialized Inbox for user: $currentUserId");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Application"),
        actions: [IconButton(onPressed: () {
          logout(context);
        }, icon: Icon(Icons.logout))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Enter username',
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: searchUser,
              child: Text('Start Chat'),
            ),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('recentChats').doc(widget.currentUserid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    print("Error fetching recentChats: ${snapshot.error}");
                    return Center(child: Text("Error loading chats. Please try again."));
                  }

                  if (!snapshot.hasData || snapshot.data == null || snapshot.data!.data() == null) {
                    print("No data found in recentChats.");
                    return Center(child: Text('No recent chats found.'));
                  }

                  try {
                    var recentChats = snapshot.data!.data() as Map<String, dynamic>;
                    List recentChatList = recentChats['chats'] ?? [];
                    if (recentChatList.isEmpty) {
                      print("Recent chats list is empty.");
                      return Center(child: Text('No recent chats available.'));
                    }
                    recentChatList.sort((a, b) =>
                        (b['lastMessageTimestamp'] ?? Timestamp(0, 0))
                            .compareTo(a['lastMessageTimestamp'] ?? Timestamp(0, 0)));

                    return ListView.builder(
                      itemCount: recentChatList.length,
                      itemBuilder: (context, index) {
                        var chatPartner = recentChatList[index];
                        String chatPartnerName = chatPartner['name'] ?? 'Unknown';
                        String chatPartnerId = chatPartner['userId'] ?? '';
                        bool isUnread = chatPartner['unread'] ?? false;
                        String lastMessage = chatPartner['lastMessage'] ?? 'No messages yet';
                        return ListTile(
                          leading: Icon(Icons.account_circle),
                          title: Text(chatPartnerName),
                          tileColor: isUnread ? Colors.blue[100] : Colors.white,
                          subtitle: Text(
                            lastMessage,
                            style: TextStyle(color: isUnread ? Colors.black : Colors.grey),
                          ),
                          onTap: ()async {
                            // onTapChat(chatPartner, index);
                            // setState(() {
                            //   // Set local state to mark as read immediately
                            //   recentChatList[index]['unread'] = false;
                            // });
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatRoomId: getChatRoomId(currentUserId, chatPartnerId),
                                  user: chatPartnerName,
                                ),
                              ),
                            );
                            recentChats['chats'][index]['unread'] = false;
                            _firestore
                                .collection('recentChats')
                                .doc(currentUserId)
                                .update({'chats': recentChatList});
                            // final recentChatsRef = _firestore.collection('recentChats').doc(currentUserId);
                            // try {
                            //   await recentChatsRef.update({
                            //     'chats': FieldValue.arrayRemove([chatPartner]) // Remove old entry
                            //   });
                            //
                            //   // Set unread to false and add updated entry back
                            //   chatPartner['unread'] = false;
                            //   await recentChatsRef.update({
                            //     'chats': FieldValue.arrayUnion([chatPartner]) // Add updated entry
                            //   });
                            // } catch (e) {
                            //   print("Error updating Firestore: $e");
                            // }
                          },
                        );
                      },
                    );


                  } catch (e) {
                    print("Error processing chat data: $e");
                    return Center(child: Text("Error displaying chats. Please check data format."));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void searchUser() async {
    String enteredUserName = searchController.text.trim();
    if (enteredUserName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a username')),
      );
      return;
    }

    final userQuery = await _firestore.collection('users').where('name', isEqualTo: enteredUserName).get();
    if (userQuery.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found')),
      );
    } else {
      final selectedUser = userQuery.docs.first;
      final selectedUserId = selectedUser['uid'];
      if (currentUserId == selectedUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You cannot chat with yourself')),
        );
        return;
      }

      createChatRoom(currentUserId, selectedUserId, enteredUserName);
    }
  }

  String getChatRoomId(String user1, String user2) {
    return user1.compareTo(user2) > 0 ? "$user1\_$user2" : "$user2\_$user1";
  }

  Future<void> createChatRoom(String currentUserId, String selectedUserId, String username) async {
    try {
      final chatRoomId = getChatRoomId(currentUserId, selectedUserId);
      final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
      final chatRoomSnapshot = await chatRoomRef.get();
      if (!chatRoomSnapshot.exists) {
        // If it doesn't exist, create a new chat room
        await chatRoomRef.set({
          'users': [currentUserId, selectedUserId],
          'chatRoomId': chatRoomId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Add this chat room to recent chats for both users
        final currentUserSnapshot = await _firestore.collection('users').doc(currentUserId).get();
        final currentUserName = currentUserSnapshot.data()?['name'] ?? 'Unknown User';
        addToRecentChats(currentUserId, selectedUserId, username);
        addToRecentChats(selectedUserId, currentUserId, currentUserName);
      }
      // chatRoomRef.get().then((doc) {
      //   if (!doc.exists) {
      //     chatRoomRef.set({
      //       'users': [currentUserId, selectedUserId],
      //       'chatRoomId': chatRoomId,
      //       'createdAt': FieldValue.serverTimestamp(),
      //     });
      //   }
      // });
      //
      // final currentUserSnapshot = await _firestore.collection('users').doc(currentUserId).get();
      // final currentUserName = currentUserSnapshot.data()?['name'] ?? 'Unknown User';
      // addToRecentChats(currentUserId, selectedUserId, username);
      // addToRecentChats(selectedUserId, currentUserId, currentUserName);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chatRoomId: chatRoomId, user: username),
        ),
      );
    } catch (e) {
      print("Error creating chat room: $e");
    }
  }

  void addToRecentChats(String userId, String chatPartnerId, String chatPartnerName) async {
    final recentChatsRef = _firestore.collection('recentChats').doc(userId);
    final recentChatSnapshot = await recentChatsRef.get();

    if (recentChatSnapshot.exists) {
      List chats = recentChatSnapshot['chats'] ?? [];
      bool alreadyExists = chats.any((chat) => chat['userId'] == chatPartnerId);
      if (!alreadyExists) {
        recentChatsRef.update({
          'chats': FieldValue.arrayUnion([
            {'userId': chatPartnerId, 'name': chatPartnerName}
          ]),
        });
      }
    } else {
      recentChatsRef.set({
        'chats': [
          {'userId': chatPartnerId, 'name': chatPartnerName}
        ],
      });
    }
  }
  void onTapChat(Map<String, dynamic> chatPartner, int index) async {
    String chatPartnerId = chatPartner['userId'];
    String chatPartnerName = chatPartner['name'];

    // Navigate to the ChatScreen with the selected chat partner
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoomId: getChatRoomId(currentUserId, chatPartnerId),
          user: chatPartnerName,
        ),
      ),
    );

    // Update Firestore to mark the chat as read
    try {
      var recentChatsDoc = _firestore.collection('recentChats').doc(currentUserId);
      var recentChatsSnapshot = await recentChatsDoc.get();

      if (recentChatsSnapshot.exists) {
        List recentChatsList = recentChatsSnapshot['chats'] ?? [];
        recentChatsList[index]['unread'] = false;

        await recentChatsDoc.update({'chats': recentChatsList});
      }
    } catch (e) {
      print("Error updating unread status: $e");
    }
  }
}
Future<void> logout(BuildContext context) async {
  try {
    // Step 1: Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    // Step 2: Clear stored data in SharedPreferences
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.clear(); // This removes all stored data

    // Step 3: Navigate to the login screen
    UiHelper.CustomAlertBox(context, "are you sure you want to logout?",alertbtn:"logout",navigateTo: Login());
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Login())); // Replace '/login' with your login screen route

  } catch (e) {
    print("Error during logout: $e");
    // Optionally, show an error message to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to log out. Please try again.")),
    );
  }
}


// import 'package:chatapp/ChatScreen.dart';
// import 'package:chatapp/User.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// class Inbox extends StatefulWidget {
//   final String currentUserid;
//   Inbox({required this.currentUserid});
//   // const Inbox({super.key});
//
//   @override
//   State<Inbox> createState() => _InboxState();
// }
//
// class _InboxState extends State<Inbox> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late final String currentUserId;
//   TextEditingController searchController=new TextEditingController();
//   var recentChats;
//
//   @override
//   void initState() {
//     super.initState();
//     currentUserId = widget.currentUserid;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Chat Application"),
//         actions: [IconButton(onPressed: (){}, icon: Icon(Icons.account_circle_rounded))],
//       ),
//       body:Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: searchController,
//               decoration: InputDecoration(
//                 hintText: 'Enter username',
//                 labelText: 'Username',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: searchUser,
//               child: Text('Start Chat'),
//             ),
//         // SizedBox(width: 10),
//
//         // Recent Chats
//         Expanded(
//           child: StreamBuilder<DocumentSnapshot>(
//             stream: _firestore
//                 .collection('recentChats')
//                 .doc(widget.currentUserid)
//                 .snapshots(),
//             builder: (context, snapshot) {
//               if (!snapshot.hasData) {
//                 return CircularProgressIndicator();
//               }
//               // if(snapshot.data!['chats'].hasData){
//               recentChats = snapshot.data!.data() as Map<String, dynamic>? ?? {};
//               List recentChatList = recentChats['chats'] ?? [];
//
//               // }
//
//               return ListView.builder(
//                 itemCount: recentChatList.length,
//                 itemBuilder: (context, index) {
//                   var chatPartner = recentChatList[index];
//                   String chatPartnerName = chatPartner['name'];
//                   String chatPartnerId = chatPartner['userId'];
//                   int unreadCount = chatPartner['unreadCount'] ?? 0;
//
//                   return ListTile(
//                     leading: Icon(Icons.account_circle),
//                     title: Text(chatPartnerName),
//                     subtitle: unreadCount > 0 ? Text('Unread messages: $unreadCount') : null,
//                     onTap: () async{
//                       // Navigate to ChatScreen
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => ChatScreen(chatRoomId: getChatRoomId(currentUserId, chatPartnerId), user: chatPartnerName),
//                         ),
//                       );
//                       final recentChatsRef=_firestore.collection('recentChats').doc(widget.currentUserid);
//                       final recentChatSnapshot=await recentChatsRef.get();
//                       if(recentChatSnapshot.exists){
//                         List chats=recentChatSnapshot['chats']??[];
//                         for(var chat in chats){
//                           if(chat['userId']==chatPartnerId){
//                             chat['unreadCount']=0;
//                             break;
//                           }
//                         }
//                         recentChatsRef.update({'chats':chats});
//                       }
//                       // _firestore.collection('recentChats').doc(widget.currentUserid).update({
//                       //   'chats': FieldValue.arrayUnion([
//                       //     {
//                       //       'userId': chatPartnerId,
//                       //       'name': chatPartnerName,
//                       //       'unreadCount': 0,
//                       //     }
//                       //   ]),
//                       // });
//                     },
//                   );
//                 });
//             },
//           ),),
//           ],
//         ),
//       ),
//     );
//   }
//   void searchUser() async{
//     String enteredUserName=searchController.text.trim();
//     if (enteredUserName.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please enter a username')),
//       );
//       return;
//     }
//     final userQuery = await _firestore
//         .collection('users')
//         .where('name', isEqualTo: enteredUserName)
//         .get();
//     if (userQuery.docs.isEmpty) {
//       // User not found
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('User not found')),
//       );
//     } else {
//       // User found, proceed to create or navigate to the chat room
//       final selectedUser = userQuery.docs.first;
//       final selectedUserId = selectedUser['uid'];
//       final currentUserId = widget.currentUserid;
//
//       // Ensure the user isn't trying to chat with themselves
//       if (currentUserId == selectedUserId) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('You cannot chat with yourself')),
//         );
//         return;
//       }
//
//       createChatRoom(currentUserId, selectedUserId, enteredUserName);
//     }
//   }
//   String getChatRoomId(String user1, String user2) {
//     // Sort user IDs to ensure uniqueness (e.g., 'user1user2' or 'user2user1')
//     if (user1.compareTo(user2) > 0) {
//       return "$user1\_$user2";
//     } else {
//       return "$user2\_$user1";
//     }
//   }
//   String generateChatRoomId(String user1, String user2) {
//     return user1.compareTo(user2) > 0 ? '$user1-$user2' : '$user2-$user1';
//   }
//
//   // Function to create chat room in Firestore
//   Future<void> createChatRoom(String currentUserId, String selectedUserId,String username) async {
//     try {
//       // final chatRoomId = generateChatRoomId(currentUserId, selectedUserId);
//       final chatRoomId = getChatRoomId(currentUserId, selectedUserId);
//       final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
//
//       chatRoomRef.get().then((doc) {
//         if (!doc.exists) {
//           chatRoomRef.set({
//             'users': [currentUserId, selectedUserId],
//             'chatRoomId': chatRoomId,
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//         }
//       });
//         final currentUserSnapshot = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
//         final currentUserName = currentUserSnapshot.data()?['name'] ?? 'Unknown User';
//         addToRecentChats(currentUserId, selectedUserId,username);
//         addToRecentChats(selectedUserId, currentUserId,currentUserName);
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ChatScreen(
//             chatRoomId: chatRoomId,
//             user: selectedUserId,
//           ),
//         ),
//       );
//         print("Chat room created with ID: $chatRoomId");
//     } catch (e) {
//       print("Error creating chat room: $e");
//     }
//   }
//   void addToRecentChats(String userId, String chatPartnerId, String chatPartnerName) {
//     final recentChatsRef =
//     FirebaseFirestore.instance.collection('recentChats').doc(userId);
//
//     recentChatsRef.set({
//       'chats': FieldValue.arrayUnion([
//         {'userId': chatPartnerId, 'name': chatPartnerName}
//       ]),
//     }, SetOptions(merge: true));
//   }
// }
// // class ChatRoomPage extends StatelessWidget{
// //   final String username; // The ID of the logged-in user
// //   ChatRoomPage({required this.username});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text("chat with $username"),
// //       ),
// //       body: Center(
// //         child: Text("Chat with $username"),
// //       ),
// //     );
// //   }
// //
// // }