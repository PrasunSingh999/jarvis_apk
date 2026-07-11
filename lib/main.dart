import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

void main() {
  runApp(const JarvisAgentApp());
}

// =========================================================================
// ROOT APP — handles the boot sequence -> main console transition
// =========================================================================
class JarvisAgentApp extends StatelessWidget {
  const JarvisAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JARVIS Build Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0B10),
        primaryColor: const Color(0xFF6EE7F9),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'monospace'),
      ),
      home: const BootScreen(),
    );
  }
}

// =========================================================================
// BOOT SCREEN — animated system-init sequence before the console appears
// =========================================================================
class BootScreen extends StatefulWidget {
  const BootScreen({super.key});
  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _fadeController;
  final List<String> _bootLines = [
    '> initializing core...',
    '> loading neural interface...',
    '> calibrating handshake protocol...',
    '> JARVIS build agent ready.',
  ];
  int _visibleLines = 0;
  Timer? _lineTimer;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _lineTimer = Timer.periodic(const Duration(milliseconds: 480), (t) {
      setState(() => _visibleLines++);
      if (_visibleLines >= _bootLines.length) {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 550), _goToConsole);
      }
    });
  }

  void _goToConsole() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, anim, __) => const BuildAgentScreen(),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _ringController.dispose();
    _fadeController.dispose();
    _lineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeController,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: AnimatedBuilder(
                  animation: _ringController,
                  builder: (context, _) => CustomPaint(
                    painter: _OrbitRingPainter(_ringController.value),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF6EE7F9), Color(0xFFB794F6)],
                ).createShader(bounds),
                child: const Text(
                  'J A R V I S',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 110,
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_bootLines.length, (i) {
                    final visible = i < _visibleLines;
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 350),
                      opacity: visible ? 1 : 0,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 350),
                        offset: visible ? Offset.zero : const Offset(-0.05, 0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            _bootLines[i],
                            style: const TextStyle(
                              color: Color(0xFF7CFFB2),
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two rotating dashed rings + pulsing core — the "arc reactor" boot motif.
class _OrbitRingPainter extends CustomPainter {
  final double t;
  _OrbitRingPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerPaint = Paint()
      ..color = const Color(0xFF6EE7F9).withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    final innerPaint = Paint()
      ..color = const Color(0xFFB794F6).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // outer dashed arc rotating clockwise
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(t * 2 * math.pi);
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: size.width / 2 - 6),
        0, math.pi * 1.4, false, outerPaint);
    canvas.restore();

    // inner dashed arc rotating counter-clockwise, faster
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-t * 2.6 * math.pi);
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: size.width / 2 - 24),
        0, math.pi * 1.0, false, innerPaint);
    canvas.restore();

    // pulsing core
    final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
    final corePaint = Paint()
      ..shader = RadialGradient(colors: [
        Colors.white.withOpacity(0.9),
        const Color(0xFF6EE7F9).withOpacity(0.4 + 0.3 * pulse),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: center, radius: 30));
    canvas.drawCircle(center, 26 + pulse * 4, corePaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) => true;
}

// =========================================================================
// MAIN CONSOLE
// =========================================================================
enum AgentStatus { idle, connecting, success, error }

class BuildAgentScreen extends StatefulWidget {
  const BuildAgentScreen({super.key});
  @override
  State<BuildAgentScreen> createState() => _BuildAgentScreenState();
}

