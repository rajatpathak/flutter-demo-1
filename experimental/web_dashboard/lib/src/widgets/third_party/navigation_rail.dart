// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Original pull request: https://github.com/flutter/flutter/pull/49574
import 'package:flutter/material.dart';

/// Defines the behavior of the labels of a [NavigationRail].
///
/// See also:
///
///   * [NavigationRail]
enum NavigationRailLabelType {
  /// Only the icons of a navigation rail item are shown.
  none,

  /// Only the selected navigation rail item will show its label.
  ///
  /// The label will animate in and out as new items are selected.
  selected,

  /// All navigation rail items will show their label.
  all,
}

/// Defines the alignment for the group of [NavigationRailDestination]s within
/// a [NavigationRail].
///
/// Navigation rail destinations can be aligned as a group to the [top],
/// [bottom], or [center] of a layout.
enum NavigationRailGroupAlignment {
  /// Place the [NavigationRailDestination]s at the top of the rail.
  top,

  /// Place the [NavigationRailDestination]s in the center of the rail.
  center,

  /// Place the [NavigationRailDestination]s at the bottom of the rail.
  bottom,
}

/// A description for an interactive button within a [NavigationRail].
///
/// See also:
///
///  * [NavigationRail]
class NavigationRailDestination {
  /// Creates an destination that is used with [NavigationRail.destinations].
  ///
  /// [icon] should not be null and [title] should not be null when this
  /// destination is used in the [NavigationRail].
  const NavigationRailDestination({
    @required this.icon,
    Widget activeIcon,
    this.title,
  })  : activeIcon = activeIcon ?? icon,
        assert(icon != null);

  /// The icon of the destination.
  ///
  /// Typically the icon is an [Icon] or an [ImageIcon] widget. If another type
  /// of widget is provided then it should configure itself to match the current
  /// [IconTheme] size and color.
  ///
  /// If [activeIcon] is provided, this will only be displayed when the
  /// destination is not selected.
  ///
  /// To make the [NavigationRail] more accessible, consider choosing an
  /// icon with a stroked and filled version, such as [Icons.cloud] and
  /// [Icons.cloud_queue]. [icon] should be set to the stroked version and
  /// [activeIcon] to the filled version.
  final Widget icon;

  /// An alternative icon displayed when this destination is selected.
  ///
  /// If this icon is not provided, the [NavigationRail] will display [icon] in
  /// either state.
  ///
  /// See also:
  ///
  ///  * [NavigationRailDestination.icon], for a description of how to pair
  ///    icons.
  final Widget activeIcon;

  /// The title of the item. If the title is not provided only the icon will be
  /// shown when not used in a [NavigationRail].
  final Widget title;
}

/// TODO
class NavigationRail extends StatefulWidget {
  /// TODO
  NavigationRail({
    this.leading,
    this.destinations,
    this.currentIndex,
    this.onDestinationSelected,
    this.groupAlignment = NavigationRailGroupAlignment.top,
    this.labelType = NavigationRailLabelType.none,
    this.labelTextStyle,
    this.selectedLabelTextStyle,
    this.iconTheme,
    this.selectedIconTheme,
  });

  /// The leading widget in the rail that is placed above the items.
  ///
  /// This is commonly a [FloatingActionButton], but may also be a non-button,
  /// such as a logo.
  final Widget leading;

  /// Defines the appearance of the button items that are arrayed within the
  /// navigation rail.
  final List<NavigationRailDestination> destinations;

  /// The index into [destinations] for the current active [NavigationRailDestination].
  final int currentIndex;

  /// Called when one of the [destinations] is selected.
  ///
  /// The stateful widget that creates the navigation rail needs to keep
  /// track of the index of the selected [NavigationRailDestination] and call
  /// `setState` to rebuild the navigation rail with the new [currentIndex].
  final ValueChanged<int> onDestinationSelected;

  /// The alignment for the [NavigationRailDestination]s as they are positioned
  /// within the [NavigationRail].
  ///
  /// Navigation rail destinations can be aligned as a group to the [top],
  /// [bottom], or [center] of a layout.
  final NavigationRailGroupAlignment groupAlignment;

  /// Defines the layout and behavior of the labels in the [NavigationRail].
  ///
  /// See also:
  ///
  ///   * [NavigationRailLabelType] for information on the meaning of different
  ///   types.
  final NavigationRailLabelType labelType;

  /// The [TextStyle] of the [NavigationRailDestination] labels.
  ///
  /// This is the default [TextStyle] for all labels. When the
  /// [NavigationRailDestination] is selected, the [selectedLabelTextStyle] will be
  /// used instead.
  final TextStyle labelTextStyle;

  /// The [TextStyle] of the [NavigationRailDestination] labels when they are
  /// selected.
  ///
  /// This field overrides the [labelTextStyle] for selected items.
  ///
  /// When the [NavigationRailDestination] is not selected, [labelTextStyle] will be
  /// used.
  final TextStyle selectedLabelTextStyle;

