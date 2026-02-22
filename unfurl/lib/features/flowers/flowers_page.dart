import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:unfurl/shared/theme.dart';
import 'package:unfurl/shared/widgets/app_drawer.dart';

// ─────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────

class EarnedFlower {
  final String filename; // e.g. "Remarkable Rose.svg"
  final String tier; // EXCELLENT | MEDIUM | SMALL | MICRO

  const EarnedFlower({required this.filename, required this.tier});

  String get assetPath {
    final folder = _folderForTier(tier);
    return 'flowers/$folder/$filename';
  }

  static String _folderForTier(String tier) {
    switch (tier) {
      case 'EXCELLENT':
        return 'AMAZINGGGG 6+ hours';
      case 'MEDIUM':
        return 'Hell yea 2hr-6hr';
      case 'SMALL':
        return 'I like 30min-2hr';
      case 'MICRO':
      default:
        return 'meh less than 30 min';
    }
  }

  // Display name strips the ".svg" extension
  String get displayName => filename.replaceAll('.svg', '');
}

// ─────────────────────────────────────────────
// Sample data – swap this out for your API/Firestore data
// ─────────────────────────────────────────────

const List<EarnedFlower> _sampleFlowers = [
  EarnedFlower(filename: 'Remarkable Rose.svg',        tier: 'EXCELLENT'),
  EarnedFlower(filename: 'Outstanding Orchid.svg',     tier: 'EXCELLENT'),
  EarnedFlower(filename: 'Mindful Mimosa.svg',         tier: 'MEDIUM'),
  EarnedFlower(filename: 'Heroic Hyacinth.svg',        tier: 'MEDIUM'),
  EarnedFlower(filename: 'Prosperous Peony.svg',       tier: 'MEDIUM'),
  EarnedFlower(filename: 'Grindset Gladiolus.svg',     tier: 'SMALL'),
  EarnedFlower(filename: 'Focused Freesia.svg',        tier: 'SMALL'),
  EarnedFlower(filename: 'Grand Gerbera.svg',          tier: 'SMALL'),
  EarnedFlower(filename: 'Hardworking Hydrangea.svg',  tier: 'SMALL'),
  EarnedFlower(filename: 'Dauntless Daisy.svg',        tier: 'MICRO'),
  EarnedFlower(filename: 'Jaunty Jasmine.svg',         tier: 'MICRO'),
  EarnedFlower(filename: 'Ambitious Almond.svg',       tier: 'MICRO'),
];

// ─────────────────────────────────────────────
// Bouquet layout helpers
// ─────────────────────────────────────────────

/// Describes where a single flower head is placed inside the bouquet stack.
class _FlowerPlacement {
  final EarnedFlower flower;
  final double dx;        // offset from bouquet centre, in logical pixels
  final double dy;        // offset from bouquet centre, in logical pixels
  final double size;      // rendered width & height of the SVG
  final double rotation;  // radians

  const _FlowerPlacement({
    required this.flower,
    required this.dx,
    required this.dy,
    required this.size,
    required this.rotation,
  });
}

