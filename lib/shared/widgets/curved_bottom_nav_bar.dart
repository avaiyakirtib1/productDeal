import 'package:flutter/material.dart';

class CurvedBottomNavBar extends StatefulWidget {
  const CurvedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CurvedNavBarItem> items;

  @override
  State<CurvedBottomNavBar> createState() => _CurvedBottomNavBarState();
}

class _CurvedBottomNavBarState extends State<CurvedBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 70),
            painter: _CurvedPainter(
              currentIndex: widget.currentIndex,
              itemCount: widget.items.length,
            ),
          ),
          SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                widget.items.length,
                (index) => _buildNavItem(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = widget.items[index];
    final isSelected = index == widget.currentIndex;
    final size = isSelected ? 28.0 : 24.0;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: size,
                height: size,
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: size,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CurvedNavBarItem {
  const CurvedNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _CurvedPainter extends CustomPainter {
  _CurvedPainter({
    required this.currentIndex,
    required this.itemCount,
  });

  final int currentIndex;
  final int itemCount;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    final itemWidth = size.width / itemCount;
    final centerX = (currentIndex * itemWidth) + (itemWidth / 2);
    final curveHeight = 25.0;
    final curveWidth = 60.0;

    // Start from top left
    path.moveTo(0, 0);

    // Top line to start of curve
    path.lineTo(centerX - curveWidth / 2, 0);

    // Create curved notch at top
    path.quadraticBezierTo(
      centerX - curveWidth / 2,
      curveHeight,
      centerX,
      curveHeight + 8,
    );
    path.quadraticBezierTo(
      centerX + curveWidth / 2,
      curveHeight,
      centerX + curveWidth / 2,
      0,
    );

    // Top line to top right
    path.lineTo(size.width, 0);

    // Right side
    path.lineTo(size.width, size.height);

    // Bottom line
    path.lineTo(0, size.height);

    // Close path
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CurvedPainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex ||
        oldDelegate.itemCount != itemCount;
  }
}
