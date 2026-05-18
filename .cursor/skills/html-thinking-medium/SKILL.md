---
name: html-thinking-medium
description: Generate self-contained HTML pages as a thinking and communication medium for codebase explanations, architecture overviews, debugging dashboards, decision tradeoffs, API references, and concept explainers. Use when the user asks to "make me an HTML page explaining X", "create a visual overview of Y", "use HTML to explain this", "generate an HTML architecture overview", "build an HTML walkthrough/dashboard/explainer", or any time a plain-text explanation would be hard to scan, lose structure, or require excessive back-and-forth. Pages are saved to disk and opened in the browser; chat stays concise.
---

# HTML as a thinking medium

## Core philosophy

Plain text forces linear reading and loses structure. HTML pages let you externalize reasoning into a navigable, visual artifact the user can scan, reference, and return to. Treat HTML not as output format, but as a shared whiteboard between you and the user.

The HTML file is the answer. Chat stays short and points to the file.

## When to use this skill

Use HTML as the primary output medium when the user wants to:

- Understand a codebase (architecture overviews, module maps, call graphs)
- Explain a complex system (dependencies, data flow, state machines)
- Debug a problem (visualize expected vs. actual behavior)
- Plan or compare approaches (tradeoff matrices)
- Walk through code (annotated reviews of non-obvious logic)
- Document an API or SDK (interactive quick-reference)
- Onboard to a repo ("here's how this codebase works")

Do NOT use HTML for: simple one-line answers, direct code edits the user asked for, snippets meant for paste, or anything the user expects inline in chat.

## Page types and structure

Pick the closest match. Mix sections from multiple types when useful.

### 1. Architecture overview

Use when the user asks "how does this codebase work?" or "explain this system."

Sections:
- Hero: what the system does in 1-2 sentences
- Visual module map (CSS grid or flexbox diagram)
- Per-module cards: responsibility, key files, public interface
- Data flow: how modules connect
- "Where to start reading" guide

### 2. Code walkthrough

Use when explaining non-obvious logic, algorithms, or patterns.

Sections:
- Annotated code blocks (syntax-highlighted, with callout comments)
- Side-by-side: "what the code does" vs. "why it does it"
- Step-by-step execution trace for key paths
- Edge cases and gotchas

### 3. Debugging dashboard

Use when diagnosing a bug or unexpected behavior.

Sections:
- Expected vs. actual comparison table
- Hypothesis list with status (confirmed, ruled out, unknown)
- Evidence log: what each finding tells you
- Recommended next steps

### 4. Decision / tradeoff page

Use when choosing between approaches, libraries, or architectures.

Sections:
- Criteria table (rows = options, columns = dimensions)
- Pros and cons cards per option
- Recommendation with rationale
- "When to revisit this decision" note

### 5. API / SDK quick-reference

Use when explaining an SDK, API surface, or configuration options.

Sections:
- Searchable or filterable method list
- Per-method: signature, description, example, gotchas
- Common patterns
- Error codes and troubleshooting table

### 6. Concept explainer

Use when teaching a concept (e.g., "explain how JWT auth works").

Sections:
- Plain-English summary (one paragraph)
- Visual diagram (CSS-drawn or ASCII art in `<pre>`)
- Step-by-step flow
- Code example
- Common mistakes

## Quality bar

Every generated page must meet these standards:

- Use semantic HTML5 (`<article>`, `<section>`, `<details>`, `<summary>`, `<nav>`)
- Inline all CSS so the page is self-contained; CDN links for fonts and `highlight.js` are fine
- Use a clean, readable font (system-ui stack or Inter via Google Fonts CDN)
- Add a sticky nav for any page longer than ~3 sections
- Syntax-highlight code with `highlight.js` from CDN
- Mobile-friendly responsive CSS
- Minimal palette: one accent color, neutral grays, white background
- Pass basic accessibility: semantic landmarks, sufficient contrast, alt text on diagrams

## Content rules

- Lead with the "so what": what should the reader understand after viewing?
- Use progressive disclosure: summary first, details inside `<details>` tags
- Don't repeat in chat what the page already says; the page is for depth, chat is for framing
- Prefer tables and visual grids over bullet lists for comparisons
- Annotate liberally; every non-obvious decision gets a tooltip or note
- Include real code and content inline; never link out to files the user has to also open

