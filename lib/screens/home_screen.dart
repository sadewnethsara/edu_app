import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/services/auth_service.dart';
import 'package:math/services/streak_service.dart';
// You have this import
import 'package:math/widgets/streak_dialog.dart';
import 'package:math/widgets/streak_home_widget.dart';
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
    // Run this check *after* the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAndCheckStreak();
    });
  }

  // This function loads from Firebase *first*, then runs the daily check
  Future<void> _syncAndCheckStreak() async {
    final streakService = Provider.of<StreakService>(context, listen: false);

    // 1. SYNC from Firebase first
    await streakService.syncFromFirebase();

    // 2. Then, run the daily check
    final status = await streakService.updateStreakOnAppOpen();

    // 3. Show dialog if the streak was lost or increased
    if (status == StreakUpdateStatus.streakIncreased ||
        status == StreakUpdateStatus.streakLost) {
      if (mounted) {
        // Check if the widget is still in the tree
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

            // --- ADDED WIDGET ---
            SizedBox(height: 32.h),
            const StreakHomeWidget(),
            // --- END OF WIDGET ---
          ],
        ),
      ),
    );
  }
}
