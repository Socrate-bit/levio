---
name: step-07-tests
description: Smart test analysis and creation - analyze patterns, create appropriate tests
prev_step: steps/step-04-validate.md
next_step: steps/step-08-run-tests.md
---

# Step 7: Tests (Analysis & Creation)

## MANDATORY EXECUTION RULES (READ FIRST):

- 🛑 NEVER create tests without analyzing existing patterns first
- 🛑 NEVER use wrong test type (unit when integration needed)
- ✅ ALWAYS analyze test infrastructure BEFORE writing
- ✅ ALWAYS follow existing test conventions exactly
- ✅ ALWAYS map tests to acceptance criteria
- 📋 YOU ARE A TEST ENGINEER, not a code generator
- 💬 FOCUS on "What tests does this ACTUALLY need?"
- 🚫 FORBIDDEN to ignore project test conventions

## EXECUTION PROTOCOLS:

- 🎯 Analyze test infrastructure first
- 💾 Document test strategy (if save_mode)
- 📖 Read similar tests before writing
- 🚫 FORBIDDEN to write tests without reading examples

## CONTEXT BOUNDARIES:

- Implementation is complete and validated
- Test infrastructure exists (discovered in this step)
- Existing tests show conventions to follow
- Focus on creating RIGHT tests, not just tests

## YOUR TASK:

Analyze existing test patterns and create appropriate tests for the implementation.

---

<available_state>
From previous steps:

| Variable | Description |
|----------|-------------|
| `{task_description}` | What was implemented |
| `{task_id}` | Kebab-case identifier |
| `{auto_mode}` | Skip confirmations |
| `{save_mode}` | Save outputs to files |
| `{economy_mode}` | Lighter test analysis |
| `{output_dir}` | Path to output (if save_mode) |
| Files modified | From implementation |
| Acceptance criteria | From step-01 |
</available_state>

---

## EXECUTION SEQUENCE:

### 1. Initialize Save Output (if save_mode)

**If `{save_mode}` = true:**

```bash
bash {skill_dir}/scripts/update-progress.sh "{task_id}" "07" "tests" "in_progress"
```

Append analysis to `{output_dir}/07-tests.md` as you work.

### 2. Test Infrastructure (pre-configured)

**Levio Flutter test stack — no discovery needed:**

| Scope | Framework | Command | Test location |
|-------|-----------|---------|---------------|
| Cubit unit | `flutter_test` + `bloc_test` | `flutter test` | `test/features/**/*_cubit_test.dart` |
| Service unit | `flutter_test` + `mocktail` | `flutter test` | `test/features/**/*_service_test.dart`, `test/shared/services/**/*_test.dart` |
| Widget | `flutter_test` | `flutter test` | `test/**/*_widget_test.dart` |
| Integration (E2E) | `integration_test` | `flutter test integration_test/` | `integration_test/*_test.dart` |

**Cubit patterns:** `bloc_test` with `build` / `act` / `expect` sequence, `mocktail` for Firestore/service fakes, `Equatable` so `expect` can match state objects directly.
**Widget patterns:** `testWidgets`, `pumpWidget`, `find.byType`, `tester.tap`. Wrap in `MaterialApp` and provide mock Cubits via `BlocProvider.value`.
**Integration patterns:** use the `integration_test` package; drive real app via `main()` bootstrap with Firebase mocks.

If `test/` does not yet exist, create it as part of the first test added. Mirror the `lib/` folder layout under `test/`.

### 3. Analyze Existing Test Patterns

**If `{economy_mode}` = true:**
→ Read 1 similar test file for patterns

**If `{economy_mode}` = false:**
→ Read 2-3 similar test files (look under `test/features/<feature>/`)

**Pattern Checklist:**
- [ ] `group` / `test` / `testWidgets` structure
- [ ] `setUp` / `tearDown` patterns
- [ ] Mocking approach (`mocktail` vs manual fakes)
- [ ] Assertion style (matchers vs Equatable equality)
- [ ] Test data approach (factory helpers vs inline)

### 4. Determine Test Strategy (scope-aware)

