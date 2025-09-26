# CLI API Contract

**Module**: `knotty-lib/cli.rkt`
**Purpose**: Command-line interface for pattern processing and conversion

## Command Structure

### Basic Usage
```bash
knotty <command> [options] <input-file> [output-file]
```

### Global Options
- `--help`, `-h`: Show help information
- `--version`, `-v`: Display version information
- `--verbose`: Enable detailed output
- `--quiet`: Suppress non-error output

## Commands

### Convert Command

#### `convert`
```bash
knotty convert [options] <input-file> [output-file]
```
**Purpose**: Convert patterns between different formats
**Parameters**:
- `input-file`: Source pattern file (.rkt, .knitspeak, or image)
- `output-file`: Destination file (format determined by extension)

**Options**:
- `--format`, `-f`: Output format (html, knitspeak, svg, png)
- `--style`: Chart style (modern, traditional, international)
- `--width`: Output width for graphics formats
- `--height`: Output height for graphics formats
- `--interactive`: Enable interactive features (HTML only)

**Examples**:
```bash
knotty convert pattern.rkt pattern.html
knotty convert --format svg --width 800 pattern.rkt chart.svg
knotty convert --style traditional pattern.knitspeak pattern.html
```

### Validate Command

#### `validate`
```bash
knotty validate [options] <pattern-file>
```
**Purpose**: Validate pattern syntax and consistency
**Parameters**:
- `pattern-file`: Pattern file to validate (.rkt format)

**Options**:
- `--strict`: Enable strict validation mode
- `--fix`: Attempt to fix common issues
- `--report`: Generate detailed validation report

**Exit Codes**:
- `0`: Pattern is valid
- `1`: Validation errors found
- `2`: File not found or unreadable

**Examples**:
```bash
knotty validate pattern.rkt
knotty validate --strict --report complex-pattern.rkt
```

### Chart Command

#### `chart`
```bash
knotty chart [options] <pattern-file> [chart-file]
```
**Purpose**: Generate standalone chart from pattern
**Parameters**:
- `pattern-file`: Source pattern file (.rkt format)
- `chart-file`: Output chart file (optional, stdout if omitted)

**Options**:
- `--format`: Chart format (svg, png, html)
- `--size`: Chart size (small, medium, large, or WIDTHxHEIGHT)
- `--legend`: Legend position (top, bottom, left, right, none)
- `--grid`: Show grid lines (true, false)
- `--numbers`: Show row/stitch numbers (true, false)

**Examples**:
```bash
knotty chart --format svg pattern.rkt chart.svg
knotty chart --size large --legend bottom pattern.rkt chart.html
```

### Import Command

#### `import`
```bash
knotty import [options] <source-file> <output-file>
```
**Purpose**: Import patterns from external formats
**Parameters**:
- `source-file`: External format file (Knitspeak, image)
- `output-file`: Knotty format output file (.rkt)

**Options**:
- `--type`: Source format (knitspeak, image, auto)
- `--encoding`: Text encoding for Knitspeak files
- `--colors`: Color detection method for images (auto, manual)
- `--threshold`: Color similarity threshold for image import

**Examples**:
```bash
knotty import pattern.knitspeak pattern.rkt
knotty import --type image --colors auto fairisle.png pattern.rkt
```

## Input/Output Formats

### Supported Input Formats
- `.rkt`: Native Knotty pattern files
- `.knitspeak`: Knitspeak text format
- `.png`, `.jpg`, `.gif`: Image files for Fair Isle import

### Supported Output Formats
- `.html`: Interactive HTML charts with instructions
- `.svg`: Scalable vector graphics
- `.png`: Raster image charts
- `.knitspeak`: Knitspeak text format
- `.rkt`: Native Knotty format

### Format Auto-Detection
File format determined by extension, with fallback to content analysis:
- Text files scanned for Knitspeak syntax
- Binary files checked for image headers
- Unknown formats trigger error with suggestions

## Configuration

### Configuration File
Optional `~/.knotty/config.rkt` file for default settings:
```racket
(define default-chart-style 'modern)
(define default-output-width 800)
(define enable-color-validation #t)
(define prefer-interactive-html #t)
```

### Environment Variables
- `KNOTTY_CONFIG`: Override config file location
- `KNOTTY_VERBOSE`: Enable verbose mode (0/1)
- `KNOTTY_TEMP_DIR`: Temporary file directory

## Error Handling

### Exit Codes
- `0`: Success
- `1`: General error (invalid pattern, conversion failure)
- `2`: File system error (file not found, permission denied)
- `3`: Invalid command line arguments
- `4`: Configuration error

### Error Messages
All errors written to stderr with descriptive messages:
```
Error: Pattern validation failed
  Row 5: Stitch count mismatch (expected 8, got 6)
  Line 42 in pattern.rkt

Error: Unsupported output format 'pdf'
  Supported formats: html, svg, png, knitspeak
  Use --help for usage information

Warning: Large pattern detected (500 rows)
  Chart generation may take several minutes
  Use --verbose to monitor progress
```

## Performance Considerations

### Processing Time
- Simple patterns (< 50 rows): < 1 second
- Medium patterns (50-200 rows): 1-5 seconds
- Large patterns (200+ rows): 5-30 seconds
- Image imports: Variable based on resolution and complexity

### Memory Usage
- Pattern loading: Linear in file size
- Chart generation: Quadratic in pattern dimensions
- Format conversion: Temporary buffers for output

### Optimization Flags
- `--fast`: Reduce quality for speed
- `--memory-limit`: Set maximum memory usage
- `--parallel`: Enable parallel processing for batch operations

## Contract Tests

### Test Cases Required
1. **Basic conversion**: .rkt to .html conversion
2. **Format validation**: Each supported input/output format
3. **Error handling**: Invalid files, unsupported formats
4. **Large patterns**: Performance with complex patterns
5. **Batch processing**: Multiple files
6. **Configuration**: Config file and environment variables
7. **Image import**: Fair Isle pattern generation
8. **Interactive features**: HTML output validation

### Test Commands
```bash
# Basic functionality tests
knotty convert test-pattern.rkt test-output.html
knotty validate invalid-pattern.rkt
knotty chart --format svg pattern.rkt chart.svg

# Error condition tests
knotty convert nonexistent.rkt output.html  # Should exit 2
knotty convert pattern.rkt output.invalid   # Should exit 1
knotty validate malformed.rkt               # Should exit 1

# Performance tests
knotty convert large-pattern.rkt --fast output.html
knotty chart --size 2000x2000 pattern.rkt huge-chart.png
```

## Integration Points

### Dependencies
- `pattern.rkt`: Pattern parsing and validation
- `chart.rkt`: Chart generation
- `html.rkt`: HTML export functionality
- `knitspeak.rkt`: Knitspeak import/export
- `png.rkt`: Image processing

### External Tools
- Saxon XSLT processor (for advanced HTML generation)
- Image processing libraries (for import functionality)
- Font rendering (for chart symbols)

### File System
- Read access to pattern files
- Write access to output directories
- Temporary file creation for processing
- Configuration file access

This contract ensures consistent, reliable command-line operation while providing comprehensive format support and clear error reporting for all user interactions.