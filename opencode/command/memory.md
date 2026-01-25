---
description: Alias for /memorize - save a memory to persist across sessions
agent: quickfix
---

# Memory (Alias for Memorize)

Save the following information to the project's memory file for future reference.

## Instructions

1. Read the current contents of `MEMORIES.md` in the project root (create it if it doesn't exist)
2. Append the new memory with a timestamp and category
3. Keep memories organized and deduplicated

## Memory to save

{arguments}

## Format

Add the memory in this format:

```markdown
### [Category] - Memory Title
> Added: YYYY-MM-DD

Memory content here...
```

Categories: `preference`, `context`, `decision`, `pattern`, `warning`, `workflow`

If the user doesn't specify a category, infer the most appropriate one.
