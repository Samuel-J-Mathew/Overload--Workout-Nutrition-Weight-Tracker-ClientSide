import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'ThreadedChatPage.dart';

class MessagesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Messages')),
        body: Center(child: Text('You must be logged in to view messages.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Messages')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('chatList')
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No messages yet.'));
          }
          final chats = snapshot.data!.docs;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data();
              final coachName = chat['coachName'] ?? 'Coach';
              final lastMessage = chat['lastMessage'] ?? '';
              final unreadCount = chat['unreadCount'] ?? 0;
              final coachId = chat['coachId'] ?? '';
              return ListTile(
                leading: CircleAvatar(child: Text(coachName[0])),
                title: Text(coachName),
                subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: unreadCount > 0
                    ? CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 12,
                  child: Text('$unreadCount', style: TextStyle(color: Colors.white, fontSize: 12)),
                )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThreadedChatPage(
                        coachId: coachId,
                        coachName: coachName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// TODO: When opening a chat, reset unreadCount to 0 for that thread.
// This can be done in ThreadedChatPage when the chat is opened.
