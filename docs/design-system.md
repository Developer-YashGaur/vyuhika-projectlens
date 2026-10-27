# Neon Orbit

Initial semantic tokens live in `ProjectLens/Shared/DesignSystem/NeonOrbit.swift`. They are a starting point, not a complete component library.

| Role | Initial value |
| --- | --- |
| Background | RGB 0.035, 0.047, 0.090 |
| Surface | RGB 0.075, 0.090, 0.150 |
| Primary text | White |
| Secondary text | RGB 0.720, 0.760, 0.860 |
| Accent | RGB 0.350, 0.940, 0.870 |
| Highlight | RGB 0.760, 0.650, 1.000 |
| Spacing | 8, 16, 24, 32 pt |
| Surface corner radius | 20 pt |

Use native semantic typography (`largeTitle`, `title2`, `body`, `caption`) for Dynamic Type. No custom font dependency. This first visual treatment is intentionally dark even under light system appearance; a separate light palette is not implemented.

Maintain WCAG AA text contrast (4.5:1 for ordinary text, 3:1 for large text) and 3:1 for meaningful controls. Current text/background combinations exceed 4.5:1; verify any new pair before use. Do not use accent color alone to communicate gain/loss, status or errors. Future interactive controls require at least 44×44 pt touch targets, clear labels and visible focus states.

The placeholder scrolls at accessibility sizes, uses a heading trait, and hides the decorative symbol from VoiceOver. No fixed text-height clipping or animation is used. Respect Reduce Motion for future animation; avoid glow effects behind body text. Validate VoiceOver reading order, accessibility sizes, increased contrast and both system appearances on a simulator/device before release. UI automation is a baseline, not a completed accessibility audit.
