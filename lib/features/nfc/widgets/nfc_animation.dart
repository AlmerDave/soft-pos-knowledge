import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

class NfcAnimation extends StatefulWidget {
  final bool isActive;

  const NfcAnimation({super.key, this.isActive = true});

  @override
  State<NfcAnimation> createState() => _NfcAnimationState();
}

class _NfcAnimationState extends State<NfcAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(NfcAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wave 1
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: (1 - _controller.value) * 0.6,
                child: Container(
                  width: 100 + (_controller.value * 180),
                  height: 100 + (_controller.value * 180),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.nfcWave,
                      width: 2.5,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Wave 2 (delayed)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delayedValue = (_controller.value + 0.33) % 1.0;
              return Opacity(
                opacity: (1 - delayedValue) * 0.5,
                child: Container(
                  width: 100 + (delayedValue * 180),
                  height: 100 + (delayedValue * 180),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.nfcWave,
                      width: 2.5,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Wave 3 (more delayed)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delayedValue = (_controller.value + 0.66) % 1.0;
              return Opacity(
                opacity: (1 - delayedValue) * 0.4,
                child: Container(
                  width: 100 + (delayedValue * 180),
                  height: 100 + (delayedValue * 180),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.nfcWave,
                      width: 2.5,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Center Icon with glow effect
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.nfc,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              );
            },
          ),
          
          // Inner pulse circle
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: 0.3 - (_controller.value * 0.3),
                child: Container(
                  width: 100 + (_controller.value * 40),
                  height: 100 + (_controller.value * 40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryPurple.withOpacity(0.1),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}