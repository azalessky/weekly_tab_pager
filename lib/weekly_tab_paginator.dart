import 'package:flutter/material.dart';

import 'package:weekly_tab_view/date_time_extension.dart';

import 'weekly_tab_controller.dart';

class WeeklyTabPaginator extends StatefulWidget {
  final WeeklyTabController controller;
  final TabController tabController;
  final List<int> weekdays;
  final int weekCount;
  final Widget Function(BuildContext, DateTime) pageBuilder;
  final ScrollPhysics? scrollPhysics;
  final Function(DateTime)? onPageChanged;

  const WeeklyTabPaginator({
    required this.controller,
    required this.tabController,
    required this.weekdays,
    required this.weekCount,
    required this.pageBuilder,
    this.scrollPhysics,
    this.onPageChanged,
    super.key,
  });

  @override
  State<WeeklyTabPaginator> createState() => _WeeklyTabPaginatorState();
}

class _WeeklyTabPaginatorState extends State<WeeklyTabPaginator> with TickerProviderStateMixin {
  late DateTime centerPosition;
  late int centerIndex;
  late TabController tabController;

  @override
  void initState() {
    super.initState();

    final itemCount = widget.weekCount * widget.weekdays.length;
    final initialPage = widget.weekdays.indexOf(widget.controller.position.weekday);

    centerPosition = widget.controller.position.weekStart(widget.weekdays);
    centerIndex = itemCount;

    tabController = TabController(
      initialIndex: centerIndex + initialPage,
      length: itemCount * 2,
      vsync: this,
    );

    tabController.addListener(_syncTabIndex);
    tabController.animation!.addListener(_syncTabOffset);
    widget.controller.addListener(_updatePosition);
  }

  @override
  void dispose() {
    tabController.removeListener(_syncTabIndex);
    tabController.animation!.removeListener(_syncTabOffset);
    widget.controller.removeListener(_updatePosition);
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      physics: widget.scrollPhysics,
      children: List.generate(
        tabController.length,
        (index) => widget.pageBuilder(context, _pageToDate(index - centerIndex)),
      ),
    );
  }

  void _syncTabIndex() {
    // if (!widget.tabController.indexIsChanging) {
    final date = _pageToDate(tabController.index - centerIndex);
    widget.onPageChanged?.call(date);
    // }
  }

  void _syncTabOffset() {
    final index = widget.tabController.index;
    final offset = tabController.offset;

    if (!widget.tabController.indexIsChanging && offset <= 1 && offset >= -1) {
      if (index == 0 && offset < 0) return;
      if (index == widget.tabController.length - 1 && offset > 0) return;
      widget.tabController.offset = tabController.offset;
    }
  }

  void _updatePosition() {
    final page = centerIndex + _dateToPage(widget.controller.position);
    tabController.animateTo(page);
  }

  DateTime _pageToDate(int page) {
    final weekdays = widget.weekdays;
    final weeks = page < 0 ? (page + 1) ~/ weekdays.length - 1 : page ~/ weekdays.length;
    final day = weekdays[page % weekdays.length] + weeks * 7;

    return centerPosition.add(Duration(days: day - centerPosition.weekday));
  }

  int _dateToPage(DateTime date) {
    final weekdays = widget.weekdays;
    final diff = date.differenceInDays(centerPosition);
    final days = weekdays.indexOf(date.weekday) - weekdays.indexOf(centerPosition.weekday);
    final weeks = diff ~/ 7 + (diff < 0 && days > 0 ? -1 : 0) + (diff > 0 && days < 0 ? 1 : 0);

    return days + weekdays.length * weeks;
  }
}