  /// The default size, opacity, and color of the icon in the
  /// [NavigationRailDestination].
  ///
  /// If this field is not provided, or provided with any null properties, then
  ///a copy of the [IconThemeData.fallback] with a custom [NavigationRail]
  /// specific color will be used.
  final IconTheme iconTheme;

  /// The size, opacity, and color of the icon in the selected
  /// [NavigationRailDestination].
  ///
  /// This field overrides the [iconTheme] for selected items.
  ///
  /// When the [NavigationRailDestination] is not selected, [iconTheme] will be
  /// used.
  final IconTheme selectedIconTheme;

  @override
  _NavigationRailState createState() => _NavigationRailState();
}

class _NavigationRailState extends State<NavigationRail>
    with TickerProviderStateMixin {
  List<AnimationController> _controllers = <AnimationController>[];
  List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  void didUpdateWidget(NavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);

    // No animated segue if the length of the items list changes.
    if (widget.destinations.length != oldWidget.destinations.length) {
      _resetState();
      return;
    }

    if (widget.currentIndex != oldWidget.currentIndex) {
      _controllers[oldWidget.currentIndex].reverse();
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget leading = widget.leading;
    return DefaultTextStyle(
      style: TextStyle(color: Theme.of(context).colorScheme.primary),
      child: Container(
        width: _railWidth,
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _verticalSpacing,
            if (leading != null) ...<Widget>[
              SizedBox(
                height: _railItemHeight,
                width: _railItemWidth,
                child: Align(
                  alignment: Alignment.center,
                  child: leading,
                ),
              ),
              _verticalSpacing,
            ],
            for (int i = 0; i < widget.destinations.length; i++)
              _RailItem(
                animation: _animations[i],
                labelKind: widget.labelType,
                selected: widget.currentIndex == i,
                icon: widget.currentIndex == i
                    ? widget.destinations[i].activeIcon
                    : widget.destinations[i].icon,
                title: DefaultTextStyle(
                  style: TextStyle(
                      color: widget.currentIndex == i
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.64)),
                  child: widget.destinations[i].title,
                ),
                onTap: () {
                  widget.onDestinationSelected(i);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _disposeControllers() {
    for (final AnimationController controller in _controllers)
      controller.dispose();
  }

  void _initControllers() {
    _controllers = List<AnimationController>.generate(
        widget.destinations.length, (int index) {
      return AnimationController(
        duration: kThemeAnimationDuration,
        vsync: this,
      )..addListener(_rebuild);
    });
    _animations = _controllers
        .map((AnimationController controller) => controller.view)
        .toList();
    _controllers[widget.currentIndex].value = 1.0;
  }

  void _resetState() {
    _disposeControllers();
    _initControllers();
  }

  void _rebuild() {
    setState(() {
      // Rebuilding when any of the controllers tick, i.e. when the items are
      // animated.
    });
  }
}

class _RailItem extends StatelessWidget {
  _RailItem({
    this.animation,
    this.labelKind,
    this.selected,
    this.icon,
    this.title,
    this.onTap,
  })  : assert(labelKind != null),
        _positionAnimation = CurvedAnimation(
          parent: ReverseAnimation(animation),
          curve: Curves.easeInOut,
          reverseCurve: Curves.easeInOut.flipped,
        );

  final Animation<double> _positionAnimation;

  final Animation<double> animation;
  final NavigationRailLabelType labelKind;
  final bool selected;
  final Widget icon;
  final Widget title;
  final VoidCallback onTap;

  double _fadeInValue() {
    if (animation.value < 0.25) {
      return 0;
    } else if (animation.value < 0.75) {
      return (animation.value - 0.25) * 2;
    } else {
      return 1;
    }
  }

  double _fadeOutValue() {
    if (animation.value > 0.75) {
      return (animation.value - 0.75) * 4;
    } else {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (labelKind) {
      case NavigationRailLabelType.none:
        content = SizedBox(width: _railItemWidth, child: icon);
        break;
      case NavigationRailLabelType.selected:
        content = SizedBox(
          width: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: _positionAnimation.value * 18),
              icon,
              Opacity(
                alwaysIncludeSemantics: true,
                opacity: selected ? _fadeInValue() : _fadeOutValue(),
                child: title,
              ),
            ],
          ),
        );
        break;
      case NavigationRailLabelType.all:
        content = SizedBox(
          width: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              icon,
              title,
            ],
          ),
        );
        break;
    }

    final ColorScheme colors = Theme.of(context).colorScheme;
    return IconTheme(
      data: IconThemeData(
        color: selected ? colors.primary : colors.onSurface.withOpacity(0.64),
      ),
      child: SizedBox(
        height: 72,
        child: Material(
          type: MaterialType.transparency,
          clipBehavior: Clip.none,
          child: InkResponse(
            onTap: onTap,
            onHover: (_) {},
            splashColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.12),
            hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.04),
            child: content,
          ),
        ),
      ),
    );
  }
}

const double _railWidth = 72;
const double _railItemWidth = _railWidth;
const double _railItemHeight = _railItemWidth;
const double _spacing = 8;
const Widget _verticalSpacing = SizedBox(height: _spacing);