/// Builds placement data for every flower in the list.
/// Flowers are arranged in concentric arcs so the bouquet stays tidy
/// even with 20+ blooms, while still feeling natural.
/// Places flowers in a neat upward-facing semicircle.
///
/// The semicircle's flat edge (diameter) sits at [originY], centred on
/// [originX]. Flowers radiate upward from that baseline in concentric
/// arcs, exactly like a hand-tied bouquet viewed from the front.
///
/// Slot order per row (n slots, left-to-right angles):
///   Row 0 (innermost): 1 flower  → straight up (centre)
///   Row 1:             3 flowers → centre, right, left
///   Row 2:             5 flowers → evenly spread across wider arc
///   Row 3+:            fills remaining flowers
List<_FlowerPlacement> _buildPlacements(
  List<EarnedFlower> flowers,
  double bouquetWidth,
  double bouquetHeight, {
  required double originX,
  required double originY,
}) {
  final rng = Random(42); // fixed seed → stable layout
  final placements = <_FlowerPlacement>[];

  double sizeFor(String tier) {
    switch (tier) {
      case 'EXCELLENT': return bouquetWidth * 0.20;
      case 'MEDIUM':    return bouquetWidth * 0.17;
      case 'SMALL':     return bouquetWidth * 0.14;
      case 'MICRO':
      default:          return bouquetWidth * 0.12;
    }
  }

  // Each row: how many slots and what arc radius (fraction of bouquetWidth)
  // Rows spread upward in a semicircle (angles from -π to 0, i.e. upper half)
  final rows = [
    _RowDef(slots: 1,  radiusFraction: 0.00), // centre
    _RowDef(slots: 3,  radiusFraction: 0.14),
    _RowDef(slots: 5,  radiusFraction: 0.26),
    _RowDef(slots: 7,  radiusFraction: 0.38),
    _RowDef(slots: 9,  radiusFraction: 0.50),
    _RowDef(slots: 11, radiusFraction: 0.62),
  ];

  int flowerIndex = 0;

  for (final row in rows) {
    if (flowerIndex >= flowers.length) break;

    final radius = bouquetWidth * row.radiusFraction;
    final n = row.slots;

    // How many flowers actually go in this row
    final inThisRow = (flowers.length - flowerIndex).clamp(0, n);

    for (int i = 0; i < inThisRow; i++) {
      double angle;
      if (n == 1) {
        angle = -pi / 2; // straight up
      } else {
        // Spread evenly across the upper semicircle (-π → 0)
        // but clamp to a slightly narrower arc so edge flowers
        // don't lean too far sideways.
        const arcSpread = pi * 0.85; // 153°
        final step = arcSpread / (n - 1);
        final startAngle = -pi / 2 - arcSpread / 2;

        // Centre the actual flowers if fewer than full row
        final offset = (n - inThisRow) / 2;
        angle = startAngle + (i + offset) * step;
      }

      // Tiny jitter so it feels hand-arranged, not mechanical
      final jitter = bouquetWidth * 0.012;
      final dx = originX + radius * cos(angle) + (rng.nextDouble() - 0.5) * jitter;
      final dy = originY + radius * sin(angle) + (rng.nextDouble() - 0.5) * jitter;

      placements.add(_FlowerPlacement(
        flower: flowers[flowerIndex],
        dx: dx,
        dy: dy,
        size: sizeFor(flowers[flowerIndex].tier),
        rotation: (rng.nextDouble() - 0.5) * 0.30,
      ));

      flowerIndex++;
    }
  }

  return placements;
}

class _RowDef {
  final int slots;
  final double radiusFraction;
  const _RowDef({required this.slots, required this.radiusFraction});
}

// ─────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────

class FlowersPage extends StatefulWidget {
  /// Pass your real earned flowers here once connected to Firestore/API.
  final List<EarnedFlower> flowers;

  const FlowersPage({
    super.key,
    this.flowers = _sampleFlowers,
  });

  @override
  State<FlowersPage> createState() => _FlowersPageState();
}

