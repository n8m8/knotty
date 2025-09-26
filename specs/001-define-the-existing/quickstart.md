# Quickstart Guide: Knotty DSL

**Feature**: Knotty Domain-Specific Language for Knitting Patterns
**Purpose**: Rapid validation of core functionality and user workflows
**Audience**: New users, integration testing, feature validation

## Prerequisites

### System Requirements
- Racket 8.0+ installed with DrRacket
- Git for repository access
- Text editor (DrRacket recommended)

### Installation Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/t0mpr1c3/knotty.git
   cd knotty
   ```

2. Install the Knotty package:
   ```bash
   raco pkg install --link knotty-lib/
   ```

3. Verify installation:
   ```bash
   raco test knotty-lib/
   ```

## Quick Start Examples

### Example 1: Basic Stockinette Pattern

**File**: `quickstart-stockinette.rkt`
```racket
#lang sweet-exp typed/racket
require "knotty-lib/main.rkt"

define
  basic-stockinette
  pattern
    [name "Basic Stockinette"]
    [technique 'hand]
    [form 'flat]
    rows(1 3 5) k10    ; Knit rows
    rows(2 4 6) p10    ; Purl rows

;; Generate and display chart
chart basic-stockinette

;; Generate written instructions
text basic-stockinette
```

**Expected Output**:
- Interactive chart showing knit/purl symbols
- Written instructions: "Row 1: Knit 10. Row 2: Purl 10..." etc.
- Pattern validation passes

**Validation Steps**:
1. Open file in DrRacket
2. Click "Run" button
3. Verify chart displays correctly
4. Check written instructions are readable
5. Confirm no error messages

### Example 2: Colorwork Pattern

**File**: `quickstart-colorwork.rkt`
```racket
#lang sweet-exp typed/racket
require "knotty-lib/main.rkt"

define
  simple-stripes
  pattern
    [name "Simple Stripes"]
    [technique 'hand]
    [form 'flat]
    ;; Yarn definitions
    yarn('A "Red" #:color "#FF0000")
    yarn('B "Blue" #:color "#0000FF")
    ;; Pattern rows
    rows(1) k8 #:yarn 'A
    rows(2) p8 #:yarn 'A
    rows(3) k8 #:yarn 'B
    rows(4) p8 #:yarn 'B

;; Export to HTML with colors
html simple-stripes #:file "stripes.html"
```

**Expected Output**:
- HTML file with colored chart
- Color legend showing red and blue yarns
- Chart displays alternating stripe pattern

**Validation Steps**:
1. Run the pattern code
2. Open generated `stripes.html` in browser
3. Verify colors match specifications
4. Check interactive features work (hover, click)
5. Confirm color legend is accurate

### Example 3: Complex Pattern with Multiple Stitches

**File**: `quickstart-complex.rkt`
```racket
#lang sweet-exp typed/racket
require "knotty-lib/main.rkt"

define
  cable-pattern
  pattern
    [name "Simple Cable"]
    [technique 'hand]
    [form 'flat]
    ;; Setup row
    row(1) p2 k4 p2
    ;; Cable cross row
    row(2) k2 c4f k2    ; c4f = cable 4 front
    ;; Regular rows
    rows(3 5 7) p2 k4 p2
    rows(4 6 8) k2 p4 k2

;; Validate pattern consistency
validate-pattern cable-pattern

;; Generate multiple export formats
html cable-pattern #:file "cable.html"
svg cable-pattern #:file "cable.svg"
```

**Expected Output**:
- Pattern validation success
- HTML chart with cable symbols
- SVG file for printing
- Written instructions with cable abbreviations

**Validation Steps**:
1. Verify pattern validation passes
2. Check HTML chart shows cable symbols correctly
3. Confirm SVG file opens and displays properly
4. Validate stitch count consistency across rows
5. Check cable instructions are clear

## Command Line Usage

### Basic Conversion
```bash
# Convert pattern to HTML
knotty convert quickstart-stockinette.rkt stockinette.html

# Validate pattern syntax
knotty validate quickstart-complex.rkt

# Generate chart only
knotty chart --format svg quickstart-colorwork.rkt stripes.svg
```

**Expected Results**:
- Conversion completes without errors
- Validation reports "Pattern is valid"
- Chart file generated with correct dimensions

### Batch Processing
```bash
# Convert multiple patterns
for pattern in *.rkt; do
  knotty convert "$pattern" "${pattern%.rkt}.html"
done

# Validate all patterns
knotty validate *.rkt
```

**Expected Results**:
- All patterns convert successfully
- No validation errors reported
- Output files created with correct names

## Integration Testing Scenarios

### Scenario 1: Pattern Designer Workflow
**User Story**: Pattern designer creates new design from scratch

**Steps**:
1. Create new `.rkt` file with pattern syntax
2. Run pattern in DrRacket to see immediate feedback
3. Iterate on design based on visual chart
4. Export to HTML for sharing
5. Validate final pattern for consistency

**Success Criteria**:
- Pattern creation is intuitive and fast
- Visual feedback helps with design decisions
- Export process is reliable and produces quality output
- Validation catches errors early in process

### Scenario 2: Import and Export Workflow
**User Story**: User imports existing Knitspeak pattern and exports to multiple formats

**Steps**:
1. Obtain Knitspeak pattern file
2. Import using CLI: `knotty import pattern.knitspeak pattern.rkt`
3. Open in DrRacket and review imported pattern
4. Make any necessary adjustments
5. Export to HTML, SVG, and back to Knitspeak

**Success Criteria**:
- Import preserves pattern structure and meaning
- Imported pattern displays correctly in chart
- Round-trip conversion maintains pattern integrity
- Multiple export formats are consistent

### Scenario 3: Large Pattern Performance
**User Story**: Advanced user works with complex, large patterns

**Steps**:
1. Create or load pattern with 200+ rows
2. Generate chart and measure time
3. Export to HTML and test browser performance
4. Validate pattern and check for memory usage
5. Batch process multiple large patterns

**Success Criteria**:
- Chart generation completes in reasonable time (<30s)
- HTML export loads smoothly in browser
- Memory usage remains manageable
- Batch processing handles multiple files reliably

## Troubleshooting Common Issues

### Issue: Pattern Validation Fails
**Symptoms**: Error messages about stitch counts or row numbers
**Solution**:
1. Check row numbering is consecutive starting from 1
2. Verify stitch counts match between adjacent rows
3. Ensure all yarn colors are defined before use
4. Check stitch syntax matches documented format

### Issue: Chart Not Displaying
**Symptoms**: Blank or malformed chart output
**Solution**:
1. Verify pattern is valid and complete
2. Check all stitch types have symbol mappings
3. Ensure chart dimensions are reasonable
4. Try different export format (SVG vs HTML vs PNG)

### Issue: HTML Export Problems
**Symptoms**: HTML file doesn't open or missing features
**Solution**:
1. Check file permissions and location
2. Verify browser supports required features
3. Try opening in different browser
4. Check console for JavaScript errors

### Issue: Performance Problems
**Symptoms**: Slow generation or high memory usage
**Solution**:
1. Break large patterns into smaller sections
2. Use simplified chart styles for large patterns
3. Close unnecessary applications to free memory
4. Consider using CLI batch mode for efficiency

## Success Validation Checklist

### Core Functionality
- [ ] Pattern creation with multiple stitch types works
- [ ] Chart generation produces readable output
- [ ] HTML export includes interactive features
- [ ] Pattern validation catches common errors
- [ ] CLI commands execute without errors

### User Experience
- [ ] DrRacket integration is smooth and responsive
- [ ] Error messages are helpful and actionable
- [ ] Documentation examples work as described
- [ ] Export formats are suitable for intended use
- [ ] Performance is acceptable for typical patterns

### Integration
- [ ] Installation process completes successfully
- [ ] All dependencies are available and working
- [ ] File I/O operations work reliably
- [ ] Batch processing handles multiple files
- [ ] Import/export preserves pattern integrity

This quickstart guide provides rapid validation of the Knotty DSL's core capabilities while serving as practical documentation for new users.