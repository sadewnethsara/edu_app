import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:math/core/router/app_router.dart';
import 'package:math/core/widgets/professional_nav_bar.dart'; // Ensure correct import
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

class MainScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with SingleTickerProviderStateMixin {
  bool _isNavBarVisible = true;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // Start fully visible
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.reverse) {
      if (_isNavBarVisible) {
        _controller.reverse();
        setState(() => _isNavBarVisible = false);
      }
    } else if (notification.direction == ScrollDirection.forward) {
      if (!_isNavBarVisible) {
        _controller.forward();
        setState(() => _isNavBarVisible = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        _handleScroll(notification);
        return false; // Allow bubble up
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Let nested scaffolds handle resizing
        extendBody: true, // Allow content to flow behind navbar
        body: widget.navigationShell,

        floatingActionButton: widget.navigationShell.currentIndex == 2
            ? ScaleTransition(
                scale: _animation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 42.w,
                      width: 42.w,
                      child: FloatingActionButton(
                        heroTag: 'communitiesFAB',
                        onPressed: () =>
                            context.pushNamed(AppRouter.communitiesListName),
                        backgroundColor: const Color(0xFFFFD300),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Icon(
                          Iconsax.hierarchy_2_outline,
                          color: Colors.black,
                          size: 22.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    FloatingActionButton(
                      heroTag: 'createPostFAB',
                      onPressed: () => context.push(AppRouter.createPostPath),
                      backgroundColor: const Color(
                        0xFFFFD300,
                      ), // Primary Yellow
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: const Icon(
                        RemixIcons.quill_pen_fill,
                        color: Colors.black,
                        size: 30,
                        weight: 100,
                      ),
                    ),
                  ],
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        bottomNavigationBar: SizeTransition(
          sizeFactor: _animation,
          axisAlignment: -1.0,
          child: ProfessionalNavBar(
            currentIndex: widget.navigationShell.currentIndex,
            onTap: (index) => _onTap(context, index),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
