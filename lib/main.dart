import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(JarvisApp());

class JarvisApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: JarvisHome(),
    );
  }
}

class JarvisHome extends StatefulWidget {
  @override
  _JarvisHomeState createState() => _JarvisHomeState();
}

class _JarvisHomeState extends State<JarvisHome> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _repoController = TextEditingController();
  String _terminalLogs = "System Idle. Awaiting commands...";
  bool _isLoading = false;

  final String serverUrl = "http://192.168.1.100:8000/api/execute"; 

  Future<void> sendCommand() async {
    setState(() {
      _isLoading = true;
      _terminalLogs = "⚡ Jarvis is spinning up a secure sandbox environment...";
    });

    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "prompt": _promptController.text,
          "repo_url": _repoController.text,
        }),
      );

      final data = jsonDecode(response.body);
      setState(() {
        _terminalLogs = "Status: ${data['status'].toUpperCase()}\n\n[LOGS]:\n${data['logs']}";
      });
    } catch (e) {
      setState(() {
        _terminalLogs = "Error connecting to Jarvis Server: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("🤖 JARVIS Build Agent")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _repoController,
              decoration: InputDecoration(labelText: "Git Repository URL", border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _promptController,
              decoration: InputDecoration(labelText: "Command (e.g., 'Run tests and fix errors')", border: OutlineInputBorder()),
            ),
            SizedBox(height: 15),
            _isLoading 
              ? CircularProgressIndicator() 
              : ElevatedButton(
                  onPressed: sendCommand, 
                  child: Text("Execute Build Task"),
                  style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
                ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                color: Colors.black,
                child: SingleChildScrollView(
                  child: Text(
                    _terminalLogs,
                    style: TextStyle(fontFamily: 'Courier', color: Colors.greenAccent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
