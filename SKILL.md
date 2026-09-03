---
name: 1c-project-scaffold
description: Scaffolds the standard 1C working-directory layout (src/cf cfe epf erf, tests/features fixtures screenshots reports, tools/vanessa, tools/neurofish-mcp, tools/mcp-toolkit, _INFOBASE, _LOGS, _archives, build, _tmp, _handoffs, _docs). Asks offline vs online before any download (offline = vendor/offline archive; online = GitHub latest). Installs comol/ai_rules_1c (AGENTS.md, .cursor rules/agents/commands/skills, .dev.env), optionally installs Vanessa (ask first; then EPF/CFE plus the vanessa-mcp skill), optionally installs Конвертация данных 2/3 (ask first; then MCP_Toolkit.epf plus kd2-rules / kd31-rules / 1c-mcp-toolkit), optionally installs comol/Humanizer_RU (ask first: skip / project-local / machine-global), and initializes OpenSpec (`openspec init`) so OPSX slash commands are present. Use when starting a new 1C project, preparing a working catalog, or when the user asks for каркас / структура каталогов / _INFOBASE / _LOGS / _docs / Vanessa tests / КД 2 / КД 3 / MCP Toolkit / Humanizer RU / установку правил 1С / OpenSpec.
---

# 1C project scaffold

