import 'package:flutter/material.dart';
import 'cardbox.dart';


class ResponsiveBodyCard extends StatelessWidget {
  final Widget formCard;
  final Widget salesCard;
  final Widget shiftCard;

  const ResponsiveBodyCard({
    Key? key,
    required this.formCard,
    required this.salesCard,
    required this.shiftCard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;

      // ==========================================================
      // DESKTOP (width >= 1000): Requested 3-Row Stacked Layout
      // (Form/Empty) then (Sales) then (Shift)
      // ==========================================================
      if (width >= 1000) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // --- ROW 1: Form Card (50%) and Empty Space (50%) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column 1: Form Card (50%)
                  Flexible(
                      flex: 50,
                      child: CardBox(
                        child: formCard,
                      )),
                  const SizedBox(width: 16),
                  // Column 2: Empty Space (50%)
                 Flexible(
                      flex: 50,
                      child: CardBox(
                        child: Container(), // Empty Container
                      )),
                ],
              ),
              const SizedBox(height: 16),

              // --- ROW 2: Sales Card (100% Full Width) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                      flex: 100,
                      child: CardBox(
                        child: salesCard,
                      )),
                ],
              ),
              const SizedBox(height: 16),

              // --- ROW 3: Shift Card (100% Full Width) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                      flex: 100,
                      child: CardBox(
                        child: shiftCard,
                      )),
                ],
              ),
            ],
          ),
        );
      }

      // ==========================================================
      // TABLET (width >= 600): Wrap Layout (No Change)
      // ==========================================================
      if (width >= 600) {
        return SingleChildScrollView(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              // Card 1 (Half width)
              SizedBox(width: (width - 16) / 2, child: CardBox(child: formCard)),
              // Card 2 (Half width)
              SizedBox(width: (width - 16) / 2, child: CardBox(child: salesCard)),
              // Card 3 (Full width)
              SizedBox(width: width, child: CardBox(child: shiftCard)),
            ],
          ),
        );
      }

      // ==========================================================
      // MOBILE (Default): Stacked Column Layout (No Change)
      // ==========================================================
      return SingleChildScrollView(
        child: Column(
          children: [
            CardBox(child: formCard),
            const SizedBox(height: 12),
            CardBox(child: salesCard),
            const SizedBox(height: 12),
            CardBox(child: shiftCard),
          ],
        ),
      );
    });
  }
}