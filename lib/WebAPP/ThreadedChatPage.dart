import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ThreadedChatPage extends StatefulWidget {
  final String coachId;
  final String coachName;
  const ThreadedChatPage({required this.coachId, required this.coachName, Key? key}) : super(key: key);

  @override
  State<ThreadedChatPage> createState() => _ThreadedChatPageState();
}

class _ThreadedChatPageState extends State<ThreadedChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chatList')
          .doc(widget.coachId)
          .update({'unreadCount': 0});
    }
  }

  void _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _controller.text.trim().isEmpty) return;
    final messageText = _controller.text.trim();
    _controller.clear();
    final now = Timestamp.now();
    final messageRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('messages')
        .doc(widget.coachId)
        .collection('chatInfo')
        .doc();
    await messageRef.set({
      'senderId': user.uid,
      'receiverId': widget.coachId,
      'text': messageText,
      'timestamp': now,
    });
    // Update chatList metadata
    final chatListRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chatList')
        .doc(widget.coachId);
    await chatListRef.set({
      'lastMessage': messageText,
      'lastMessageTime': now,
      'coachId': widget.coachId,
      'coachName': widget.coachName,
      'clientId': user.uid,
      'clientName': user.displayName ?? '',
      'unreadCount': FieldValue.increment(1),
      'participantIds': [user.uid, widget.coachId],
    }, SetOptions(merge: true));
    // Optionally scroll to bottom
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.coachName)),
        body: Center(child: Text('You must be logged in.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.coachName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('messages')
                  .doc(widget.coachId)
                  .collection('chatInfo')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: \\${snapshot.error}'));
                }
                final messages = snapshot.data?.docs ?? [];
                if (messages.isEmpty) {
                  return Center(child: Text('No messages yet.'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data();
                    final isMe = msg['senderId'] == user.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[400] : Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}