## File handling in Cursor

1. Save the file as `.html` in a sensible location:
   - Project-specific explanation: `docs/<topic>.html` in the workspace
   - One-off scratch artifact: `.cursor/scratch/<topic>.html` (create the folder if missing) or the workspace root
2. Use the Write tool to create the file; do not paste full HTML into chat
3. After saving, reply with:
   - The absolute or workspace-relative path
   - A one-sentence summary of what the page covers
   - The shell command to open it: `open <path>` on macOS, `xdg-open <path>` on Linux
4. If the user asks to update the page, edit the existing file in place; don't create `<topic>-v2.html`

## Required HTML skeleton

Start every page from this template, then specialize:

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{Page title}}</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/styles/github.min.css">
  <script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/highlight.min.js"></script>
  <style>
    :root {
      --accent: #2563eb;
      --bg: #ffffff;
      --fg: #111827;
      --muted: #6b7280;
      --border: #e5e7eb;
      --card: #f9fafb;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
      color: var(--fg);
      background: var(--bg);
      line-height: 1.6;
    }
    nav.sticky {
      position: sticky; top: 0; background: var(--bg);
      border-bottom: 1px solid var(--border);
      padding: 0.75rem 1.5rem; z-index: 10;
    }
    main { max-width: 960px; margin: 0 auto; padding: 2rem 1.5rem; }
    h1, h2, h3 { line-height: 1.25; }
    h2 { border-bottom: 1px solid var(--border); padding-bottom: 0.4rem; margin-top: 2.5rem; }
    a { color: var(--accent); }
    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 1rem 1.25rem;
      margin: 0.75rem 0;
    }
    .grid { display: grid; gap: 1rem; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); }
    table { width: 100%; border-collapse: collapse; margin: 1rem 0; }
    th, td { text-align: left; padding: 0.6rem; border-bottom: 1px solid var(--border); }
    th { background: var(--card); }
    code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 0.95em; }
    pre code { display: block; padding: 1rem; border-radius: 8px; overflow-x: auto; }
    details { margin: 0.5rem 0; }
    summary { cursor: pointer; font-weight: 600; }
    @media (max-width: 600px) { main { padding: 1rem; } }
  </style>
</head>
<body>
  <nav class="sticky"><strong>{{Short title}}</strong></nav>
  <main>
    <article>
      <!-- Sections go here -->
    </article>
  </main>
  <script>hljs.highlightAll();</script>
</body>
</html>
```

## Workflow

1. Confirm the page type that fits the request (architecture, walkthrough, debug, tradeoff, API, concept)
2. Gather facts from the codebase using read and search tools before writing the page; never invent file names or APIs
3. Draft the HTML using the skeleton above and the matching page-type sections
4. Save to the right location using the Write tool
5. Reply in chat with: file path, one-line summary, open command. Nothing else unless the user asks

## Prompt patterns that fit this skill

| User wants to | Likely page type |
|---|---|
| Understand a codebase | Architecture overview |
| Explain complex logic | Code walkthrough |
| Debug a problem | Debugging dashboard |
| Compare options | Decision / tradeoff |
| Document an API | API quick-reference |
| Explain a concept | Concept explainer |
| Onboard someone | Architecture overview + concept explainer |

## Good vs. bad

Bad: respond with 400 words of prose explaining the auth flow. The user has to scroll, can't navigate, and forgets it next session.

Good: write `docs/auth-flow.html` with a sequence diagram, annotated code per step, and an edge-cases section. Reply with the file path, a one-line summary, and `open docs/auth-flow.html`.

## Anti-patterns

- Pasting the full HTML body into chat instead of writing the file
- Creating `<topic>-v2.html`, `<topic>-final.html`, `<topic>-final-final.html`; edit in place
- Adding external JS frameworks (React, Vue) when plain HTML and a sprinkle of CSS will do
- Using lorem ipsum or invented file paths and APIs; pull real names from the codebase
- Writing time-sensitive content ("as of 2025..."); describe the system, not the calendar
- Skipping the sticky nav on long pages
- Repeating the page content in the chat reply
