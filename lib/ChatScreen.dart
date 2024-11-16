import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/User.dart';

class ChatScreen extends StatefulWidget {
  final String user;
  final String chatRoomId;
  ChatScreen({required this.user, required this.chatRoomId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;
  String messageText = '';
  TextEditingController messageController=new TextEditingController();

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          loggedInUser = user;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void sendMessage() async {
    if (messageText.trim().isEmpty) {
      return;
    }
    _firestore.collection('chatRooms').doc(widget.chatRoomId).collection('messages').add({
      'text': messageText,
      'sender': loggedInUser?.email,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead':false,
    });
    // await updateRecentChats(loggedInUser?.email, receiverId, messageText, FieldValue.serverTimestamp());
    // await updateRecentChats(receiverId, loggedInUser?.email, messageText, FieldValue.serverTimestamp());
    final currentUserId = loggedInUser?.uid ?? '';
    final chatRoomId = widget.chatRoomId;
    final otherUserId = chatRoomId.replaceAll(currentUserId, '').replaceAll('_', '');

    final recentChatsRef = _firestore.collection('recentChats').doc(otherUserId);
    final recentChatsSnapshot = await recentChatsRef.get();
    if(recentChatsSnapshot.exists){
      List chats=recentChatsSnapshot['chats']??[];
      bool chatExists= false;
      for(var chat in chats){
        if(chat['userId']==currentUserId){
          chat['unreadCount']=(chat['unreadCount']??0)+1;
          chatExists=true;
          break;
        }
      }
      if(!chatExists){
        chats.add({
          'userId':currentUserId,
          'name':widget.user,
          'unreadCount':1,
        });
      }
      recentChatsRef.update({'chats':chats});
    }
    else{
      recentChatsRef.set({
        'chats':[{
          'userId':currentUserId,
          'name':widget.user,
          'unreadCount':1,
        }],
      });
    }
    setState(() {
      messageText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.user}'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _auth.signOut();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MessagesStream(chatRoomId:widget.chatRoomId,currentUserEmail: loggedInUser?.email),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    onChanged: (value) {
                      messageText = value;
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: (){
                    sendMessage();
                    messageController.clear();
                  }
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Future<void> updateRecentChats(String? userId, String? chatPartnerId, String lastMessage, FieldValue timestamp) async {
    final recentChatsRef = FirebaseFirestore.instance.collection('recentChats').doc(userId);

    try {
      final recentChatSnapshot = await recentChatsRef.get();

      if (recentChatSnapshot.exists) {
        // If the document exists, update the existing chats array
        List chats = recentChatSnapshot['chats'] ?? [];
        bool chatExists = false;

        // Check if chat with chatPartnerId already exists
        for (var chat in chats) {
          if (chat['userId'] == chatPartnerId) {
            // Update existing chat with last message, timestamp, and unread status
            chat['lastMessage'] = lastMessage;
            chat['lastMessageTimestamp'] = timestamp;
            chat['unread'] = true;
            chatExists = true;
            break;
          }
        }

        // If the chat doesn't exist, add a new chat entry
        if (!chatExists) {
          chats.add({
            'userId': chatPartnerId,
            'name': 'Chat Partner Name', // Replace with actual name if available
            'lastMessage': lastMessage,
            'lastMessageTimestamp': timestamp,
            'unread': true
          });
        }

        await recentChatsRef.update({'chats': chats});
      } else {
        // If document doesn't exist, create it with a new chat entry
        await recentChatsRef.set({
          'chats': [
            {
              'userId': chatPartnerId,
              'name': 'Chat Partner Name', // Replace with actual name if available
              'lastMessage': lastMessage,
              'lastMessageTimestamp': timestamp,
              'unread': true
            }
          ],
        });
      }
    } catch (e) {
      print("Error updating recentChats: $e");
    }
  }

}

class MessagesStream extends StatelessWidget {
  final String chatRoomId;
  final String? currentUserEmail;
  MessagesStream({required this.chatRoomId,required this.currentUserEmail});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp',descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        final messages = snapshot.data!.docs;
        List<MessageBubble> messageBubbles = [];
        for (var message in messages) {
          final messageText = message['text'];
          final messageSender = message['sender'];
          final messageBubble =
          MessageBubble(sender: messageSender, text: messageText,isMe: currentUserEmail == messageSender);
          messageBubbles.add(messageBubble);
        }
        return ListView(
          reverse: true,
          children: messageBubbles,
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;

  MessageBubble({required this.sender, required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:   isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
              topLeft: Radius.circular(30),
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            )
                : BorderRadius.only(
              topRight: Radius.circular(30),
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.grey[300],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                text,
                style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
