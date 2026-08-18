import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

const List<String> kOperatorLabels = ['+', '-', 'x', '/', '%', '←', 'AC'];

class CalculatorButton extends StatelessWidget {
  final String label;
  final bool wide;
  final bool isEquals;
  final VoidCallback onTap;

  const CalculatorButton({
    super.key,
    required this.label,
    required this.onTap,
    this.wide = false,
    this.isEquals = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOperator = kOperatorLabels.contains(label);
    final bgColor = isEquals ? AppColors.accent : AppColors.buttonBg;
    final textColor = isEquals
        ? AppColors.textLight
        : (isOperator ? AppColors.accent : AppColors.textLight);

    return AspectRatio(
      aspectRatio: wide ? 2 : 1,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 25,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
