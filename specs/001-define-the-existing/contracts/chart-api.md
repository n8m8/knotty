# Chart API Contract

**Module**: `knotty-lib/chart.rkt`
**Purpose**: Visual chart generation from knitting patterns

## Functions

### Chart Generation

#### `make-chart`
```racket
(make-chart pattern [options ...])
→ Chart
```
**Purpose**: Generates visual chart representation from pattern
**Parameters**:
- `pattern`: Valid Pattern object
- `options`: Optional chart formatting settings

**Validation**:
- Pattern must be valid and complete
- Chart dimensions must be computable
- All stitch types must have visual symbols

**Returns**: Chart object with grid and legend
**Throws**: `exn:fail?` if chart cannot be generated

#### `chart->svg`
```racket
(chart->svg chart [width height])
→ String
```
**Purpose**: Converts chart to SVG format
**Parameters**:
- `chart`: Chart object
- `width`, `height`: Optional dimensions in pixels

**Returns**: SVG markup as string
**Throws**: `exn:fail?` if conversion fails

#### `chart->html`
```racket
(chart->html chart [interactive?])
→ String
```
**Purpose**: Converts chart to HTML format
**Parameters**:
- `chart`: Chart object
- `interactive?`: Boolean for interactive features

**Returns**: HTML markup with embedded CSS/JS
**Throws**: `exn:fail?` if conversion fails

### Chart Queries

#### `chart-dimensions`
```racket
(chart-dimensions chart)
→ (Values Natural Natural)
```
**Purpose**: Returns chart width and height
**Parameters**:
- `chart`: Chart object

**Returns**: Width and height in stitches/rows

#### `chart-legend`
```racket
(chart-legend chart)
→ (HashTable StitchType Symbol)
```
**Purpose**: Returns mapping of stitch types to visual symbols
**Parameters**:
- `chart`: Chart object

**Returns**: Hash table of stitch symbol mappings

#### `chart-cell`
```racket
(chart-cell chart row-index stitch-index)
→ ChartCell
```
**Purpose**: Returns specific cell from chart grid
**Parameters**:
- `chart`: Chart object
- `row-index`: Zero-based row index
- `stitch-index`: Zero-based stitch index

**Returns**: ChartCell with symbol and metadata
**Throws**: `exn:fail?` if indices out of bounds

### Chart Validation

#### `validate-chart`
```racket
(validate-chart chart)
→ (U Chart exn:fail?)
```
**Purpose**: Validates chart consistency and completeness
**Parameters**:
- `chart`: Chart object to validate

**Checks**:
- Grid dimensions match pattern dimensions
- All cells have valid symbols
- Legend covers all stitch types in pattern
- Symbol mappings are unique and readable

**Returns**: Original chart if valid
**Throws**: `exn:fail?` with validation error details

## Chart Options

### Formatting Options
```racket
(make-chart pattern
  #:style 'modern          ; Symbol style: modern, traditional, international
  #:color-scheme 'high-contrast  ; Color scheme for colorwork
  #:grid-lines? #t         ; Show grid lines
  #:row-numbers? #t        ; Show row numbers
  #:stitch-numbers? #f     ; Show stitch numbers
  #:legend-position 'right ; Legend placement
  #:scale 1.0              ; Chart scaling factor
)
```

### Export Options
```racket
(chart->svg chart
  #:width 800              ; Output width in pixels
  #:height 600             ; Output height in pixels
  #:background-color "white" ; Background color
  #:border? #t             ; Chart border
)

(chart->html chart
  #:interactive? #t        ; Enable click/hover features
  #:responsive? #t         ; Responsive design
  #:theme 'light           ; Color theme
  #:embed-fonts? #t        ; Include font definitions
)
```

## Error Handling

### Exception Types
- `exn:fail:contract?`: Invalid function arguments
- `exn:fail:user?`: Chart generation failures
- `exn:fail:filesystem?`: File I/O errors for export

### Common Error Messages
- "Pattern validation failed: DETAILS"
- "Unknown stitch type: STITCH_TYPE"
- "Chart dimensions exceed maximum: WIDTHxHEIGHT"
- "Symbol mapping conflict for stitch type: TYPE"
- "Invalid chart coordinates: (ROW, STITCH)"

## Contract Tests

### Test Cases Required
1. **Basic chart generation**: Simple stockinette pattern
2. **Complex pattern charts**: Multiple stitch types and colors
3. **Large pattern handling**: Performance with 100+ rows
4. **Symbol uniqueness**: Ensure no symbol conflicts
5. **Colorwork charts**: Multiple yarn colors display
6. **Export format validation**: SVG and HTML output
7. **Interactive features**: Click/hover functionality
8. **Edge cases**: Single row, single stitch patterns

### Test Data
```racket
;; Simple pattern for chart testing
(define test-chart-pattern
  (pattern
    [name "Chart Test"]
    (row 1) k4 p4
    (row 2) p4 k4
    (row 3) k4 p4
    (row 4) p4 k4))

;; Expected chart dimensions
(define expected-width 8)
(define expected-height 4)

;; Expected legend entries
(define expected-legend
  (hash 'knit "□"
        'purl "•"))
```

## Performance Characteristics

### Time Complexity
- Chart generation: O(rows × stitches)
- SVG export: O(rows × stitches)
- HTML export: O(rows × stitches) + template processing
- Cell queries: O(1)

### Memory Usage
- Chart storage: O(rows × stitches) for grid
- Symbol cache: O(unique stitch types)
- Export buffers: Temporary allocation for output generation

### Optimization Notes
- Grid computed lazily for large patterns
- Symbol rendering cached for repeated exports
- Interactive HTML uses efficient DOM updates

## Integration Points

### Dependencies
- `pattern.rkt`: Pattern data structures
- `stitch.rkt`: Stitch type definitions and properties
- `colors.rkt`: Color management and conversion
- `util.rkt`: Common utility functions

### Used By
- `html.rkt`: HTML export with embedded charts
- `gui.rkt`: Interactive chart display
- `cli.rkt`: Command-line chart generation

### External Resources
- Symbol font files for traditional charts
- CSS templates for HTML export
- SVG templates for vector graphics

This contract ensures reliable chart generation while maintaining visual consistency and supporting multiple output formats for different use cases.