---
name: 1c-project-scaffold
description: Scaffolds the standard 1C working-directory layout. Collects all answers first (online/offline, Vanessa, КД 2/3, Humanizer RU, test IB, git init+commit), then creates dirs (Vanessa/KD folders only if chosen), installs comol/ai_rules_1c, optional Vanessa / MCP Toolkit / Humanizer, OpenSpec, optional IB, then git only if the user said yes. Offline = vendor/offline archive; online = GitHub latest. Use when starting a new 1C project, preparing a working catalog, or when the user asks for каркас / структура каталогов / _INFOBASE / _LOGS / _docs / Vanessa tests / КД 2 / КД 3 / MCP Toolkit / Humanizer RU / установку правил 1С / OpenSpec.
---

# 1C project scaffold

Repeat a standard 1C working layout in **any** project root. After resolving the project root, **ask every question in Phase A** (online/offline, Vanessa, КД, Humanizer, test IB, git) **before** `scaffold.sh`, `git clone`, GitHub `/releases/latest`, `npx`, `install-1c-rules.sh`, downloads, OpenSpec, or IB create. Silence is never an answer. Do **not** create `1Cv8.1CD` unless the user explicitly picks an IB option in Phase A (skip / empty / from sources / a tmplts template). An **empty** IB must not load configuration from XML or `.cf`/`.cfe`. Do **not** vendor the 1c-rules clone into the project. Scaffold is incomplete until OpenSpec init succeeds or is proven already done (Phase B, OpenSpec step). Git init/commit only in Phase C after a **yes** on the git question.

## Layout to create

Always:

```
src/cf/              # XML dump of main configuration  → EXPORT_PATH
src/cfe/             # extension sources               → EXTENSIONS_PATH
src/epf/
src/erf/
build/_for_debug/    # build artifacts                 → RELEASE_PATH
_INFOBASE/           # file infobase (folder; 1Cv8.1CD only after IB choice) → INFOBASE_PATH
_LOGS/               # Designer / ibcmd log            → LOG_PATH
_archives/           # source .cf / .cfe / .dt         → ARCHIVES_PATH
_tmp/                # scratch / temp                  → TMP_PATH
_handoffs/           # session handoff notes           → HANDOFFS_PATH
_docs/               # project documentation (in git)  → DOCS_PATH
.gitignore
.cursorignore
```

Only if Vanessa=yes (`scaffold.sh --vanessa`):

```
tests/features/      # Vanessa .feature scenarios
tests/fixtures/      # test JSON/XML/CSV
tests/screenshots/   # run screenshots (gitignored)
tests/reports/       # run reports (gitignored)
tools/vanessa/       # vanessa-automation-single.epf + VAExtension.cfe (*.epf/*.cfe gitignored)
tools/neurofish-mcp/ # client_mcp.cfe (*.cfe gitignored)
```

Only if КД ≠ 0 (`scaffold.sh --kd`):

```
tools/mcp-toolkit/   # MCP_Toolkit.epf (*.epf gitignored)
```

Empty dirs get `.gitkeep`. If `src/cf` already has a dump, leave its files untouched.

Vanessa dirs are **not** registered in 1C metadata. Paths to features / reports / screenshots are set later in Vanessa UI or VAParams when running tests. Do **not** create `tests/` or `tools/vanessa` / `tools/neurofish-mcp` when Vanessa=нет. Do **not** create `tools/mcp-toolkit` when КД=0. Binaries are downloaded only after the matching Phase A answer — never on silence and never on **no** / **0**.

1c-rules (Phase B) also places `openspec/` (README, `specs/`, `changes/`, stub `project.md`). That folder is **not** a substitute for OpenSpec init: Cursor `/opsx-*` commands appear only after official `openspec init`.

## Steps

1. Resolve the target root: the directory the user named, or the current project root. Confirm it is a project folder, not `~` / `Downloads` / a CLI config dir (`~/.cursor`, `~/.config`, `~/.codex`, `~/.claude`). Stop and ask if the path is ambiguous.

### Phase A — questions only

No `scaffold.sh`, no `mkdir` of the layout, no `install-1c-rules.sh`, no download-*, no OpenSpec, no `create-empty-ib` / seed, no `git init`. The only allowed read is `list-templates.sh` for the IB tmplts list. Do **not** treat silence as an answer. Ask **all** of the following in this order, in the user’s language, and wait for a complete set before Phase B.

