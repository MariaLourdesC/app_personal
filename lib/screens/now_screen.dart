import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/capacity/current_window.dart';
import '../logic/capacity/time_window.dart';
import '../logic/priority/decision_result.dart';
import '../logic/priority/next_window_finder.dart';
import '../logic/priority/priority_engine.dart';
import '../logic/priority/task_adapter.dart';
import '../models/task.dart';
import '../models/task_completion.dart';
import '../models/task_source.dart';
import '../models/task_status.dart';
import '../repositories/completion_repository.dart';
import '../repositories/config_repository.dart';
import '../repositories/fixed_event_repository.dart';
import '../repositories/task_repository.dart';
import 'reason_text.dart';

const _accentPink = Color(0xFFE85A94);
const _accentPurple = Color(0xFF8B5CD6);
const _textDark = Color(0xFF3A2E38);
const _textMuted = Color(0xFF8C7E88);

class NowScreen extends StatefulWidget {
  const NowScreen({
    super.key,
    required this.taskRepository,
    required this.completionRepository,
    required this.fixedEventRepository,
    required this.configRepository,
  });

  final TaskRepository taskRepository;
  final CompletionRepository completionRepository;
  final FixedEventRepository fixedEventRepository;
  final ConfigRepository configRepository;

  @override
  State<NowScreen> createState() => _NowScreenState();
}

class _NowScreenState extends State<NowScreen> {
  bool _loading = true;
  DecisionResult? _result;
  Task? _currentTask;
  CurrentBlock _block = CurrentBlock.disponible;
  TimeWindow? _nextWindow;
  DateTime? _taskStart;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  final _quickCaptureController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _quickCaptureController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final tasks = await widget.taskRepository.getAll();
    final events = await widget.fixedEventRepository.getAll();
    final user = await widget.configRepository.getUser();

    DecisionResult? result;
    var block = CurrentBlock.disponible;
    TimeWindow? nextWindow;

    if (user != null) {
      final now = DateTime.now();
      final windowResult = currentWindow(
        now: now,
        fixedEvents: events,
        user: user,
      );
      block = windowResult.block;
      final window = windowResult.window;

      final ready = tasksReadyForPriority(tasks);
      final candidates = ready.map(priorityCandidateFromTask).toList();

      // Todas las ventanas del día; la primera es la actual, el resto son
      // las posteriores que §23 necesita para su protección.
      final windows = remainingWindows(
        now: now,
        fixedEvents: events,
        user: user,
      );
      final laterWindows = windows.isEmpty
          ? <TimeWindow>[]
          : windows.sublist(1);

      if (window != null && candidates.isNotEmpty) {
        try {
          result = decide(candidates, window, laterWindows: laterWindows);
        } on StateError {
          // Ninguna candidata cabe en esta ventana (CP-07): buscamos en
          // cuál de las siguientes sí habría espacio, para poder decirlo.
          result = null;
          nextWindow = nextWindowWithSpace(
            candidates: candidates,
            windows: laterWindows,
          );
        }
      } else if (candidates.isNotEmpty) {
        nextWindow = nextWindowWithSpace(
          candidates: candidates,
          windows: windows,
        );
      }
    }

    final winnerTask = result == null
        ? null
        : await widget.taskRepository.getById(result.candidate.id);

