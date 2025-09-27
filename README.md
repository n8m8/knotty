# Knotty

Domain Specific Language for knitting patterns with comprehensive AI-driven rebuild system

[![Coverage Status](https://coveralls.io/repos/github/t0mpr1c3/knotty/badge.svg?branch=main)](https://coveralls.io/github/t0mpr1c3/knotty?branch=main)

[Documentation](https://t0mpr1c3.github.io/knotty/index.html) | [AI Rebuild Guide](docs/ai-rebuild/)

## 🤖 AI-Driven Rebuild System

Knotty features a complete AI-driven rebuild system designed for autonomous setup, development, and deployment by AI agents. The system ensures consistent, reliable builds across all platforms with comprehensive automation and error recovery.

### Quick Start for AI Agents

```bash
# Autonomous setup (30-second build target)
git clone https://github.com/t0mpr1c3/knotty.git
cd knotty
# Follow setup guides in docs/ai-rebuild/ for platform-specific instructions
```

### AI Agent Documentation

Comprehensive guides for AI agents are available in [`docs/ai-rebuild/`](./docs/ai-rebuild/):

- **[Complete Setup Guide](./docs/ai-rebuild/complete-setup-guide.md)** - Step-by-step autonomous setup
- **[Troubleshooting Guide](./docs/ai-rebuild/troubleshooting.md)** - Error diagnosis and recovery
- **[Performance Optimization](./docs/ai-rebuild/performance-optimization.md)** - Build and runtime optimization
- **[Platform Notes](./docs/ai-rebuild/platform-notes.md)** - Platform-specific considerations
- **[Agent Examples](./docs/ai-rebuild/agent-examples.md)** - Integration patterns and workflows

### Performance Targets

The AI rebuild system is optimized for:
- **Build time:** <30 seconds (cold build)
- **Cross-platform:** macOS, Linux, Windows, Alpine Linux
- **Autonomous operation:** Complete error recovery and optimization
- **Quality assurance:** Comprehensive validation and testing

## Description

Grid-based editors are handy for colorwork.
[Knitspeak](https://stitch-maps.com/about/knitspeak/) is great for lace.
Knotty aims for the best of both worlds. It's a way to design knitting patterns
that incorporate both textured stitches and multiple colors of yarn.

## Features

Knotty patterns are encoded in a format that is easy for humans to write and parse,
but is also highly structured.

Patterns can be viewed and saved in an HTML format that contains an interactive
knitting chart and written instructions. You can also import and export Knitspeak
files, and create Fair Isle patterns directly from color graphics.

Knotty has been coded as a module for
[Typed Racket](https://docs.racket-lang.org/ts-guide/). Reference information
is available in the [manual](https://t0mpr1c3.github.io/knotty/index.html).

A [Knotty executable](https://github.com/t0mpr1c3/knotty/releases) is also
available that can be used from the command line to convert knitting patterns from
one format to another.

## Getting Started

Clone [this repository](https://github.com/t0mpr1c3/knotty).

Download the latest version of [Racket](https://download.racket-lang.org/)
for your operating system. It comes with the graphical application DrRacket.
Open DrRacket and select the menu option "File > Install Package". Type
"knotty" into the text box and press "Install".

Open the test script `demo.rkt` from the `knotty-lib` directory of the repository
and press "Run" in the top right of the window. The demonstration script contains
a very short knitting pattern, together with many lines of comments describing how
to go about making your own.
