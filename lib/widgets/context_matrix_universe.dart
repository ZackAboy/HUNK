import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/context_entry.dart';
import 'context_matrix_models.dart';
import 'context_matrix_theme.dart';

class ContextMatrixUniverse extends StatefulWidget {
  const ContextMatrixUniverse({
    super.key,
    required this.nodes,
    required this.expandedSections,
    required this.focusedSection,
    required this.onSectionFocused,
    required this.onSectionManaged,
    required this.onAdd,
    required this.onEdit,
    required this.onResetFocus,
  });

  final List<ContextSectionNodeData> nodes;
  final Set<ContextSection> expandedSections;
  final ContextSection? focusedSection;
  final ValueChanged<ContextSection> onSectionFocused;
  final ValueChanged<ContextSection> onSectionManaged;
  final void Function(ContextSection section, String? title) onAdd;
  final ValueChanged<ContextEntry> onEdit;
  final VoidCallback onResetFocus;

  @override
  State<ContextMatrixUniverse> createState() => _ContextMatrixUniverseState();
}

class _ContextMatrixUniverseState extends State<ContextMatrixUniverse>
    with TickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _entranceController;
  late final AnimationController _focusController;
  Animation<Matrix4>? _focusAnimation;
  bool _hasInitialTransform = false;
  bool _pendingFocusTransform = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _focusController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 380),
        )..addListener(() {
          final animation = _focusAnimation;
          if (animation != null) {
            _transformationController.value = animation.value;
          }
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceController.value = 1;
    } else if (!_entranceController.isCompleted) {
      _entranceController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ContextMatrixUniverse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedSection != widget.focusedSection) {
      _pendingFocusTransform = true;
    }
  }

  @override
  void dispose() {
    _focusController.dispose();
    _entranceController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(
          constraints.maxWidth,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 620,
        );
        final contentSize = _contentSizeFor(viewport);
        final layout = _UniverseLayout.build(
          size: contentSize,
          nodes: widget.nodes,
          expandedSections: widget.expandedSections,
          focusedSection: widget.focusedSection,
        );

        _scheduleInitialTransform(viewport, layout, reduceMotion);
        _scheduleFocusTransformIfNeeded(
          viewport,
          layout,
          reduceMotion: reduceMotion,
        );

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.2, -0.3),
              radius: 1.08,
              colors: [
                Color(0xFF0B2542),
                ContextMatrixStyle.background2,
                ContextMatrixStyle.background,
              ],
            ),
          ),
          child: SizedBox(
            key: const ValueKey('context-network-chart'),
            height: viewport.height,
            width: viewport.width,
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _transformationController,
                      builder: (context, _) {
                        final matrix = _transformationController.value;
                        final storage = matrix.storage;
                        return CustomPaint(
                          key: const ValueKey(
                            'context-matrix-infinite-backdrop',
                          ),
                          isComplex: true,
                          willChange: true,
                          painter: _InfiniteMatrixBackdropPainter(
                            pan: Offset(storage[12], storage[13]),
                            scale: matrix.getMaxScaleOnAxis(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                InteractiveViewer(
                  key: const ValueKey('context-matrix-universe-viewer'),
                  transformationController: _transformationController,
                  constrained: false,
                  minScale: 0.58,
                  maxScale: 2.25,
                  boundaryMargin: const EdgeInsets.all(2400),
                  panEnabled: true,
                  scaleEnabled: true,
                  child: AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, _) {
                      final progress = reduceMotion
                          ? 1.0
                          : Curves.easeOutCubic.transform(
                              _entranceController.value,
                            );
                      return SizedBox(
                        width: contentSize.width,
                        height: contentSize.height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ContextMatrixConnectionPainter(
                                  edges: layout.edges,
                                  center: layout.center,
                                  progress: progress,
                                ),
                              ),
                            ),
                            for (final node in layout.visualNodes)
                              _PositionedUniverseNode(
                                node: node,
                                progress: progress,
                                onTap: () => _handleNodeTap(
                                  node,
                                  layout,
                                  viewport,
                                  reduceMotion: reduceMotion,
                                ),
                                onLongPress: () => _handleNodeLongPress(node),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _UniverseControls(
                    onReset: () =>
                        _focusHub(layout, viewport, reduceMotion: reduceMotion),
                    onZoomIn: () => _zoomToFocused(
                      layout,
                      viewport,
                      scaleDelta: 0.22,
                      reduceMotion: reduceMotion,
                    ),
                    onZoomOut: () => _zoomToFocused(
                      layout,
                      viewport,
                      scaleDelta: -0.22,
                      reduceMotion: reduceMotion,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleNodeTap(
    _UniverseVisualNode node,
    _UniverseLayout layout,
    Size viewport, {
    required bool reduceMotion,
  }) {
    switch (node.kind) {
      case _UniverseNodeKind.hub:
        _focusHub(layout, viewport, reduceMotion: reduceMotion);
      case _UniverseNodeKind.section:
        final section = node.section!;
        if (widget.focusedSection == section) {
          widget.onSectionManaged(section);
        } else {
          widget.onSectionFocused(section);
          _animateToNode(
            node,
            viewport,
            scale: 1.18,
            reduceMotion: reduceMotion,
          );
        }
      case _UniverseNodeKind.entry:
        widget.onEdit(node.entry!);
      case _UniverseNodeKind.missing:
        widget.onAdd(node.section!, node.missingTitle);
    }
  }

  void _handleNodeLongPress(_UniverseVisualNode node) {
    switch (node.kind) {
      case _UniverseNodeKind.section:
        widget.onSectionManaged(node.section!);
      case _UniverseNodeKind.entry:
        widget.onEdit(node.entry!);
      case _UniverseNodeKind.hub:
      case _UniverseNodeKind.missing:
        break;
    }
  }

  void _focusHub(
    _UniverseLayout layout,
    Size viewport, {
    required bool reduceMotion,
  }) {
    widget.onResetFocus();
    _animateToNode(
      layout.hub,
      viewport,
      scale: _initialScaleFor(viewport),
      reduceMotion: reduceMotion,
    );
  }

  void _zoomToFocused(
    _UniverseLayout layout,
    Size viewport, {
    required double scaleDelta,
    required bool reduceMotion,
  }) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final nextScale = (currentScale + scaleDelta).clamp(0.58, 2.25);
    final target = widget.focusedSection == null
        ? layout.hub
        : layout.nodeForSection(widget.focusedSection!) ?? layout.hub;
    _animateToNode(
      target,
      viewport,
      scale: nextScale.toDouble(),
      reduceMotion: reduceMotion,
    );
  }

  void _scheduleInitialTransform(
    Size viewport,
    _UniverseLayout layout,
    bool reduceMotion,
  ) {
    if (_hasInitialTransform || viewport.width <= 0 || viewport.height <= 0) {
      return;
    }
    _hasInitialTransform = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _animateToNode(
        widget.focusedSection == null
            ? layout.hub
            : layout.nodeForSection(widget.focusedSection!) ?? layout.hub,
        viewport,
        scale: _initialScaleFor(viewport),
        reduceMotion: true,
      );
    });
  }

  void _scheduleFocusTransformIfNeeded(
    Size viewport,
    _UniverseLayout layout, {
    required bool reduceMotion,
  }) {
    if (!_pendingFocusTransform ||
        viewport.width <= 0 ||
        viewport.height <= 0) {
      return;
    }
    _pendingFocusTransform = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final target = widget.focusedSection == null
          ? layout.hub
          : layout.nodeForSection(widget.focusedSection!) ?? layout.hub;
      _animateToNode(
        target,
        viewport,
        scale: widget.focusedSection == null
            ? _initialScaleFor(viewport)
            : 1.18,
        reduceMotion: reduceMotion,
      );
    });
  }

  void _animateToNode(
    _UniverseVisualNode node,
    Size viewport, {
    required double scale,
    required bool reduceMotion,
  }) {
    final target = _matrixForNode(node.center, viewport, scale);
    if (reduceMotion) {
      _focusController.stop();
      _transformationController.value = target;
      return;
    }

    _focusAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: target,
    ).animate(CurvedAnimation(parent: _focusController, curve: Curves.easeOut));
    _focusController
      ..reset()
      ..forward();
  }

  Matrix4 _matrixForNode(Offset center, Size viewport, double scale) {
    final tx = viewport.width / 2 - center.dx * scale;
    final ty = viewport.height / 2 - center.dy * scale;
    return Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, tx)
      ..setEntry(1, 3, ty);
  }

  Size _contentSizeFor(Size viewport) {
    final width = math.max(1800.0, viewport.width * 3.2);
    final height = math.max(1800.0, viewport.height * 2.35);
    return Size(width, height);
  }

  double _initialScaleFor(Size viewport) {
    if (viewport.width < 390) {
      return 0.78;
    }
    if (viewport.width < 560) {
      return 0.86;
    }
    return 0.94;
  }
}