class _FlowersPageState extends State<FlowersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bouquet'),
      ),
      drawer: const AppDrawer(currentRoute: '/flowers'),
      body: Container(
        decoration: const BoxDecoration(gradient: blossomBackground),
        child: Column(
          children: [
            // ── Header card ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFFD1E5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Garden',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.flowers.length} bloom${widget.flowers.length == 1 ? '' : 's'} earned • every completed task blooms into something beautiful.',
                    ),
                  ],
                ),
              ),
            ),

            // ── Bouquet ──────────────────────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // The bouquet visual occupies most of the available height,
                  // capped so it doesn't get absurdly tall on tablets.
                  final bouquetHeight =
                      (constraints.maxHeight * 0.92).clamp(0.0, 620.0);
                  final bouquetWidth =
                      (constraints.maxWidth * 0.72).clamp(0.0, 360.0);

                  return Center(
                    child: SizedBox(
                      width: bouquetWidth,
                      height: bouquetHeight,
                      child: _BouquetStack(
                        flowers: widget.flowers,
                        bouquetWidth: bouquetWidth,
                        bouquetHeight: bouquetHeight,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bouquet stack widget
// ─────────────────────────────────────────────

class _BouquetStack extends StatelessWidget {
  final List<EarnedFlower> flowers;
  final double bouquetWidth;
  final double bouquetHeight;

  const _BouquetStack({
    required this.flowers,
    required this.bouquetWidth,
    required this.bouquetHeight,
  });

  @override
  Widget build(BuildContext context) {
    // ── SVG intrinsic dimensions ──────────────────────────────────────────
    // paper.svg:       1080 × 2296
    //   • cone opening is ~14px from top of canvas  → 14/2296 = 0.61% from top
    // stemsleaves.svg:  993 × 913
    //   • content reaches the very top edge (0px padding)
    //   • ~10px empty gap at the bottom               → bottom padding = 10/913 = 1.1%

    const double paperAspect  = 2296 / 1080; // ~2.126
    const double leavesAspect = 993  / 913;  // ~1.088

    // Paper rendered width = bouquetWidth (width-constrained by BoxFit.contain).
    // Rendered height follows from aspect ratio.
    final renderedPaperW = bouquetWidth;
    final renderedPaperH = renderedPaperW * paperAspect;

    // We want the full cone (from opening to tip) visible on screen.
    // Give the paper box exactly the rendered height so no clipping occurs,
    // but cap it so it doesn't overflow the bouquet area.
    final paperBoxHeight = renderedPaperH.clamp(0.0, bouquetHeight * 0.82);

    // Because BoxFit.contain is bottom-aligned and the box may be shorter than
    // the full rendered height (due to the clamp), the image is cropped at the top.
    // The visible portion starts at (renderedPaperH - paperBoxHeight) into the SVG.
    // The cone opening in the SVG is at 14/2296 = 0.61% from top of the SVG.
    final svgConeOpeningPx  = renderedPaperH * 0.0061; // px from top of rendered image
    final visibleStartPx    = renderedPaperH - paperBoxHeight; // how much is cropped off top
    final coneOpeningInBox  = svgConeOpeningPx - visibleStartPx; // px from top of Positioned box
    final coneOpeningY      = (bouquetHeight - paperBoxHeight) + coneOpeningInBox.clamp(0.0, paperBoxHeight);

    // ── Stems/leaves ─────────────────────────────────────────────────────
    // Scale leaves so their width matches the paper width.
    final renderedLeavesW = renderedPaperW * 0.70;
    final renderedLeavesH = renderedLeavesW / leavesAspect;

    // The leaves SVG has ~10px bottom gap in a 913px canvas = 1.1% wasted.
    // We want the visual bottom of the leaves to sit at coneOpeningY so they
    // tuck into the paper opening naturally.
    final leavesVisualH   = renderedLeavesH * (1 - 0.011); // strip bottom gap
    final leavesTopY      = coneOpeningY - leavesVisualH + renderedLeavesH * 1.17;
    final leavesLeft      = (bouquetWidth - renderedLeavesW) / 2;

    // Flower origin: shifted down to match leaves position
    final originX = bouquetWidth / 2;
    final originY = coneOpeningY + renderedLeavesH * 0.9;

    final placements = _buildPlacements(
      flowers, bouquetWidth, bouquetHeight,
      originX: originX,
      originY: originY,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── 1. Paper cone — behind leaves ─────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: paperBoxHeight,
          child: SvgPicture.asset(
            'flowers/paper.svg',
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
          ),
        ),

        // ── 2. Stems / leaves — in front of paper ─────────────────────────
        Positioned(
          left: leavesLeft,
          top: leavesTopY,
          width: renderedLeavesW,
          height: renderedLeavesH,
          child: SvgPicture.asset(
            'flowers/stemsleaves.svg',
            fit: BoxFit.contain,
          ),
        ),

        // ── 3. Flower heads (MICRO at back → EXCELLENT at front) ──────────
        ..._sortedPlacements(placements).map((p) {
          return Positioned(
            left: p.dx - p.size / 2,
            top:  p.dy - p.size / 2,
            width: p.size,
            height: p.size,
            child: Transform.rotate(
              angle: p.rotation,
              child: SvgPicture.asset(
                p.flower.assetPath,
                fit: BoxFit.contain,
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Returns placements sorted so lower tiers render behind higher tiers.
  List<_FlowerPlacement> _sortedPlacements(List<_FlowerPlacement> placements) {
    const order = {'MICRO': 0, 'SMALL': 1, 'MEDIUM': 2, 'EXCELLENT': 3};
    return [...placements]
      ..sort((a, b) =>
          (order[a.flower.tier] ?? 0).compareTo(order[b.flower.tier] ?? 0));
  }
}


