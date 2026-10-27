# Neon Orbit

A native iPhone experience with an editorial rhythm: expressive rounded headlines, generous space, a restrained orbital illustration and one clear action. No dashboard grids, invented balances or decorative charts.

## Adaptive semantic palette

Tokens live in `ProjectLens/Shared/DesignSystem/NeonOrbit.swift`; named asset colors adapt to system appearance. Accent colors used as text meet 4.5:1 against both surfaces in each appearance. Thin borders and orbit paths are decorative and do not communicate state alone.

| Role | Light | Dark |
| --- | --- | --- |
| Background | #F5F5FC | #0B1020 |
| Raised surface | #FFFFFF | #151D32 |
| Primary text | #141C32 | #F2F4FC |
| Secondary text | #505E78 | #AEBAD1 |
| Primary accent: violet | #6335D4 | #B1A0FF |
| Secondary accent: cyan | #067482 | #66E4EF |
| Positive: lime | #456B00 | #B9ED65 |
| Decorative border | #C6CADA | #33415E |
| Primary action fill | #6335D4 | #6840D8 |
| Text on primary action | #FFFFFF | #FFFFFF |

Violet anchors navigation and primary actions. Cyan adds secondary emphasis. Lime accompanies the explicitly labeled Income type; future financial indicators must pair color with a label/symbol. Selection uses a checkmark, border and accessibility value. Never infer gain/loss from color alone.

## Typography, space and depth

Use system semantic text styles so every content label scales with Dynamic Type. Large titles and section headings use the rounded system design; the small editorial eyebrow uses monospaced caption. Body and control labels retain the system default. No custom fonts or packages.

Spacing tokens: 4, 8, 16, 24, 32 and 48 pt. Controls have 16 pt radii; cards have 24 pt radii. Minimum interactive height is 44 pt, with flexible text height. Cards use one restrained shadow (black at 10%, 12 pt radius, 4 pt vertical offset). The decorative symbol alone has a fixed illustration size and is hidden from VoiceOver. No fixed-size text containers, aggressive glow or continuous animation.

## Navigation and Quick Add

`NavigationShell` owns the selected tab and a single Quick Add presentation Boolean. Four native tabs each contain a NavigationStack: Home, Money, Projects and Upcoming. Selection begins at Home and is retained while a sheet opens or closes. The safe-area inset keeps the prominent Quick Add action above native tab chrome and away from scroll content. Native controls handle system adaptation; content is centered at a maximum 600 pt readable width on wide iPhones.

`OrbitEmptyState` shares the visual layout while each destination has its own copy. These are honest previews of planned tools, not populated product screens. No sums, records, schedules or projects are fabricated.

`QuickAddSheet` is a reusable native large sheet with scrollable type rows and a persistent Done control. Expense, Income, Recurring commitment and Transfer can be selected to preview the category. An explicit notice explains that forms and saving are unavailable. Selection resets on reopening. There is no transaction form, save action or financial calculation.

## Accessibility and motion

- Respect system dark/light appearance; no forced color scheme. Asset colors have explicit variants. Increased contrast remains a required manual check.
- All content can scroll at accessibility text sizes and in landscape. No truncating line limits. Native tabs provide spoken labels and selected traits; buttons expose labels, selection values and preview-only hints.
- Headings have header traits; decorative artwork is hidden. Reading order follows visual order.
- Use at least 4.5:1 for ordinary text and 3:1 for meaningful nontext indicators. Unit tests resolve actual color assets for light/dark text, accents and action contrast.
- Custom selection animation is 0.18 seconds ease-in/out; `accessibilityReduceMotion` disables it. No custom entrance, orbit, parallax or looping animations. System sheet/tab transitions follow platform accessibility settings.
- Before calling this release-ready, verify small and large iPhones, landscape, light/dark, accessibility text sizes, VoiceOver, Increase Contrast and Reduce Motion on a functioning simulator/device. Compiling tests does not constitute this audit.
