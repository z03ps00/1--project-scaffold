# 1C Project Scaffold

**Cursor-скилл стандартного рабочего каркаса 1С-проекта**

Поднимает в любом каталоге типовой рабочий каркас 1С: `src/`, `tests/`, `_INFOBASE/`, `_LOGS/`, правила [comol/ai_rules_1c](https://github.com/comol/ai_rules_1c), опционально Vanessa, Конвертация данных и [Humanizer RU](https://github.com/comol/Humanizer_RU), затем OpenSpec.

[![Cursor Skill](https://img.shields.io/badge/Cursor-Skill-000000.svg)](#установка-в-cursor)
[![Install](https://img.shields.io/badge/install-online%20%7C%20offline-informational.svg)](#онлайн-и-офлайн)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)
[![GitHub](https://img.shields.io/badge/author-z03ps00-black.svg)](https://github.com/z03ps00)

---

## Зачем это нужно

Новый 1С-каталог редко начинается с готового рабочего места. Чаще это пустая папка и фраза вроде:

> Подними каркас 1С в этом каталоге. Vanessa нужна, КД пока нет. ИБ — пустая.

Для человека это понятно. Агент без протокола может создать только часть каталогов, молча скачать EPF, забыть OpenSpec или положить `1Cv8.1CD` без спроса.

Skill даёт Cursor одну задачу: собрать **полный** каркас по явным ответам пользователя — до любых `git clone`, загрузок с GitHub и `npx`.

```text
Запрос «подними каркас 1С»
      ↓
Cursor + 1c-project-scaffold
      ↓
вопросы: офлайн/онлайн → Vanessa? → КД? → Humanizer RU? → какая ИБ?
      ↓
каталоги, 1c-rules, опциональные бинарники и скиллы, OpenSpec
```

Сам Skill предназначен для Cursor. Результат — обычный 1С-проект на диске, с которым можно работать дальше любым клиентом.

## Что делает Skill

Агент по [SKILL.md](SKILL.md) проходит фиксированный цикл. Молчание **не** считается ответом ни на один вопрос.

1. Выбрать корень проекта (не `~`, не `Downloads`, не каталог конфига CLI).
2. Спросить **онлайн** или **офлайн** — до любых загрузок.
3. Создать каталоги и ignore-файлы (`scaffold.sh`).
4. Поставить [comol/ai_rules_1c](https://github.com/comol/ai_rules_1c): `AGENTS.md`, `.cursor/`, `.dev.env`.
5. Спросить про **Vanessa Automation**. Да — EPF/CFE, скилл `vanessa-mcp`, `.cursor/mcp.json`. Нет — пустые `tests/` и `tools/vanessa`.
6. Спросить про **Конвертация данных** (0 / КД 2 / КД 3 / обе). Не ноль — `MCP_Toolkit.epf` и скиллы toolkit / `kd2-rules` / `kd31-rules`.
7. Спросить про **Humanizer RU** (0 / локально в проект / глобально на компьютер). Не ноль — скилл `humanizer-ru`.
8. Инициализировать **OpenSpec** (`openspec init`). Каркас без этого шага не считается завершённым.
9. Дописать пути в `.dev.env` и секцию «Структура каталогов» в `USER-RULES.md`.
10. Спросить про тестовую ИБ: не создавать / пустая / шаблон из `tmplts`. Затем отчёт.

Главное правило:

```text
молчание ≠ да и ≠ нет
```

Бинарники Vanessa и MCP Toolkit появляются на диске только после явного выбора. `1Cv8.1CD` — только после явного пункта на шаге ИБ.

## Что получается на выходе

Дерево **проекта** (не этого репозитория):

```text
project/
├── src/cf/                 # XML-выгрузка основной конфигурации
├── src/cfe/                # расширения
├── src/epf/
├── src/erf/
├── tests/features/         # Vanessa .feature
├── tests/fixtures/
├── tests/screenshots/      # gitignored
├── tests/reports/          # gitignored
├── tools/vanessa/          # EPF/CFE только если Vanessa = да
├── tools/neurofish-mcp/    # client_mcp.cfe только если Vanessa = да
├── tools/mcp-toolkit/      # MCP_Toolkit.epf только если КД ≠ 0
├── build/_for_debug/
├── _INFOBASE/              # 1Cv8.1CD только после выбора ИБ
├── _LOGS/
├── _archives/
├── _tmp/
├── _handoffs/
├── _docs/
├── .dev.env
├── USER-RULES.md
├── AGENTS.md
├── .gitignore
└── .cursorignore
```

Пустые каталоги получают `.gitkeep`. `*.epf` и `*.cfe` в git проекта не попадают; рядом лежит git-tracked `VERSION.txt`. Существующая выгрузка в `src/cf` не перезаписывается.

## Установка в Cursor

```bash
git clone https://github.com/z03ps00/1--project-scaffold.git
cd 1--project-scaffold
ln -sfn "$(pwd)" ~/.cursor/skills/1c-project-scaffold
```

После этого агент читает `~/.cursor/skills/1c-project-scaffold/SKILL.md`. Пути в протоколе (`bash ~/.cursor/skills/1c-project-scaffold/scripts/...`) менять не нужно: скрипты считают корень скилла от своего расположения и работают и через симлинк, и из клона.

Нужно:

- Cursor;
- `bash`;
- для **онлайн**: `git`, `curl`, `python3`;
- для **1c-rules**: `pwsh` (иначе агент ставит правила lean-каналом по `AGENT-INSTALL.md`);
- для **OpenSpec**: Node ≥ 20.19.0; в офлайне — ещё и `openspec` в PATH.

Перезапустите Cursor после первого появления скилла, чтобы подхватились skills и `/opsx-*`.

## Использование

После установки достаточно обычного запроса:

```text
Подними каркас 1С в этом каталоге.
```

```text
Сделай структуру с Vanessa и КД 2, пустая ИБ.
```

```text
Только каталоги и правила, без Vanessa и без Конвертации данных.
```

```text
Офлайн-установка каркаса, зависимости из архива скилла.
```

Агент сам задаст режим (онлайн/офлайн), Vanessa, КД, Humanizer RU и ИБ. Не скачивает зависимости, пока нет явного ответа.

## Онлайн и офлайн

Вопрос задаётся **до** `git clone`, GitHub `/releases/latest` и `npx`.

**Онлайн** — свежие релизы с GitHub, clone `ai_rules_1c` и при выборе Humanizer — clone `Humanizer_RU`. OpenSpec: `openspec` в PATH, иначе `npx --yes @fission-ai/openspec@latest`.

**Офлайн** — копия из архива скилла, без сети для этих зависимостей:

| Файл | Назначение |
|------|------------|
| [`vendor/offline/MANIFEST.txt`](vendor/offline/MANIFEST.txt) | дата сборки, теги, URL, sha256 |
| [`vendor/offline/1c-scaffold-deps.tar.gz`](vendor/offline/1c-scaffold-deps.tar.gz) | снимок `ai_rules_1c` (без `.git`), `humanizer-ru`, Vanessa EPF/CFE, neurofish CFE, MCP Toolkit (linux / windows / macos) |

OpenSpec в офлайне только с локального CLI. `npx` не вызывается. Нет `openspec` в PATH — каркас останавливается: поставить CLI заранее или выбрать онлайн. Дырявый архив не дополняется из интернета.

Обновить архив (нужна сеть):

```bash
bash ~/.cursor/skills/1c-project-scaffold/scripts/pack-offline-bundle.sh
```

Текущий снимок (см. манифест): `ai_rules_1c` `4aef5cad`, Humanizer RU `19186272`, Vanessa `1.2.043.28`, neurofish `v0.6.5`, MCP Toolkit `v1.8.0`.

## Структура

Дерево **этого** репозитория:

```text
1c-project-scaffold/
├── SKILL.md
├── README.md
├── LICENSE
├── scripts/
│   ├── scaffold.sh
│   ├── install-1c-rules.sh
│   ├── download-vanessa-deps.sh
│   ├── install-vanessa-mcp.sh
│   ├── install-vanessa-config.sh
│   ├── download-mcp-toolkit.sh
│   ├── install-kd-skills.sh
│   ├── install-humanizer-ru.sh
│   ├── pack-offline-bundle.sh
│   ├── offline-lib.sh
│   ├── list-templates.sh
│   └── create-empty-ib.sh
├── templates/
│   ├── gitignore
│   ├── cursorignore
│   └── mcp.json
└── vendor/
    ├── offline/                 # архив для офлайн-установки
    ├── vanessa-mcp/
    ├── 1c-mcp-toolkit/
    ├── kd2-rules/
    └── kd31-rules/
```

`SKILL.md` — протокол агента (шаги, hard stops, отчёт). Скрипты вызываются из протокола. Vendored-скиллы Vanessa/КД копируются после явного выбора. Humanizer RU копируется из GitHub (онлайн) или из архива (офлайн) — локально в проект или глобально на компьютер, не в оба места сразу.

## Авторство и зависимости

Этот скилл — обвязка. Сами правила 1С, Vanessa, MCP в клиенте, toolkit, Humanizer RU и OpenSpec принадлежат своим авторам.

| Репозиторий | Автор | Лицензия | Роль в скилле |
|-------------|-------|----------|----------------|
| [comol/ai_rules_1c](https://github.com/comol/ai_rules_1c) | [comol](https://github.com/comol) | в GitHub не указана | правила, агенты, `.dev.env`; clone (онлайн) или снимок в офлайн-архиве |
| [comol/Humanizer_RU](https://github.com/comol/Humanizer_RU) | [comol](https://github.com/comol) | MIT | скилл `humanizer-ru`: локально в проект или глобально на компьютер |
| [Pr-Mex/vanessa-automation](https://github.com/Pr-Mex/vanessa-automation) | Leonid Pautov / [Pr-Mex](https://github.com/Pr-Mex) | BSD-3-Clause | `vanessa-automation-single.epf`, `VAExtension.cfe` |
| [1c-neurofish/onec-client-mcp-devkit](https://github.com/1c-neurofish/onec-client-mcp-devkit) | [1c-neurofish](https://github.com/1c-neurofish) | LGPL-3.0 | `client_mcp.cfe` |
| [ROCTUP/1c-mcp-toolkit](https://github.com/ROCTUP/1c-mcp-toolkit) | [ROCTUP](https://github.com/ROCTUP) | GPL-3.0 | `MCP_Toolkit.epf` (linux / windows / macos) |
| [Desko77/cursor-1c-skills](https://github.com/Desko77/cursor-1c-skills) | [Desko77](https://github.com/Desko77) | MIT | адаптация скиллов `kd2-rules`, `kd31-rules`, `1c-mcp-toolkit` в `vendor/` |
| [Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec) | [Fission-AI](https://github.com/Fission-AI) | MIT | `openspec init`; онлайн — `npx @fission-ai/openspec@latest` |

`vendor/vanessa-mcp/` — протокол этого репозитория (цикл «состояние → шаги библиотеки → `check_syntax` → `run_scenario`»), не апстрим Desko77.

Версии офлайн-снимка и контрольные суммы — в [`vendor/offline/MANIFEST.txt`](vendor/offline/MANIFEST.txt).

## Что Skill намеренно не делает

`1c-project-scaffold` не заменяет Vanessa, Конфигуратор, КД, Humanizer RU и OpenSpec. Он только собирает рабочее место.

- не делает `git init` в проекте;
- не создаёт `1Cv8.1CD` и не подставляет шаблон без явного выбора;
- не загружает `client_mcp.cfe`, `VAExtension.cfe` и `MCP_Toolkit.epf` в конфигурацию (файлы на диске; toolkit открывается через Файл → Открыть в копии ИБ КД);
- в офлайне не ходит в GitHub и не вызывает `npx`;
- не перезаписывает уже лежащие `*.epf` / `*.cfe` и пользовательские `USER-RULES.md` / `memory.md` / `LLM-RULES.md`.

```text
Запрос на каркас
      ↓
Cursor Skill
      ↓
Рабочий каталог 1С
      ↓
разработка / Vanessa / КД / Humanizer RU / OpenSpec
```

## Лицензия

Протокол, скрипты и наши адаптации скиллов распространяются по [MIT License](LICENSE).

Бинарники Vanessa, neurofish и MCP Toolkit в офлайн-архиве и в целевом проекте остаются под лицензиями своих авторов (см. таблицу выше). Скилл их не перелицензирует.

## Сопровождение

| Путь | Назначение |
|------|------------|
| `SKILL.md` | протокол: шаги, hard stops, отчёт |
| `scripts/` | установка каркаса, 1c-rules, Vanessa, toolkit, Humanizer RU, офлайн-архив, ИБ |
| `templates/` | `.gitignore`, `.cursorignore`, `mcp.json` |
| `vendor/offline/` | архив зависимостей для офлайн-установки |
| `vendor/vanessa-mcp/` | протокол Vanessa + `docs/integration.md` (в проект, не в `_docs/`) |
| `vendor/kd2-rules/` `vendor/kd31-rules/` `vendor/1c-mcp-toolkit/` | скиллы КД / toolkit |

---

Сделано для повторяемого рабочего места 1С в Cursor · MIT · [z03ps00](https://github.com/z03ps00)
