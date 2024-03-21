import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:http/http.dart' as http;

class Chatbot extends StatefulWidget {
  const Chatbot({Key? key});

  @override
  State<Chatbot> createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot> {
  ChatUser me = ChatUser(id: '1', firstName: 'megh');
  ChatUser ai = ChatUser(id: '2', firstName: 'AskAI');
  List<ChatMessage> allMessages = [];
  List<ChatUser> typing = [];

  final oururl = 'https://api.openai.com/v1/chat/completions';
  final header = {
    'Content-Type': 'application/json',
    'Authorization':
    'Bearer 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'
  };

  @override
  void initState() {
    super.initState();
    // Clear the chat history when the widget initializes
    resetChat();
  }

  void resetChat() {
    setState(() {
      allMessages.clear();
    });
  }

  void getdata(ChatMessage m) async {
    typing.add(ai); // Set typing status to AskAI
    allMessages.insert(0, m);
    setState(() {});

    var data = {
      "model": "gpt-3.5-turbo",
      "messages": [
        {"role": "user", "content": m.text}
      ]
    };

    try {
      var response = await http.post(Uri.parse(oururl),
          headers: header, body: jsonEncode(data));

      if (response.statusCode == 200) {
        var responseBody = response.body;
        if (responseBody != null) {
          var result = jsonDecode(responseBody);
          if (result['choices'] != null && result['choices'].isNotEmpty) {
            var message = result['choices'][0]['message'];
            if (message != null &&
                message is Map<String, dynamic> &&
                message['content'] is String) {
              var text = message['content'] as String;
              print(text);

              ChatMessage m1 =
              ChatMessage(text: text, user: ai, createdAt: DateTime.now());

              allMessages.insert(0, m1);
            } else {
              print("Error: 'content' is null or not a String.");
              print("Response body: $result");
            }
          } else {
            print("Error: No choices found in response.");
            print("Response body: $result");
          }
        } else {
          print("Error: Response body is null.");
        }
      } else {
        print("Error: ${response.reasonPhrase}");
      }
    } catch (error) {
      print("Error: $error");
    }
    typing.remove(ai);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // Set background color of the app bar
        title: Row(
          children: [
            GestureDetector(
              onTap: resetChat,
              child: Text(
                'AskAI',
                style:
                TextStyle(color: Colors.black), // Set text color explicitly
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () {
                resetChatDialog();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Icon(Icons.delete),
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            Container(
              height: 92,
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              padding: EdgeInsets.symmetric(vertical: 30, horizontal: 5),
              child: ListTile(
                leading: Icon(Icons.handshake, color: Colors.white),
                title: Text(
                  'Welcome',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text('New Chat'),
              leading: Icon(Icons.chat),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Chatbot(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey[200], // Set background color for chat screen
        child: DashChat(
          typingUsers: typing,
          currentUser: me,
          onSend: (ChatMessage m) {
            getdata(m);
          },
          messages: allMessages,
        ),
      ),
    );
  }

  void resetChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Chat"),
          content: Text("This will delete the current chat. Continue?"),
          backgroundColor: Colors.white,
          actions: <Widget>[
            TextButton(
              child: Text("CANCEL"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                "DELETE",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Save chat history to storage or database
                // For demonstration, we'll just clear the chat
                resetChat();
              },
            ),
          ],
        );
      },
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Chatbot(),
  ));
}