**A1. Online / offline.** Do this **before** any `git clone`, GitHub `/releases/latest`, or `npx`. Do **not** download or copy binaries yet.

   - онлайн — clone `comol/ai_rules_1c` from GitHub; Vanessa / neurofish / MCP Toolkit from `/releases/latest`; clone `comol/Humanizer_RU` if the user picks local/global on A4; OpenSpec via `openspec` on PATH or `npx --yes @fission-ai/openspec@latest`. Call install/download scripts **without** `--offline`.
   - офлайн — no network for those deps. Copy from the skill archive [vendor/offline/1c-scaffold-deps.tar.gz](vendor/offline/1c-scaffold-deps.tar.gz) (versions in [vendor/offline/MANIFEST.txt](vendor/offline/MANIFEST.txt)). Pass `--offline` to `install-1c-rules.sh`, `download-vanessa-deps.sh`, `download-mcp-toolkit.sh`, and `install-humanizer-ru.sh` (`--offline` may appear anywhere in argv). OpenSpec: only a local `openspec` on PATH; if it is missing — **stop** (do not `npx`). If the archive or a required member is missing (script exit 2) — **stop** that branch; do **not** fall back to GitHub. To refresh the archive later (while online): `bash ~/.cursor/skills/1c-project-scaffold/scripts/pack-offline-bundle.sh`.

   Remember the choice for every later install/download step in this run. Only the source of 1c-rules, binaries, and Humanizer changes.

**A2. Vanessa Automation** (сценарные UI-тесты, `.feature`, MCP, клиент тестирования). Do **not** download silently.

   - 0 / нет — later: do not download Vanessa deps, do not install `vanessa-mcp`, do not write `vanessaAutomation` in `.cursor/mcp.json`, do not add «Сценарные тесты Vanessa» to `USER-RULES.md`, do **not** create `tests/` or `tools/vanessa` / `tools/neurofish-mcp`. Report: `Vanessa: skipped (user declined)`.
   - да — later run the Vanessa branch in Phase B.

**A3. Конвертация данных** (КД 2.0 XML-правила / КД 3.1 EnterpriseData, живая ИБ КД, MCP Toolkit).

   - 0 / нет — later: do not download `MCP_Toolkit.epf`, do not install `1c-mcp-toolkit` / `kd2-rules` / `kd31-rules`, do not add «Конвертация данных» to `USER-RULES.md`, do **not** create `tools/mcp-toolkit`. Report: `KD: skipped (user declined)`.
   - КД 2 / КД 3 / обе — later run the KD branch in Phase B (`kd2` / `kd31` / `both`).

