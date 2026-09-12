import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user.dart';
import '../repositories/config_repository.dart';

const _accentPink = Color(0xFFE85A94);
const _accentPurple = Color(0xFF8B5CD6);
const _textDark = Color(0xFF3A2E38);
const _textMuted = Color(0xFF8C7E88);

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key, required this.repository});

  final ConfigRepository repository;

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  TimeOfDay? _sleepTime;
  TimeOfDay? _wakeTime;

  // Con los defaults iniciales que el propio PRD documenta (§20, §34) —
  // no son invención, son los números que el texto da como "configuración
  // inicial" / "mínimo inicial".
  final _focusBlockController = TextEditingController(text: '30');
  final _breakController = TextEditingController(text: '5');
  final _personalController = TextEditingController(text: '45');

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _focusBlockController.dispose();
    _breakController.dispose();
    _personalController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final existing = await widget.repository.getUser();
    if (existing != null) {
      _sleepTime = _toTimeOfDay(existing.sleepTarget);
      _wakeTime = _toTimeOfDay(existing.wakeTarget);
      _focusBlockController.text = existing.focusBlockMinutes.inMinutes
          .toString();
      _breakController.text = existing.breakMinutes.inMinutes.toString();
      _personalController.text = existing.protectedPersonalMinutes.inMinutes
          .toString();
    }
    setState(() => _loading = false);
  }

  TimeOfDay _toTimeOfDay(Duration d) =>
      TimeOfDay(hour: d.inHours, minute: d.inMinutes.remainder(60));

  Duration _toDuration(TimeOfDay t) =>
      Duration(hours: t.hour, minutes: t.minute);

  Future<void> _pickSleepTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _sleepTime ?? const TimeOfDay(hour: 23, minute: 0),
    );
    if (picked != null) setState(() => _sleepTime = picked);
  }

  Future<void> _pickWakeTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime ?? const TimeOfDay(hour: 6, minute: 30),
    );
    if (picked != null) setState(() => _wakeTime = picked);
  }

  Future<void> _save() async {
    if (_sleepTime == null || _wakeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige hora de dormir y de despertar')),
      );
      return;
    }

    final user = User(
      id: 'user',
      timezone: 'local',
      sleepTarget: _toDuration(_sleepTime!),
      wakeTarget: _toDuration(_wakeTime!),
      focusBlockMinutes: Duration(
        minutes: int.tryParse(_focusBlockController.text) ?? 30,
      ),
      breakMinutes: Duration(
        minutes: int.tryParse(_breakController.text) ?? 5,
      ),
      protectedPersonalMinutes: Duration(
        minutes: int.tryParse(_personalController.text) ?? 45,
      ),
      defaultBufferMinutes: Duration.zero,
    );

    await widget.repository.saveUser(user);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada ✨')),
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    Text(
                      'Configuración',
                      style: GoogleFonts.baloo2(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: _accentPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Se usa para calcular tu ventana disponible del día',
                      style: TextStyle(fontSize: 13, color: _textMuted),
                    ),
                    const SizedBox(height: 20),
                    _TimeRow(
                      label: 'Hora de dormir',
                      value: _sleepTime,
                      onTap: _pickSleepTime,
                    ),
                    const SizedBox(height: 12),
                    _TimeRow(
                      label: 'Hora de despertar',
                      value: _wakeTime,
                      onTap: _pickWakeTime,
                    ),
                    const SizedBox(height: 20),
                    _MinutesField(
                      label: 'Bloque de foco (minutos)',
                      controller: _focusBlockController,
                    ),
                    const SizedBox(height: 12),
                    _MinutesField(
                      label: 'Pausa activa (minutos)',
                      controller: _breakController,
                    ),
                    const SizedBox(height: 12),
                    _MinutesField(
                      label: 'Tiempo personal protegido (minutos)',
                      controller: _personalController,
                    ),
                    const SizedBox(height: 24),
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
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.label, required this.value, required this.onTap});

  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: _textDark)),
            Text(
              value == null ? 'Elegir' : value!.format(context),
              style: const TextStyle(
                color: _accentPurple,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinutesField extends StatelessWidget {
  const _MinutesField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: _textDark))),
          SizedBox(
            width: 60,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}
