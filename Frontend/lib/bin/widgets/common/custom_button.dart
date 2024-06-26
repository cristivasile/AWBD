import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final Color color;
  final void Function()? onPressed;
  final double size;
  final Icon icon;

  const CustomButton({
    Key? key,
    required this.color,
    required this.onPressed,
    required this.size,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        child: FloatingActionButton(
          onPressed: onPressed,
          child: icon,
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
