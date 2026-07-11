import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const JarvisAgentApp());
}

class JarvisAgentApp extends StatelessWidget {
  const JarvisAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JARVIS Build Agent',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121214),
        primaryColor: const Color(0xFF6366F1),
      ),
      home: const BuildAgentScreen(),
    );
  }
}

class BuildAgentScreen extends StatefulWidget {
  const BuildAgentScreen({super.key});

  @override
  State<BuildAgentScreen> createState() => _BuildAgentScreenState();
}

class _BuildAgentScreenState extends State<BuildAgentScreen> {
  final TextEditingController _ipController = TextEditingController(text: '192.168.1.33');
  final TextEditingController _repoController = TextEditingController();
  final TextEditingController _commandController = TextEditingController();
  
  String _terminalLogs = "System Idle. Awaiting commands...";
  bool _isLoading = false;

  Future<void> _executeTask() async {
    if (_repoController.text.isEmpty || _commandController.text.isEmpty) {
      setState(() {
        _terminalLogs = "⚠️ Error: Please fill in both fields.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _terminalLogs = "🚀 Connecting to Jarvis Agent Server [${_ipController.text}:8000]...\nExecuting task loops...";
    });

    try {
      final response = await http.post(
        Uri.parse('http://${_ipController.text}:8000/api/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'repo_url': _repoController.text,
          'prompt': _commandController.text,
        }),
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _terminalLogs = "[Task Completed Successfully]\n\n${data['logs']}";
        });
      } else {
        setState(() {
          _terminalLogs = "❌ Server Error (${response.statusCode}): ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _terminalLogs = "❌ Connection Failed.\nEnsure your phone is on the same Wi-Fi network and that server.py is actively running on your PC.\n\nDetails: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.android, color: Colors.greenAccent),
            SizedBox(width: 10),
            Text('JARVIS Build Agent'),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E24),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Server IP Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.dns, color: Colors.indigoAccent),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repoController,
              decoration: const InputDecoration(
                labelText: 'Git Repository URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commandController,
              decoration: const InputDecoration(
                labelText: "Command (e.g., 'Run tests')",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.terminal),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _executeTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Execute Build Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            const Text('Terminal Output', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2D2D34)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _terminalLogs,
                    style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 13),
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
