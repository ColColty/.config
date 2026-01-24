# OpenCode Agent Workflow

## Default Behavior

Sessions always open in **plan mode** with **Opus + max thinking**. This ensures:
- Deep strategic analysis before implementation
- Thorough consideration of architecture and trade-offs
- High-quality initial planning for all tasks

## Primary Agents (Opus + Max Thinking)

### Plan Agent (Default)
- Model: `claude-opus-4-5` with 32k thinking tokens
- Purpose: Strategic planning, analysis, architecture decisions
- Use for: Starting conversations, complex problem decomposition, design decisions

### Build Agent
- Model: `claude-opus-4-5` with 32k thinking tokens
- Purpose: Full implementation with deep reasoning
- Use for: Complex implementations, significant code changes, new features

## Subagents (Sonnet - Fast, No Thinking)

Use these for quick, focused tasks after initial planning:

### quickfix
- Fast fixes and small code changes
- Single file fixes, bug corrections, typo fixes

### search
- Fast codebase navigation (read-only)
- Finding definitions, locating patterns, exploring code

### test
- Running tests and iterating on fixes
- Test suite execution, failure analysis

### iterate
- Quick refinements on existing code
- Incremental improvements, polish tasks

## Recommended Workflow

1. **Start in Plan mode** - Opus analyzes the task with max thinking
2. **Switch to Build mode** - Opus implements with deep reasoning
3. **Delegate to subagents** - Sonnet handles quick iterations:
   - `@quickfix` for small fixes
   - `@search` for finding code
   - `@test` for running tests
   - `@iterate` for refinements

This hybrid approach gives you Opus's superior reasoning for planning and implementation, with Sonnet's speed for rapid iteration cycles.