class _ContextMatrixConnectionPainter extends CustomPainter {
  const _ContextMatrixConnectionPainter({
    required this.edges,
    required this.center,
    required this.progress,
  });

  final List<_UniverseEdge> edges;
  final Offset center;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    _drawOrbitRings(canvas);

    for (final edge in edges) {
      final to = Offset.lerp(edge.from, edge.to, progress)!;
      final control = Offset.lerp(edge.from, edge.control, progress)!;
      final path = Path()
        ..moveTo(edge.from.dx, edge.from.dy)
        ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);

      final glow = Paint()
        ..color = edge.color.withValues(alpha: edge.alpha * 0.16 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = edge.width + 5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, glow);

      final line = Paint()
        ..color = edge.color.withValues(alpha: edge.alpha * 0.72 * progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = edge.width
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, line);
    }
  }

  void _drawOrbitRings(Canvas canvas) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ContextMatrixStyle.cyan.withValues(alpha: 0.08);
    for (final radius in const [150.0, 245.0, 338.0]) {
      canvas.drawCircle(center, radius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ContextMatrixConnectionPainter oldDelegate) {
    return oldDelegate.edges != edges ||
        oldDelegate.progress != progress ||
        oldDelegate.center != center;
  }
}

class _InfiniteMatrixBackdropPainter extends CustomPainter {
  const _InfiniteMatrixBackdropPainter({
    required this.pan,
    required this.scale,
  });