**A4. Humanizer RU** ([comol/Humanizer_RU](https://github.com/comol/Humanizer_RU) — editor of Russian LLM text, not an AI-detector). Do **not** call `npx skills add`.

   - 0 / нет — later: do not copy the skill, do not add «Читаемость русского». Report: `humanizer-ru: skipped (user declined)`.
   - локально — only `$ROOT/.cursor/skills/humanizer-ru/`.
   - глобально — only `~/.cursor/skills/humanizer-ru/`.

   Local and global are exclusive.

**A5. Test infobase.** Do **not** create silently. **Empty vs from sources is the load gate:** empty → never load XML / `.cf` / `.cfe`; from sources → create an empty file IB first, then load.

   - If `{INFOBASE_PATH}/1Cv8.1CD` already exists and is non-empty — skip the create question, do not recreate. Still **do not** load sources unless the user explicitly asks in this run (existing IB is not “from sources” by default). Remember: IB already present.
   - Discover templates (do not guess extra disks). If the folder is missing, **ask the user for the path** and re-run with that argument:

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/list-templates.sh
# if tmplts=not found on stderr, ask for the directory, then:
bash ~/.cursor/skills/1c-project-scaffold/scripts/list-templates.sh "/path/to/tmplts"
```

     Resolution order inside the script: `ConfigurationTemplatesLocation` in `~/.1C/1cestart/1cestart.cfg`, then `$HOME/.1cv8/1C/1cv8/tmplts`. stdout is TSV `n<TAB>catalog<TAB>file` from each `.mft` `[ConfigN]` (`Catalog` + `Source` next to the `.mft`; missing files skipped). Empty list is valid (exit 0).

   - Then one question, in the user’s language, with this shape (do not reuse TSV numbers as-is):

     - 0 — не создавать ИБ
     - 1 — **пустая ИБ** (без шаблона, конфигурацию из исходников **не** грузить)
     - 2 — **ИБ из исходников** (пустой CREATEINFOBASE, затем загрузка конфигурации)
     - 3… — TSV rows in order: question number = TSV `n` + 2. Show `catalog` and whether the file is `.cf` (configuration only) or `.dt` (demo with data; can take several minutes, up to ~1 GB).

   If the user picks **2 / from sources**, ask the **second** question immediately (silence is not an answer):

     - XML already in `src/cf` — show this option **only if** `src/cf/Configuration.xml` exists.
     - files `.cf` / `.cfe` — ask for paths (user attachments). If `src/cf/Configuration.xml` already exists, also ask whether to replace the dump (`--replace-xml` later only after explicit confirmation).
     - If `src/cf` has no `Configuration.xml` and the user gave no `.cf` paths — ask for paths. Do not invent a tmplts file.

**A6. Git.** Initialize a repository and make the **first commit after** the full install (Phase B OpenSpec + IB, and seed if chosen)? (да / нет). Do **not** treat silence as no. Do **not** `git init` or commit until Phase C.

Until A1–A6 (and the from-sources follow-up if A5=2) are answered — do not start Phase B.

### Phase B — pipeline from answers

2. Create dirs and ignore files. Pass `--vanessa` if A2=да, `--kd` if A3≠0 (both flags default off):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/scaffold.sh "/absolute/path/to/project"
# examples:
# bash .../scaffold.sh "/absolute/path/to/project" --vanessa
# bash .../scaffold.sh "/absolute/path/to/project" --kd
# bash .../scaffold.sh "/absolute/path/to/project" --vanessa --kd
```

Templates live in [templates/gitignore](templates/gitignore) and [templates/cursorignore](templates/cursorignore) (no Vanessa artifact rules in the templates). Existing `.gitignore` / `.cursorignore` are kept; if `--vanessa` and `.gitignore` already exists without Vanessa artifact rules, the script **appends** `tests/screenshots/*` and `tests/reports/*` (keeping `.gitkeep`). Same idea for `.cursorignore`. Vanessa=нет — **do not** create `tests/` or vanessa/neurofish. КД=0 — **do not** create `tools/mcp-toolkit`.

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

4. **Vanessa branch** — only if A2=да. If a download script exits non-zero (network / GitHub 4xx / missing asset, or offline: missing bundle / missing member) — **stop the Vanessa branch**: do not install `vanessa-mcp`, do not write `mcp.json` / `_docs`, do not pretend binaries are in place. Do **not** fall back to GitHub when the user chose offline. Continue with Humanizer and OpenSpec and report the Vanessa failure.

     a. Binaries. Does **not** overwrite existing `*.epf` / `*.cfe`. Does **not** load anything into an infobase.

        Online (GitHub `/releases/latest`, no version hardcoded):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/download-vanessa-deps.sh "/absolute/path/to/project"
```

        Offline (copy from the skill archive):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/download-vanessa-deps.sh "/absolute/path/to/project" --offline
```

        Sources (online): [1c-neurofish/onec-client-mcp-devkit](https://github.com/1c-neurofish/onec-client-mcp-devkit/releases/latest) → `tools/neurofish-mcp/client_mcp.cfe`; [Pr-Mex/vanessa-automation](https://github.com/Pr-Mex/vanessa-automation/releases/latest) → `tools/vanessa/vanessa-automation-single.epf` (from the `vanessa-automation-single*.zip`, not the full zip) and `tools/vanessa/VAExtension.cfe`. Do **not** download `training.zip`, `TTSCache.zip`, or a separate VanessaExt CFE (the add-in is inside the single EPF). Script stdout includes `source=online|offline`, tags/URLs — copy them into the final report. `VERSION.txt` next to each dest is git-tracked; binaries are gitignored.

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

4.5. **KD branch** — only if A3≠0. If the download script exits non-zero — **stop the KD branch**: do not install the skills, do not write `_docs`, do not pretend the EPF is in place. Do **not** fall back to GitHub when the user chose offline. Continue with Humanizer and OpenSpec and report the KD failure.

     a. EPF. Does **not** overwrite an existing `tools/mcp-toolkit/*.epf`. Does **not** load anything into an infobase.

        Online (GitHub `/releases/latest`, no version hardcoded):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/download-mcp-toolkit.sh "/absolute/path/to/project"
```

        Offline (copy OS asset from the skill archive):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/download-mcp-toolkit.sh "/absolute/path/to/project" --offline
```

        Source (online): [ROCTUP/1c-mcp-toolkit](https://github.com/ROCTUP/1c-mcp-toolkit/releases/latest). OS asset: Linux → `MCP_Toolkit_linux.epf`, Windows → `MCP_Toolkit.epf`, macOS → `MCP_Toolkit_macos.epf`; saved as `tools/mcp-toolkit/MCP_Toolkit.epf`. Script stdout includes `source=online|offline`, `mcp-toolkit_tag` / `mcp-toolkit_url` — copy them into the final report. `VERSION.txt` is git-tracked; the `*.epf` is gitignored.

     b. Vendored skills (`1c-mcp-toolkit` always + chosen KD skill(s)). Second argument: `kd2` | `kd31` | `both` matching A3:

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/install-kd-skills.sh "/absolute/path/to/project" both
```

        Copies [vendor/1c-mcp-toolkit/](vendor/1c-mcp-toolkit/) (incl. [docs/integration.md](vendor/1c-mcp-toolkit/docs/integration.md)), [vendor/kd2-rules/](vendor/kd2-rules/), [vendor/kd31-rules/](vendor/kd31-rules/) → `$ROOT/.cursor/skills/<name>/` (only the names implied by the argument). If `$ROOT/.cursor/skills/<name>/SKILL.md` already exists — skip (do not overwrite). If `~/.cursor/skills/<name>/SKILL.md` is missing on this machine — copy there too; if it exists, leave it. Appends `MCP_TOOLKIT_PORT` / `KD2_PORT` / `KD31_PORT` to `.dev.env` when those keys are missing. Do **not** write skill guides into `_docs/`. Script stdout has `<name>: installed | already present | skipped (no vendor)` — put those lines in the final report. Do **not** hand-edit `AGENTS.md`; Cursor loads skills from `.cursor/skills/<name>/SKILL.md`. Do **not** write a Cursor MCP URL for toolkit (agent uses HTTP curl to localhost).

4.6. **Humanizer branch** — only if A4 is local or global. If the install script exits non-zero — **stop the Humanizer branch**; do **not** fall back to GitHub when the user chose offline. Continue with OpenSpec and report the Humanizer failure. Do **not** write both local and global. Do **not** overwrite an existing `SKILL.md` at the chosen dest. Do **not** touch `~/.cursor/skills/humanizer/` (a different skill). Do **not** install the Python linter package.

     Online (`git clone --depth=1`, copy `skills/humanizer-ru/`):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/install-humanizer-ru.sh "/absolute/path/to/project" local
```

     Offline (member `humanizer-ru/` in the skill archive):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/install-humanizer-ru.sh "/absolute/path/to/project" global --offline
```

     Second argument is `local` or `global` matching A4. Script stdout includes `source=online|offline`, `humanizer_ru_commit=…`, `scope=local|global`, `humanizer-ru: installed | already present` — copy those lines into the final report.

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
   - **Verify** — `openspec doctor` (or, **online only** if CLI is not on PATH: `npx --yes @fission-ai/openspec@latest doctor`) with no YAML-object warning. If init or doctor fails — **stop**; do not go to `.dev.env` / IB / git steps.

6. Patch `.dev.env` (installer creates the file; this pass fills layout paths). Re-run scaffold with the **same** `--vanessa` / `--kd` flags as step 2:

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/scaffold.sh "/absolute/path/to/project" [--vanessa] [--kd]
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

Template for the section (write as markdown, include the tree of dirs that **exist**; do **not** list `tests/` / `tools/vanessa` / `tools/neurofish-mcp` when Vanessa=нет; do **not** list `tools/mcp-toolkit` when КД=0):

- Heading `## Структура каталогов`
- Tree: always `src/cf` `src/cfe` `src/epf` `src/erf` `build/` `_INFOBASE/` `_LOGS/` `_archives/` `_tmp/` `_handoffs/` `_docs/`; plus Vanessa dirs only if A2=да; plus `tools/mcp-toolkit` only if A3≠0.
- Line: paths live in `.dev.env`; `_INFOBASE` has no `1Cv8.1CD` until the IB choice (empty / from sources / tmplts) or `/loadfrom1cbase` / Designer creates it. After the IB step, **rewrite this sentence** to match the choice (empty and sources not loaded; from XML; from `.cf`/`.cfe` plus dump into `src/cf` and `src/cfe/<Name>/`; template `Catalog` + file).
- If Vanessa=yes: Vanessa paths are not registered in 1C metadata — set feature/report/screenshot dirs in Vanessa UI or VAParams at run time; EPF/CFE live in `tools/vanessa/` and `tools/neurofish-mcp/` locally (`*.epf` / `*.cfe` gitignored). Port in `.cursor/mcp.json` must match the form «Управление МСР» after the first start. Setup: [`.cursor/skills/vanessa-mcp/docs/integration.md`](.cursor/skills/vanessa-mcp/docs/integration.md).
- If Vanessa=no: do **not** mention `tests/` or `tools/vanessa` / `tools/neurofish-mcp` (those dirs were not created).
- If KD≠0: `MCP_Toolkit.epf` lives in `tools/mcp-toolkit/` locally (`*.epf` gitignored); open it in a **copy** of the KD infobase (Файл → Открыть), do not load into configuration. Ports: `KD2_PORT` / `KD31_PORT` / `MCP_TOOLKIT_PORT` in `.dev.env`. Setup: [`.cursor/skills/1c-mcp-toolkit/docs/integration.md`](.cursor/skills/1c-mcp-toolkit/docs/integration.md).
- If KD=0: do **not** mention `tools/mcp-toolkit` (the dir was not created).

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

8. Create the test infobase from the **already known** A5 answer. Do **not** ask again.

   - **0 / no** — leave `_INFOBASE` without `1Cv8.1CD`; say so in the report (`IB: skipped`). Do not load sources.
   - **1 / empty** — helper without a template file (list name = project folder name). **Do not** call `seed-from-xml.sh` / `seed-from-binaries.sh` / `db-load-*` / dump. Report: `IB: empty; sources: not loaded`.

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/create-empty-ib.sh \
  "/absolute/path/to/project" "Project folder name"
```

   - **2 / from sources** — create the empty file IB with the same helper (no template), then seed from the follow-up already collected in A5:

     - XML in `src/cf`:

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/seed-from-xml.sh \
  "/absolute/path/to/project"
```

       Loads `src/cf` then each `src/cfe/<Name>/` from `EXTENSION_NAMES` (or discovers names under `src/cfe`). **Does not dump.** Report: `IB: from-xml`.

     - files `.cf` / `.cfe`:

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/seed-from-binaries.sh \
  "/absolute/path/to/project" "/path/main.cf" "/path/A.cfe" "/path/B.cfe"
```

       If `src/cf/Configuration.xml` already exists, **stop** unless the user already confirmed replacing the dump in A5; only then add `--replace-xml` before the project path. Report: `IB: from-cf/cfe`. Do **not** copy binaries into `_archives`.

     Seed script exit `2` (no `pwsh` / no `db-*.ps1`) or other non-zero: **stop the seed branch**, keep the empty IB, put the error in the report. Do not roll back the rest of the scaffold.

   - **template N** (question ≥ 3) — same create helper, third argument = the `file` column from TSV. `.dt` create can run many minutes — size the shell wait accordingly (do not kill the process early). This is **not** repository sources: do **not** run seed scripts unless the user later explicitly asks to replace the configuration.

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/create-empty-ib.sh \
  "/absolute/path/to/project" "Project folder name" "/path/from/tsv.dt"
```

   Do **not** use project `db-create.ps1` for IB create on Linux: `$env:TEMP` is empty, and `File="path with spaces"` quotes become literal argv — 1C answers «Неверные или отсутствующие параметры соединения». The helper calls `1cv8 CREATEINFOBASE` with `File=\"${IB}\";` as one argument, optional `/UseTemplate` as a separate argv, `/AddToList`, `/L ru`, and registers into `~/.1C/1cestart/ibases.v8i`. It moves `_INFOBASE/.gitkeep` aside for the create and restores it.

   **Linux IB ops** (load / dump after A5 choice 2): do not compose Designer `/F` lines. Source [`scripts/linux-ib-env.sh`](scripts/linux-ib-env.sh) via the seed helpers: if `TEMP`/`TMP`/`TMPDIR` are empty, set them to `/tmp`; pass `-V8Path` to the **ibcmd** binary (not `1cv8.exe`). `ibcmd config export` refuses a non-empty target — `src/cf/.gitkeep` must be stashed first (`seed-from-binaries.sh` does this). Git init is Phase C (after this step): do not stop on `git status` failure during seed; refuse a dump only when `src/cf/Configuration.xml` already exists (unless `--replace-xml`).

### Phase C — git (only if A6=да)

After successful OpenSpec and the IB step (and seed, if it ran):

- if `.git` already exists — **do not** `git init` again; commit new scaffold files if there is something to commit;
- if `.git` is missing — `git init`, then `git add` honoring `.gitignore`, commit with a short message such as `init: 1C project scaffold`;
- do **not** `git add --force` for `.dev.env`, `1Cv8.1CD`, `*.epf` / `*.cfe`;
- do **not** `git config`; do **not** skip hooks;
- XML under `src/cf` is committed if it is not ignored (a ЗУП dump can be large — one line in the report).

If A6=нет — do **not** `git init` and do not commit.

If there is nothing to commit after `git add`, do not create an empty commit; report that.

9. Report: **source** — `offline` (packed_at + tags from `vendor/offline/MANIFEST.txt`) or `online` (GitHub tags/URLs from script stdout); created dirs (always layout; `tests/` + `tools/vanessa/` + `tools/neurofish-mcp/` only if Vanessa=yes; `tools/mcp-toolkit/` only if KD≠0); ignore files new or kept; 1c-rules version and tools (or “already installed”); **Vanessa** — either `skipped (user declined)` **or** neurofish tag + `client_mcp.cfe` URL, Vanessa tag + asset names (`vanessa-automation-single*.zip`, `VAExtension*.cfe`), `vanessa-mcp: installed | already present | skipped (no vendor)`, whether `.cursor/mcp.json` was wrote/merged/kept, **or** Vanessa-branch failure (GitHub/network **or** missing offline bundle) with the script error; **KD** — either `skipped (user declined)` **or** choice (`kd2` / `kd31` / `both`), ROCTUP tag + asset name + URL, `1c-mcp-toolkit` / `kd2-rules` / `kd31-rules`: `installed | already present | skipped`, whether `.dev.env` port keys were appended, **or** KD-branch failure (GitHub/network **or** missing offline bundle) with the script error; **Humanizer** — either `skipped (user declined)` **or** `scope=local|global`, `humanizer-ru: installed | already present`, `humanizer_ru_commit`, **or** Humanizer-branch failure (clone/network **or** missing offline bundle) with the script error; OpenSpec (initialized this run / already present skip / CLI or Node failure — last one means the scaffold did not finish; offline with no `openspec` on PATH is a CLI failure); CLI version and `--tools` list; whether `.dev.env` was patched; **IB** — `skipped` (already present or user 0) / `empty` (sources not loaded) / `from-xml` / `from-cf/cfe` / `template` (`Catalog` + file) plus `1Cv8.1CD` size, `EXTENSION_NAMES` if written, or seed-branch failure with the script error; **git** — `skipped (user declined)` / `init+commit` / `commit` (existing repo) / `nothing to commit`, and a one-line note if `src/cf` XML was included and is large. After a **first** 1c-rules init:

   - Recommend restarting the AI client (MCP, subagents, and `/opsx-*` commands load at startup).
   - Mention `/economymode` and `/rulesmodel` (see `AGENT-INSTALL.md`).
   - Present the `/installtools` menu (MCP bundle first, then Cognee, EDT-MCP, agent-browser, Windows-MCP) and wait for the user’s choice — do not install those tools silently.

## Hard stops

- Do not `git init` or commit without an explicit **yes** on Phase A question A6. Do not `git init` or commit before OpenSpec success and the IB step (and seed, if chosen) have finished.
- Do not `git add --force` `.dev.env`, `1Cv8.1CD`, `*.epf`, or `*.cfe`. Do not `git config`. Do not skip hooks.
- Do not run `scaffold.sh`, `install-1c-rules.sh`, download-*, OpenSpec, `create-empty-ib`, or seed until Phase A answers are complete.
- Do not create `tests/`, `tools/vanessa`, or `tools/neurofish-mcp` when Vanessa=нет. Do not create `tools/mcp-toolkit` when КД=0.
- Do not copy `_WEB`, `scripts`, `node_modules`.
- Do not overwrite an existing XML dump in `src/cf` during layout create (`scaffold.sh`). A dump from `seed-from-binaries.sh` over existing `Configuration.xml` requires `--replace-xml` and an explicit user confirmation.
- Do not create `1Cv8.1CD` or load a template / sources without an explicit A5 choice (0 / empty / from sources / a listed template). Existing non-empty `1Cv8.1CD` is left untouched.
- Do not load XML / `.cf` / `.cfe` into the IB when the user picked **empty** (A5 = 1). Empty means sources stay unloaded.
- Do not load XML / `.cf` / `.cfe` without an explicit **from sources** choice (or an explicit replace after a tmplts IB).
- Do not dump over an existing `src/cf/Configuration.xml` unless the user confirmed replace (`seed-from-binaries.sh --replace-xml`).
- Do not copy user `.cf` / `.cfe` into `_archives` silently.
- Do not treat silence on the A5 empty vs from-sources question as either choice.
- Do not vendor `comol/ai_rules_1c` into the project (clone or offline snapshot only to a temp cache).
- Do not install 1c-rules into a CLI config dir or home folder.
- Do not overwrite user-modified 1c-rules files (`USER-RULES.md`, `memory.md`, `LLM-RULES.md`, any `userModified` artefact).
- Do not write skill guides into `_docs/` (`_docs` is user/project documents only). Vanessa setup → `.cursor/skills/vanessa-mcp/docs/integration.md`. KD/toolkit setup → `.cursor/skills/1c-mcp-toolkit/docs/integration.md`.
- Do not overwrite an existing `.cursor/skills/vanessa-mcp/` in the project or `~/.cursor/skills/vanessa-mcp/` if already present.
- Do not treat silence on the A1 offline/online question as either choice.
- Do not `git clone` 1c-rules, curl GitHub releases, or `npx` OpenSpec when the user chose **offline**. If the offline bundle or a required member is missing — stop that branch; do **not** fall back to the network.
- Do not call `npx` for OpenSpec in offline mode. Missing `openspec` on PATH in offline = stop (same as missing Node).
- Do not download or copy Vanessa / neurofish binaries without an explicit **yes** on A2. Do not treat silence as yes or no.
- Do not load `client_mcp.cfe` or `VAExtension.cfe` into an infobase (Configurator) — files on disk + `_docs` only.
- Do not overwrite existing `*.epf` / `*.cfe` in `tools/vanessa/` or `tools/neurofish-mcp/` or `tools/mcp-toolkit/`.
- Do not overwrite an existing `.cursor/skills/1c-mcp-toolkit/`, `kd2-rules/`, or `kd31-rules/` in the project or the matching `~/.cursor/skills/` copy if already present.
- Do not download or copy `MCP_Toolkit.epf` without an explicit A3 choice (КД 2 / КД 3 / обе). Do not treat silence as yes or no.
- Do not install `humanizer-ru` without an explicit A4 choice (0 / local / global). Do not treat silence as skip or a scope pick. Do not write both local and global. Do not overwrite an existing `humanizer-ru/SKILL.md`. Do not touch `~/.cursor/skills/humanizer/` (different skill). Do not run `npx skills add`. Do not install the Python linter as part of the scaffold.
- Do not clone `comol/Humanizer_RU` when the user chose **offline**; use the archive member `humanizer-ru/`.
- Do not load `MCP_Toolkit.epf` into a configuration (Configurator) — Файл → Открыть in a KD session only; write only on a copy IB, never production KD.
- Do not write an AWG / docker-gateway URL into `.cursor/mcp.json` (keep `127.0.0.1`). Do not overwrite an existing `vanessaAutomation` entry. Do not write the Vanessa MCP key when the user declined Vanessa.
- Do not finish the scaffold without a successful OpenSpec init or a proven skip (step 5). Missing Node, failed CLI, or `openspec doctor` YAML-object warning = stop, not a warning in an otherwise-green report.
- Do not delete `openspec/project.md`.
- Do not overwrite `openspec/config.yaml` when it already parses as a YAML object.
