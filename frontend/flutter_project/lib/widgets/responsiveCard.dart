import 'package:flutter/material.dart';
import 'cardbox.dart';

/// A layout widget that arranges dashboard cards responsively.
/// 
/// On Wide Screens (Desktop/Tablet):
/// - Row 1 displays 'Form' and 'Daily Report' side-by-side.
/// - Rows 2 and 3 display 'Sales' and 'Shift' as full-width blocks.
/// 
/// On Narrow Screens (Mobile):
/// - All cards are stacked vertically in a single column.
class ResponsiveBodyCard extends StatelessWidget {
  final Widget formCard;
  final Widget dailyReportCard;
  final Widget salesCard;
  final Widget shiftCard; 

  const ResponsiveBodyCard({
    super.key,
    required this.formCard,
    required this.salesCard,
    required this.dailyReportCard,
    required this.shiftCard,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Threshold for switching between mobile and desktop layout
        final width = constraints.maxWidth;
        final bool isDesktop = width >= 600;
        
        // Dynamic spacing based on screen size
        final double spacing = isDesktop ? 16 : 12;

        return SingleChildScrollView(
          padding: EdgeInsets.all(spacing),
          child: Column(
            children: [
              // --- Row 1: Input Section ---
              // On desktop, we use IntrinsicHeight so both cards match the tallest sibling's height.
              if (isDesktop)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: CardBox(child: formCard)),
                      SizedBox(width: spacing),
                      Expanded(child: CardBox(child: dailyReportCard)),
                    ],
                  ),
                )
              else ...[
                // On mobile, we stack them for better vertical scrolling experience.
                CardBox(child: formCard),
                SizedBox(height: spacing),
                CardBox(child: dailyReportCard),
              ],

              SizedBox(height: spacing),

              // --- Row 2: Visual Analytics ---
              // Typically contains a Line Chart or Bar Graph (Sales Data).
              CardBox(child: salesCard),

              SizedBox(height: spacing),

              // --- Row 3: Operational Status ---
              // Displays the real-time staff shift assignments.
              CardBox(child: shiftCard),
            ],
          ),
        );
      },
    );
  }
}