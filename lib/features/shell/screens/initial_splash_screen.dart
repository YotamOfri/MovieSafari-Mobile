import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../providers/api_provider.dart';

class InitialSplashScreen extends ConsumerStatefulWidget {
  const InitialSplashScreen({super.key});

  @override
  ConsumerState<InitialSplashScreen> createState() => _InitialSplashScreenState();
}

class _InitialSplashScreenState extends ConsumerState<InitialSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)),
    );

    _controller.forward();

    // Pre-fetch critical data while splash is showing
    _preFetchData();

    // Navigate to home after animation + a small delay
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        context.go('/');
      }
    });
  }

  void _preFetchData() {
    ref.read(heroCarouselProvider);
    ref.read(filteredMoviesProvider);
    ref.read(filteredSeriesProvider);
    ref.read(trendingMoviesProvider);
    ref.read(trendingSeriesProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Image (Poster Banner)
          Image.asset(
            'assets/PosterBanner.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0F1014)),
          ),
          
          // 2. Blur Overlay + Darkening
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F1014).withValues(alpha: 0.7),
                    const Color(0xFF0F1014).withValues(alpha: 0.9),
                    const Color(0xFF0F1014),
                  ],
                ),
              ),
            ),
          ),
          
          // 3. Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        children: [
                          // App Logo (SVG)
                          Container(
                            width: 180,
                            height: 180,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withValues(alpha: 0.15),
                                  blurRadius: 60,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: SvgPicture.asset(
                              'assets/Logo.svg',
                              fit: BoxFit.contain,
                              placeholderBuilder: (context) => const CircularProgressIndicator(),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // App Name
                          const Text(
                            'Movie safari',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Explore the cinematic wild',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.6),
                              letterSpacing: 2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          
          // Bottom Loading Indicator
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'PREPARING YOUR SAFARI...',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
