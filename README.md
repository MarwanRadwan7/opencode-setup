# opencode-setup

## LSP Setup: Install All Language Servers at Once
```bash
chmod +x setup-lsps.sh && ./setup-lsps.sh
```
### What's covered vs. what opencode auto-installs
 
| Installed by script | Auto-installed by opencode |
|---|---|
| gopls, rust-analyzer, pyright | astro, bash-language-server |
| typescript-language-server | clangd, kotlin-ls, lua-ls |
| ruby-lsp, csharp-ls | php-intelephense, svelte |
| elixir-ls, hls, ocamllsp | terraform, tinymist |
| clojure-lsp, zls, nixd | vue, yaml-language-server |
| jdtls (Java, Linux only) | eslint (requires project dep) |
 
> **Note:** Language runtimes themselves (Go, Rust, Node, Java, .NET, Ruby, etc.) must be installed before running this script. The script only installs the LSP servers on top of whatever runtimes you already have.

## Installing Necessary Skills for Opencode Agent

```bash
npx skills add jeffallan/claude-skills
```

## Cool Plugins

- [OpenCode Open Agent Control](https://github.com/darrenhinde/OpenAgentsControl)
- [OpenCode-Notify](https://github.com/kdcokenny/opencode-notify)
- [OpenCode Agent Skills Discovery](https://github.com/joshuadavidthomas/opencode-agent-skills)

---
## Cool Skills

### Valyu: Real-Time Web Search & Specialised Data Access

The problem: Coding agents are excellent at working with code. They're much worse at working with the real world because the real world is locked behind paywalls, proprietary databases, and specialized APIs that general-purpose search can't reach.

- Building a financial research app? You need SEC filings.
- Building a biomedical tool? You need PubMed and ChEMBL.
- Building an economic analysis dashboard? You need FRED and BLS.

Without these data sources, agents generate plausible-sounding but outdated or fabricated information.

What it does: The Valyu skill connects coding agents to 36+ specialised data sources, search for docs, and quality web search through a single API. One search call returns results from across the web AND sources like SEC 10-K filings, PubMed, ChEMBL (2.5M bioactive compounds), clinical trials, FRED economic indicators, patent databases, and academic publishers.

```bash
npx skills add https://github.com/valyuai/skills --skill valyu-best-practices
```

---

### PlanetScale Database Skills

The problem: Database work is where agents make their worst mistakes. Schema design decisions that cause pain six months later. Queries that work fine at 100 rows and collapse at 100,000. Missing indexes discovered only in production.

Agents treat databases like any other code. They write something that runs and move on.

PlanetScale's database skills change this by giving agents deep context about serverless MySQL, Postgres, branching workflows, and query performance from the start.

What it does: PlanetScale runs a serverless MySQL-compatible database platform with a branching model that maps directly to git: you create a database branch for each feature, merge it when done, and never touch production schema directly. The PlanetScale skill teaches agents to:

- Design schemas using PlanetScale's foreign key and branching conventions
- Write queries that use indexes correctly (and flag when they won't)
- Use `pscale` CLI to create branches, deploy requests, and manage migrations
- Treat schema changes as code — reviewable, reversible, mergeable

```bash
# Install pscale CLI
brew install planetscale/tap/pscale

# Authenticate
pscale auth login

# Install the skill
npx skills add planetscale/agent-skill
```

**Example workflow the agent handles end-to-end:**

> User: Add user preferences to the schema

Agent:
1. Creates a new database branch: `pscale branch create mydb add-user-prefs`
2. Switches connection to the branch
3. Designs the schema:

```sql
CREATE TABLE user_preferences (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id VARCHAR(36) NOT NULL,
  theme ENUM('light', 'dark', 'system') DEFAULT 'system',
  notifications_enabled TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user_id (user_id)
);
```

---

### Excalidraw Diagram Generator

The problem: Architecture decisions, system designs, data flow explanations — these are communicated in prose or in whiteboard sessions that nobody records.

Code comments describe what something does; diagrams show why it's structured that way. Most agents can describe an architecture in text. Almost none can generate a diagram that makes the argument visually.

What it does: This skill generates production-quality Excalidraw diagrams from natural language descriptions. What makes it different from simpler diagram tools is the design philosophy baked into the skill itself:

- **Diagrams that argue, not display.** Every shape and grouping mirrors the concept it represents. Fan-out structures for one-to-many relationships. Timeline layouts for sequential flows. Convergence shapes for aggregation. The agent doesn't default to uniform card grids — it maps visual structure to conceptual structure.
- **Evidence artifacts.** Technical diagrams include actual code snippets and real JSON payloads inline, not placeholder text.
- **Visual self-validation.** The skill includes a Playwright-based render pipeline. The agent generates the Excalidraw JSON, renders it to PNG, reviews its own output for layout issues (overlapping text, misaligned arrows, unbalanced spacing), and fixes problems before presenting the result. No more broken diagrams.

```bash
npx skills add https://github.com/coleam00/excalidraw-diagram-skill --skill excalidraw-diagram
```

**Example prompts:**

```
Create an Excalidraw diagram showing how a request flows through
our API gateway, auth middleware, and downstream services

Generate an architecture diagram for a multi-tenant SaaS with
separate database schemas per tenant and a shared analytics layer

Draw a sequence diagram for our OAuth2 PKCE flow including
the browser, authorization server, and resource server
```

---

### Shannon: Autonomous AI Pentester

The problem: Security testing is the step most development teams skip — not because they don't care, but because it's expensive, slow, and requires specialized knowledge.

A traditional pentest costs thousands of dollars and returns a PDF report two weeks later. Manual security review catches some vulnerabilities and misses others based on the reviewer's specific expertise. Meanwhile, the codebase keeps moving.

Shannon is an autonomous pen testing agent that runs against your local or staging environment, executes real exploits, and reports only the vulnerabilities it can actually prove.

What it does: The Shannon skill wraps KeygraphHQ's Shannon, a white-box security testing framework that analyzes source code, maps attack surfaces, and executes real attacks across 50+ vulnerability types in 5 OWASP categories.

The benchmark result worth knowing: **96.15% exploit success rate** on the XBOW security benchmark (100/104 exploits). This is not a scanner that flags potential issues — it's an agent that either exploits the vulnerability or doesn't report it.

```bash
npx skills add unicodeveloper/shannon
```

> Prerequisites: Docker (runs everything in containers) and an Anthropic API key.

**How to run:**

```bash
# Full pentest of a local app
/shannon http://localhost:3000 myapp

# Target specific vulnerability categories
/shannon --scope=xss,injection http://localhost:8080 frontend

# Named workspace (for resuming if interrupted)
/shannon --workspace=audit-q1 http://staging.example.com backend-api

# Check status of a running pentest
/shannon status

# View the latest report
/shannon results
```

**The 5-phase pipeline** (runs in parallel where possible):

| Phase | Name | Description |
|-------|------|-------------|
| 1 | Pre-Recon | Static source code analysis + external scans (Nmap, Subfinder, WhatWeb) |
| 2 | Recon | Live attack surface mapping via headless browser |
| 3 | Vulnerability Analysis | 5 parallel agents: Injection / XSS / SSRF / Authentication / Authorization |
| 4 | Exploitation | Each agent spawns a dedicated exploitation agent, executes real attacks |
| 5 | Reporting | Executive summary + reproducible PoC for every finding |

**What Shannon covers (50+ specific vulnerability types):**

- **Injection:** SQL injection (union, blind, time-based), command injection, SSTI, NoSQL injection
- **XSS:** Reflected, stored, DOM-based, via file upload, mutation XSS
- **SSRF:** Internal service access, cloud metadata (AWS/GCP/Azure), DNS rebinding, protocol smuggling
- **Broken Authentication:** Default credentials, JWT flaws (none algorithm, weak signing), session fixation, CSRF, MFA bypass
- **Broken Authorization:** IDOR, privilege escalation, path traversal, forced browsing, mass assignment

**Runtime and cost:** ~1–1.5 hours per full pentest, ~$50 using Claude Sonnet.

**Safety gates built in:** Shannon confirms authorization before every run, warns against production targets, supports scope controls and avoid-list rules (e.g. skip `/logout`, `/admin/delete`), and runs all attack tools inside Docker. Nothing executes on your host.

> ⚠️ **Important:** Shannon executes real attacks. Only run it against systems you own or have explicit written authorization to test. The skill enforces an authorization gate at every invocation.

---

### Browser Use

The problem: Coding agents are blind to the live web. They can write a scraper, but they can't run it. They can describe what a page looks like, but they can't interact with it. If your agent needs to fill out a form, log into a dashboard, scrape dynamic content, or verify that a deployed feature actually works end-to-end, you've hit a wall.

Browser Use solves this by giving the agent actual control of a browser.

What it does: The Browser Use skill connects Claude to a headless browser instance. The agent can navigate URLs, click elements, fill forms, extract content from JavaScript-rendered pages, take screenshots, and interact with complex web UIs — all as part of a natural language workflow.

This is different from scraping libraries. The agent doesn't need to understand the DOM structure ahead of time. It navigates the web the same way a human does: look, click, read, act.

```bash
npx skills add https://github.com/browser-use/browser-use --skill browser-use
```

**Example workflow:**

> User: Check that the signup flow on our staging environment works end-to-end and screenshot any errors

Agent:
1. Opens `https://staging.yourapp.com/signup`
2. Fills in test email and password
3. Clicks "Create account"
4. Follows verification email link
5. Screenshots the dashboard (confirms successful signup)
6. Reports: "Signup flow works. One issue: the 'Verify email' button is below the fold on mobile. Find attached screenshot."

The same skill handles research tasks: "Find the three most recent funding announcements in climate tech and summarize the amounts and investors." The agent actually opens pages, reads them, and synthesises — not from cached training data, but from the live web.

Browser Use turns Claude from a code-generation tool into an end-to-end QA engineer, research analyst, and automation operator. Any workflow that requires a human to open a browser and click through something is now a workflow the agent can handle.
