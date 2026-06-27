// lib/widgets/left_sidebar.dart
import 'package:flutter/material.dart';

class LeftSidebar extends StatefulWidget {
  final bool open;
  final void Function(bool) onToggle;
  final int selectedIndex;
  final void Function(int) onSelect;

  const LeftSidebar({required this.open, required this.onToggle, required this.selectedIndex, required this.onSelect, super.key});

  @override
  State<LeftSidebar> createState() => _LeftSidebarState();
}

class _LeftSidebarState extends State<LeftSidebar> with SingleTickerProviderStateMixin {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.open;
  }

  @override
  void didUpdateWidget(covariant LeftSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open != widget.open) _open = widget.open;
  }

  void _handleDrag(DragUpdateDetails details) {
    if (details.delta.dx > 8) {
      widget.onToggle(true);
    } else if (details.delta.dx < -8) {
      widget.onToggle(false);
    }
  }

  Widget _iconButton(IconData icon, String label, int idx) {
    final bool sel = widget.selectedIndex == idx;
    return InkWell(
      onTap: () => widget.onSelect(idx),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: sel ? Colors.orangeAccent.withOpacity(0.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: sel ? Colors.orangeAccent : Colors.white70),
            if (widget.open) ...[
              const SizedBox(width: 12),
              Flexible(child: Text(label, style: TextStyle(color: sel ? Colors.white : Colors.white70))),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.open ? 220.0 : 64.0;
    return GestureDetector(
      onHorizontalDragUpdate: _handleDrag,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          border: Border(right: BorderSide(color: Colors.white.withOpacity(0.04))),
        ),
        child: Column(
          children: [
            _iconButton(Icons.dashboard, 'Analytics', 0),
            _iconButton(Icons.person_add, 'Register', 1),
            _iconButton(Icons.list_alt, 'Teachers', 2),
            _iconButton(Icons.sensors, 'Live Status', 3),
            const Spacer(),
            if (widget.open)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Logout', style: TextStyle(color: Colors.white70)),
                  )
                ],
              )
            else
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              ),
          ],
        ),
      ),
    );
  }
}
