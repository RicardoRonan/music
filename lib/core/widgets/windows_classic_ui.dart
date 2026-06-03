import 'package:flutter/material.dart';

import '../../theme/windows_classic_theme_extension.dart';

/// Raised Win95-style border (2px outset).
class WindowsClassicOutsetBorder extends StatelessWidget {
  const WindowsClassicOutsetBorder({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(2),
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.winColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? c.chrome,
        border: c.outsetBorder,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Sunken Win95-style border (2px inset).
class WindowsClassicInsetBorder extends StatelessWidget {
  const WindowsClassicInsetBorder({
    super.key,
    required this.child,
    this.color,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.winColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? c.panel,
        border: c.insetBorder,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Tab strip matching the code-snippet card header.
class WindowsClassicTabRow extends StatelessWidget {
  const WindowsClassicTabRow({
    super.key,
    required this.tabs,
    this.activeIndex = 0,
    this.onTabSelected,
  });

  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.winColors;
    return Container(
      height: 20,
      color: c.chrome,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < tabs.length; i++)
            _Tab(
              label: tabs[i],
              active: i == activeIndex,
              colors: c,
              onTap: onTabSelected != null ? () => onTabSelected!(i) : null,
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.colors,
    this.onTap,
  });

  final String label;
  final bool active;
  final WindowsClassicColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tab = Container(
      height: active ? 19 : 18,
      margin: EdgeInsets.only(top: active ? 0 : 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.chrome,
        border: Border(
          top: BorderSide(color: colors.highlight, width: 2),
          left: BorderSide(color: colors.highlight, width: 2),
          right: BorderSide(color: colors.shadow, width: 2),
          bottom: BorderSide(
            color: active ? colors.chrome : colors.shadow,
            width: active ? 1 : 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: active ? colors.accent : colors.onSurface,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'Tahoma',
        ),
      ),
    );

    if (onTap == null) return tab;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: tab);
  }
}

/// Win95-style collapsible section (replaces Material [ExpansionTile]).
class WindowsClassicCollapsibleSection extends StatefulWidget {
  const WindowsClassicCollapsibleSection({
    super.key,
    required this.title,
    required this.children,
    this.count,
    this.initiallyExpanded = false,
  });

  final String title;
  final int? count;
  final bool initiallyExpanded;
  final List<Widget> children;

  @override
  State<WindowsClassicCollapsibleSection> createState() =>
      _WindowsClassicCollapsibleSectionState();
}

class _WindowsClassicCollapsibleSectionState
    extends State<WindowsClassicCollapsibleSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final c = context.winColors;
    final label = widget.count != null
        ? '${widget.title} · ${widget.count}'
        : widget.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: c.chrome,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tahoma',
                      color: c.onSurface,
                    ),
                  ),
                ),
                WindowsClassicButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  child: Text(_expanded ? '−' : '+', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          WindowsClassicInsetBorder(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.children,
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }
}

/// Single-row list item for classic inset panels.
class WindowsClassicListRow extends StatelessWidget {
  const WindowsClassicListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.winColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: c.onSurface),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tahoma',
                      color: c.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'Tahoma',
                        color: c.onSurface,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 14, color: c.onSurface),
          ],
        ),
      ),
    );
  }
}

/// Inset list panel under library category/folder tabs.
class WindowsClassicListPanel extends StatelessWidget {
  const WindowsClassicListPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WindowsClassicInsetBorder(
      padding: const EdgeInsets.all(2),
      child: child,
    );
  }
}

/// Grey toolbar button with outset / inset press states.
class WindowsClassicButton extends StatefulWidget {
  const WindowsClassicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsets padding;

  @override
  State<WindowsClassicButton> createState() => _WindowsClassicButtonState();
}

class _WindowsClassicButtonState extends State<WindowsClassicButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.winColors;
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 0),
        padding: _pressed
            ? widget.padding + const EdgeInsets.only(left: 1, top: 1)
            : widget.padding,
        decoration: BoxDecoration(
          color: c.chrome,
          border: _pressed
              ? Border(
                  top: BorderSide(color: c.shadow, width: 2),
                  left: BorderSide(color: c.shadow, width: 2),
                  bottom: BorderSide(color: c.highlight, width: 2),
                  right: BorderSide(color: c.highlight, width: 2),
                )
              : c.outsetBorder,
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 11,
            color: enabled ? c.onSurface : c.disabled,
            fontFamily: 'Tahoma',
          ),
          child: IconTheme.merge(
            data: IconThemeData(
              size: 16,
              color: enabled ? c.onSurface : c.disabled,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
