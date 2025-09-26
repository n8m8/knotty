# Pattern API Contract

**Module**: `knotty-lib/pattern.rkt`
**Purpose**: Core pattern creation, validation, and manipulation

## Functions

### Pattern Creation

#### `pattern`
```racket
(pattern [options ...] row-spec ...)
→ Pattern
```
**Purpose**: Creates and validates a new knitting pattern
**Parameters**:
- `options`: Optional keyword arguments (name, technique, form)
- `row-spec ...`: Variable number of row specifications

**Validation**:
- All rows must be valid Row objects
- Row numbers must be consecutive starting from 1
- Stitch counts must be consistent across rows
- At least one row required

**Returns**: Valid Pattern object
**Throws**: `exn:fail?` if validation fails

**Example**:
```racket
(pattern
  [name "Simple Stockinette"]
  (rows 1 3) k8
  (rows 2 4) p8
  (row 5) bind-off)
```

### Row Creation

#### `row` / `rows`
```racket
(row number-spec stitch-spec ...)
→ Row
(rows number-spec stitch-spec ...)
→ List[Row]
```
**Purpose**: Creates row specifications for patterns
**Parameters**:
- `number-spec`: Single integer or list of integers
- `stitch-spec ...`: Sequence of stitch specifications

**Validation**:
- Numbers must be positive integers
- Stitch specifications must be valid
- Total stitch count must be computable

**Returns**: Row object or list of Row objects
**Throws**: `exn:fail?` for invalid specifications

### Pattern Validation

#### `validate-pattern`
```racket
(validate-pattern pattern)
→ (U Pattern exn:fail?)
```
**Purpose**: Validates pattern consistency and correctness
**Parameters**:
- `pattern`: Pattern object to validate

**Checks**:
- Row number sequence is consecutive
- Stitch counts match between adjacent rows
- All yarn colors are defined
- Stitch types are valid

**Returns**: Original pattern if valid
**Throws**: `exn:fail?` with descriptive error message

### Pattern Queries

#### `pattern-row-count`
```racket
(pattern-row-count pattern)
→ Natural
```
**Purpose**: Returns total number of rows in pattern
**Parameters**:
- `pattern`: Pattern object

**Returns**: Number of rows as natural number

#### `pattern-stitch-count`
```racket
(pattern-stitch-count pattern)
→ Natural
```
**Purpose**: Returns stitch count per row (assumes consistent)
**Parameters**:
- `pattern`: Pattern object

**Returns**: Number of stitches per row
**Throws**: `exn:fail?` if stitch counts are inconsistent

#### `pattern-yarn-colors`
```racket
(pattern-yarn-colors pattern)
→ (Listof YarnColor)
```
**Purpose**: Returns list of all yarn colors used in pattern
**Parameters**:
- `pattern`: Pattern object

**Returns**: List of unique yarn color identifiers

## Error Handling

### Exception Types
- `exn:fail:contract?`: Invalid function arguments
- `exn:fail:user?`: Pattern validation failures
- `exn:fail:read?`: Malformed pattern syntax

### Common Error Messages
- "Row numbers must be consecutive starting from 1"
- "Stitch count mismatch: row N has X stitches, expected Y"
- "Undefined yarn color: COLOR_NAME"
- "Invalid stitch type: STITCH_TYPE"
- "Pattern must contain at least one row"

## Contract Tests

### Test Cases Required
1. **Valid pattern creation**: Standard multi-row pattern
2. **Row validation**: Consecutive numbering enforcement
3. **Stitch count consistency**: Adjacent row compatibility
4. **Yarn color validation**: Undefined color detection
5. **Empty pattern rejection**: Minimum row requirement
6. **Invalid stitch types**: Unsupported stitch detection
7. **Short row handling**: Stitch count exception cases
8. **Complex patterns**: Large patterns with multiple techniques

### Test Data
```racket
;; Valid basic pattern
(define test-pattern-valid
  (pattern
    [name "Test Pattern"]
    (row 1) k10
    (row 2) p10
    (row 3) k10
    (row 4) p10))

;; Invalid stitch count
(define test-pattern-invalid-count
  (pattern
    [name "Invalid Count"]
    (row 1) k10
    (row 2) p8))  ; Should fail

;; Missing row number
(define test-pattern-missing-row
  (pattern
    [name "Missing Row"]
    (row 1) k10
    (row 3) p10))  ; Should fail - no row 2
```

## Integration Points

### Dependencies
- `stitch.rkt`: Stitch type definitions and validation
- `yarn.rkt`: Yarn color specifications
- `util.rkt`: Common utility functions

### Used By
- `chart.rkt`: Chart generation from patterns
- `html.rkt`: HTML export functionality
- `knitspeak.rkt`: Knitspeak conversion
- `cli.rkt`: Command-line interface

## Performance Characteristics

### Time Complexity
- Pattern creation: O(n) where n = total stitches
- Validation: O(n) where n = total stitches
- Queries: O(1) for cached properties, O(n) for computed values

### Memory Usage
- Immutable structures: Safe for concurrent access
- Pattern storage: Linear in total stitch count
- Validation overhead: Minimal additional allocation

This contract ensures reliable pattern creation and manipulation while maintaining the functional programming principles of the Racket implementation.