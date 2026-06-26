---
name: figma-design-system
description: Extracts design tokens and codifies a design system from Figma. Invoked when the user says "build a design system from Figma", "extract design tokens", "extract Figma variables", "codify design system", "pull tokens from Figma", or "generate tokens.json". Uses the figma-dev-mode MCP to read the current selection, variables, and styles — read-only; does not draw or author frames in Figma.
---

# Figma Design System Skill

Extract design intent from Figma and codify it as a portable, W3C design-tokens–style `tokens.json` plus a human-readable design-system spec. The agent reads; it does not draw.

**Read-only boundary:** Official Dev Mode MCP reads designs and powers Code Connect; it does not author design systems inside Figma.

## Process

### 1. Connect and read

Use the `figma-dev-mode` MCP (declared in the plugin manifest at `http://127.0.0.1:3845/mcp`). The MCP provides read tools for inspecting the live Figma file:

- `get_selection` — inspect the currently selected node(s) and their computed properties.
- `get_variables` / `get_local_variable_collections` — enumerate all design variables (color, number, string, boolean) and their mode values.
- `get_styles` — read named styles (color, text, effect, grid).

Call these tools in sequence. If no selection exists, read document-level variables and styles first; narrow to components once the token vocabulary is established.

### 2. Categorize tokens

Map Figma primitives to W3C design-token categories:

| Figma source | Token category |
|---|---|
| Color variables / color styles | `color` |
| Typography styles (font, size, weight, line-height, tracking) | `typography` / `fontSize`, `fontWeight`, `lineHeight`, `letterSpacing` |
| Number variables mapped to spacing | `spacing` |
| Number variables mapped to corner radius | `borderRadius` |
| Effect styles (box-shadow, drop-shadow) | `shadow` |
| Stroke / border widths | `borderWidth` |

Separate **primitive tokens** (raw values, e.g. `color.blue.500`) from **semantic tokens** (role-mapped aliases, e.g. `color.background.primary → {color.blue.500}`).

### 3. Output `tokens.json`

Emit a W3C Design Tokens Community Group (DTCG) format file:

```json
{
  "color": {
    "blue": {
      "500": { "$type": "color", "$value": "#3B82F6" }
    },
    "background": {
      "primary": { "$type": "color", "$value": "{color.blue.500}" }
    }
  },
  "fontSize": {
    "sm": { "$type": "dimension", "$value": "14px" },
    "base": { "$type": "dimension", "$value": "16px" },
    "lg": { "$type": "dimension", "$value": "18px" }
  },
  "spacing": {
    "1": { "$type": "dimension", "$value": "4px" },
    "2": { "$type": "dimension", "$value": "8px" },
    "4": { "$type": "dimension", "$value": "16px" }
  },
  "borderRadius": {
    "sm": { "$type": "dimension", "$value": "4px" },
    "md": { "$type": "dimension", "$value": "8px" },
    "full": { "$type": "dimension", "$value": "9999px" }
  },
  "shadow": {
    "sm": { "$type": "shadow", "$value": { "offsetX": "0px", "offsetY": "1px", "blur": "2px", "spread": "0px", "color": "#00000014" } }
  }
}
```

Write the file to the project root as `tokens.json`. If CSS custom properties are also needed, emit a `tokens.css` companion using `--token-name: value;` conventions (kebab-case, e.g. `--color-background-primary`).

### 4. Record auto-layout intent

For each auto-layout frame or component in the selection, note in the design-system spec:

- **Direction** → CSS `flex-direction` (`row` / `column`)
- **Spacing mode** (packed vs. space-between) → `justify-content`
- **Alignment** → `align-items`
- **Gap** → `gap` (map to a spacing token if one matches)
- **Padding** → individual padding sides, mapped to spacing tokens
- **Wrap** → `flex-wrap: wrap` when Figma wrapping is on

Write these as annotated component layout specs in `design-system.md` so the frontend engineer can reproduce layout in CSS/Tailwind without guessing.

### 5. Write the design-system spec

Produce `design-system.md` alongside `tokens.json`. Include:

1. **Token inventory** — summary table of each category and token count.
2. **Component inventory** — list of top-level component sets found in the selection.
3. **Auto-layout intent** — per-component flex/grid mappings from step 4.
4. **Typography scale** — rendered table of all text styles with computed values.
5. **Color palette** — primitive palette + semantic role mapping.
6. **Usage notes** — any Figma constraints, mode variants (light/dark), or missing mappings that need designer clarification.

### 6. Validate before handing off

- Confirm every `$value` that is a reference (`{token.path}`) resolves to a defined token — no dangling references.
- Confirm `tokens.json` is valid JSON (`Bash: node -e "JSON.parse(require('fs').readFileSync('tokens.json','utf8'))" && echo valid`).
- Flag any Figma variable that has no clear token category mapping so it is not silently dropped.
