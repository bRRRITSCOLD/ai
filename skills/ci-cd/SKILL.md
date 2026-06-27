---
name: ci-cd
description: Builds CI/CD pipelines and release automation. Invoked when the user says "write the CI", "set up GitHub Actions", "CI pipeline", "build pipeline", "test in CI", "automate releases", "release workflow", "semantic versioning automation", "build caching", "deploy pipeline", "environment promotion", "CD", or "continuous delivery". Produces pipelines that build, lint, test across the unit/integration/e2e tiers, gate PRs, and cut versioned releases automatically.
---

# CI/CD Skill

Automate the path from commit to released artifact: every PR is gated by build + lint + typecheck + tests; merges to the default branch cut a versioned release automatically; deploys are reproducible and promotable. Fast, cacheable, and honest — a green pipeline must mean the change is actually safe. Keep pipelines as simple as the project needs (`principles-dry-kiss`, `YAGNI`).

This plugin's own CI is a worked example: `validate.yml` gates every PR; `release.yml` auto-bumps and tags on merge. Mirror that shape.

## Pipeline shape

Two workflows cover most projects:

1. **Validate (on PR + push to default branch)** — build, lint, typecheck, and the test tiers. Fails the PR on any red. This is the merge gate.
2. **Release (on push to default branch)** — derive the version bump, tag, and publish/deploy. Guard against re-trigger loops.

### 1. The validate gate

```yaml
# .github/workflows/validate.yml
name: validate
on:
  pull_request:
  push: { branches: [main] }
jobs:
  validate:
    # Skip the push run on the bot's release commit so validation doesn't
    # re-run on `chore(release): … [skip ci]` (matches this repo's validate.yml).
    if: github.event_name == 'pull_request' || !contains(github.event.head_commit.message, '[skip ci]')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - # set up the toolchain (language version pinned), with dependency cache
      - run: <install>
      - run: <lint + typecheck>      # same checks as the devex pre-commit hook
      - run: <unit tests>
      - run: <integration tests>     # bring up Docker deps as needed (see devex)
```

- **Gate on the same checks developers run locally** — the `devex` pre-commit and this gate must agree, or "passes locally, fails in CI" erodes trust (`principles-dry-kiss`).
- Run the **test tiers** per `principles-tdd`: unit always; integration/e2e with their Docker/build-tag setup. Don't silently skip a tier — a skipped tier is an untested tier.
- **Cache** dependencies and build outputs keyed on lockfiles; caching is the cheapest pipeline speedup.
- Make integration/e2e dependencies the **same pinned versions** as local `devex` compose and `cloud-infra` provisioning.

### 2. Release automation

Automate versioning from commit history so humans never hand-edit versions.

```yaml
# .github/workflows/release.yml
name: release
on:
  push: { branches: [main] }
permissions: { contents: write }
concurrency: { group: release, cancel-in-progress: false }  # serialize: two merges can't race the same bump
jobs:
  release:
    if: ${{ !contains(github.event.head_commit.message, '[skip ci]') }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0, persist-credentials: true }  # full history to tag; creds to push the bump
      - # derive the bump from the squash-merge subject per the git-workflow semver table
      - # bump the version file, commit as `chore(release): vX.Y.Z [skip ci]`, tag, publish
```

- **Break the loop:** the bot's release commit must carry `[skip ci]` (or an equivalent path filter) so it doesn't trigger another release.
- **Never interpolate untrusted text into a shell `run:`** — pass commit messages/PR titles via `env:`, not inline `${{ … }}`, to avoid script injection.
- Derive the bump from **Conventional Commits** (see `git-workflow`); keep the rule the release script reads (subject line) consistent with what `git-workflow` documents.
- Tag and cut a release with generated notes; for deploys, publish the artifact and let CD promote it.

## Continuous delivery / environments

- Promote one built artifact through environments (e.g. staging → prod); do **not** rebuild per environment (`principles-dry-kiss` — the artifact tested is the artifact shipped).
- Keep environment differences in config (from the `cloud-infra` secrets/config mechanism), not in separate builds.
- Gate production promotion on the validate gate being green plus any required approval.
- Make rollback a first-class, documented step — a deploy you can't reverse is a liability.

## Security & secrets

- Pin action versions (avoid floating `@v`-less or mutable tags where supply-chain risk matters).
- Least-privilege `permissions:` per workflow; grant `contents: write` etc. only where needed.
- Secrets come from the CI provider's secret store, injected as env — never committed, never echoed into logs.

## Boundaries

- **`git-workflow`** owns the commit/PR/merge conventions and the semver-from-subject mapping — reference it; don't restate it.
- **`cloud-infra`** owns what the pipeline deploys *to* (provisioned targets, secrets store). **`devex`** owns the local mirror of these checks. This skill owns the pipeline itself.
