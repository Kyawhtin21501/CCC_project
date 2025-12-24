import 'package:flutter/material.dart';
import 'cardbox.dart';

class ResponsiveBodyCard extends StatelessWidget {
  final Widget formCard;
  final Widget dailyReportCard;
  final Widget salesCard;

  const ResponsiveBodyCard({
    super.key,
    required this.formCard,
    required this.salesCard,
    required this.dailyReportCard,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Desktop & Tablet View
        if (width >= 600) {
          return SingleChildScrollView(
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: CardBox(child: formCard)),
                      const SizedBox(width: 16),
                      Expanded(child: CardBox(child: dailyReportCard)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CardBox(child: salesCard),
              ],
            ),
          );
        }

        // Mobile View
        return SingleChildScrollView(
          child: Column(
            children: [
              CardBox(child: formCard),
              const SizedBox(height: 12),
              CardBox(child: dailyReportCard),
              const SizedBox(height: 12),
              CardBox(child: salesCard),
            ],
          ),
        );
      },
    );
  }
}