    _ticker?.cancel();
    final start = DateTime.now();
    setState(() {
      _result = result;
      _currentTask = winnerTask;
      _block = block;
      _nextWindow = nextWindow;
      _loading = false;
      _taskStart = start;
      _elapsed = Duration.zero;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed = DateTime.now().difference(start));
    });
  }

  Future<void> _finish() async {
    final task = _currentTask;
    final start = _taskStart;
    if (task == null || start == null) return;

    final end = DateTime.now();
    await widget.completionRepository.save(
      TaskCompletion(
        id: 'completion-${end.microsecondsSinceEpoch}',
        taskId: task.id,
        start: start,
        end: end,
        actualDuration: end.difference(start),
        estimatedDuration: task.estimatedDuration,
      ),
    );

    await widget.taskRepository.save(
      Task(
        id: task.id,
        title: task.title,
        description: task.description,
        pillarId: task.pillarId,
        consequenceLevel: task.consequenceLevel,
        strategicValue: task.strategicValue,
        deadline: task.deadline,
        desiredDate: task.desiredDate,
        estimatedDuration: task.estimatedDuration,
        energyRequired: task.energyRequired,
        divisible: task.divisible,
        status: TaskStatus.terminada,
        createdAt: task.createdAt,
        completedAt: end,
        source: task.source,
        responsiblePerson: task.responsiblePerson,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('¡Tarea terminada! 🎉')));
    }

    await _load();
  }

  Future<void> _quickCapture() async {
    final title = _quickCaptureController.text.trim();
    if (title.isEmpty) return;
    final now = DateTime.now();
    await widget.taskRepository.save(
      Task(
        id: 'task-${now.microsecondsSinceEpoch}',
        title: title,
        status: TaskStatus.porIniciar,
        createdAt: now,
        source: TaskSource.cajaRapida,
      ),
    );
    _quickCaptureController.clear();
    // A propósito, no llamo a _load() aquí: CP-12 exige que la tarea en
    // curso y su timer no se interrumpan al usar la caja rápida.
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Guardado en el Inbox')));
    }
  }

  void _showReason() {
    final result = _result;
    if (result == null) return;
    final lines = reasonText(result.reason, result.assumed);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Por qué esta tarea?',
                style: GoogleFonts.baloo2(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 16),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    line,
                    style: TextStyle(fontSize: 15, color: _textDark),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAF3F6), Color(0xFFF5EFFB)],
          ),
        ),
        child: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final result = _result;
    final task = _currentTask;
    if (result == null || task == null) {
      return _BlockedState(block: _block, nextWindow: _nextWindow);
    }

    final estimated = result.candidate.estimatedDuration;
    final progress = (_elapsed.inSeconds / estimated.inSeconds).clamp(0.0, 1.0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AHORA',
                style: GoogleFonts.baloo2(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: _accentPurple,
                ),
              ),
              GestureDetector(
                onTap: _showReason,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '¿Por qué ahora?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _accentPurple,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: GoogleFonts.baloo2(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _InfoPill(
                    text: '⏱ ${estimated.inMinutes} min estimados',
                    color: const Color(0xFF3F6FA0),
                  ),
                  if (task.deadline != null)
                    _InfoPill(
                      text: '📅 ${task.deadline!.day}/${task.deadline!.month}',
                      color: const Color(0xFFB5623A),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 14,
                      backgroundColor: const Color(0xFFF0E0E8),
                      valueColor: const AlwaysStoppedAnimation(_accentPink),
                    ),
                  ),
                  Text(
                    _formatElapsed(_elapsed),
                    style: GoogleFonts.baloo2(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finish,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Terminar', style: TextStyle(fontSize: 17)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quickCaptureController,
                        onSubmitted: (_) => _quickCapture(),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Anotar algo rápido...',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _quickCapture,
                      icon: const Icon(Icons.add_circle, color: _accentPink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'No interrumpe tu tarea actual',
                style: TextStyle(fontSize: 11, color: _textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// CP-11 exige que los bloques duros expliquen el motivo, no que aparezca
/// una pantalla vacía. El tiempo personal además se muestra como el bloque
/// actual (decisión de producto de la usuaria), no como una ausencia.
class _BlockedState extends StatelessWidget {
  const _BlockedState({required this.block, this.nextWindow});

  final CurrentBlock block;

  /// CP-07: "se muestra la siguiente ventana en la que sí habrá espacio".
  final TimeWindow? nextWindow;

  @override
  Widget build(BuildContext context) {
    final (emoji, title, subtitle) = switch (block) {
      CurrentBlock.tiempoPersonal => (
        '🌿',
        'Tu tiempo personal',
        'Este rato es tuyo. La app no propone nada aquí.',
      ),
      CurrentBlock.sueno => (
        '🌙',
        'Hora de dormir',
        'El sueño es un bloque no negociable.',
      ),
      CurrentBlock.eventoFijo => (
        '📌',
        'Estás en un compromiso',
        'Hay un evento fijo en curso ahora mismo.',
      ),
      CurrentBlock.disponible => (
        '✨',
        'Nada por ahora',
        'No hay ninguna tarea que quepa en el hueco disponible.',
      ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.baloo2(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: _textMuted),
            ),
            if (nextWindow != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Siguiente hueco con espacio: '
                  '${_formatHour(nextWindow!.start)} – '
                  '${_formatHour(nextWindow!.end)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _accentPurple,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatHour(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _formatElapsed(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
