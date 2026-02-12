import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/core/models/post_model.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/core/services/logger_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class PollWidget extends StatefulWidget {
  final String postId;
  final PollData pollData;
  final FirebaseFirestore? firestore; // For testing

  const PollWidget({
    super.key,
    required this.postId,
    required this.pollData,
    this.firestore,
  });

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasVoted = false;
  List<int> _votedOptionIndices = [];
  Set<int> _selectedIndices = {};
  late List<int> _currentVoteCounts;
  late int _currentTotalVotes;
  late AnimationController _animController;

  FirebaseFirestore get _firestore =>
      widget.firestore ?? FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _currentVoteCounts = List.from(widget.pollData.voteCounts);
    _currentTotalVotes = widget.pollData.totalVotes;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _checkUserVote();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PollWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pollData != oldWidget.pollData ||
        widget.postId != oldWidget.postId) {
      setState(() {
        _currentVoteCounts = List.from(widget.pollData.voteCounts);
        _currentTotalVotes = widget.pollData.totalVotes;
      });
      _checkUserVote();
    }
  }

  Future<void> _checkUserVote() async {
    final user = context.read<AuthService>().user;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final voteDoc = await _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('votes')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _hasVoted = voteDoc.exists;
          if (_hasVoted) {
            final data = voteDoc.data();
            if (data != null) {
              if (data['optionIndices'] != null) {
                _votedOptionIndices = List<int>.from(data['optionIndices']);
              } else if (data['optionIndex'] != null) {
                _votedOptionIndices = [data['optionIndex'] as int];
              }
              _animController.forward();
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Error checking vote', error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVote(List<int> optionIndices) async {
    final user = context.read<AuthService>().user;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in to vote.')));
      return;
    }

    if (_hasVoted &&
        optionIndices.length == _votedOptionIndices.length &&
        optionIndices.every((i) => _votedOptionIndices.contains(i))) {
      return;
    }

    setState(() => _isLoading = true);

    final bool wasVoted = _hasVoted;
    final List<int> oldVotedIndices = List.from(_votedOptionIndices);
    final List<int> oldCounts = List.from(_currentVoteCounts);
    final int oldTotal = _currentTotalVotes;

    setState(() {
      if (wasVoted) {
        for (final index in oldVotedIndices) {
          if (index < _currentVoteCounts.length) {
            _currentVoteCounts[index]--;
            _currentTotalVotes--;
          }
        }
      }

      for (final index in optionIndices) {
        if (index < _currentVoteCounts.length) {
          _currentVoteCounts[index]++;
          _currentTotalVotes++;
        }
      }

      _hasVoted = true;
      _votedOptionIndices = optionIndices;

      _animController.forward(from: 0.0);
    });

    try {
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId);
      final voteRef = postRef.collection('votes').doc(user.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final voteDoc = await transaction.get(voteRef);
        final bool isChangeVote = voteDoc.exists;

        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) throw Exception("Post not found");

        final latestPost = PostModel.fromSnapshot(postSnapshot);
        final latestPoll = latestPost.pollData;
        if (latestPoll == null) throw Exception("Poll data missing");

        List<int> newCounts = List.from(latestPoll.voteCounts);
        late int currentTotal;

        if (isChangeVote) {
          final data = voteDoc.data();
          List<int> previousIndices = [];
          if (data != null) {
            if (data['optionIndices'] != null) {
              previousIndices = List<int>.from(data['optionIndices']);
            } else if (data['optionIndex'] != null) {
              previousIndices = [data['optionIndex'] as int];
            }
          }

          for (final index in previousIndices) {
            if (index < newCounts.length) {
              newCounts[index] = (newCounts[index] - 1).clamp(0, 999999);
            }
          }
          currentTotal = latestPoll.totalVotes - previousIndices.length;
        } else {
          currentTotal = latestPoll.totalVotes;
        }

        for (final index in optionIndices) {
          if (index < newCounts.length) {
            newCounts[index] += 1;
            currentTotal++;
          }
        }

        transaction.update(postRef, {
          'pollData.voteCounts': newCounts,
          'pollData.totalVotes': currentTotal,
        });

        transaction.set(voteRef, {
          'optionIndices': optionIndices,
          'votedAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      logger.e('Vote failed', error: e);
      if (mounted) {
        setState(() {
          _hasVoted = wasVoted;
          _votedOptionIndices = oldVotedIndices;
          _currentVoteCounts = oldCounts;
          _currentTotalVotes = oldTotal;
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Vote failed: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pollData.options.length < 2) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isExpired = widget.pollData.endsAt.toDate().isBefore(DateTime.now());

    final showResults = _hasVoted || isExpired;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      alignment: Alignment.topCenter,
      child: Container(
        margin: EdgeInsets.only(top: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...List.generate(widget.pollData.options.length, (index) {
              final option = widget.pollData.options[index];

              if (showResults) {
                return _buildResultRow(theme, index, option);
              } else {
                if (widget.pollData.allowMultipleVotes) {
                  return _buildMultiChoiceRow(theme, index, option);
                } else {
                  return _buildSingleChoiceButton(theme, index, option);
                }
              }
            }),

            if (!showResults && widget.pollData.allowMultipleVotes)
              AnimatedOpacity(
                opacity: _selectedIndices.isNotEmpty ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: _selectedIndices.isNotEmpty
                    ? Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _handleVote(_selectedIndices.toList()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          child: const Text('Vote'),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

            Padding(
              padding: EdgeInsets.only(top: 12.h, left: 4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Spaced out
                children: [
                  Row(
                    children: [
                      Text(
                        '${NumberFormat.compact().format(_currentTotalVotes)} votes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ' · ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade400,
                        ),
                      ),
                      Text(
                        isExpired
                            ? "Final results"
                            : "${widget.pollData.lengthDays} days left",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleChoiceButton(ThemeData theme, int index, String option) {
    final isExpired = widget.pollData.endsAt.toDate().isBefore(DateTime.now());
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: OutlinedButton(
        onPressed: isExpired ? null : () => _handleVote([index]),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          side: BorderSide(color: theme.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r), // More rounded/premium
          ),
          alignment:
              Alignment.centerLeft, // Left align text for better readability
        ),
        child: Text(
          option,
          textAlign: TextAlign.left,
          maxLines: 2,
          overflow: TextOverflow.ellipsis, // Logic Fix: Handle long text
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 15.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildMultiChoiceRow(ThemeData theme, int index, String option) {
    final isSelected = _selectedIndices.contains(index);
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedIndices.remove(index);
            } else {
              _selectedIndices.add(index);
            }
          });
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? theme.primaryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12.r),
            color: isSelected
                ? theme.primaryColor.withValues(alpha: 0.05)
                : null,
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  key: ValueKey(isSelected),
                  color: isSelected ? theme.primaryColor : Colors.grey.shade400,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  option,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis, // Logic Fix: Handle long text
                  style: TextStyle(
                    color: isSelected
                        ? theme.primaryColor
                        : theme.textTheme.bodyLarge?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(ThemeData theme, int index, String option) {
    int votes = 0;
    if (index < _currentVoteCounts.length) {
      votes = _currentVoteCounts[index];
    }

    final double percentage = _currentTotalVotes == 0
        ? 0.0
        : (votes / _currentTotalVotes);
    final isExpired = widget.pollData.endsAt.toDate().isBefore(DateTime.now());
    final isSelected = _votedOptionIndices.contains(index);

    final Color barColor = isSelected
        ? theme.primaryColor.withValues(alpha: 0.2)
        : Colors.grey.withValues(alpha: 0.15);
    final Color textColor = isSelected
        ? theme.primaryColor
        : theme.textTheme.bodyMedium?.color ?? Colors.black;
    final FontWeight fontWeight = isSelected
        ? FontWeight.bold
        : FontWeight.w500;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: isExpired ? null : () => _handleVote([index]),
        borderRadius: BorderRadius.circular(12.r),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 46.h,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: theme.brightness == Brightness.light
                        ? Colors.grey.shade100
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                ),

                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Container(
                      height: 46.h,
                      width:
                          constraints.maxWidth *
                          (percentage * _animController.value),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        color: barColor,
                      ),
                    );
                  },
                ),

                Container(
                  height: 46.h,
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: fontWeight,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      if (isSelected) ...[
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.check_circle,
                          color: theme.primaryColor,
                          size: 18.sp,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
