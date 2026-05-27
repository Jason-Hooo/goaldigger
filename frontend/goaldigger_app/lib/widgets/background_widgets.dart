part of '../main.dart';

class PinkBackground extends StatelessWidget {
  const PinkBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE7F0), Color(0xFFFFF6FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -40,
            left: -20,
            child: DecorBlob(size: 140, color: Color(0xFFFFC7DA)),
          ),
          Positioned(
            top: 180,
            right: -60,
            child: DecorBlob(size: 200, color: Color(0xFFFFD9E8)),
          ),
          Positioned(
            bottom: -40,
            left: 30,
            child: DecorBlob(size: 160, color: Color(0xFFFFC0D6)),
          ),
        ],
      ),
    );
  }
}

class DecorBlob extends StatelessWidget {
  const DecorBlob({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.6),
      ),
    );
  }
}
