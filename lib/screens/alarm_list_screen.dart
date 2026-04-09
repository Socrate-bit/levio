import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../alarm/alarm_cubit.dart';
import '../alarm/alarm_state.dart'; // ChallengeType is defined here

class AlarmListScreen extends StatelessWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AlarmCubit(),
      child: const _AlarmListView(),
    );
  }
}

class _AlarmListView extends StatelessWidget {
  const _AlarmListView();

  Future<void> _pickAndAddAlarm(BuildContext context) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
    );
    if (picked == null || !context.mounted) return;

    final challenge = await showModalBottomSheet<ChallengeType>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ChallengePicker(),
    );
    if (challenge == null || !context.mounted) return;

    final today = DateTime.now();
    final alarmDateTime = DateTime(
      today.year,
      today.month,
      today.day,
      picked.hour,
      picked.minute,
    );
    context.read<AlarmCubit>().addAlarm(alarmDateTime, challenge);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Alarms',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        onPressed: () => _pickAndAddAlarm(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<AlarmCubit, AlarmState>(
        builder: (context, state) {
          if (state.alarms.isEmpty) {
            return const Center(
              child: Text(
                'No alarms set.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: state.alarms.length,
            separatorBuilder: (_, _) =>
                const Divider(color: Colors.white12, height: 1),
            itemBuilder: (context, index) {
              final alarm = state.alarms[index];
              final time = TimeOfDay.fromDateTime(alarm.dateTime);
              return ListTile(
                leading: const Icon(Icons.alarm, color: Colors.white),
                title: Text(
                  time.format(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${_alarmSubtitle(alarm.dateTime)} · ${switch (alarm.challenge) {
                    ChallengeType.pushup => 'Push-ups',
                    ChallengeType.shake => 'Shake',
                    ChallengeType.photo => 'Photo',
                    ChallengeType.speech => 'Speech',
                  }}',
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () =>
                      context.read<AlarmCubit>().removeAlarm(alarm.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _alarmSubtitle(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.isNegative) return 'Ringing';
    if (diff.inMinutes < 60) return 'In ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'In ${diff.inHours} hr ${diff.inMinutes % 60} min';
    return 'Tomorrow';
  }
}

class _ChallengePicker extends StatelessWidget {
  const _ChallengePicker();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Challenge',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.fitness_center, color: Colors.white),
              title: const Text(
                'Push-ups',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                '10 push-ups detected by camera',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context, ChallengeType.pushup),
            ),
            ListTile(
              leading: const Icon(Icons.vibration, color: Colors.white),
              title: const Text(
                'Shake',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Shake your phone vigorously 10 times',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context, ChallengeType.shake),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text(
                'Photo',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Take a picture of a door',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context, ChallengeType.photo),
            ),
            ListTile(
              leading: const Icon(Icons.mic, color: Colors.white),
              title: const Text(
                'Speech',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "Read 'My name is Lucas' aloud",
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context, ChallengeType.speech),
            ),
          ],
        ),
      ),
    );
  }
}