Repeat a standard 1C working layout in **any** project root. First **ask** offline vs online (do not clone / curl GitHub / `npx` until that choice). Then install [comol/ai_rules_1c](https://github.com/comol/ai_rules_1c) into that same root, then **ask** whether Vanessa Automation will be used (do not place binaries until an explicit yes), then **ask** whether Конвертация данных 2 / 3 will be used (do not place MCP Toolkit until an explicit choice), then **ask** whether to install [comol/Humanizer_RU](https://github.com/comol/Humanizer_RU) (skip / project-local / machine-global), then initialize OpenSpec. Do **not** create `1Cv8.1CD` unless the user explicitly picks an option on the step-8 question (empty IB or a template). Do **not** vendor the 1c-rules clone into the project. Scaffold is incomplete until OpenSpec init succeeds or is proven already done (step 5).

## Layout to create

```
src/cf/              # XML dump of main configuration  → EXPORT_PATH
src/cfe/             # extension sources               → EXTENSIONS_PATH
src/epf/
src/erf/
tests/features/      # Vanessa .feature scenarios
tests/fixtures/      # test JSON/XML/CSV
tests/screenshots/   # run screenshots (gitignored)
tests/reports/       # run reports (gitignored)
tools/vanessa/       # vanessa-automation-single.epf + VAExtension.cfe (downloaded only if Vanessa=yes; *.epf/*.cfe gitignored)
tools/neurofish-mcp/ # client_mcp.cfe (downloaded only if Vanessa=yes; *.cfe gitignored)
tools/mcp-toolkit/   # MCP_Toolkit.epf (downloaded only if KD=2/3/both; *.epf gitignored)
build/_for_debug/    # build artifacts                 → RELEASE_PATH
_INFOBASE/           # file infobase (folder; 1Cv8.1CD only after step 8 choice) → INFOBASE_PATH
_LOGS/               # Designer / ibcmd log            → LOG_PATH
_archives/           # source .cf / .cfe / .dt         → ARCHIVES_PATH
_tmp/                # scratch / temp                  → TMP_PATH
_handoffs/           # session handoff notes           → HANDOFFS_PATH
_docs/               # project documentation (in git)  → DOCS_PATH
.gitignore
.cursorignore
```

Empty dirs get `.gitkeep`. If `src/cf` already has a dump, leave its files untouched.

Vanessa dirs are **not** registered in 1C metadata. Paths to features / reports / screenshots are set later in Vanessa UI or VAParams when running tests. Binaries are downloaded only after an explicit **yes** on the step-4 Vanessa question — never on silence and never on **no**. The empty `tools/mcp-toolkit/` dir is created in step 2; `MCP_Toolkit.epf` is downloaded only after an explicit КД choice on step 4.5 — never on silence and never on **0 / нет**.

1c-rules (step 3) also places `openspec/` (README, `specs/`, `changes/`, stub `project.md`). That folder is **not** a substitute for step 5: Cursor `/opsx-*` commands appear only after official `openspec init`.

## Steps

1. Resolve the target root: the directory the user named, or the current project root. Confirm it is a project folder, not `~` / `Downloads` / a CLI config dir (`~/.cursor`, `~/.config`, `~/.codex`, `~/.claude`). Stop and ask if the path is ambiguous.

1.5. **Ask** whether to install dependencies **offline** or **online**. Do this **before** any `git clone`, GitHub `/releases/latest`, or `npx`. Do **not** download or copy binaries yet. Do **not** treat silence as either choice. One question, in the user’s language:

   - онлайн — clone `comol/ai_rules_1c` from GitHub; Vanessa / neurofish / MCP Toolkit from `/releases/latest`; clone `comol/Humanizer_RU` if the user picks local/global on step 4.6; OpenSpec via `openspec` on PATH or `npx --yes @fission-ai/openspec@latest`. Call install/download scripts **without** `--offline`.
   - офлайн — no network for those deps. Copy from the skill archive [vendor/offline/1c-scaffold-deps.tar.gz](vendor/offline/1c-scaffold-deps.tar.gz) (versions in [vendor/offline/MANIFEST.txt](vendor/offline/MANIFEST.txt)). Pass `--offline` to `install-1c-rules.sh`, `download-vanessa-deps.sh`, `download-mcp-toolkit.sh`, and `install-humanizer-ru.sh` (`--offline` may appear anywhere in argv). OpenSpec: only a local `openspec` on PATH; if it is missing — **stop** (do not `npx`). If the archive or a required member is missing (script exit 2) — **stop** that branch; do **not** fall back to GitHub. To refresh the archive later (while online): `bash ~/.cursor/skills/1c-project-scaffold/scripts/pack-offline-bundle.sh`.

   Remember the choice for every later install/download step in this run. Vanessa / KD / Humanizer / IB questions stay the same; only the source of 1c-rules, binaries, and Humanizer changes.

2. Create dirs and ignore files:

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/scaffold.sh "/absolute/path/to/project"
```

Templates live in [templates/gitignore](templates/gitignore) and [templates/cursorignore](templates/cursorignore). Existing `.gitignore` / `.cursorignore` are kept; if `.gitignore` already exists without Vanessa artifact rules, the script **appends** `tests/screenshots/*` and `tests/reports/*` (keeping `.gitkeep`).

3. Install **1c-rules** into the same project root (protocol: that repo’s `AGENT-INSTALL.md`).

   - If `.ai-rules.json` already exists: skip init (do not re-init, do not `update` unless the user asked).
   - Default tool: `cursor`. Add other adapter ids only when their directories already exist (`.opencode/`, `.claude/`, …) or the user named them.
   - Preferred channel — PowerShell installer (`pwsh` required):

     Online:

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/install-1c-rules.sh "/absolute/path/to/project" cursor
```

     Offline (snapshot from the bundle, no `git clone`):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/install-1c-rules.sh "/absolute/path/to/project" cursor --offline
```

   - If the script exits `2` (`pwsh` missing): follow `AGENT-INSTALL.md` lean placement yourself. Online: clone to a **temp** cache. Offline: use the path printed as `offline_ai_rules_source=` (already extracted from the bundle — do not clone). Copy from `content/` via `adapters/cursor.yaml`, rewrite `AGENTS.md` paths, write `.ai-rules.json`. Do not dump the clone/snapshot into the project.
   - `USER-RULES.md`, `memory.md`, `LLM-RULES.md` are created once and never overwritten by the installer. Keep any structure section already in `USER-RULES.md`.
   - Do not hand-edit installed `AGENTS.md`.

4. **Ask** whether this project will use **Vanessa Automation** (сценарные UI-тесты, `.feature`, MCP, клиент тестирования). Do this **before** any Vanessa download, `vanessa-mcp` install, or `mcp.json` write. Do **not** download silently. Do **not** treat silence as “no” or “yes”. One question, in the user’s language:

   - 0 / нет — не скачивать зависимости Vanessa, не ставить скилл `vanessa-mcp`, не писать `vanessaAutomation` в `.cursor/mcp.json`, не добавлять абзац «Сценарные тесты Vanessa» в `USER-RULES.md`. Empty `tests/` and `tools/vanessa` / `tools/neurofish-mcp` dirs stay (created in step 2). Report: `Vanessa: skipped (user declined)`.
   - да — run the Vanessa branch **in this order**. If a download script exits non-zero (network / GitHub 4xx / missing asset, or offline: missing bundle / missing member) — **stop the Vanessa branch**: do not install `vanessa-mcp`, do not write `mcp.json` / `_docs`, do not pretend binaries are in place. Do **not** fall back to GitHub when the user chose offline. Continue with Humanizer (step 4.6) and OpenSpec (step 5) and report the Vanessa failure.

     a. Binaries. Does **not** overwrite existing `*.epf` / `*.cfe`. Does **not** load anything into an infobase.

        Online (GitHub `/releases/latest`, no version hardcoded):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/download-vanessa-deps.sh "/absolute/path/to/project"
```

        Offline (copy from the skill archive):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/download-vanessa-deps.sh "/absolute/path/to/project" --offline
```

        Sources (online): [1c-neurofish/onec-client-mcp-devkit](https://github.com/1c-neurofish/onec-client-mcp-devkit/releases/latest) → `tools/neurofish-mcp/client_mcp.cfe`; [Pr-Mex/vanessa-automation](https://github.com/Pr-Mex/vanessa-automation/releases/latest) → `tools/vanessa/vanessa-automation-single.epf` (from the `vanessa-automation-single*.zip`, not the full zip) and `tools/vanessa/VAExtension.cfe`. Do **not** download `training.zip`, `TTSCache.zip`, or a separate VanessaExt CFE (the add-in is inside the single EPF). Script stdout includes `source=online|offline`, tags/URLs — copy them into the step-9 report. `VERSION.txt` next to each dest is git-tracked; binaries are gitignored.

     b. Vendored **vanessa-mcp** skill:

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/install-vanessa-mcp.sh "/absolute/path/to/project"
```

        Copies [vendor/vanessa-mcp/](vendor/vanessa-mcp/) → `$ROOT/.cursor/skills/vanessa-mcp/`. If `$ROOT/.cursor/skills/vanessa-mcp/SKILL.md` already exists — skip (do not overwrite). If `~/.cursor/skills/vanessa-mcp/SKILL.md` is missing on this machine — copy there too; if it exists, leave it. Script stdout ends with `vanessa-mcp: installed | already present | skipped (no vendor)` — put that line in the final report. Do **not** hand-edit `AGENTS.md` for this skill; Cursor loads it from `.cursor/skills/vanessa-mcp/SKILL.md`.

     c. Project MCP URL + install guide (only if missing; merge `vanessaAutomation` into an existing `.cursor/mcp.json` that lacks the key; never overwrite an existing `vanessaAutomation` / `VanessaAutomation` entry; URL is `http://127.0.0.1:5431/mcp` — not an AWG / docker-gateway address):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/install-vanessa-config.sh "/absolute/path/to/project"
```

        Setup guide lives in the skill: [vendor/vanessa-mcp/docs/integration.md](vendor/vanessa-mcp/docs/integration.md) (copied with the skill). Do **not** write it into `_docs/`. After the first MCP start, the user must match the port in `.cursor/mcp.json` to the form «Управление МСР».

4.5. **Ask** whether this project will use **Конвертация данных** (КД 2.0 XML-правила / КД 3.1 EnterpriseData, живая ИБ КД, MCP Toolkit). Do this **before** any toolkit download or `kd2-rules` / `kd31-rules` / `1c-mcp-toolkit` install. Do **not** download silently. Do **not** treat silence as “no” or a version pick. One question, in the user’s language:

   - 0 / нет — не скачивать `MCP_Toolkit.epf`, не ставить скиллы `1c-mcp-toolkit` / `kd2-rules` / `kd31-rules`, не добавлять секцию «Конвертация данных» в `USER-RULES.md`. Empty `tools/mcp-toolkit` stays (created in step 2). Report: `KD: skipped (user declined)`.
   - КД 2 / КД 3 / обе — run the KD branch **in this order**. If the download script exits non-zero (network / GitHub 4xx / missing asset, or offline: missing bundle / missing member) — **stop the KD branch**: do not install the skills, do not write `_docs`, do not pretend the EPF is in place. Do **not** fall back to GitHub when the user chose offline. Continue with Humanizer (step 4.6) and OpenSpec (step 5) and report the KD failure.

     a. EPF. Does **not** overwrite an existing `tools/mcp-toolkit/*.epf`. Does **not** load anything into an infobase.

        Online (GitHub `/releases/latest`, no version hardcoded):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/download-mcp-toolkit.sh "/absolute/path/to/project"
```

        Offline (copy OS asset from the skill archive):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/download-mcp-toolkit.sh "/absolute/path/to/project" --offline
```

        Source (online): [ROCTUP/1c-mcp-toolkit](https://github.com/ROCTUP/1c-mcp-toolkit/releases/latest). OS asset: Linux → `MCP_Toolkit_linux.epf`, Windows → `MCP_Toolkit.epf`, macOS → `MCP_Toolkit_macos.epf`; saved as `tools/mcp-toolkit/MCP_Toolkit.epf`. Script stdout includes `source=online|offline`, `mcp-toolkit_tag` / `mcp-toolkit_url` — copy them into the step-9 report. `VERSION.txt` is git-tracked; the `*.epf` is gitignored.

     b. Vendored skills (`1c-mcp-toolkit` always + chosen KD skill(s)). Second argument: `kd2` | `kd31` | `both`:

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/install-kd-skills.sh "/absolute/path/to/project" both
```

        Copies [vendor/1c-mcp-toolkit/](vendor/1c-mcp-toolkit/) (incl. [docs/integration.md](vendor/1c-mcp-toolkit/docs/integration.md)), [vendor/kd2-rules/](vendor/kd2-rules/), [vendor/kd31-rules/](vendor/kd31-rules/) → `$ROOT/.cursor/skills/<name>/` (only the names implied by the argument). If `$ROOT/.cursor/skills/<name>/SKILL.md` already exists — skip (do not overwrite). If `~/.cursor/skills/<name>/SKILL.md` is missing on this machine — copy there too; if it exists, leave it. Appends `MCP_TOOLKIT_PORT` / `KD2_PORT` / `KD31_PORT` to `.dev.env` when those keys are missing. Do **not** write skill guides into `_docs/`. Script stdout has `<name>: installed | already present | skipped (no vendor)` — put those lines in the final report. Do **not** hand-edit `AGENTS.md`; Cursor loads skills from `.cursor/skills/<name>/SKILL.md`. Do **not** write a Cursor MCP URL for toolkit (agent uses HTTP curl to localhost).

4.6. **Ask** whether to install **Humanizer RU** ([comol/Humanizer_RU](https://github.com/comol/Humanizer_RU) — editor of Russian LLM text, not an AI-detector). Do this **before** any clone or copy of `humanizer-ru`. Do **not** install silently. Do **not** treat silence as “no” or a scope pick. Do **not** call `npx skills add`. One question, in the user’s language:

   - 0 / нет — не копировать скилл, не добавлять абзац «Читаемость русского» в `USER-RULES.md`. Report: `humanizer-ru: skipped (user declined)`.
   - локально — только `$ROOT/.cursor/skills/humanizer-ru/`.
   - глобально — только `~/.cursor/skills/humanizer-ru/`.

   Local and global are exclusive. Do **not** write both. Do **not** overwrite an existing `SKILL.md` at the chosen dest. Do **not** touch `~/.cursor/skills/humanizer/` (a different skill). Do **not** install the Python linter package.

   If the install script exits non-zero (network / clone / missing bundle member) — **stop the Humanizer branch**; do **not** fall back to GitHub when the user chose offline. Continue with OpenSpec (step 5) and report the Humanizer failure.

     Online (`git clone --depth=1`, copy `skills/humanizer-ru/`):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/install-humanizer-ru.sh "/absolute/path/to/project" local
```

     Offline (member `humanizer-ru/` in the skill archive):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/install-humanizer-ru.sh "/absolute/path/to/project" global --offline
```

     Second argument is `local` or `global` matching the user’s pick. Script stdout includes `source=online|offline`, `humanizer_ru_commit=…`, `scope=local|global`, `humanizer-ru: installed | already present` — copy those lines into the step-9 report.

5. Initialize **OpenSpec** in the same project root. Mandatory: do not skip, do not treat the 1c-rules `openspec/` scaffold as done.

   - **Tools** — same set as step 3: default `cursor`; add other adapter ids when their directories already exist or the user named them. Pass them to CLI as `--tools cursor` or `--tools cursor,claude,...`.
   - **Node** — require Node ≥ 20.19.0 (`node -v`). If Node is missing or older — **stop**. Report that Node 20.19+ is required; do not continue the scaffold without OpenSpec.
   - **CLI** — if `openspec` is on PATH, use it.
     - **Online** and PATH has no `openspec`: invoke via `npx --yes @fission-ai/openspec@latest` (do not require a global `npm install -g`).
     - **Offline**: do **not** call `npx`. If `openspec` is missing from PATH — **stop**. Report that a local OpenSpec CLI is required for offline install (`npm i -g @fission-ai/openspec` while online, or choose online mode). Do not continue the scaffold without OpenSpec.

     Example with a local CLI:

```bash
cd "/absolute/path/to/project"
openspec init --tools cursor --no-animation --profile core
```

     Example without a local CLI (**online only**; replace `cursor` with the step-3 tool list):

```bash
cd "/absolute/path/to/project"
npx --yes @fission-ai/openspec@latest init --tools cursor --no-animation --profile core
```

   - **Skip** only when all of: the matching command file already exists (Cursor: `.cursor/commands/opsx-propose.md`; Claude Code: `.claude/commands/opsx/propose.md`; other adapters: that tool’s `/opsx-propose` / `/opsx:propose` command file) **and** `openspec/config.yaml` parses as a YAML **object** (not `null`, not comments-only). Same idea as skipping 1c-rules when `.ai-rules.json` exists. If either check fails — run init.
   - **Do not delete** `openspec/project.md`. CLI 1.9+ may ask to move context into `config.yaml` and remove the file; for this skill that file is the 1c-rules 1C metadata snapshot (filled from `Configuration.xml` on installer init/update). Leave it.
   - **`config.yaml`** — the 1c-rules template is comments-only; `openspec doctor` then reports `not a valid YAML object`. After init, if the file is still not a YAML object: write a **minimal** valid file (`schema: spec-driven`, `project.name` = folder name, short `context` that this is a 1C project, operational params live in `.dev.env`, 1C facts in OpenSpec artifacts need MCP confirmation). Do **not** overwrite a file that already parses as an object.
   - **Verify** — `openspec doctor` (or, **online only** if CLI is not on PATH: `npx --yes @fission-ai/openspec@latest doctor`) with no YAML-object warning. If init or doctor fails — **stop**; do not go to `.dev.env` / IB steps.

6. Patch `.dev.env` (installer creates the file; this pass fills layout paths). Re-run scaffold:

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/scaffold.sh "/absolute/path/to/project"
```

   The script sets, when `.dev.env` exists:

   - `PLATFORM_PATH` — newest `/opt/1cv8/x86_64/8.3.*` (fallback `8.3.27.2130`)
   - `PLATFORM_VERSION` — `CompatibilityMode` from `src/cf/Configuration.xml` (e.g. `Version8_3_27` → `8.3.27`)
   - `INFOBASE_KIND=file`
   - `INFOBASE_PATH=<root>/_INFOBASE`
   - `EXPORT_PATH=<root>/src/cf`
   - `EXTENSIONS_PATH=<root>/src/cfe`
   - `RELEASE_PATH=<root>/build`
   - `LOG_PATH=<root>/_LOGS/1cv8.log`
   - `TMP_PATH=<root>/_tmp` (append if the key is absent from the 1c-rules template)
   - `DOCS_PATH=<root>/_docs` (append if absent)
   - `HANDOFFS_PATH=<root>/_handoffs` (append if absent)
   - `ARCHIVES_PATH=<root>/_archives` (append if absent)

   Other 1c-rules keys stay as they are (`USE_EDT` from the installer, usually `false` in `-NonInteractive`). If `.dev.env` is still missing after step 3, report the installer failure; do not invent a full `.dev.env`.

7. Merge a **Структура каталогов** section into `USER-RULES.md` (create the file if absent). Fill the project name from the folder name. If `src/cf/Configuration.xml` exists, add Name / Version / CompatibilityMode. Do not wipe other user content. Do not edit `AGENTS.md`.

Template for the section (write as markdown, include the tree):

- Heading `## Структура каталогов`
- Tree: `src/cf` `src/cfe` `src/epf` `src/erf` `tests/features` `tests/fixtures` `tests/screenshots` `tests/reports` `tools/vanessa` `tools/neurofish-mcp` `tools/mcp-toolkit` `build/` `_INFOBASE/` `_LOGS/` `_archives/` `_tmp/` `_handoffs/` `_docs/`
- Line: paths live in `.dev.env`; `_INFOBASE` is empty until the user picks a test infobase on step 8 (empty or from a template) or `/loadfrom1cbase` / Designer creates `1Cv8.1CD`.
- If Vanessa=yes: Vanessa paths are not registered in 1C metadata — set feature/report/screenshot dirs in Vanessa UI or VAParams at run time; EPF/CFE live in `tools/vanessa/` and `tools/neurofish-mcp/` locally (`*.epf` / `*.cfe` gitignored). Port in `.cursor/mcp.json` must match the form «Управление МСР» after the first start. Setup: [`.cursor/skills/vanessa-mcp/docs/integration.md`](.cursor/skills/vanessa-mcp/docs/integration.md).
- If Vanessa=no: dirs `tests/` and `tools/vanessa` / `tools/neurofish-mcp` exist empty; binaries were not downloaded.
- If KD≠0: `MCP_Toolkit.epf` lives in `tools/mcp-toolkit/` locally (`*.epf` gitignored); open it in a **copy** of the KD infobase (Файл → Открыть), do not load into configuration. Ports: `KD2_PORT` / `KD31_PORT` / `MCP_TOOLKIT_PORT` in `.dev.env`. Setup: [`.cursor/skills/1c-mcp-toolkit/docs/integration.md`](.cursor/skills/1c-mcp-toolkit/docs/integration.md).
- If KD=0: dir `tools/mcp-toolkit` exists empty; the EPF was not downloaded.

**Only if Vanessa=yes** and `USER-RULES.md` does not yet have a **Сценарные тесты Vanessa** heading, append this paragraph (do not duplicate if already present; do **not** add it when the user declined Vanessa):

```markdown
## Сценарные тесты Vanessa

Написание, проверка и прогон сценарных тестов Vanessa (`.feature` / Gherkin, MCP, клиент тестирования) ведутся по скиллу `vanessa-mcp` ([`.cursor/skills/vanessa-mcp/SKILL.md`](.cursor/skills/vanessa-mcp/SKILL.md)): обязательный цикл «состояние → шаги из библиотеки → `check_syntax` → `run_scenario` → правка по результату», без выдуманных шагов Gherkin.

Пошаговая установка MCP и клиента тестирования: [`.cursor/skills/vanessa-mcp/docs/integration.md`](.cursor/skills/vanessa-mcp/docs/integration.md).
```

**Only if KD≠0** and `USER-RULES.md` does not yet have a **Конвертация данных** heading, append the matching paragraph (do not duplicate; do **not** add it when the user declined KD). Keep only the skill lines that were installed (`kd2` / `kd31` / both):

```markdown
## Конвертация данных

Правила обмена в живой ИБ «Конвертация данных» ведутся через MCP Toolkit (`tools/mcp-toolkit/MCP_Toolkit.epf`, скилл [`1c-mcp-toolkit`](.cursor/skills/1c-mcp-toolkit/SKILL.md)): сначала `health-probe`, потом helpers, BSL не сочинять.

- КД 2.0 (XML для универсального обмена) — скилл [`kd2-rules`](.cursor/skills/kd2-rules/SKILL.md), порт `KD2_PORT` (часто 7003).
- КД 3.1 (EnterpriseData, модуль менеджера) — скилл [`kd31-rules`](.cursor/skills/kd31-rules/SKILL.md), порт `KD31_PORT` (часто 6011).

Обработку открыть в сессии ИБ КД (копия, не боевая): Файл → Открыть, встроенный сервер, при записи снять защиту `Записать` / `Удалить`. В конфигурацию не загружать.

Пошаговая установка: [`.cursor/skills/1c-mcp-toolkit/docs/integration.md`](.cursor/skills/1c-mcp-toolkit/docs/integration.md).
```

**Only if Humanizer was installed** (local or global) and `USER-RULES.md` does not yet have a **Читаемость русского** heading, append the matching paragraph (do not duplicate; do **not** add it when the user declined). Local:

```markdown
## Читаемость русского

Правка русского текста после нейросети — по скиллу `humanizer-ru` ([`.cursor/skills/humanizer-ru/SKILL.md`](.cursor/skills/humanizer-ru/SKILL.md)): канцелярит и пустые зачины убирать, факты и голос автора не трогать.
```

Global (home path instead of the project-relative link):

```markdown
## Читаемость русского

Правка русского текста после нейросети — по скиллу `humanizer-ru` (`~/.cursor/skills/humanizer-ru/SKILL.md`): канцелярит и пустые зачины убирать, факты и голос автора не трогать.
```

8. **Ask** which test infobase to create. Do this **before** the final report and `/installtools` menu. Do **not** create silently. Do **not** treat silence as “no”, “empty”, or a template pick. Do **not** choose a demo `.dt` for the user.

   - If `{INFOBASE_PATH}/1Cv8.1CD` already exists and is non-empty — skip the question, do not recreate.
   - Discover templates (do not guess extra disks). If the folder is missing, **ask the user for the path** and re-run with that argument:

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/list-templates.sh
# if tmplts=not found on stderr, ask for the directory, then:
bash ~/.cursor/skills/1c-project-scaffold/scripts/list-templates.sh "/path/to/tmplts"
```

     Resolution order inside the script: `ConfigurationTemplatesLocation` in `~/.1C/1cestart/1cestart.cfg`, then `$HOME/.1cv8/1C/1cv8/tmplts`. stdout is TSV `n<TAB>catalog<TAB>file` from each `.mft` `[ConfigN]` (`Catalog` + `Source` next to the `.mft`; missing files skipped). Empty list is valid (exit 0).

   - Then one question, in the user’s language, with this shape (do not reuse TSV numbers as-is):

     - 0 — не создавать ИБ
     - 1 — пустая ИБ (без шаблона)
     - 2… — TSV rows in order: question number = TSV `n` + 1. Show `catalog` and whether the file is `.cf` (configuration only) or `.dt` (demo with data; can take several minutes, up to ~1 GB).

   - **0 / no** — leave `_INFOBASE` without `1Cv8.1CD`; say so in the report.
   - **empty** — helper without a template file (list name = project folder name):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/create-empty-ib.sh \
  "/absolute/path/to/project" "Project folder name"
```

   - **template N** — same helper, third argument = the `file` column from TSV. `.dt` create can run many minutes — size the shell wait accordingly (do not kill the process early):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/create-empty-ib.sh \
  "/absolute/path/to/project" "Project folder name" "/path/from/tsv.dt"
```

   Do **not** use project `db-create.ps1` for this on Linux: `$env:TEMP` is empty, and `File="path with spaces"` quotes become literal argv — 1C answers «Неверные или отсутствующие параметры соединения». The helper calls `1cv8 CREATEINFOBASE` with `File=\"${IB}\";` as one argument, optional `/UseTemplate` as a separate argv, `/AddToList`, `/L ru`, and registers into `~/.1C/1cestart/ibases.v8i`. It moves `_INFOBASE/.gitkeep` aside for the create and restores it.

9. Report: **source** — `offline` (packed_at + tags from `vendor/offline/MANIFEST.txt`) or `online` (GitHub tags/URLs from script stdout); created dirs (incl. `tests/` + `tools/vanessa/` + `tools/neurofish-mcp/` + `tools/mcp-toolkit/`); ignore files new or kept; 1c-rules version and tools (or “already installed”); **Vanessa** — either `skipped (user declined)` **or** neurofish tag + `client_mcp.cfe` URL, Vanessa tag + asset names (`vanessa-automation-single*.zip`, `VAExtension*.cfe`), `vanessa-mcp: installed | already present | skipped (no vendor)`, whether `.cursor/mcp.json` was wrote/merged/kept, **or** Vanessa-branch failure (GitHub/network **or** missing offline bundle) with the script error; **KD** — either `skipped (user declined)` **or** choice (`kd2` / `kd31` / `both`), ROCTUP tag + asset name + URL, `1c-mcp-toolkit` / `kd2-rules` / `kd31-rules`: `installed | already present | skipped`, whether `.dev.env` port keys were appended, **or** KD-branch failure (GitHub/network **or** missing offline bundle) with the script error; **Humanizer** — either `skipped (user declined)` **or** `scope=local|global`, `humanizer-ru: installed | already present`, `humanizer_ru_commit`, **or** Humanizer-branch failure (clone/network **or** missing offline bundle) with the script error; OpenSpec (initialized this run / already present skip / CLI or Node failure — last one means the scaffold did not finish; offline with no `openspec` on PATH is a CLI failure); CLI version and `--tools` list; whether `.dev.env` was patched; whether the test IB was skipped (already present), refused, created empty, or created from a template (`Catalog` + file) plus `1Cv8.1CD` size. After a **first** 1c-rules init:

   - Recommend restarting the AI client (MCP, subagents, and `/opsx-*` commands load at startup).
   - Mention `/economymode` and `/rulesmodel` (see `AGENT-INSTALL.md`).
   - Present the `/installtools` menu (MCP bundle first, then Cognee, EDT-MCP, agent-browser, Windows-MCP) and wait for the user’s choice — do not install those tools silently.

## Hard stops

- Do not `git init`.
- Do not copy `_WEB`, `scripts`, `node_modules`.
- Do not overwrite an existing XML dump in `src/cf`.
- Do not create `1Cv8.1CD` or load a template without an explicit step-8 choice (0 / empty / a listed template). Existing non-empty `1Cv8.1CD` is left untouched.
- Do not vendor `comol/ai_rules_1c` into the project (clone or offline snapshot only to a temp cache).
- Do not install 1c-rules into a CLI config dir or home folder.
- Do not overwrite user-modified 1c-rules files (`USER-RULES.md`, `memory.md`, `LLM-RULES.md`, any `userModified` artefact).
- Do not write skill guides into `_docs/` (`_docs` is user/project documents only). Vanessa setup → `.cursor/skills/vanessa-mcp/docs/integration.md`. KD/toolkit setup → `.cursor/skills/1c-mcp-toolkit/docs/integration.md`.
- Do not overwrite an existing `.cursor/skills/vanessa-mcp/` in the project or `~/.cursor/skills/vanessa-mcp/` if already present.
- Do not treat silence on the step-1.5 offline/online question as either choice.
- Do not `git clone` 1c-rules, curl GitHub releases, or `npx` OpenSpec when the user chose **offline**. If the offline bundle or a required member is missing — stop that branch; do **not** fall back to the network.
- Do not call `npx` for OpenSpec in offline mode. Missing `openspec` on PATH in offline = stop (same as missing Node).
- Do not download or copy Vanessa / neurofish binaries without an explicit **yes** on the step-4 Vanessa question. Do not treat silence as yes or no.
- Do not load `client_mcp.cfe` or `VAExtension.cfe` into an infobase (Configurator) — files on disk + `_docs` only.
- Do not overwrite existing `*.epf` / `*.cfe` in `tools/vanessa/` or `tools/neurofish-mcp/` or `tools/mcp-toolkit/`.
- Do not overwrite an existing `.cursor/skills/1c-mcp-toolkit/`, `kd2-rules/`, or `kd31-rules/` in the project or the matching `~/.cursor/skills/` copy if already present.
- Do not download or copy `MCP_Toolkit.epf` without an explicit step-4.5 choice (КД 2 / КД 3 / обе). Do not treat silence as yes or no.
- Do not install `humanizer-ru` without an explicit step-4.6 choice (0 / local / global). Do not treat silence as skip or a scope pick. Do not write both local and global. Do not overwrite an existing `humanizer-ru/SKILL.md`. Do not touch `~/.cursor/skills/humanizer/` (different skill). Do not run `npx skills add`. Do not install the Python linter as part of the scaffold.
- Do not clone `comol/Humanizer_RU` when the user chose **offline**; use the archive member `humanizer-ru/`.
- Do not load `MCP_Toolkit.epf` into a configuration (Configurator) — Файл → Открыть in a KD session only; write only on a copy IB, never production KD.
- Do not write an AWG / docker-gateway URL into `.cursor/mcp.json` (keep `127.0.0.1`). Do not overwrite an existing `vanessaAutomation` entry. Do not write the Vanessa MCP key when the user declined Vanessa.
- Do not finish the scaffold without a successful OpenSpec init or a proven skip (step 5). Missing Node, failed CLI, or `openspec doctor` YAML-object warning = stop, not a warning in an otherwise-green report.
- Do not delete `openspec/project.md`.
- Do not overwrite `openspec/config.yaml` when it already parses as a YAML object.
