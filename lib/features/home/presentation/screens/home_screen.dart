import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/core/services/streak_service.dart';
import 'package:math/core/widgets/streak_dialog.dart';
import 'package:math/core/widgets/streak_home_widget.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAndCheckStreak();
    });
  }

  Future<void> _syncAndCheckStreak() async {
    final streakService = Provider.of<StreakService>(context, listen: false);

    await streakService.syncFromFirebase();

    final status = await streakService.updateStreakOnAppOpen();

    if (status == StreakUpdateStatus.streakIncreased ||
        status == StreakUpdateStatus.streakLost) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // User must tap button
          builder: (context) => const StreakDialog(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    return Scaffold(
      appBar: AppBar(title: const Text("Math App Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            user?.photoURL != null
                ? CircleAvatar(
                    radius: 50.r,
                    backgroundColor: Colors.grey.shade300,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user!.photoURL!,
                        fit: BoxFit.cover,
                        width: 100.r,
                        height: 100.r,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            Icon(Icons.person, size: 50.sp),
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 50.r,
                    child: Icon(Icons.person, size: 50.sp),
                  ),
            SizedBox(height: 16.h),
            Text(
              user?.displayName ?? "No Name",
              style: const TextStyle(fontSize: 20),
            ),
            SizedBox(height: 8.h),
            Text(
              user?.email ?? "No Email",
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),
            if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
              Text(
                user.phoneNumber!,
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
              ),

            SizedBox(height: 32.h),
            const StreakHomeWidget(),
          ],
        ),
      ),
    );
  }
}
