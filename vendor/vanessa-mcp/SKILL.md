---
name: vanessa-mcp
description: "Protocol for writing, checking and running Vanessa Automation scenario tests (.feature / Gherkin / Turbo Gherkin) through the Vanessa MCP server and its test client. Use whenever the user asks to write, debug, or run a Vanessa scenario, a .feature file, a UI test of the 1C test client (клиент тестирования), or mentions Vanessa MCP / Vanessa Automation. Enforces the tool loop (state → library steps → check_syntax → run_scenario → fix by run result), bans invented Gherkin steps, and keeps Vanessa separate from the data MCPs (1c_mcp / 1c-data-mcp)."
---

# Vanessa MCP — scenario protocol

Contract for the Cursor agent when authoring and running Vanessa Automation UI scenarios via MCP. Files are English; Gherkin keywords and step text in `.feature` files stay Russian; replies to the user stay Russian.

Companion docs — load on demand:

- [`docs/tools.md`](docs/tools.md) — full Vanessa MCP tool catalog grouped by workflow phase (baseline names + live aliases).
- [`docs/write-loop.md`](docs/write-loop.md) — the research → write → syntax → run → fix loop, step by step.
- Project setup (server, ports, test client, VAExtension) — [`docs/integration.md`](docs/integration.md). Do **not** put this guide in project `_docs/` (`_docs` is user documents only).

## When this skill applies

Load it when the user asks to: write / edit / debug / run a Vanessa `.feature` scenario; do a UI test of the test client (клиент тестирования); work through Vanessa MCP / Vanessa Automation; search Gherkin (Turbo Gherkin) steps for a scenario. Narrow one-off questions the parent can answer with a single tool call do not require the full loop.

## Preflight (before any scenario work)

1. **MCP exposed?** Confirm the Vanessa MCP tools are in the current session schema (the server is typically `VanessaAutomation` in `.cursor/mcp.json`). If they are **not** exposed, tell the user to keep «Управление МСР» running and reload Cursor MCP, and do **not** pretend a tool was called or claim a `run_scenario` result. The URL/port lives in `.cursor/mcp.json` (`VanessaAutomation.url`) — read it there, do not hardcode a port.
2. **State first.** Call `get_vanessa_automation_state` (live name wins — see below) before UI actions: is a scenario running, which feature/scenario is current, is the test client connected.
3. **Test client connected?** If not, read the profile name from `manage_test_client_profiles` (`action=get_list`) and connect via `manage_test_client` (`action=connect`) with that exact profile name. Do not assume a hardcoded profile. Do not reconnect if already connected unless an error requires it.

## Hard bans

- **No invented Gherkin steps.** Never write a step from memory. Find each step via `search_for_steps_by_keywords` (or `frequently_used_steps`) in the Vanessa library first. A file with unknown steps MUST NOT be run.
- **No skipping syntax check.** After writing or editing a `.feature`, run `check_syntax` (via `open_feature_file` first). Only a zero-problem file may go to `run_scenario`.
- **No wrong MCP class.** For Vanessa UI scenarios use the Vanessa Automation MCP only. `1c_mcp` (Kharin) and `1c-data-mcp` manage IB data over HTTP — they do **not** drive the test client and are out of scope here.
- **No OS titles as window assertions.** «открылось окно …» asserts the inner 1C window title from `get_window_list_testclient` / `get_active_window_data`, not the OS application caption (e.g. `Демо-база / Управление торговлей, редакция 11`).
- **No fake success.** If `run_scenario` did not return Success, or the client/MCP is down, say so and record the blocker — never claim a verified run.

## The loop (short)

```
state → (connect client) → search library steps → write/edit .feature (tests/features/)
      → open_feature_file → check_syntax → load_features → run_scenario → get_test_results
      → on fail: fix by reported window/step/error → re-run → until Success or documented blocker
```

Full detail, including form inspection and screenshot debugging, in [`docs/write-loop.md`](docs/write-loop.md).

## Baseline vs live tool names

The baseline catalog is the official `docs/AI/index.md` (branch `develop`); names are **snake_case** (`get_vanessa_automation_state`, `manage_test_client` with `action=connect`, `search_for_steps_by_keywords`, `check_syntax`, `run_scenario`, `get_test_results`). There is **no** `connect_test_client` tool — connection is `manage_test_client action=connect`. If the current session exposes a tool under a different name, **call the live name** and note it as an alias in `docs/tools.md`. The session schema is the final authority.

## Project facts

- New / edited scenario files live under `tests/features/`. Reports go to `tests/reports/`, screenshots to `tests/screenshots/` (both out of git). Never put `.feature` under `src/` or `_docs/`.
- Gherkin header: `# language: ru`; keywords `Функционал:` / `Сценарий:` and Russian step text. Typical library-step examples (confirm each via search before writing): `И я закрываю все окна клиентского приложения`, `И Пауза 1`, `Когда В командном интерфейсе я выбираю "Продажи" "Заказы клиентов"`, `Тогда открылось окно "Заказы клиентов"`, `И я активизирую окно "Начальная страница"`.
- The test manager IB, `client_mcp.cfe`, Vanessa EPF, VanessaExt and VAExtension are operational prerequisites. This skill does not install or change them, nor any BSL / metadata / CFE. Setup: [`docs/integration.md`](docs/integration.md).
