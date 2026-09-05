import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/consequence_level.dart';
import '../models/energy_required.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

const _accentPink = Color(0xFFE85A94);
const _accentPurple = Color(0xFF8B5CD6);
const _textDark = Color(0xFF3A2E38);
const _textMuted = Color(0xFF8C7E88);

class EditTaskScreen extends StatefulWidget {
  const EditTaskScreen({
    super.key,
    required this.task,
    required this.repository,
  });

  final Task task;
  final TaskRepository repository;

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late ConsequenceLevel? _consequenceLevel;
  late EnergyIntensity? _energyIntensity;
  late EnergyType? _energyType;
  late DateTime? _deadline;
  late final TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _consequenceLevel = widget.task.consequenceLevel;
    _energyIntensity = widget.task.energyRequired?.intensity;
    _energyType = widget.task.energyRequired?.type;
    _deadline = widget.task.deadline;
    _durationController = TextEditingController(
      text: widget.task.estimatedDuration?.inMinutes.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final minutes = int.tryParse(_durationController.text);
    final energyRequired = (_energyIntensity != null && _energyType != null)
        ? EnergyRequired(intensity: _energyIntensity!, type: _energyType!)
        : null;

    final updated = Task(
      id: widget.task.id,
      title: widget.task.title,
      description: widget.task.description,
      pillarId: widget.task.pillarId,
      consequenceLevel: _consequenceLevel,
      strategicValue: widget.task.strategicValue,
      deadline: _deadline,
      desiredDate: widget.task.desiredDate,
      estimatedDuration: minutes == null ? null : Duration(minutes: minutes),
      energyRequired: energyRequired,
      divisible: widget.task.divisible,
      status: widget.task.status,
      createdAt: widget.task.createdAt,
      completedAt: widget.task.completedAt,
      source: widget.task.source,
      responsiblePerson: widget.task.responsiblePerson,
    );

    await widget.repository.save(updated);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      color: _accentPurple,
                    ),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    Text(
                      widget.task.title,
                      style: GoogleFonts.baloo2(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel('Consecuencia'),
                    _SegmentedPicker<ConsequenceLevel>(
                      options: ConsequenceLevel.values,
                      selected: _consequenceLevel,
                      labelOf: (v) => _capitalize(v.name),
                      onSelected: (v) =>
                          setState(() => _consequenceLevel = v),
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel('Energía requerida'),
                    _SegmentedPicker<EnergyIntensity>(
                      options: EnergyIntensity.values,
                      selected: _energyIntensity,
                      labelOf: (v) => _capitalize(v.name),
                      onSelected: (v) => setState(() => _energyIntensity = v),
                    ),
                    const SizedBox(height: 8),
                    _SectionLabel('Tipo de energía'),
                    _SegmentedPicker<EnergyType>(
                      options: EnergyType.values,
                      selected: _energyType,
                      labelOf: (v) => _capitalize(v.name),
                      onSelected: (v) => setState(() => _energyType = v),
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel('Duración estimada'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Ej. 30',
                              ),
                            ),
                          ),
                          Text('min', style: TextStyle(color: _textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionLabel('Deadline'),
                    InkWell(
                      onTap: _pickDeadline,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _deadline == null
                                  ? 'Sin definir'
                                  : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                              style: TextStyle(
                                color: _deadline == null
                                    ? _textMuted
                                    : _textDark,
                              ),
                            ),
                            Text(
                              _deadline == null ? '+ Agregar' : 'Cambiar',
                              style: const TextStyle(
                                color: _accentPurple,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _textMuted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SegmentedPicker<T> extends StatelessWidget {
  const _SegmentedPicker({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    super.key,
  });

  final List<T> options;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = option == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(option),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [_accentPink, _accentPurple],
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  labelOf(option),
                  style: TextStyle(
                    color: isSelected ? Colors.white : _textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
