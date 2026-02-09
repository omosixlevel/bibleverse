import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/data/repository.dart';
import '../../app.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _statusMessage = 'Initializing...';
  double _progress = 0.0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Extended to 5s
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Wait for the full 5s animation to complete (or at least most of it)
    // We'll use a minimum delay to ensure the user sees the splash
    final minSplashDuration = Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    final repository = Provider.of<Repository>(context, listen: false);

    setState(() {
      _statusMessage = 'Syncing data...';
      _progress = 0.3;
    });

    try {
      // Preload Data (Events, Rooms)
      await repository.preloadData();

      setState(() {
        _statusMessage = 'Ready!';
        _progress = 1.0;
      });

      // Ensure the minimum 5s duration has passed
      await minSplashDuration;

      if (mounted) {
        // Navigate to Home (AppShell)
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AppShell(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(
              milliseconds: 800,
            ), // Slower fade out
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading data. Retrying...';
      });
      debugPrint('Splash Error: $e');
      // Retry or show error button? For hackathon, auto-proceed to home anyway
      // after a delay might be safer than getting stuck.
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme
                  .colorScheme
                  .surface, // Start with surface color (usually light/white or dark)
              theme.colorScheme.primaryContainer.withOpacity(
                0.3,
              ), // Subtle tint
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SvgPicture.asset(
                    'assets/images/bibleverseSVG.svg',
                    width: 220,
                    height: 220,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Animated Text & Loader
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'BIBLEVERSE',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dwell. Connect. Grow.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        letterSpacing: 1.2,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Elegant minimalistic loader
                    SizedBox(
                      width: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress > 0 ? _progress : null,
                          backgroundColor: theme.colorScheme.outlineVariant
                              .withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        letterSpacing: 1.5,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
