---
description: Interview the user about the project's tech stack and write .ai/stack-profile.md, which overrides the implementation skills' built-in defaults.
argument-hint: [optional stack hints]
---

Invoke the `stack-profile` skill to set up this project's stack profile.

Interview the user for the dimensions in the `stack-profile` format — languages, frontend framework, component primitives, styling, forms/validation, URL state, backend language(s) + HTTP framework + validation, data stores, infra target + IaC + local infra, test runner + e2e. Use any hints in: $ARGUMENTS. Ask only for what isn't already obvious from the hints or the existing repo (Grep/Glob for package.json, go.mod, Cargo.toml, existing configs first).

Then write `.ai/stack-profile.md` per the `stack-profile` skill's format — **write only the lines that diverge from the defaults**; omit fields that match a default (a present-but-blank field would be ambiguous). If nothing diverges, say so and skip writing the file. Note explicitly which choices differ from the built-in defaults, and remind the user that discipline (TDD/DDD/pragmatic-SOLID/DRY-KISS, ports-and-adapters, test tiers, naming) stays invariant regardless of stack.
