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
  ChatUser ai = ChatUser(id: '2', firstName: 'ChatGPT');
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

  void loadChatHistory() {
    // Load chat history from storage or database
    // For demonstration, we'll not add any pre-defined messages here
    setState(() {
      allMessages = []; // Remove any pre-defined messages
    });
  }

  void getdata(ChatMessage m) async {
    typing.add(ai);
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

              ChatMessage m1 = ChatMessage(
                  text: text, user: ai, createdAt: DateTime.now());

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
                style: TextStyle(color: Colors.black), // Set text color explicitly
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
              padding: EdgeInsets.symmetric(vertical: 30, horizontal: 10),
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
              title: Text('Chat History'),
              leading: Icon(Icons.history),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatHistoryScreen(allMessages: allMessages),
                  ),
                );
              },
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
        color: Colors.white, // Set background color for chat screen
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

class ChatHistoryScreen extends StatelessWidget {
  final List<ChatMessage> allMessages;

  const ChatHistoryScreen({Key? key, required this.allMessages})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group chat messages by date
    Map<DateTime, List<ChatMessage>> groupedMessages = {};
    allMessages.forEach((message) {
      DateTime date = DateTime(
        message.createdAt!.year,
        message.createdAt!.month,
        message.createdAt!.day,
      );
      if (!groupedMessages.containsKey(date)) {
        groupedMessages[date] = [];
      }
      groupedMessages[date]!.insert(
        0,
        message,
      ); // Insert at the beginning to maintain order
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat History'),
      ),
      body: Container(
        color: Colors.white, // Set background color to white
        child: ListView.builder(
          itemCount: groupedMessages.length,
          itemBuilder: (context, index) {
            DateTime date = groupedMessages.keys.elementAt(index);
            List<ChatMessage> messages = groupedMessages[date]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: messages.map((message) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: message.user.id == '1'
                              ? Colors.blue[100]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(fontSize: 16.0),
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              message.user.id == '1' ? 'Me' : 'ChatGPT',
                              style: TextStyle(
                                fontSize: 12.0,
                                // fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}



void main() {
  runApp(MaterialApp(
    home: Chatbot(),
  ));
}