| Implementation Type | Test Type | Framework |
|--------------------|-----------|-----------|
| Cubit | `bloc_test` sequences | `flutter_test` + `bloc_test` (`flutter test`) |
| Service (Firestore/Firebase) | Unit with mocked FirebaseFirestore | `flutter_test` + `mocktail` |
| Widget with logic | `testWidgets` interactions | `flutter_test` |
| Native MethodChannel handler | Unit with `setMockMethodCallHandler` | `flutter_test` |
| Screen / user flow | Integration (E2E) | `integration_test` (`flutter test integration_test/`) |
| Shared helper | Unit | `flutter_test` |

### 5. Create Test Plan

```markdown
## Test Plan

### Cubit Tests
**Framework:** `flutter_test` + `bloc_test`
**Command:** `flutter test`

**Unit:** `test/features/alarms/alarm_cubit_test.dart`
- emits [Loading, Loaded] on init (happy path)
- emits [Loaded(empty)] when Firestore returns no alarms (edge case)
- rolls back optimistic update on Firestore error (rollback)
- cancels alarm stream subscription in close() (lifecycle)

### Integration Tests (if scope changes a critical flow)
**Framework:** `integration_test`
**Command:** `flutter test integration_test/`

**E2E:** `integration_test/alarm_dismiss_flow_test.dart`
- completes pushup mission and dismisses alarm
- native ring event navigates to dismiss route
```

**If `{auto_mode}` = false:**

```yaml
questions:
  - header: "Tests"
    question: "Review the test plan. Ready to create tests?"
    options:
      - label: "Create tests (Recommended)"
        description: "Proceed with planned tests"
      - label: "Add more tests"
        description: "I want additional test cases"
      - label: "Modify approach"
        description: "Change the strategy"
      - label: "Skip tests"
        description: "Don't create tests"
    multiSelect: false
```

### 6. Create Tests

**CRITICAL: Follow existing patterns EXACTLY**

1. Read a similar test for reference
2. Create test file matching structure
3. Write tests following conventions

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:levio/features/alarms/cubit/alarm_cubit.dart';
import 'package:levio/features/alarms/services/alarm_service.dart';

class _MockAlarmService extends Mock implements AlarmService {}

void main() {
  group('AlarmCubit', () {
    late _MockAlarmService service;

    setUp(() {
      service = _MockAlarmService();
    });

    blocTest<AlarmCubit, AlarmState>(
      'emits [Loading, Loaded] on init',
      build: () {
        when(() => service.watchAlarms()).thenAnswer((_) => Stream.value(const []));
        return AlarmCubit(service);
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        const AlarmState.loading(),
        const AlarmState.loaded(alarms: []),
      ],
    );
  });
}
```

### 7. Verify Tests

```bash
dart analyze test
```

List created tests:
```
**Tests Created:**
- `test/features/alarms/alarm_cubit_test.dart` (4 tests)
- `test/features/alarms/services/alarm_service_test.dart` (2 tests)
```

### 8. Complete Save Output (if save_mode)

**If `{save_mode}` = true:**

Append to `{output_dir}/07-tests.md`:
```markdown
---
## Step Complete
**Status:** ✓ Complete
**Tests created:** {count}
**Test files:** {list}
**Next:** step-08-run-tests.md
**Timestamp:** {ISO timestamp}
```

---

## SUCCESS METRICS:

✅ Test infrastructure analyzed
✅ Existing patterns studied
✅ Appropriate test types chosen
✅ Tests follow codebase conventions
✅ Tests pass `dart analyze`
✅ All AC have corresponding tests

## FAILURE MODES:

❌ Writing tests without analyzing patterns
❌ Wrong test type for implementation
❌ Ignoring project conventions
❌ Tests don't match acceptance criteria
❌ Over-testing (testing implementation, not behavior)
❌ **CRITICAL**: Not using AskUserQuestion for approval

## TEST PROTOCOLS:

- Analyze BEFORE writing
- Follow existing patterns EXACTLY
- Test behavior, not implementation
- Map to acceptance criteria
- Create minimal, focused tests

---

## NEXT STEP:

After tests created, load `./step-08-run-tests.md`

<critical>
Remember: Create the RIGHT tests - analyze patterns first, then write!
</critical>
