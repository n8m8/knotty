# Implementation Plan: Knotty Domain-Specific Language for Knitting Patterns

**Branch**: `001-define-the-existing` | **Date**: 2025-09-26 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-define-the-existing/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   ✓ Loaded: Knotty DSL for knitting patterns with 15 functional requirements
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   ✓ Project Type detected: single (Racket library with CLI)
   ✓ Structure Decision: Option 1 (single project)
3. Fill the Constitution Check section based on the content of the constitution document.
   ✓ Constitution template loaded (no specific constraints for this project)
4. Evaluate Constitution Check section below
   ✓ No violations detected
   ✓ Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   ✓ All technical details already known from existing codebase
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file
7. Re-evaluate Constitution Check section
   ✓ Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

## Summary
Knotty is an existing domain-specific language for knitting patterns built in Typed Racket. It enables pattern designers to write structured, human-readable knitting patterns that generate interactive HTML charts and written instructions. The system supports both textured stitches and colorwork, includes validation, and offers multi-format export capabilities including HTML, Knitspeak, and graphics.

## Technical Context
**Language/Version**: Typed Racket (latest stable)
**Primary Dependencies**: Racket standard libraries, Saxon XSLT processor, threading, syntax parsing
**Storage**: File-based (.rkt pattern files, exported HTML/graphics)
**Testing**: RackUnit test framework (module+ test)
**Target Platform**: Cross-platform (Linux, macOS, Windows via Racket)
**Project Type**: single - Racket library with CLI executable
**Performance Goals**: Pattern compilation <5s for typical patterns, HTML generation <10s
**Constraints**: Memory-efficient for large colorwork patterns, CLI interface required
**Scale/Scope**: Individual pattern files, patterns up to 1000+ rows, batch processing support

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: PASS - No constitution constraints apply to this documentation exercise of existing features.

## Project Structure

### Documentation (this feature)
```
specs/001-define-the-existing/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# Option 1: Single project (CURRENT STRUCTURE)
knotty-lib/              # Main library modules
├── main.rkt            # Public API entry point
├── pattern.rkt         # Core pattern definition
├── stitch.rkt          # Stitch operations
├── chart.rkt           # Chart generation
├── html.rkt            # HTML export
├── knitspeak.rkt       # Knitspeak import/export
├── cli.rkt             # Command-line interface
├── colors.rkt          # Color management
└── [other modules]

knotty/                 # Documentation and tests
├── tests/              # Test suite
└── scribblings/        # Documentation source

specs/                  # Feature specifications
└── 001-define-the-existing/
```

**Structure Decision**: Option 1 - Single project (existing Racket library structure maintained)

## Phase 0: Outline & Research

Since this is documenting existing functionality, all technical details are already known from the codebase analysis. No NEEDS CLARIFICATION items exist.

**Research Summary**:
- **Racket/Typed Racket**: Chosen for DSL capabilities, strong typing, pattern matching
- **Module System**: Racket's module system provides clear API boundaries
- **CLI Design**: Command-line interface follows Unix conventions
- **Export Formats**: HTML with embedded CSS/JS, Knitspeak text format, PNG graphics
- **Validation**: Pattern consistency checks built into core data structures

**Output**: research.md (comprehensive technology analysis)

## Phase 1: Design & Contracts

**Key Entities Identified**:
- Pattern: Main container with metadata and rows
- Row: Sequence of stitches with numbering
- Stitch: Individual knitting operations with properties
- Chart: Visual representation for display
- Instructions: Text-based knitting directions
- Yarn: Color and material specifications
- Export Format: Output format specifications

**API Contracts**:
- Pattern creation and validation
- Chart generation from patterns
- HTML export with interactive features
- Knitspeak import/export
- Command-line interface operations

**Output**: data-model.md, /contracts/*, quickstart.md, CLAUDE.md

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Document existing API contracts from pattern.rkt, chart.rkt, html.rkt
- Create validation test scenarios from functional requirements
- Generate user workflow tests from acceptance scenarios
- Document CLI interface contracts from cli.rkt
- Create integration tests for export formats

**Ordering Strategy**:
- Core data model documentation first (Pattern, Row, Stitch)
- API contract documentation (creation, validation, export)
- User workflow validation tests
- Integration tests for CLI and export formats

**Estimated Output**: 20-25 documentation and validation tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)
**Phase 4**: Implementation (execute tasks.md following constitutional principles)
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

No constitutional violations identified for this documentation task.

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented

---
*Based on Constitution template - See `/.claude/.specify/memory/constitution.md`*