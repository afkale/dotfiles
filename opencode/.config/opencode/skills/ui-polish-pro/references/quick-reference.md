# UI Polish Pro — Quick Reference

## Anti-Pattern Table

| # | AI Default (Slop) | Deliberate Alternative | Key Moves |
|---|---|---|---|
| 1 | Vertically stacked centered sections | Asymmetric CSS Grid layouts | `grid-template-columns: 2fr 1fr;` offset align, wide+narrow pairs |
| 2 | Shadows and borders for separation | Contrast + whitespace | Padding, type weight, light-on-lighter — no `shadow-*` or `border` on sections |
| 3 | Everything in a rounded-2xl card | Content on the page ground | Card only for clickable grouped units; sections are layout, not containers |
| 4 | Inset hero image in a rounded card | Full-bleed hero / app-frame | Edge-to-edge; inset only for live UI mockup or brief-asked render |
| 5 | Inter, Roboto, system-ui | Distinctive typefaces | Google Fonts pairings; Satoshi, Cabinet Grotesk, Source Serif, etc. |
| 6 | Card backgrounds define hierarchy | Typographic scale defines hierarchy | Weight + size + tracking instead of `bg-white rounded-2xl shadow` |
| 7 | Gray-on-gray (`text-gray-500` on `bg-gray-100`) | Brand-tinted muted tones, verified contrast | Desaturated primary tint; verify 4.5:1 body, 3:1 large text |
| 8 | Raw hex in components | Semantic token graph | Palette → `--surface`, `--on-surface`, `--accent`, `--muted` → components |
| 9 | Static buttons and cards | Hover and press on every interactive element | Step on hover, press on click; linked card lifts 2px; photo zooms 1.02-1.03 |
| 10 | 3D tilt, auto-carousel, timed tabs | Static layout, scroll, click-to-reveal; one dealt moment | Tilt never; dealt moment only via taste-skill (one per page, two on long page) |
| 11 | "Make it modern / clean / beautiful" | Specific prompt with references, states, behaviors | "Full-bleed image, asymmetric grid, Satoshi Bold 3rem, hover lifts 2px" |
| 12 | No error/loading/empty/edge states | Audit every component for all states | Error boundary, skeleton, empty state, keyboard nav, aria, focus management |
| 13 | Ship without review | Automated checks + screenshots | gate.mjs, copy-lint, consistency, perf, pro-rules checklist, breakpoint shots |
| 14 | Redundant wrappers, borders, icons, copy | Every line earns its place | "Does this serve?" If no: delete. Sparse > padded. |

## Which Skill for What

| Task | Go To |
|------|-------|
| Full design system (colors, fonts, spacing, style per product) | `ui-ux-pro-max --design-system` |
| Color ramps, OKLCH palettes, APCA contrast, token architecture | `color-expert` (dr-color) |
| Premium landing page, hero, moments, motion layer, photographs | `design-taste-frontend` (taste-skill) |
| Stack-specific implementation (React, Next.js, Vue, SwiftUI, etc.) | `ui-ux-pro-max --stack <name>` |
| UX best practices, WCAG, accessibility | `ui-ux-pro-max --domain ux` |
| Icon recommendations | `ui-ux-pro-max --domain icons` |
| GSAP animation presets | `ui-ux-pro-max --domain gsap` |
| Chart types | `ui-ux-pro-max --domain chart` |
| Apply anti-slop rules | **This skill** — rules 1-14 |
| Automated checks | `design-taste-frontend` gate.mjs / consistency.mjs / perf.mjs |
| Pre-delivery checklist | `ui-ux-pro-max` pro-rules.md |

## Prompt Upgrade Examples

```
SLOP: "Make this card look modern."
BETTER: "Remove the shadow and border. Set the background to oklch(98% 0.005 250).
         Add 2rem padding. Use weight 700 for the heading, 400 for the body.
         The linked card lifts 2px on hover."
```

```
SLOP: "Clean up the dashboard."
BETTER: "Replace the card grid with a 2fr 1fr asymmetric CSS Grid. The main
         content area full width, the sidebar narrow. Remove every shadow and
         border. Use typographic scale for hierarchy: headings bold 1.25rem,
         body 0.875rem weight 400, labels 0.75rem weight 500 uppercase. Set
         the ground to oklch(97% 0.005 250), surfaces at oklch(100% 0 0)."
```

```
SLOP: "Better colors."
BETTER: "Build a 9-step OKLCH ramp from oklch(65% 0.18 260) to
         oklch(20% 0.06 260). Create semantic tokens: --surface, --on-surface,
         --accent, --muted, --success, --warning, --danger. Verify every
         text/background pair in light and dark mode against WCAG AA."
```

## Breakpoint Reference

- 1440px — Desktop primary
- 1024px — Small desktop / landscape tablet
- 820px — iPad portrait
- 768px — Tablet portrait
- 390px — Mobile primary
- 320px — Minimum width (overflow check)
