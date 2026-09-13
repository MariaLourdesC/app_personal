import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_personal/logic/capture/rules_capture_parser.dart';
import 'package:app_personal/models/pillar.dart';
import 'package:app_personal/models/task.dart';
import 'package:app_personal/repositories/task_repository.dart';
import 'package:app_personal/screens/capture_screen.dart';

class _FakeTaskRepository implements TaskRepository {
  final saved = <Task>[];

  @override
  Future<void> save(Task task) async => saved.add(task);

  @override
  Future<List<Task>> getAll() async => saved;

  @override
  Future<Task?> getById(String id) async => null;

  @override
  Future<List<Pillar>> getPillars() async => [];
}

void main() {
  testWidgets('la vista previa muestra la fecha detectada al escribir', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaptureScreen(
          parser: RulesCaptureParser(),
          repository: _FakeTaskRepository(),
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextField),
      'comprar comida para los perros mañana',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Para el'), findsOneWidget);
  });
}