class _BuildAgentScreenState extends State<BuildAgentScreen> with TickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController(text: '192.168.1.33');
  final TextEditingController _repoController = TextEditingController();
  final TextEditingController _commandController = TextEditingController();

  AgentStatus _status = AgentStatus.idle;
  String _fullLog = 'System idle. Awaiting commands...';
  String _typedLog = '';
  Timer? _typeTimer;

  late final AnimationController _entranceController;
  late final AnimationController _statusPulseController;
  late final AnimationController _buttonPressController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _statusPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _buttonPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.06,
    );

    _startTypewriter(_fullLog);
  }

  void _startTypewriter(String text) {
    _typeTimer?.cancel();
    _typedLog = '';
    int i = 0;
    _typeTimer = Timer.periodic(const Duration(milliseconds: 12), (t) {
      if (i >= text.length) {
        t.cancel();
        return;
      }
      setState(() => _typedLog += text[i]);
      i++;
    });
  }

  Color get _statusColor {
    switch (_status) {
      case AgentStatus.idle:
        return const Color(0xFF808A9A);
      case AgentStatus.connecting:
        return const Color(0xFF6EE7F9);
      case AgentStatus.success:
        return const Color(0xFF6EFFA3);
      case AgentStatus.error:
        return const Color(0xFFFF6E6E);
    }
  }

  String get _statusLabel {
    switch (_status) {
      case AgentStatus.idle:
        return 'IDLE';
      case AgentStatus.connecting:
        return 'CONNECTING';
      case AgentStatus.success:
        return 'TASK COMPLETE';
      case AgentStatus.error:
        return 'ERROR';
    }
  }

  Future<void> _executeTask() async {
    HapticFeedback.selectionClick();
    if (_repoController.text.isEmpty || _commandController.text.isEmpty) {
      setState(() {
        _status = AgentStatus.error;
      });
      _startTypewriter('⚠ Error: please fill in both the repository URL and command fields.');
      return;
    }

    setState(() {
      _status = AgentStatus.connecting;
    });
    _startTypewriter(
      '➤ connecting to Jarvis agent server [${_ipController.text}:8000]...\n> executing task loop...',
    );

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
        setState(() => _status = AgentStatus.success);
        _startTypewriter('[Task completed successfully]\n\n${data['logs']}');
      } else {
        setState(() => _status = AgentStatus.error);
        _startTypewriter('✗ Server error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      setState(() => _status = AgentStatus.error);
      _startTypewriter(
        '✗ Connection failed.\nEnsure your phone is on the same Wi-Fi network and that server.py is actively running on your PC.\n\nDetails: $e',
      );
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _statusPulseController.dispose();
    _buttonPressController.dispose();
    _typeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entrance = CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _statusPulseController,
              builder: (context, _) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor.withOpacity(0.6 * _statusPulseController.value + 0.2),
                      blurRadius: 10 + 6 * _statusPulseController.value,
                      spreadRadius: 1 + 2 * _statusPulseController.value,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('JARVIS BUILD AGENT', style: TextStyle(letterSpacing: 2, fontSize: 15)),
          ],
        ),
      ),
      body: Stack(
        children: [
          const _AnimatedGridBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 100, 18, 24),
              child: FadeTransition(
                opacity: entrance,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                      .animate(entrance),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StaggerIn(index: 0, controller: _entranceController, child: _statusBanner()),
                      const SizedBox(height: 18),
                      _StaggerIn(index: 1, controller: _entranceController, child: _glassField(
                        controller: _ipController,
                        label: 'Server IP Address',
                        icon: Icons.dns_rounded,
                      )),
                      const SizedBox(height: 14),
                      _StaggerIn(index: 2, controller: _entranceController, child: _glassField(
                        controller: _repoController,
                        label: 'Git Repository URL',
                        icon: Icons.code_rounded,
                      )),
                      const SizedBox(height: 14),
                      _StaggerIn(index: 3, controller: _entranceController, child: _glassField(
                        controller: _commandController,
                        label: 'Command (e.g. "Run tests")',
                        icon: Icons.terminal_rounded,
                      )),
                      const SizedBox(height: 22),
                      _StaggerIn(index: 4, controller: _entranceController, child: _executeButton()),
                      const SizedBox(height: 26),
                      _StaggerIn(index: 5, controller: _entranceController, child: _terminalPanel()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _statusColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: _status == AgentStatus.connecting
                ? SizedBox(
                    key: const ValueKey('spin'),
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _statusColor),
                  )
                : Icon(
                    key: ValueKey(_status),
                    _status == AgentStatus.success
                        ? Icons.check_circle_rounded
                        : _status == AgentStatus.error
                            ? Icons.error_rounded
                            : Icons.radio_button_unchecked_rounded,
                    color: _statusColor,
                    size: 18,
                  ),
          ),
          const SizedBox(width: 10),
          Text(
            _statusLabel,
            style: TextStyle(color: _statusColor, letterSpacing: 1.5, fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return _FocusGlow(
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.04),
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF8B96A8), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF6EE7F9), size: 19),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF6EE7F9), width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _executeButton() {
    final isLoading = _status == AgentStatus.connecting;
    return GestureDetector(
      onTapDown: (_) => _buttonPressController.forward(),
      onTapUp: (_) => _buttonPressController.reverse(),
      onTapCancel: () => _buttonPressController.reverse(),
      onTap: isLoading ? null : _executeTask,
      child: AnimatedBuilder(
        animation: _buttonPressController,
        builder: (context, child) => Transform.scale(
          scale: 1 - _buttonPressController.value,
          child: child,
        ),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: isLoading
                  ? [const Color(0xFF3A4152), const Color(0xFF2B3140)]
                  : [const Color(0xFF6EE7F9), const Color(0xFFB794F6)],
            ),
            boxShadow: isLoading
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF6EE7F9).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2.4),
                    )
                  : const Text(
                      'EXECUTE TASK',
                      key: ValueKey('label'),
                      style: TextStyle(
                        color: Color(0xFF0A0B10),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.6,
                        fontSize: 13.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _terminalPanel() {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6EE7F9).withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _dot(const Color(0xFFFF6E6E)),
              const SizedBox(width: 6),
              _dot(const Color(0xFFFFD86E)),
              const SizedBox(width: 6),
              _dot(const Color(0xFF6EFFA3)),
              const SizedBox(width: 10),
              const Text('terminal output', style: TextStyle(color: Color(0xFF7A8494), fontSize: 11.5)),
            ],
          ),
          const Divider(color: Color(0xFF232A38), height: 22),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                color: Color(0xFF7CFFB2),
                height: 1.5,
              ),
              children: [
                TextSpan(text: _typedLog),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _BlinkingCursor(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(0.8)),
      );
}

