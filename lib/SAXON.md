# Saxon XSLT Processor Integration

## Overview

This directory contains the Saxon-HE (Home Edition) XSLT processor, which provides XSLT 2.0/3.0 and XPath 2.0/3.0 support for advanced chart generation features in the Knotty DSL project.

## Current Version

- **Saxon-HE Version**: 12.9
- **JAR File**: `saxon-he-12.9.jar` (5.5 MB)
- **Release Date**: September 12, 2025
- **License**: Mozilla Public License Version 2.0

## Requirements

### Java Runtime Environment
- **Minimum**: Java 8 (JRE 1.8+)
- **Recommended**: Java 11 or later
- **Memory**: 1GB RAM minimum, 2GB recommended for large patterns
- **Command**: `java -Xmx1024m -jar saxon-he-12.9.jar`

### Dependencies
Saxon-HE 12.9 includes the following optional dependencies:
- XML Resolver (org.xmlresolver)
- HTML Parser (nu.validator.htmlparser) - optional
- JavaMail API - optional
- JLine console utilities - optional

## Integration with Racket

### Basic Usage Pattern
```racket
(define saxon-jar-path
  (build-path (current-directory) "lib" "saxon-he-12.9.jar"))

(define (run-saxon input-xml xsl-file output-file)
  (system (format "java -jar ~a -s:~a -xsl:~a -o:~a"
                  saxon-jar-path input-xml xsl-file output-file)))

(define (run-saxon-with-memory input-xml xsl-file output-file)
  (system (format "java -Xmx1024m -jar ~a -s:~a -xsl:~a -o:~a"
                  saxon-jar-path input-xml xsl-file output-file)))
```

### Error Handling
```racket
(define (run-saxon-safe input-xml xsl-file output-file)
  (let ([result (system (format "java -jar ~a -s:~a -xsl:~a -o:~a"
                               saxon-jar-path input-xml xsl-file output-file))])
    (unless (= result 0)
      (error "Saxon XSLT transformation failed with exit code" result))))
```

### Command Line Options
Common Saxon-HE command line options:
- `-s:source.xml` - Source XML document
- `-xsl:transform.xsl` - XSLT stylesheet
- `-o:output.xml` - Output file
- `-t` - Display timing information
- `-warnings:silent` - Suppress warnings
- `-dtd:off` - Disable DTD validation

## Features Supported

### XSLT Capabilities
- **XSLT 2.0**: Full support including grouping, multiple output documents
- **XSLT 3.0**: Streaming transformations, packages, higher-order functions
- **XPath 2.0/3.0**: Advanced path expressions and functions
- **fn:transform()**: Dynamic XSLT invocation from within stylesheets

### Output Formats
- XML, HTML, XHTML
- Text output
- SVG generation for knitting charts
- JSON output (XSLT 3.0 feature)

## Knitting Chart Applications

Saxon-HE is specifically used in Knotty for:

1. **Chart Generation**: Converting knitting pattern data to SVG charts
2. **Symbol Processing**: XSLT 2.0 grouping for stitch pattern analysis
3. **Multi-format Output**: Generating HTML, SVG, and text outputs
4. **Pattern Validation**: XPath 2.0 expressions for pattern consistency

### Example XSLT Usage
```xsl
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="knitting-pattern">
    <svg xmlns="http://www.w3.org/2000/svg">
      <xsl:for-each-group select="stitch" group-by="@row">
        <g class="row-{current-grouping-key()}">
          <xsl:apply-templates select="current-group()"/>
        </g>
      </xsl:for-each-group>
    </svg>
  </xsl:template>
</xsl:stylesheet>
```

## Troubleshooting

### Common Issues

1. **Java Not Found**
   ```
   Error: 'java' is not recognized as an internal or external command
   ```
   **Solution**: Install Java Runtime Environment and ensure `java` is in PATH

2. **Out of Memory Errors**
   ```
   Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
   ```
   **Solution**: Increase heap size with `-Xmx2048m` or higher

3. **JAR Not Found**
   ```
   Error: Unable to access jarfile saxon-he-12.9.jar
   ```
   **Solution**: Verify JAR file exists and path is correct

### Validation Commands
```bash
# Test Java installation
java -version

# Test Saxon JAR
java -jar lib/saxon-he-12.9.jar -t

# Test with sample transformation
java -jar lib/saxon-he-12.9.jar -s:sample.xml -xsl:sample.xsl -o:output.xml
```

## Upgrading Saxon

### When to Upgrade
- Security vulnerabilities in current version
- New XSLT 3.0 features required
- Performance improvements needed
- Bug fixes affecting knitting chart generation

### Upgrade Process
1. Download new Saxon-HE JAR from [Maven Central](https://mvnrepository.com/artifact/net.sf.saxon/Saxon-HE)
2. Update JAR filename in Racket code
3. Test with existing XSLT stylesheets
4. Update version in this documentation

### Version Compatibility
- **Saxon-HE 9.x**: XSLT 2.0 only
- **Saxon-HE 10.x**: XSLT 3.0 partial support
- **Saxon-HE 11.x**: XSLT 3.0 enhanced support
- **Saxon-HE 12.x**: XSLT 3.0 full support, performance improvements

## AI Agent Instructions

For autonomous rebuilds, AI agents should:

1. **Verify Saxon Presence**: Check that `lib/saxon-he-12.9.jar` exists
2. **Test Java Runtime**: Ensure `java -version` succeeds
3. **Validate Integration**: Run sample XSLT transformation
4. **Update if Needed**: Use provided download script if JAR is missing

### Automated Validation
```bash
# Add to build scripts
if [ ! -f "lib/saxon-he-12.9.jar" ]; then
    echo "Saxon JAR missing, downloading..."
    ./scripts/download-saxon.sh
fi

java -jar lib/saxon-he-12.9.jar -t > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Saxon validation failed"
    exit 1
fi
```

## References

- [Saxon Documentation](http://www.saxonica.com/documentation/index.html)
- [XSLT 3.0 Specification](https://www.w3.org/TR/xslt-30/)
- [Maven Central Repository](https://mvnrepository.com/artifact/net.sf.saxon/Saxon-HE)
- [Saxon GitHub Repository](https://github.com/Saxonica/Saxon-HE)