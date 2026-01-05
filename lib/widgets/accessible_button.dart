import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibleButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final String semanticLabel; // What TalkBack says
  final Color? color;
  final IconData? icon;

  const AccessibleButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.semanticLabel,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // ♿ Semantics wrapper for Screen Readers
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: true,
      excludeSemantics: true, // Hide internal child details, read label only
      child: SizedBox(
        height: 80, // Minimum accessible height
        width: double.infinity, // Full width for easy tapping
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Theme.of(context).primaryColor,
          ),
          onPressed: () {
            // 🔊 Haptic feedback could go here
            onTap();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 40, color: Colors.white),
                const SizedBox(width: 16),
              ],
              Text(
                text,
                style: Theme.of(context).textTheme.button,
              ),
            ],
          ),
        ),
      ),
    );
  }
}