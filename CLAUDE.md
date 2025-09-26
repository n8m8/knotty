# Claude Tools

## Discord CLI
- `discord-cli send-message <channel> <message> [--server <server>]`
- `discord-cli read-messages <channel> [--limit <limit>] [--server <server>]`
- `discord-cli check-inbox [--server <server>]`

Requires `DISCORD_TOKEN` env var.

# Project Context: Knotty DSL

## Technical Stack
**Language**: Typed Racket with sweet-exp syntax
**Primary Dependencies**: Racket standard libraries, Saxon XSLT processor
**Storage**: File-based (.rkt pattern files, exported formats)
**Project Type**: Single library with CLI executable
**Testing**: RackUnit framework (module+ test)

## Key Modules
- `pattern.rkt`: Core pattern creation and validation
- `chart.rkt`: Visual chart generation from patterns
- `html.rkt`: HTML export with interactive features
- `knitspeak.rkt`: Knitspeak format import/export
- `cli.rkt`: Command-line interface operations
- `stitch.rkt`: Stitch type definitions and operations
- `colors.rkt`: Color management for colorwork patterns

## Testing Commands
- `make test`: Run full test suite via RackUnit
- `raco test knotty-lib/`: Test library modules
- `raco test knotty/`: Test documentation and examples

## Build Commands
- `make install`: Install package with dependencies
- `make build`: Compile libraries from source
- `make docs`: Generate and view documentation
- `make clean`: Remove build artifacts

## Recent Changes
- Added Garn, Loop, Course, and Knitgraph structs
- Enhanced test coverage using mocks for side effects
- Improved font handling in distribution

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.