---
name: technical-seo
description: Use when building or reviewing the technical/on-page SEO of a web app — metadata, Open Graph, JSON-LD structured data, sitemap/robots, canonical/hreflang, crawlable rendering (SSR/SSG), URL design, and Core Web Vitals. Triggers include "SEO", "meta tags", "structured data", "JSON-LD", "sitemap", "robots.txt", "canonical", "Open Graph / social preview", "search ranking", "crawlable", "Core Web Vitals", "hreflang", "indexing". Owned by frontend-engineer. NOT for keyword research or content/marketing strategy.
---

# Technical SEO

On-page and technical SEO for a web app: make every page **crawlable, indexable, accurately described, and fast**. This is an engineering concern that lives in the frontend/routing layer — it is owned by `frontend-engineer` and applied per route via `pages-templates`.

**In scope (engineering):** metadata, social cards, structured data, sitemap/robots, canonical/hreflang, crawlable rendering, URL design, redirects, Core Web Vitals.

**Out of scope (not a dev-team concern):** keyword research, content/topic strategy, copywriting, link building, off-page authority. A thin solo/indie checklist for those lives at the very bottom — clearly fenced — but the team does **not** own marketing SEO. Point the user there; don't try to be an SEO agency.

These are defaults for the plugin's stack (TanStack Start SSR). **Read `.ai/stack-profile.md` first** (see the `stack-profile` skill); if the project declares a different framework, apply the same SEO discipline using that framework's head/routing/render APIs — research them before writing. The discipline below is framework-invariant; only the API surface changes.

## The non-negotiable: crawlable rendering

Search crawlers index the **initial HTML response**. If the primary content of a page only appears after client-side hydration, it may not be indexed reliably.

- **Server-render (SSR) or pre-render (SSG) every indexable route.** TanStack Start SSRs by default — keep route content in the server render path, not gated behind a client-only effect.
- `view-source:` (or `curl`) the page: the title, meta description, headings, primary copy, and JSON-LD must be present in the **raw HTML**, before any JS runs. If they're missing there, SEO is broken regardless of how the page looks in a browser.
- Client-only widgets (charts, dashboards behind auth) don't need SEO — but public marketing/content/product pages do. Decide per route.

## Per-route metadata (owned with `pages-templates`)

Every indexable route emits, in the document `<head>`:

| Tag | Rule |
|---|---|
| `<title>` | Unique per page, ~50–60 chars, primary intent first. Never the same title on two pages. |
| `<meta name="description">` | Unique, ~150–160 chars, accurate (not keyword-stuffed). Drives the SERP snippet. |
| `<link rel="canonical">` | Absolute URL of the page's canonical version. Self-referencing by default; point variants (query-param, pagination, A/B) at the real one. |
| `<meta name="robots">` | `index,follow` by default; `noindex` for thin/duplicate/private pages (set deliberately, never by accident). |
| Open Graph | `og:title`, `og:description`, `og:image` (1200×630), `og:url`, `og:type`. |
| Twitter | `twitter:card` (`summary_large_image`), title/description/image. |

In TanStack Start, set these via the route's `head()`/meta API so they render server-side. **Centralize the builder** (`buildMeta({ title, description, canonical, image, ... })`) — one source of truth per `principles-dry-kiss`, not hand-written tags per route. Provide site-wide defaults + per-route overrides.

## Structured data (JSON-LD)

Emit JSON-LD `<script type="application/ld+json">` server-side for the page's type:

- `Organization` / `WebSite` (with `SearchAction`) site-wide, once.
- `BreadcrumbList` on nested pages.
- `Article` / `BlogPosting` (author, datePublished, dateModified, headline, image) for content.
- `Product` (+ `Offer`, `AggregateRating`) for commerce.
- `FAQPage`, `HowTo`, `Event`, etc. where the content genuinely matches — never mark up content that isn't visibly on the page (a guidelines violation).

Build JSON-LD from the **same data** that renders the page (single source — DRY), not a hand-maintained duplicate that can drift. Validate against Google's Rich Results Test + schema.org before shipping.

