# ProjectLens product requirements

## Established direction

Product: **Vyuhika ProjectLens** (display name **ProjectLens**). Company: **Vyuhika**. Primary platform: native iOS, initially iPhone. Design direction: **Neon Orbit**. Target users: developers, freelancers, indie hackers and startup founders.

The product aims to connect personal financial tracking with project finances so users can understand costs and plan work with better financial context.

## Planned capabilities — none implemented

- Personal and project financial tracking.
- Recurring subscriptions, budgets and invoices.
- Cost allocation across projects.
- Release planning and financial intelligence.

Future exploration: cloud synchronization, automated provider integrations, collaborative workspaces and AI-supported insights. Scope, providers, pricing, backend architecture and delivery order are undecided.

## Current milestone

Refine Neon Orbit and provide four native destinations (Home, Money, Projects, Upcoming) with honest empty states and a preview-only Quick Add entry-type sheet. Support system appearances, Dynamic Type, VoiceOver and Reduce Motion. No onboarding, backend, money calculations or financial records are part of this milestone.

## Product constraints

Financial correctness and privacy are architectural priorities. Do not imply financial tools are usable before they exist. Avoid genuine-looking mock user records. Currency precision, rounding, time zones, invoice jurisdictions, data retention and sync conflicts require explicit decisions before related implementation. AI output must never silently become authoritative financial data.

## Acceptance

The shell identifies ProjectLens, communicates that tools are planned, supports large text and VoiceOver, and makes no network requests or persistent financial writes. Build and test results must be reported honestly, including environment limitations.
