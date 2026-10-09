#!/usr/bin/env python3
"""Seed a throwaway $HOME with fake named Claude Code sessions for demo screenshots.

Usage: python3 demo/seed.py <fake-home>
"""
import json
import os
import sys
import time
import uuid

SESSIONS = [
    # (title, project dir, age in seconds, prompts)
    ("auth-refactor", "api-gateway", 25 * 60, [
        "move the JWT validation out of the middleware and into its own package",
        "add tests for expired and malformed tokens",
        "the refresh endpoint still uses the old helper, update it too",
        "run the full suite and fix anything that broke",
    ]),
    ("flaky-ci-tests", "web-app", 3 * 3600, [
        "the checkout e2e test fails about 1 in 5 runs on CI, figure out why",
        "add a retry around the payment iframe load and log timings",
        "that wasn't it. look at the shared fixture teardown order",
    ]),
    ("release-notes-v2.4", "web-app", 9 * 3600, [
        "draft release notes for v2.4 from the merged PRs since v2.3.0",
        "group them by feature, fix, and chore",
        "shorter. one line per item",
    ]),
    ("postgres-migration", "billing", 2 * 86400, [
        "write a migration that splits invoices.amount into amount_cents and currency",
        "make it backfill in batches of 10k so it doesn't lock the table",
        "add a down migration",
    ]),
    ("dark-mode", "web-app", 3 * 86400, [
        "add a dark mode toggle to the settings page using CSS variables",
        "persist the choice in localStorage and respect prefers-color-scheme by default",
    ]),
    ("k8s-helm-chart", "infra", 5 * 86400, [
        "create a helm chart for the api-gateway service",
        "add an HPA targeting 70% cpu",
        "lint it and render the templates for staging",
    ]),
    ("rate-limiter", "api-gateway", 9 * 86400, [
        "implement a token bucket rate limiter backed by redis",
        "benchmark it at 5k rps",
    ]),
    ("cli-rewrite-go", "devtools", 16 * 86400, [
        "port the bash deploy script to a Go CLI with cobra",
        "add --dry-run",
    ]),
    ("dotfiles-cleanup", "~", 23 * 86400, [
        "find unused aliases in ~/.aliases",
        "remove the ones that point at tools I no longer have installed",
    ]),
    ("onboarding-docs", "handbook", 31 * 86400, [
        "turn these notes into an onboarding guide for new backend engineers",
    ]),
]


def rec(**kw):
    return json.dumps(kw, separators=(",", ":"))


def main(home):
    now = time.time()
    for title, proj, age, prompts in SESSIONS:
        cwd = home if proj == "~" else os.path.join(home, "code", proj)
        os.makedirs(cwd, exist_ok=True)
        pdir = os.path.join(home, ".claude", "projects", cwd.replace("/", "-"))
        os.makedirs(pdir, exist_ok=True)
        path = os.path.join(pdir, f"{uuid.uuid4()}.jsonl")
        lines = [rec(type="custom-title", customTitle=title)]
        for p in prompts:
            lines.append(rec(type="user", cwd=cwd, message={"role": "user", "content": p}))
            lines.append(rec(type="assistant", cwd=cwd, message={"role": "assistant", "content": [{"type": "text", "text": "Done. " * 400}]}))
        with open(path, "w") as fh:
            fh.write("\n".join(lines) + "\n")
        t = now - age
        os.utime(path, (t, t))


if __name__ == "__main__":
    target = os.path.abspath(sys.argv[1])
    # Only seed a fresh, empty directory so this can never touch a real ~/.claude.
    if not os.path.isdir(target) or os.listdir(target):
        sys.exit(f"seed.py: {target} must be an existing empty directory")
    main(target)
