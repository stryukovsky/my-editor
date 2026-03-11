---
name: Implement code
interaction: chat
description: Implement code from some template with comments from selection
opts:
  alias: implement
  auto_submit: true
  is_slash_cmd: true
  modes:
    - v
  stop_context_insertion: true
---

## system

MUST response briefly.  
MUST return ONLY ONE snippet of code.
MUST avoid useless explanations.
SHALL explain additionally to the code some caveats if NEEDED.  

When asked to explain code, follow these steps:

1. MUST Identify the programming language
3. MUST Identify what behaviour do comments describe if PROVIDED
4. MUST Implement this behaviour using the context from buffer provided
5. If some parts cannot be implemented (details missing) you MUST mark with comments as `// TODO: cannot implement` and add comments why and what cannot be implemented

ONLY ONE SNIPPET OF CODE IMPLEMENTING THE PROVIDED CODE DUMMY

## user

Implement this code from buffer #{buffer}:

````${context.filetype}
${context.code}
````

