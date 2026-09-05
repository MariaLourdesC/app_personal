import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/task.dart';
import '../repositories/task_repository.dart';
import 'edit_task_screen.dart';

const _bgTop = Color(0xFFFAF3F6);
const _bgBottom = Color(0xFFF5EFFB);
const _accentPink = Color(0xFFE85A94);
const _accentPurple = Color(0xFF8B5CD6);
const _textDark = Color(0xFF3A2E38);
const _textMuted = Color(0xFF8C7E88);

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, required this.repository});

  final TaskRepository repository;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = widget.repository.getAll();
  }

  Future<void> _openTask(Task task) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            EditTaskScreen(task: task, repository: widget.repository),
      ),
    );
    setState(() {
      _tasksFuture = widget.repository.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inbox ✨',
                      style: GoogleFonts.baloo2(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: _accentPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tareas capturadas por completar',
                      style: TextStyle(fontSize: 14, color: _textMuted),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Task>>(
                  future: _tasksFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final tasks = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return GestureDetector(
                          onTap: () => _openTask(task),
                          child: _TaskCard(task: task),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E0E8)),
        boxShadow: [
          BoxShadow(
            color: _accentPink.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: GoogleFonts.baloo2(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _fieldChip(
                label: 'Consecuencia',
                value: task.consequenceLevel?.name,
                hue: _accentPink,
              ),
              _fieldChip(
                label: 'Energía',
                value: task.energyRequired?.intensity.name,
                hue: _accentPurple,
              ),
              _fieldChip(
                label: 'Duración',
                value: task.estimatedDuration == null
                    ? null
                    : '${task.estimatedDuration!.inMinutes} min',
                hue: const Color(0xFF3F6FA0),
              ),
              _fieldChip(
                label: 'Deadline',
                value: task.deadline == null
                    ? null
                    : '${task.deadline!.day}/${task.deadline!.month}',
                hue: const Color(0xFFB5623A),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldChip({
    required String label,
    required String? value,
    required Color hue,
  }) {
    final isFilled = value != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: isFilled
            ? LinearGradient(colors: [_accentPink, _accentPurple])
            : null,
        color: isFilled ? null : hue.withValues(alpha: 0.12),
      ),
      child: Text(
        isFilled ? '$label: $value' : label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: isFilled ? Colors.white : hue,
        ),
      ),
    );
  }
}
