import 'package:flutter/material.dart';
import 'cardbox.dart';

class ResponsiveBodyCard extends StatelessWidget {
  final Widget formCard;
  final Widget dailyReportCard;
  final Widget salesCard;
  final Widget shiftCard; // Added new slot

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
        final width = constraints.maxWidth;
        final bool isDesktop = width >= 600;
        final double spacing = isDesktop ? 16 : 12;

        return SingleChildScrollView(
          padding: EdgeInsets.all(spacing),
          child: Column(
            children: [
              // Row 1: Form and Daily Report
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
                CardBox(child: formCard),
                SizedBox(height: spacing),
                CardBox(child: dailyReportCard),
              ],

              SizedBox(height: spacing),

              // Row 2: Sales Chart
              CardBox(child: salesCard),

              SizedBox(height: spacing),

              // Row 3: Today's Shift Assignment (The one you liked)
              CardBox(child: shiftCard),
            ],
          ),
        );
      },
    );
  }
}