/// Staggers each child's fade/slide-in based on [index] and a shared [controller].
class _StaggerIn extends StatelessWidget {
  final int index;
  final AnimationController controller;
  final Widget child;
  const _StaggerIn({required this.index, required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    final start = (index * 0.08).clamp(0.0, 0.8);
    final end = (start + 0.5).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }
}

/// Adds a soft glow behind a text field while it holds focus.
class _FocusGlow extends StatefulWidget {
  final Widget child;
  const _FocusGlow({required this.child});
  @override
  State<_FocusGlow> createState() => _FocusGlowState();
}

class _FocusGlowState extends State<_FocusGlow> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: const Color(0xFF6EE7F9).withOpacity(0.18),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Simple blinking text-cursor, like a live terminal caret.
class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(width: 7, height: 14, color: const Color(0xFF7CFFB2)),
    );
  }
}

/// Slow-drifting faint grid + scanline, purely ambient — respects reduced motion
/// implicitly by being subtle and non-essential to comprehension.
class _AnimatedGridBackground extends StatefulWidget {
  const _AnimatedGridBackground();
  @override
  State<_AnimatedGridBackground> createState() => _AnimatedGridBackgroundState();
}

class _AnimatedGridBackgroundState extends State<_AnimatedGridBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.2,
            colors: [Color(0xFF141A26), Color(0xFF0A0B10)],
          ),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _GridPainter(_c.value),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double t;
  _GridPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6EE7F9).withOpacity(0.035)
      ..strokeWidth = 1;
    const spacing = 34.0;
    final offset = (t * spacing) % spacing;
    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = -spacing + offset; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => true;
}
