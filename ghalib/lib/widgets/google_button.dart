import 'package:flutter/material.dart';

class GoogleButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const GoogleButton({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/download.png', height: 24), 
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}
