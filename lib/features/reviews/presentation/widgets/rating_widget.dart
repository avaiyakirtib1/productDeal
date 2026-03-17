import 'package:flutter/material.dart';

/// Star rating widget (1-5 stars)
class RatingWidget extends StatelessWidget {
  const RatingWidget({
    super.key,
    required this.rating,
    this.size = 20,
    this.showNumber = false,
    this.color,
  });

  final double rating; // 0-5
  final double size;
  final bool showNumber;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starColor = color ?? theme.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starIndex = index + 1;
          if (rating >= starIndex) {
            // Full star
            return Icon(
              Icons.star,
              size: size,
              color: starColor,
            );
          } else if (rating > starIndex - 1) {
            // Half star
            return Icon(
              Icons.star_half,
              size: size,
              color: starColor,
            );
          } else {
            // Empty star
            return Icon(
              Icons.star_border,
              size: size,
              color: starColor.withValues(alpha: 0.3),
            );
          }
        }),
        if (showNumber) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

/// Rating selector for review form
class RatingSelector extends StatefulWidget {
  const RatingSelector({
    super.key,
    required this.onRatingChanged,
    this.initialRating,
    this.size = 32,
  });

  final Function(int) onRatingChanged;
  final int? initialRating;
  final double size;

  @override
  State<RatingSelector> createState() => _RatingSelectorState();
}

class _RatingSelectorState extends State<RatingSelector> {
  int? _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starColor = theme.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isSelected =
            _selectedRating != null && starIndex <= _selectedRating!;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRating = starIndex;
            });
            widget.onRatingChanged(starIndex);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              size: widget.size,
              color: isSelected ? starColor : starColor.withValues(alpha: 0.3),
            ),
          ),
        );
      }),
    );
  }
}
