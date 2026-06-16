import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:raheeq_main/utils/colors.dart';

/// A modern, premium Soundwave/Audio-wave Loading Indicator.
/// Replaces the legacy Water Loading Indicator with an interactive, glowing soundwave animation.
class WaterLoadingIndicator extends StatefulWidget {
  final double size;
  final String? message;
  final Color? waveColor1;
  final Color? waveColor2;
  final Color? dropletBackgroundColor;
  final bool showContainer;

  const WaterLoadingIndicator({
    super.key,
    this.size = 40.0,
    this.message,
    this.waveColor1,
    this.waveColor2,
    this.dropletBackgroundColor,
    this.showContainer = true,
  });

  @override
  State<WaterLoadingIndicator> createState() => _WaterLoadingIndicatorState();
}

class _WaterLoadingIndicatorState extends State<WaterLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Soundwave configuration for 5 beautiful bouncing bars
  final List<double> _minHeights = [0.25, 0.45, 0.30, 0.50, 0.20];
  final List<double> _maxHeights = [0.85, 1.00, 0.90, 1.00, 0.75];

  // Custom multipliers for varying animation cycles and speeds per bar
  final List<double> _speedMultipliers = [1.0, 1.2, 0.9, 1.3, 1.1];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Proportional dimensions using the full widget size
    final innerSize = widget.size;

    final barWidth = innerSize * 0.12;
    final spacing = innerSize * 0.08;

    final bool hasMessage =
        widget.message != null && widget.message!.isNotEmpty;

    final Widget animationWidget = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Build the list of animated bars
        final List<Widget> bars = List.generate(5, (index) {
          // Calculate individual bar motion using sine wave and specific speed/phase offsets
          final double angle =
              (_controller.value * 2 * math.pi * _speedMultipliers[index]) +
              (index * 0.65);
          final double sineValue =
              (math.sin(angle) + 1.0) / 2.0; // Map from [-1, 1] to [0, 1]

          // Final animated height for this specific bar
          final double heightFactor =
              _minHeights[index] +
              (_maxHeights[index] - _minHeights[index]) * sineValue;
          final double barHeight = innerSize * heightFactor;

          return Container(
            width: barWidth,
            height: barHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(barWidth / 2),
              gradient: LinearGradient(
                colors: [
                  widget.waveColor1 ?? AppColors.buttonBlue,
                  widget.waveColor2 ?? AppColors.headerlightblue,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          );
        });

        final Widget soundwave = SizedBox(
          width: innerSize,
          height: innerSize,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(bars.length * 2 - 1, (index) {
              // Alternate between bar widgets and spacing gaps
              if (index.isEven) {
                return bars[index ~/ 2];
              } else {
                return SizedBox(width: spacing);
              }
            }),
          ),
        );

        Widget content;
        if (widget.showContainer) {
          content = SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(child: soundwave),
          );
        } else {
          content = soundwave;
        }

        return content;
      },
    );

    if (!hasMessage) {
      return Center(child: animationWidget);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          animationWidget,
          const SizedBox(height: 16),
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.buttonBlueDark,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
