# Tasks: Knotty Domain-Specific Language Documentation and Validation

**Input**: Design documents from `/specs/001-define-the-existing/`
**Prerequisites**: plan.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

## Execution Flow (main)
```
1. Load plan.md from feature directory
   ✓ Loaded: Typed Racket library with CLI, multi-format export
   ✓ Extract: Racket/RackUnit, file-based storage, single project structure
2. Load optional design documents:
   ✓ data-model.md: 7 entities (Pattern, Row, Stitch, Chart, Instructions, Yarn, ExportFormat)
   ✓ contracts/: 3 API modules (pattern-api, chart-api, cli-api)
   ✓ research.md: Technology decisions and architecture
   ✓ quickstart.md: 3 user scenarios and integration tests
3. Generate tasks by category:
   ✓ Setup: documentation validation, contract verification
   ✓ Tests: contract tests, integration scenarios, user workflow validation
   ✓ Core: entity validation, API functionality verification
   ✓ Integration: CLI operations, format exports, batch processing
   ✓ Polish: performance validation, documentation completeness
4. Apply task rules:
   ✓ Different modules = mark [P] for parallel
   ✓ Same module = sequential validation
   ✓ Tests before validation (documentation-first approach)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness: All contracts tested, all entities validated, all workflows covered
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different modules, no dependencies)
- Include exact file paths for validation and testing

## Path Conventions
- **Existing codebase**: `knotty-lib/` (library), `knotty/tests/` (tests)
- **Documentation specs**: `specs/001-define-the-existing/`
- Tasks focus on validation and documentation rather than new implementation

## Phase 3.1: Setup and Preparation
- [ ] T001 Validate existing project structure matches implementation plan specifications in `specs/001-define-the-existing/plan.md`
- [ ] T002 Verify all Racket dependencies are available and test framework (RackUnit) is functional via `make test`
- [ ] T003 [P] Create contract validation test framework in `knotty/tests/contract/`

## Phase 3.2: Contract Tests (TDD Validation) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests validate existing API contracts match specifications and MUST FAIL if contracts are incomplete**
- [ ] T004 [P] Contract test for pattern creation API in `knotty/tests/contract/test_pattern_api.rkt` (validates `pattern.rkt` functions)
- [ ] T005 [P] Contract test for chart generation API in `knotty/tests/contract/test_chart_api.rkt` (validates `chart.rkt` functions)
- [ ] T006 [P] Contract test for CLI interface operations in `knotty/tests/contract/test_cli_api.rkt` (validates `cli.rkt` commands)
- [ ] T007 [P] Integration test for basic stockinette workflow in `knotty/tests/integration/test_stockinette_workflow.rkt`
- [ ] T008 [P] Integration test for colorwork pattern workflow in `knotty/tests/integration/test_colorwork_workflow.rkt`
- [ ] T009 [P] Integration test for complex cable pattern workflow in `knotty/tests/integration/test_cable_workflow.rkt`

## Phase 3.3: Entity Validation (ONLY after contract tests exist)
- [ ] T010 [P] Validate Pattern entity structure and validation rules in `knotty-lib/pattern.rkt`
- [ ] T011 [P] Validate Row entity structure and stitch count consistency in `knotty-lib/rows.rkt`
- [ ] T012 [P] Validate Stitch entity types and properties in `knotty-lib/stitch.rkt`
- [ ] T013 [P] Validate Chart entity generation and grid structure in `knotty-lib/chart.rkt`
- [ ] T014 [P] Validate Instructions entity text generation in `knotty-lib/stitch-instructions.rkt`
- [ ] T015 [P] Validate Yarn entity color management in `knotty-lib/yarn.rkt`
- [ ] T016 [P] Validate ExportFormat entity output generation in `knotty-lib/html.rkt`

## Phase 3.4: API Functionality Verification
- [ ] T017 Pattern validation error handling for invalid stitch counts and missing rows
- [ ] T018 Chart symbol mapping completeness for all stitch types in pattern library
- [ ] T019 HTML export interactive features and embedded CSS/JavaScript functionality
- [ ] T020 CLI format conversion accuracy across all supported input/output combinations
- [ ] T021 Knitspeak import/export round-trip integrity in `knotty-lib/knitspeak.rkt`

## Phase 3.5: Integration and Batch Processing
- [ ] T022 CLI batch processing validation with multiple pattern files
- [ ] T023 Performance testing with large patterns (200+ rows) for memory and time constraints
- [ ] T024 File I/O error handling for invalid pattern files and missing dependencies
- [ ] T025 Cross-platform compatibility testing (if multiple platforms available)

## Phase 3.6: User Scenario Validation
- [ ] T026 [P] Execute quickstart Example 1 (Basic Stockinette) and validate all outputs
- [ ] T027 [P] Execute quickstart Example 2 (Colorwork Pattern) and validate color accuracy
- [ ] T028 [P] Execute quickstart Example 3 (Complex Cable Pattern) and validate chart symbols
- [ ] T029 End-to-end workflow test: pattern creation → validation → chart → HTML export
- [ ] T030 Import workflow test: Knitspeak → Knotty → multiple export formats

## Phase 3.7: Documentation and Polish
- [ ] T031 [P] Verify all code examples in quickstart.md execute without errors
- [ ] T032 [P] Update API documentation to match current contract specifications
- [ ] T033 [P] Performance benchmarking and documentation of timing constraints
- [ ] T034 Error message clarity and helpfulness validation across all failure modes
- [ ] T035 Comprehensive test coverage report and gap analysis

## Dependencies
- Setup (T001-T003) before all other phases
- Contract tests (T004-T009) before entity validation (T010-T016)
- Entity validation before API verification (T017-T021)
- T017 blocks T019 (HTML export needs pattern validation)
- T018 blocks T019 (chart symbols needed for HTML)
- API verification before integration testing (T022-T025)
- All core validation before user scenarios (T026-T030)
- Core functionality before documentation polish (T031-T035)

## Parallel Execution Examples

### Contract Tests Launch (T004-T009)
```
Task: "Contract test for pattern creation API in knotty/tests/contract/test_pattern_api.rkt"
Task: "Contract test for chart generation API in knotty/tests/contract/test_chart_api.rkt"
Task: "Contract test for CLI interface operations in knotty/tests/contract/test_cli_api.rkt"
Task: "Integration test for basic stockinette workflow in knotty/tests/integration/test_stockinette_workflow.rkt"
Task: "Integration test for colorwork pattern workflow in knotty/tests/integration/test_colorwork_workflow.rkt"
Task: "Integration test for complex cable pattern workflow in knotty/tests/integration/test_cable_workflow.rkt"
```

### Entity Validation Launch (T010-T016)
```
Task: "Validate Pattern entity structure and validation rules in knotty-lib/pattern.rkt"
Task: "Validate Row entity structure and stitch count consistency in knotty-lib/rows.rkt"
Task: "Validate Stitch entity types and properties in knotty-lib/stitch.rkt"
Task: "Validate Chart entity generation and grid structure in knotty-lib/chart.rkt"
Task: "Validate Instructions entity text generation in knotty-lib/stitch-instructions.rkt"
Task: "Validate Yarn entity color management in knotty-lib/yarn.rkt"
Task: "Validate ExportFormat entity output generation in knotty-lib/html.rkt"
```

### User Scenario Validation Launch (T026-T028)
```
Task: "Execute quickstart Example 1 (Basic Stockinette) and validate all outputs"
Task: "Execute quickstart Example 2 (Colorwork Pattern) and validate color accuracy"
Task: "Execute quickstart Example 3 (Complex Cable Pattern) and validate chart symbols"
```

## Notes
- [P] tasks = different files/modules, no dependencies
- Focus on validation rather than new implementation
- Verify existing functionality matches documented contracts
- All tests should initially pass (existing codebase)
- Document any discrepancies between specs and implementation

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - pattern-api.md → T004, T010, T017 (pattern creation and validation)
   - chart-api.md → T005, T013, T018, T019 (chart generation and HTML export)
   - cli-api.md → T006, T020, T022 (CLI operations and batch processing)

2. **From Data Model**:
   - Pattern entity → T010 (structure validation)
   - Row entity → T011 (consistency validation)
   - Stitch entity → T012 (type validation)
   - Chart entity → T013 (generation validation)
   - Instructions entity → T014 (text generation)
   - Yarn entity → T015 (color management)
   - ExportFormat entity → T016 (output validation)

3. **From User Stories**:
   - Quickstart Example 1 → T007, T026 (basic workflow)
   - Quickstart Example 2 → T008, T027 (colorwork)
   - Quickstart Example 3 → T009, T028 (complex patterns)

4. **Ordering**:
   - Setup → Contract Tests → Entity Validation → API Verification → Integration → User Scenarios → Polish
   - Dependencies ensure sequential execution where needed

## Validation Checklist
*GATE: Checked by main() before returning*

- [x] All contracts have corresponding tests (T004-T006)
- [x] All entities have validation tasks (T010-T016)
- [x] All tests come before implementation verification
- [x] Parallel tasks truly independent (different files/modules)
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] User scenarios covered comprehensively (T026-T030)
- [x] Documentation validation included (T031-T035)