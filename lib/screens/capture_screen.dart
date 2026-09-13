import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/capture/capture_parser.dart';
import '../logic/capture/capture_result.dart';
import '../logic/capture/task_from_capture.dart';
import '../repositories/task_repository.dart';

const _accentPink = Color(0xFFE85A94);
const _accentPurple = Color(0xFF8B5CD6);
const _textMuted = Color(0xFF8C7E88);

/// C1: captura por lenguaje natural. Recibe la interfaz `CaptureParser`,
/// no una implementación concreta — el día que el parser sea una llamada
/// a un modelo, esta pantalla no cambia.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({
    super.key,
    required this.parser,
    required this.repository,
  });

  final CaptureParser parser;
  final TaskRepository repository;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _controller = TextEditingController();
  CaptureResult? _preview;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _controller.removeListener(_updatePreview);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _updatePreview() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _preview = null);
      return;
    }
    final result = await widget.parser.parse(text, now: DateTime.now());
    if (mounted) setState(() => _preview = result);
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final capture = await widget.parser.parse(text, now: now);
    await widget.repository.save(
      taskFromCapture(
        capture,
        id: 'task-${now.microsecondsSinceEpoch}',
        now: now,
      ),
    );

    _controller.clear();
    if (mounted) {
      setState(() => _preview = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardado en el Inbox ✨')),
      );
    }
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Capturar',
                  style: GoogleFonts.baloo2(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: _accentPurple,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Escríbelo como lo pensaste. Lo demás se completa después.',
                  style: TextStyle(fontSize: 13, color: _textMuted),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    minLines: 1,
                    maxLines: 3,
                    onSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'comprar comida para los perros mañana',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_preview != null) _CapturePreview(result: _preview!),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Muestra lo que el parser entendió, para poder corregir en el momento
/// si leyó mal la fecha — el parser es heurístico y puede equivocarse.
class _CapturePreview extends StatelessWidget {
  const _CapturePreview({required this.result});

  final CaptureResult result;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (result.targetDate != null) {
      chips.add(_chip('📅 Para el ${_formatDate(result.targetDate!)}'));
    }
    if (result.deadline != null) {
      chips.add(_chip('⏳ Vence el ${_formatDate(result.deadline!)}'));
    }
    if (result.action == null) {
      chips.add(_chip('Sin verbo reconocido', muted: true));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _chip(String text, {bool muted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: muted
            ? _textMuted.withValues(alpha: 0.12)
            : _accentPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: muted ? _textMuted : _accentPurple,
        ),
      ),
    );
  }
}

const _weekdayNames = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const _monthNames = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String _formatDate(DateTime date) {
  final weekday = _weekdayNames[date.weekday - 1];
  final month = _monthNames[date.month - 1];
  return '$weekday ${date.day} de $month';
}