## Site-level files

- **`sitemap.xml`** — generated from the route/content set (not hand-maintained), absolute URLs, `lastmod`, only canonical indexable URLs. Split + index if >50k URLs. Serve at `/sitemap.xml`, reference in `robots.txt`, submit in Search Console.
- **`robots.txt`** — allow crawl of public routes, disallow private/auth/duplicate paths, link the sitemap. Don't `Disallow` something you also `noindex` (the crawler must reach the page to see the `noindex`).

## URL design & redirects

- Lowercase, hyphen-separated, stable, human-readable, shallow hierarchy that mirrors site structure. No tracking params in canonical URLs.
- A URL is a contract: when one changes, **301-redirect** the old → new (preserve link equity). Never let an indexed URL 404 silently. (Wire redirects with `devops-engineer` / `cloud-infra` at the edge, or in the router.)
- Trailing-slash and `www`/apex: pick one canonical form, 301 the rest.

## Internationalization

Multi-locale sites: `hreflang` annotations (reciprocal, including `x-default`), locale in the URL (`/en/`, `/fr/`), and per-locale canonical. Keep it consistent or crawlers ignore it.

## Performance = ranking (Core Web Vitals)

Core Web Vitals are ranking signals. Hold budgets — **LCP < 2.5s, CLS < 0.1, INP < 200ms** (field/p75):

- Optimize the LCP element (hero image/text): preload, right-sized responsive images (AVIF/WebP), no render-blocking.
- Reserve space for images/embeds/ads (width+height or aspect-ratio) to keep CLS ≈ 0.
- Self-host/`font-display: swap` fonts; avoid layout-shifting late webfonts.
- Ship less JS to the critical path; defer non-critical.

This overlaps delivery/infra — reference `cloud-infra` (CDN, caching, edge, image pipeline) and `devex`; **do not restate** perf-infra rules here. Frontend owns the in-page causes; devops owns delivery.

## Build with the principles, not around them

- **`principles-tdd` + `test-design`** — write tests that assert SEO output: route emits the expected `<title>`/description/canonical, JSON-LD parses and has required fields, sitemap contains exactly the canonical indexable set, `noindex` pages are actually excluded. SEO regressions are silent in the UI — tests are the only guard. TDD them like any behavior.
- **`principles-dry-kiss`** — one `buildMeta`, one JSON-LD builder, one sitemap generator, all fed from the page's real data. No per-route hand-copied tags (they drift and rot).
- **`principles-pragmatic-solid`** — metadata/structured-data builders are small, single-purpose, composable per page type.

## Pre-ship audit (run before merging an indexable page)

1. `view-source` / `curl`: title, description, canonical, headings, primary copy, JSON-LD all in raw HTML.
2. Lighthouse SEO category ≥ 95; Core Web Vitals within budget (lab + field if available).
3. Rich Results Test: JSON-LD valid, no errors, matches visible content.
4. Canonical correct and absolute; `robots` directive intentional.
5. Page is in `sitemap.xml` (or deliberately excluded); `robots.txt` doesn't block it.
6. OG/Twitter preview renders (real image, right dimensions).
7. Any changed URL has a 301 from its old path.

---

## Appendix — content SEO (OUT of core scope; solo/indie only)

The team does **not** own marketing SEO. But when *you* wear the marketing hat on a solo project, a minimal checklist — not a discipline, not an agent's job:

- **One intent per page.** Know the search intent a page targets; make the `<title>` and `<h1>` reflect it (aligned, not identical).
- **One `<h1>`**, logical `<h2>/<h3>` outline that mirrors the content.
- **Internal links** between related pages with descriptive anchor text (helps crawl + relevance).
- **Freshness** — update `dateModified` and the content when facts change; stale content decays.
- **Descriptive, unique** titles/descriptions written for humans (CTR), not keyword lists.
- For real keyword research, competitive analysis, or link strategy → that's a marketing/SEO-specialist task **outside this dev team**. Use a dedicated tool/service; don't ask the engineering agents to invent it.
