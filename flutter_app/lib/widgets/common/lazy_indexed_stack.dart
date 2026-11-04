import 'package:flutter/material.dart';

/// Like [IndexedStack], but a child is only built the first time its tab is
/// shown. After that it stays alive, so scroll position and state are kept
/// when the user switches tabs. Tabs listed in [eager] are built up front.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Set<int> eager;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.eager = const {},
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late List<bool> _built;

  @override
  void initState() {
    super.initState();
    _built = List<bool>.generate(
      widget.children.length,
      (i) => i == widget.index || widget.eager.contains(i),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_built.length != widget.children.length) {
      final old = _built;
      _built = List<bool>.generate(
        widget.children.length,
        (i) => i < old.length ? old[i] : false,
      );
    }
    _built[widget.index] = true;

    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _built[i] ? widget.children[i] : const SizedBox.shrink(),
      ],
    );
  }
}
