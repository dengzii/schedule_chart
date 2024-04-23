import 'dart:math';

import 'package:flutter/material.dart';

void logd(String tag, String log) {
  print("[$tag] $log");
}

class ScheduleChart extends StatefulWidget {
  const ScheduleChart({super.key});

  @override
  State<ScheduleChart> createState() => _ScheduleChartState();
}

class _ScheduleChartState extends State<ScheduleChart> {
  final ScrollController scrollControllerY = ScrollController();
  final ScrollController scrollControllerX = ScrollController();

  Offset topLeft = Offset.zero;
  Size size = Size.zero;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      setState(() {
        topLeft = renderBox.localToGlobal(Offset.zero) + const Offset(30, 0);
        size = renderBox.size;
        logd("Chart", "topLeft: $topLeft, size: $size");
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollControllerY,
      child: Column(
        children: [
          SingleChildScrollView(
            controller: scrollControllerX,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [body(context)],
            ),
          ),
        ],
      ),
    );
  }

  Widget body(BuildContext context) {
    return SizedBox(
      height: 2000,
      width: 800,
      child: Row(
        children: [scaleY(), Expanded(child: chart())],
      ),
    );
  }

  Widget scaleY() {
    return Container(
        color: Colors.cyan,
        height: 2000,
        width: 30,
        child: Column(
          children: [
            for (var i = 0; i < 20; i++)
              SizedBox(
                height: 2000 / 20,
                width: 30,
                child: Text(
                  i.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
          ],
        ));
  }

  Widget chart() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _background(),
        Positioned(
          top: 0,
          left: 0,
          child: SizedBox(
            width: 800,
            height: 2000,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 6; i++)
                  Expanded(
                    child: ChartColumn(
                      index: i,
                      onDrag: (details) {
                        _checkDrag2Boundary(details.globalPosition);
                      },
                      topLeft: topLeft,
                      scrollControllerY: scrollControllerY,
                      scrollControllerX: scrollControllerX,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _background() {
    return Container(
      color: Colors.grey.withAlpha(30),
      height: 2000,
      width: double.infinity,
      child: Column(
        children: [
          for (var i = 0; i < 20; i++)
            const SizedBox(
              height: 2000 / 20,
              width: double.infinity,
              child: Divider(),
            ),
        ],
      ),
    );
  }

  _checkDrag2Boundary(Offset offset) {
    const boundary = 100;
    final top = topLeft.dy + boundary;
    final bottom = size.height + topLeft.dy - boundary;
    final left = topLeft.dx + boundary;
    final right = size.width + topLeft.dx - boundary;

    double tY = scrollControllerY.offset;
    if (offset.dy > bottom) {
      if (scrollControllerY.offset >=
          scrollControllerY.position.maxScrollExtent) {
        return;
      }
      tY = scrollControllerY.offset + 3;
    } else if (offset.dy < top) {
      if (scrollControllerY.offset <= 0) return;
      tY = scrollControllerY.offset - 3;
    }
    scrollControllerY.jumpTo(tY);

    if (offset.dx > right) {
      if (scrollControllerX.offset >=
          scrollControllerX.position.maxScrollExtent) {
        return;
      }
      scrollControllerX.jumpTo(scrollControllerX.offset + 3);
    } else if (offset.dx < left) {
      if (scrollControllerX.offset <= 0) {
        return;
      }
      scrollControllerX.jumpTo(scrollControllerX.offset - 3);
    }
  }
}

class Pair<F, S> {
  final F first;
  final S second;

  Pair(this.first, this.second);
}

class Range {
  final double start;
  final double end;

  Range({required this.start, required this.end});

  bool isOverlap(Range other) {
    final a = contains(other.end) || contains(other.start);
    final b = other.contains(start) || other.contains(end);
    return a || b;
  }

  bool contains(double s) {
    return start < s && s < end;
  }

  Range operator +(Range other) {
    return Range(start: min(start, other.start), end: max(end, other.end));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Range && other.start == start && other.end == end;
  }

  @override
  String toString() {
    return 'Range{start: $start, end: $end}';
  }
}

class CardInfo {
  int column;
  Range range;

  CardGroup? group;
  int hoverColumn = -1;
  double hoverY = -1;
  bool hoverGroup = false;
  Color color = randomColor();
  String id = randomId();

  CardInfo({
    required this.column,
    required this.range,
    this.group,
  });

  static String randomId() {
    return Random.secure().nextInt(100000).toString();
  }

  static Color randomColor() {
    final c = Random.secure().nextInt(0xFFFFFF) + 0xFF000000;
    return Color(c.toInt());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardInfo && other.column == column && other.range == range;
  }

  @override
  int get hashCode {
    return column.hashCode ^ range.hashCode;
  }

  bool isOverlap(CardInfo other) {
    return range.start <= other.range.end && range.end >= other.range.start;
  }

  double height() {
    return range.end - range.start;
  }

  @override
  String toString() {
    return 'CardInfo{column: $column, range: $range, hoverColumn: $hoverColumn, hoverY: $hoverY, hoverGroup: $hoverGroup}';
  }

  CardInfo copyWith({
    int? column,
    Range? range,
    CardGroup? group,
  }) {
    return CardInfo(
      column: column ?? this.column,
      range: range ?? this.range,
      group: group ?? this.group,
    )
      ..id = id
      ..color = color;
  }
}

class CardGroup {
  final List<CardInfo> cards = [];

  final ColumnState column;

  Range range = Range(start: double.infinity, end: 0);

  CardGroup(this.column);

  void insert(CardInfo card) {
    cards.add(card);
    cards.sort((a, b) => (a.range.start - b.range.start).toInt());
    card.group = this;
    range = range + card.range;
  }

  List<CardInfo> removeIsolated() {
    List<CardInfo> isolated = [];
    for (var card in cards) {
      if (!cards.any((c) => c != card && c.isOverlap(card))) {
        isolated.add(card);
      }
    }
    cards.removeWhere((c) => isolated.contains(c));
    for (var c in isolated) {
      c.group = null;
    }
    _updateRange();
    return isolated;
  }

  bool isOverlap(CardInfo card) {
    return range.isOverlap(card.range);
  }

  bool isOverlapGroup(CardGroup group) {
    return range.isOverlap(group.range);
  }

  void update(CardInfo old, CardInfo new_) {
    final index = cards.indexWhere((element) => element == old);
    if (index != -1) {
      cards[index] = new_;
      _updateRange();
    }
  }

  void _updateRange() {
    final start = cards.isEmpty
        ? double.infinity
        : cards.map((e) => e.range.start).reduce(min);
    final end = cards.isEmpty
        ? 0.000000000000
        : cards.map((e) => e.range.end).reduce(max);
    range = Range(start: start, end: end);
  }
}

class ColumnState extends ChangeNotifier {
  final int index;
  final List<CardGroup> groups;
  late State<dynamic> state;

  static const tag = "ColumnState";

  ColumnState({required this.index, required this.groups});

  void add(CardInfo card) {
    card.group?.column.remove(card);
    CardGroup? group;
    for (var i in groups) {
      if (i.isOverlap(card)) {
        group = i;
        break;
      }
    }
    if (group == null) {
      group = CardGroup(this);
      groups.add(group);
    }
    group.insert(card);

    _checkOverlaps();
    notifyListeners();
    logd(tag, "add: $index, ${card.id}");
  }

  void updated(CardInfo card) {
    final group = card.group;
    if (group != null) _checkIsolate(group);
  }

  void remove(CardInfo card) {
    final group = card.group;
    if (group != null) {
      logd(tag, "remove: $index, ${card.id}");
      card.group = null;
      group.cards.remove(card);
      _checkIsolate(group);
      notifyListeners();
    } else {
      logd(tag, "remove: group not found, ${card.id}");
    }
  }

  void _checkOverlaps() {
    Pair<CardGroup, CardGroup>? overlap = _findOverlap();
    while (overlap != null) {
      final target = overlap.first.cards.length > overlap.second.cards.length
          ? overlap.second
          : overlap.first;
      groups.remove(target);
      for (var card in target.cards) {
        card.group = null;
        add(card);
      }
      overlap = _findOverlap();
    }
  }

  Pair<CardGroup, CardGroup>? _findOverlap() {
    for (var group in groups) {
      CardGroup? overlap;
      for (var i in groups) {
        if (i.isOverlapGroup(group)) {
          overlap = i;
          break;
        }
      }
      if (overlap != null) {
        return Pair(group, overlap);
      }
    }
    return null;
  }

  void _checkIsolate(CardGroup group) {
    final isolated = group.removeIsolated();
    for (var c in isolated) {
      add(c);
    }
    if (group.cards.isEmpty) {
      groups.remove(group);
    }
  }
}

class ChartColumn extends StatefulWidget {
  final Offset topLeft;
  final ScrollController scrollControllerY;
  final ScrollController scrollControllerX;
  final DragUpdateCallback onDrag;
  final int index;

  const ChartColumn({
    super.key,
    required this.index,
    required this.onDrag,
    required this.topLeft,
    required this.scrollControllerY,
    required this.scrollControllerX,
  });

  @override
  State<ChartColumn> createState() => _ChartColumnState();
}

class _ChartColumnState extends State<ChartColumn> {
  double width = 130;

  ColumnState state = ColumnState(index: 0, groups: []);

  double offsetY() => widget.scrollControllerY.offset;

  double offsetX() => widget.scrollControllerX.offset;

  @override
  void initState() {
    super.initState();
    state.addListener(() {
      setState(() {
        logd("column-${widget.index}", "updated");
      });
    });
    state.add(rndCard());
    state.add(rndCard());
    state.add(rndCard());
  }

  CardInfo rndCard() {
    final h = Random.secure().nextInt(400);
    final y = Random.secure().nextInt(1000 - h).toDouble();
    return CardInfo(column: widget.index, range: Range(start: y, end: y + h));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.red.withAlpha(30),
        width: width,
        child: DragTarget<CardInfo>(
          onAccept: (d) {
            if (d.column == widget.index) return;
            d.group?.column.remove(d);

            final insert = d.copyWith(
              column: widget.index,
              range: Range(start: d.hoverY, end: d.hoverY + d.height()),
            );
            state.add(insert);
          },
          onMove: (d) {
            d.data.hoverColumn = widget.index;
            d.data.hoverY = getY(d.offset.dy);
          },
          onLeave: (d) {
            // logd("onLeave", "column-${widget.index} $d");
          },
          onWillAcceptWithDetails: (details) {
            // logd("onWillAcceptWithDetails",
            //     "column-${widget.index} -> ${details.data}");
            return true;
          },
          builder: (context, list, obj) {
            return content(context);
          },
        ));
  }

  Widget content(BuildContext context) {
    return Stack(
      children: [
        for (var group in state.groups)
          Positioned(
            top: group.range.start,
            height: group.range.end - group.range.start,
            width: width,
            child: Container(
              color: Colors.green.withAlpha(40),
              width: width,
              height: group.range.end - group.range.start,
              child: Row(
                children: [
                  for (var c in group.cards)
                    Expanded(
                      child: Stack(
                        children: [card(group, c, true)],
                      ),
                    )
                ],
              ),
            ),
          ),
      ],
    );
  }

  void onDropHit(CardInfo from, CardInfo to) {
    logd("onWillGroup", "column-${widget.index} -> $from");

    setState(() {
      //
    });
  }

  void onDragEnd(CardGroup group, CardInfo card, DraggableDetails details) {
    if (card.hoverColumn != widget.index || card.hoverGroup) {
      card.group?.column.remove(card);
    } else {
      final y = getY(details.offset.dy);
      card.range = Range(start: y, end: y + card.height());
      state.updated(card);
    }
  }

  Widget card(CardGroup group, CardInfo card, bool grouped) {
    final start = card.range.start - group.range.start;
    final height = card.range.end - card.range.start;

    return Positioned(
      top: start,
      height: height,
      width: width,
      child: DraggableItem(
        data: card,
        onDropHit: grouped
            ? null
            : (from) {
                onDropHit(from, card);
              },
        grouped: grouped,
        onDrag: widget.onDrag,
        onDragEnd: (details) {
          onDragEnd(group, card, details);
        },
      ),
    );
  }

  double getY(double y) {
    return y - widget.topLeft.dy + offsetY();
  }
}

typedef OnDropHitCallback<T> = void Function(T target);

class DraggableItem extends StatelessWidget {
  final Widget? child;
  final CardInfo data;
  final DragEndCallback onDragEnd;
  final DragUpdateCallback onDrag;
  final OnDropHitCallback<CardInfo>? onDropHit;

  final bool grouped;

  const DraggableItem({
    this.child,
    required this.onDropHit,
    required this.grouped,
    required this.onDragEnd,
    required this.onDrag,
    required this.data,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return content(context);
  }

  Widget buildWithTarget() {
    return DragTarget<CardInfo>(
      builder: (c, o, l) {
        return content(c);
      },
      onWillAccept: (d) {
        return !grouped && d != data;
      },
      onMove: (d) {
        if (grouped || d.data == data) return;
        d.data.hoverGroup = true;
      },
      onLeave: (d) {
        if (grouped || d == data) return;
        d?.hoverGroup = false;
      },
      onAcceptWithDetails: (details) {
        logd("onAcceptWithDetails", "*****");
        onDropHit?.call(details.data);
      },
    );
  }

  Widget content(BuildContext context) {
    final height = data.range.end - data.range.start;
    return LongPressDraggable(
      data: data,
      onDragUpdate: onDrag,
      onDragEnd: onDragEnd,
      childWhenDragging: Container(
        height: height,
        color: data.color.withAlpha(160),
        child: Text(
          data.id,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            decoration: TextDecoration.none,
          ),
        ),
      ),
      feedback: Container(
        height: height,
        color: data.color,
        child: Text(
          data.id,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            decoration: TextDecoration.none,
          ),
        ),
      ),
      child: Container(
        height: height,
        color: data.color,
        child: Text(
          data.id,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