  final Offset pan;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ContextMatrixStyle.background,
            Color(0xFF071A2B),
            Color(0xFF101025),
          ],
        ).createShader(rect),
    );

    _drawNebula(canvas, size);
    _drawRepeatingGrid(canvas, size);
    _drawStarField(canvas, size);
  }

  void _drawNebula(Canvas canvas, Size size) {
    final slowPan = pan * 0.025;
    final centerA =
        Offset(size.width * 0.28, size.height * 0.24) + slowPan * -1;
    final centerB =
        Offset(size.width * 0.78, size.height * 0.72) + slowPan * 0.7;

    for (final glow in [
      (
        center: centerA,
        radius: size.shortestSide * 0.64,
        color: ContextMatrixStyle.electricBlue,
        alpha: 0.18,
      ),
      (
        center: centerB,
        radius: size.shortestSide * 0.56,
        color: ContextMatrixStyle.violet,
        alpha: 0.13,
      ),
    ]) {
      canvas.drawCircle(
        glow.center,
        glow.radius,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  glow.color.withValues(alpha: glow.alpha),
                  glow.color.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: glow.center, radius: glow.radius),
              ),
      );
    }
  }

  void _drawRepeatingGrid(Canvas canvas, Size size) {
    const majorSpacing = 72.0;
    const minorSpacing = 24.0;
    final parallax = pan * (0.09 / scale.clamp(0.7, 2.4));

    _drawGridLayer(
      canvas,
      size,
      spacing: minorSpacing,
      offset: parallax * 0.55,
      color: Colors.white.withValues(alpha: 0.012),
      strokeWidth: 0.6,
    );
    _drawGridLayer(
      canvas,
      size,
      spacing: majorSpacing,
      offset: parallax,
      color: ContextMatrixStyle.cyan.withValues(alpha: 0.045),
      strokeWidth: 0.8,
    );
  }

  void _drawGridLayer(
    Canvas canvas,
    Size size, {
    required double spacing,
    required Offset offset,
    required Color color,
    required double strokeWidth,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;
    final startX = -_positiveModulo(offset.dx, spacing);
    final startY = -_positiveModulo(offset.dy, spacing);

    for (var x = startX; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = startY; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawStarField(Canvas canvas, Size size) {
    final starPaint = Paint();
    final driftX = _positiveModulo(pan.dx * 0.04, size.width + 160);
    final driftY = _positiveModulo(pan.dy * 0.04, size.height + 160);

    for (var index = 0; index < 120; index += 1) {
      final x = _positiveModulo(index * 97.0 + driftX, size.width + 160) - 80;
      final y = _positiveModulo(index * 53.0 + driftY, size.height + 160) - 80;
      final bright = index % 11 == 0;
      final radius = bright ? 1.35 : 0.75;
      final color = bright
          ? ContextMatrixStyle.electricBlue.withValues(alpha: 0.28)
          : ContextMatrixStyle.cyan.withValues(alpha: 0.13);

      starPaint.color = color;
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  double _positiveModulo(double value, double divisor) {
    return ((value % divisor) + divisor) % divisor;
  }

  @override
  bool shouldRepaint(covariant _InfiniteMatrixBackdropPainter oldDelegate) {
    return oldDelegate.pan != pan || oldDelegate.scale != scale;
  }
}

class _PositionedUniverseNode extends StatelessWidget {
  const _PositionedUniverseNode({
    required this.node,
    required this.progress,
    required this.onTap,
    required this.onLongPress,
  });

  final _UniverseVisualNode node;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final animatedCenter = Offset.lerp(node.anchor, node.center, progress)!;
    final nodeProgress = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));
    final scale = node.scale * (0.78 + nodeProgress * 0.22);

    return Positioned(
      left: animatedCenter.dx - node.size.width / 2,
      top: animatedCenter.dy - node.size.height / 2,
      width: node.size.width,
      height: node.size.height,
      child: Opacity(
        opacity: (node.opacity * progress).clamp(0.0, 1.0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(node.depth * 0.10)
            ..rotateY(node.depth * -0.08),
          child: Transform.scale(
            scale: scale,
            child: _UniverseNodeButton(
              node: node,
              onTap: onTap,
              onLongPress: onLongPress,
            ),
          ),
        ),
      ),
    );
  }
}

class _UniverseNodeButton extends StatelessWidget {
  const _UniverseNodeButton({
    required this.node,
    required this.onTap,
    required this.onLongPress,
  });

  final _UniverseVisualNode node;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isBubble =
        node.kind == _UniverseNodeKind.hub ||
        node.kind == _UniverseNodeKind.section;
    final glow = node.color.withValues(alpha: node.isFocused ? 0.42 : 0.24);
    final border = node.isMissing
        ? ContextMatrixStyle.warning.withValues(alpha: 0.72)
        : node.color.withValues(alpha: node.isFocused ? 0.88 : 0.54);

    return Semantics(
      button: true,
      label: node.semanticLabel,
      child: Tooltip(
        message: node.tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: node.key,
            customBorder: isBubble ? const CircleBorder() : null,
            borderRadius: isBubble ? null : BorderRadius.circular(999),
            onTap: onTap,
            onLongPress: onLongPress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isBubble ? 8 : 12,
                vertical: isBubble ? 7 : 8,
              ),
              decoration: BoxDecoration(
                shape: isBubble ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isBubble ? null : BorderRadius.circular(999),
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.42),
                  radius: 1.1,
                  colors: [
                    Colors.white.withValues(alpha: 0.28),
                    node.color.withValues(alpha: 0.88),
                    Color.lerp(node.color, Colors.black, 0.48)!,
                  ],
                ),
                border: Border.all(
                  color: border,
                  width: node.isFocused || node.isPinned ? 2.0 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glow,
                    blurRadius: node.isFocused ? 30 : 18,
                    spreadRadius: node.isFocused ? 3 : 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.46),
                    blurRadius: 18,
                    offset: Offset(0, 10 + node.depth * 8),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (node.icon != null) ...[
                      Icon(node.icon, color: Colors.white, size: node.iconSize),
                      SizedBox(
                        height: node.kind == _UniverseNodeKind.hub ? 5 : 3,
                      ),
                    ],
                    Text(
                      node.label,
                      textAlign: TextAlign.center,
                      maxLines: node.maxLabelLines,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    if (node.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        node.subtitle!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UniverseControls extends StatelessWidget {
  const _UniverseControls({
    required this.onReset,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onReset;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ContextMatrixStyle.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ContextMatrixStyle.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ControlButton(
            tooltip: 'Reset view',
            icon: Icons.center_focus_strong_outlined,
            onPressed: onReset,
          ),
          _ControlButton(
            tooltip: 'Zoom out',
            icon: Icons.remove,
            onPressed: onZoomOut,
          ),
          _ControlButton(
            tooltip: 'Zoom in',
            icon: Icons.add,
            onPressed: onZoomIn,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      color: ContextMatrixStyle.text,
    );
  }
}

class _UniverseLayout {
  const _UniverseLayout({
    required this.size,
    required this.center,
    required this.hub,
    required this.visualNodes,
    required this.edges,
  });

  final Size size;
  final Offset center;
  final _UniverseVisualNode hub;
  final List<_UniverseVisualNode> visualNodes;
  final List<_UniverseEdge> edges;

  _UniverseVisualNode? nodeForSection(ContextSection section) {
    for (final node in visualNodes) {
      if (node.kind == _UniverseNodeKind.section && node.section == section) {
        return node;
      }
    }
    return null;
  }

  static _UniverseLayout build({
    required Size size,
    required List<ContextSectionNodeData> nodes,
    required Set<ContextSection> expandedSections,
    required ContextSection? focusedSection,
  }) {
    final center = Offset(size.width / 2, size.height / 2);
    final visualNodes = <_UniverseVisualNode>[];
    final edges = <_UniverseEdge>[];
    final radiusX = math.min(size.width * 0.36, 330.0);
    final radiusY = math.min(size.height * 0.33, 300.0);
    final focusedIndex = focusedSection == null
        ? -1
        : nodes.indexWhere((node) => node.section == focusedSection);
    final focusedAngle = focusedIndex == -1
        ? null
        : _angleForIndex(focusedIndex, nodes.length);

    final hub = _UniverseVisualNode(
      key: const ValueKey('context-hub-node'),
      kind: _UniverseNodeKind.hub,
      center: center,
      anchor: center,
      size: const Size.square(126),
      label: 'Core',
      subtitle: 'You',
      color: ContextMatrixStyle.electricBlue,
      icon: Icons.person_outline,
      iconSize: 28,
      tooltip: 'Context Core',
      semanticLabel: 'Context Core user profile node',
      scale: focusedSection == null ? 1.08 : 0.98,
      opacity: 1,
      depth: 0.55,
      isFocused: focusedSection == null,
    );
    visualNodes.add(hub);

    for (var index = 0; index < nodes.length; index += 1) {
      final data = nodes[index];
      final angle = _angleForIndex(index, nodes.length);
      final sectionColor = ContextMatrixStyle.sectionColor(data.section);
      final isFocused = data.section == focusedSection;
      final isExpanded = expandedSections.contains(data.section);
      final angularDistance = focusedAngle == null
          ? 0.0
          : _angularDistance(angle, focusedAngle);
      final nearFocus = focusedAngle == null
          ? 1.0
          : (1 - angularDistance / math.pi).clamp(0.0, 1.0);
      final radialShift = focusedAngle == null
          ? 0.0
          : isFocused
          ? 34.0
          : -18.0 + nearFocus * 24.0;
      final depth = 0.5 + 0.5 * math.sin(angle);
      final sectionCenter = Offset(
        center.dx + math.cos(angle) * (radiusX + radialShift),
        center.dy + math.sin(angle) * (radiusY + radialShift),
      );
      final sectionSize = isFocused
          ? const Size.square(112)
          : Size.square(82 + depth * 12);
      final sectionOpacity = focusedAngle == null
          ? 0.96
          : isFocused
          ? 1.0
          : (0.52 + nearFocus * 0.34);
      final sectionScale = isFocused
          ? 1.12
          : 0.88 + depth * 0.08 + nearFocus * 0.08;

      visualNodes.add(
        _UniverseVisualNode(
          key: ValueKey('context-section-${data.section.storageValue}'),
          kind: _UniverseNodeKind.section,
          section: data.section,
          center: sectionCenter,
          anchor: center,
          size: sectionSize,
          label: ContextMatrixStyle.shortSectionLabel(data.section),
          color: sectionColor,
          icon: ContextMatrixStyle.sectionIcon(data.section),
          iconSize: isFocused ? 25 : 21,
          tooltip: '${data.section.label} details',
          semanticLabel: '${data.section.label} matrix node',
          scale: sectionScale,
          opacity: sectionOpacity,
          depth: depth,
          isFocused: isFocused,
        ),
      );

      edges.add(
        _UniverseEdge(
          from: center,
          to: sectionCenter,
          control: _controlPoint(center, sectionCenter, curve: 28),
          width: isFocused ? 2.0 : 1.0 + depth * 0.5,
          color: sectionColor,
          alpha: isFocused ? 0.92 : sectionOpacity * 0.48,
        ),
      );

      if (isExpanded) {
        _addChildren(
          data: data,
          sectionCenter: sectionCenter,
          center: center,
          sectionColor: sectionColor,
          sectionDepth: depth,
          isFocused: isFocused,
          visualNodes: visualNodes,
          edges: edges,
        );
      }
    }

    visualNodes.sort((a, b) => a.depth.compareTo(b.depth));

    return _UniverseLayout(
      size: size,
      center: center,
      hub: hub,
      visualNodes: visualNodes,
      edges: edges,
    );
  }

  static void _addChildren({
    required ContextSectionNodeData data,
    required Offset sectionCenter,
    required Offset center,
    required Color sectionColor,
    required double sectionDepth,
    required bool isFocused,
    required List<_UniverseVisualNode> visualNodes,
    required List<_UniverseEdge> edges,
  }) {
    final limit = isFocused ? 6 : 3;
    final childItems = <_UniverseChildItem>[
      for (final entry in data.entries.take(limit))
        _UniverseChildItem.entry(entry),
      for (final title in data.missingTitles.take(
        math.max(2, limit - data.entries.length),
      ))
        _UniverseChildItem.missing(title),
    ].take(limit).toList();

    if (childItems.isEmpty) {
      return;
    }

    final outwardAngle = math.atan2(
      sectionCenter.dy - center.dy,
      sectionCenter.dx - center.dx,
    );
    final spread = childItems.length == 1 ? 0.0 : math.pi / 2.25;
    final childRadius = isFocused ? 108.0 : 82.0;

    for (var index = 0; index < childItems.length; index += 1) {
      final offsetFactor = childItems.length == 1
          ? 0.0
          : index / (childItems.length - 1) - 0.5;
      final childAngle = outwardAngle + offsetFactor * spread;
      final centerOffset = Offset(
        sectionCenter.dx + math.cos(childAngle) * childRadius,
        sectionCenter.dy + math.sin(childAngle) * childRadius,
      );
      final item = childItems[index];
      final isEntry = item.entry != null;
      final color = isEntry
          ? ContextMatrixStyle.sourceColor(item.entry!.source)
          : ContextMatrixStyle.warning;
      final size = isEntry
          ? Size(isFocused ? 122 : 108, isFocused ? 48 : 42)
          : Size(isFocused ? 116 : 96, isFocused ? 42 : 38);
      final depth = (sectionDepth + 0.16 + index * 0.012).clamp(0.0, 1.0);
      final opacity = isFocused ? 0.96 : 0.62;

      edges.add(
        _UniverseEdge(
          from: sectionCenter,
          to: centerOffset,
          control: _controlPoint(sectionCenter, centerOffset, curve: 18),
          width: isFocused ? 1.3 : 0.8,
          color: color,
          alpha: isFocused ? 0.72 : 0.28,
        ),
      );

      if (isEntry) {
        final entry = item.entry!;
        visualNodes.add(
          _UniverseVisualNode(
            key: ValueKey('context-entry-node-${entry.id}'),
            kind: _UniverseNodeKind.entry,
            section: data.section,
            entry: entry,
            center: centerOffset,
            anchor: sectionCenter,
            size: size,
            label: entry.title,
            color: color,
            tooltip: '${entry.title}: edit context',
            semanticLabel: '${entry.title} context entry',
            scale: isFocused ? 1.0 : 0.84,
            opacity: opacity,
            depth: depth,
            isPinned: entry.isPinned,
          ),
        );
      } else {
        final missingTitle = item.missingTitle!;
        visualNodes.add(
          _UniverseVisualNode(
            key: ValueKey(
              'context-missing-node-${data.section.storageValue}-$missingTitle',
            ),
            kind: _UniverseNodeKind.missing,
            section: data.section,
            missingTitle: missingTitle,
            center: centerOffset,
            anchor: sectionCenter,
            size: size,
            label: missingTitle,
            color: color,
            tooltip: '$missingTitle: add context',
            semanticLabel: '$missingTitle missing context field',
            scale: isFocused ? 0.98 : 0.8,
            opacity: opacity,
            depth: depth,
          ),
        );
      }
    }
  }

  static double _angleForIndex(int index, int total) {
    return -math.pi / 2 + (index / total) * math.pi * 2;
  }

  static double _angularDistance(double a, double b) {
    return math.acos(math.cos(a - b)).abs();
  }

  static Offset _controlPoint(Offset from, Offset to, {required double curve}) {
    final midpoint = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    final vector = to - from;
    final length = vector.distance;
    if (length == 0) {
      return midpoint;
    }
    final normal = Offset(-vector.dy / length, vector.dx / length);
    return midpoint + normal * curve;
  }
}

class _UniverseVisualNode {
  const _UniverseVisualNode({
    required this.key,
    required this.kind,
    required this.center,
    required this.anchor,
    required this.size,
    required this.label,
    required this.color,
    required this.tooltip,
    required this.semanticLabel,
    required this.scale,
    required this.opacity,
    required this.depth,
    this.subtitle,
    this.icon,
    this.iconSize = 20,
    this.section,
    this.entry,
    this.missingTitle,
    this.isFocused = false,
    this.isPinned = false,
  });

  final Key key;
  final _UniverseNodeKind kind;
  final Offset center;
  final Offset anchor;
  final Size size;
  final String label;
  final String? subtitle;
  final Color color;
  final IconData? icon;
  final double iconSize;
  final String tooltip;
  final String semanticLabel;
  final double scale;
  final double opacity;
  final double depth;
  final ContextSection? section;
  final ContextEntry? entry;
  final String? missingTitle;
  final bool isFocused;
  final bool isPinned;

  bool get isMissing => kind == _UniverseNodeKind.missing;

  int get maxLabelLines {
    return switch (kind) {
      _UniverseNodeKind.hub => 1,
      _UniverseNodeKind.section => 2,
      _UniverseNodeKind.entry => 1,
      _UniverseNodeKind.missing => 1,
    };
  }
}

class _UniverseEdge {
  const _UniverseEdge({
    required this.from,
    required this.to,
    required this.control,
    required this.width,
    required this.color,
    required this.alpha,
  });

  final Offset from;
  final Offset to;
  final Offset control;
  final double width;
  final Color color;
  final double alpha;
}

class _UniverseChildItem {
  const _UniverseChildItem.entry(this.entry) : missingTitle = null;
  const _UniverseChildItem.missing(this.missingTitle) : entry = null;

  final ContextEntry? entry;
  final String? missingTitle;
}

enum _UniverseNodeKind { hub, section, entry, missing }
