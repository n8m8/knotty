# Data Model: Knotty DSL Entities

**Feature**: Knotty Domain-Specific Language for Knitting Patterns
**Phase**: 1 - Design & Contracts
**Date**: 2025-09-26

## Core Entities

### Pattern
**Purpose**: Main container representing a complete knitting design
**Fields**:
- `name`: String - Human-readable pattern name
- `technique`: Technique (hand | machine) - Knitting method
- `form`: Form (flat | circular) - Construction style
- `rows`: List[Row] - Ordered sequence of pattern rows
- `options`: Options - Global pattern settings
- `yarn-specs`: List[Yarn] - Color and material definitions

**Validation Rules**:
- Name must be non-empty string
- Rows must form consecutive sequence starting at 1
- Stitch counts must be consistent across rows (except short rows)
- At least one row required

**State Transitions**:
1. Created → Validated (all rows and stitches checked)
2. Validated → Compiled (chart and instructions generated)
3. Compiled → Exported (output formats created)

### Row
**Purpose**: Individual horizontal line of stitches within a pattern
**Fields**:
- `number`: Integer - Row identifier (1-based)
- `stitches`: List[Stitch] - Sequence of knitting operations
- `yarn-color`: YarnColor - Active yarn for this row
- `direction`: Direction (knit | purl) - Default stitch type
- `is-short-row`: Boolean - Whether row breaks normal stitch count

**Validation Rules**:
- Row number must be positive integer
- Stitches list cannot be empty
- Stitch count must match previous row (unless short row)
- Yarn color must be defined in pattern yarn specs

**Relationships**:
- Belongs to exactly one Pattern
- Contains one or more Stitches
- References YarnColor from pattern specs

### Stitch
**Purpose**: Fundamental knitting operation with specific properties
**Fields**:
- `type`: StitchType - Operation category (knit, purl, yarn-over, decrease, etc.)
- `count`: Integer - Number of times to repeat this stitch
- `modifier`: StitchModifier - Special properties (through-back-loop, etc.)
- `yarn-color`: YarnColor - Specific color for this stitch (overrides row default)

**Validation Rules**:
- Type must be valid StitchType enum value
- Count must be positive integer
- Modifier combinations must be valid for stitch type
- Yarn color must exist in pattern specifications

**Relationships**:
- Belongs to exactly one Row
- May reference YarnColor for colorwork

### Chart
**Purpose**: Visual grid representation of the pattern
**Fields**:
- `pattern`: Pattern - Source pattern for visualization
- `grid`: Grid[ChartCell] - 2D array of visual symbols
- `legend`: Map[StitchType, Symbol] - Symbol mapping for stitches
- `dimensions`: Dimensions - Width and height in stitches/rows

**Validation Rules**:
- Grid dimensions must match pattern row/stitch counts
- All stitch types must have legend entries
- Symbols must be distinct and readable

**Relationships**:
- Generated from exactly one Pattern
- Contains ChartCell elements mapping to Stitches

### Instructions
**Purpose**: Written text format describing pattern execution
**Fields**:
- `pattern`: Pattern - Source pattern for instructions
- `sections`: List[InstructionSection] - Organized text blocks
- `abbreviations`: Map[String, String] - Stitch abbreviation definitions
- `notes`: List[String] - Special instructions and tips

**Validation Rules**:
- All stitches must have corresponding abbreviations
- Instructions must cover all pattern rows
- Section order must match pattern execution order

**Relationships**:
- Generated from exactly one Pattern
- References all Stitches through abbreviations

### Yarn
**Purpose**: Color and material specifications for pattern
**Fields**:
- `id`: YarnColor - Unique identifier within pattern
- `name`: String - Human-readable color name
- `hex-color`: String - Hexadecimal color code for display
- `material`: String - Yarn composition description
- `weight`: YarnWeight - Standardized yarn thickness

**Validation Rules**:
- ID must be unique within pattern
- Hex color must be valid 6-digit hexadecimal
- Material description should be non-empty
- Weight must be standard yarn weight category

**Relationships**:
- Referenced by Rows and Stitches
- Defined at Pattern level

### ExportFormat
**Purpose**: Output format specifications and metadata
**Fields**:
- `type`: FormatType (HTML | Knitspeak | PNG | SVG) - Output format
- `settings`: FormatSettings - Format-specific configuration
- `metadata`: Map[String, String] - Additional format information

**Validation Rules**:
- Type must be supported format
- Settings must be valid for chosen format type
- Required metadata fields must be present

**Relationships**:
- Applied to Pattern for export operations
- Configures Chart and Instructions generation

## Entity Relationships

```
Pattern 1 ──→ * Row 1 ──→ * Stitch
   ↓              ↓         ↓
   │              │         │
   ↓              ↓         ↓
Pattern 1 ──→ * Yarn ←──── * (references)
   ↓
   │
   ↓
Pattern 1 ──→ 1 Chart
   ↓
   │
   ↓
Pattern 1 ──→ 1 Instructions
   ↓
   │
   ↓
Pattern 1 ──→ * ExportFormat
```

## Data Validation Matrix

| Entity | Structural | Consistency | Business Rules |
|--------|------------|-------------|----------------|
| Pattern | ✓ Required fields | ✓ Row sequence | ✓ Min 1 row |
| Row | ✓ Number + stitches | ✓ Stitch count | ✓ Valid yarn refs |
| Stitch | ✓ Type + count | ✓ Modifier compat | ✓ Positive count |
| Chart | ✓ Grid dimensions | ✓ Pattern mapping | ✓ Symbol uniqueness |
| Instructions | ✓ All sections | ✓ Abbrev coverage | ✓ Complete coverage |
| Yarn | ✓ ID + hex color | ✓ Unique IDs | ✓ Valid hex format |

## Type Definitions

### Enums
```
StitchType: knit | purl | yarn-over | knit-2-together |
           slip-slip-knit | cable-front | cable-back | ...

Technique: hand | machine

Form: flat | circular

Direction: knit | purl

YarnWeight: lace | sport | dk | worsted | bulky | ...

FormatType: HTML | Knitspeak | PNG | SVG
```

### Complex Types
```
Dimensions: { width: Integer, height: Integer }
ChartCell: { symbol: String, stitch-type: StitchType, color: YarnColor }
InstructionSection: { title: String, content: String, row-range: (Integer, Integer) }
FormatSettings: { varies by FormatType }
```

## Persistence Model

### File Formats
- **Source**: `.rkt` files containing pattern definitions
- **Compiled**: In-memory structures during processing
- **Export**: Format-specific output files

### Storage Strategy
- Patterns stored as human-readable Racket code
- No database required for individual patterns
- Batch processing operates on file collections
- Export artifacts cached for performance

This data model supports all functional requirements while maintaining the immutable, functional design principles of the Racket implementation.