# Интеграция Vanessa Automation + MCP + Cursor

Пошаговая инструкция для этого проекта: скачанные файлы уже лежат в `tools/`. Осталось поставить расширения в ИБ, открыть Vanessa и подключить Cursor.

Официальная справка Vanessa: [docs/AI/index.md](https://github.com/Pr-Mex/vanessa-automation/blob/develop/docs/AI/index.md).  
Расширение MCP (нейрофиш): [onec-client-mcp-devkit](https://github.com/1c-neurofish/onec-client-mcp-devkit).

> **Важно:** [vladimir-kharin/1c_mcp](https://github.com/vladimir-kharin/1c_mcp) — **другой** MCP (данные ИБ через HTTP). Он **не заменяет** нейрофиш для Vanessa. Для UI-тестов нужен именно `client_mcp.cfe` + Vanessa.

Точные версии скачанных файлов — в `tools/vanessa/VERSION.txt` и `tools/neurofish-mcp/VERSION.txt`.

---

## 1. Что лежит в репозитории

| Путь | Назначение |
|------|------------|
| `tools/vanessa/vanessa-automation-single.epf` | Vanessa (single) |
| `tools/vanessa/VAExtension.cfe` | Расширение **клиента** тестирования |
| `tools/neurofish-mcp/client_mcp.cfe` | MCP-сервер **для Vanessa** (ИБ менеджера тестирования) |
| `tests/features/` | Сюда кладём `.feature` |
| `tests/fixtures/` | JSON/XML/CSV для сценариев |
| `tests/screenshots/`, `tests/reports/` | Артефакты прогонов (в git не коммитятся) |
| `_INFOBASE/` | Файловая ИБ → `INFOBASE_PATH` в `.dev.env` |
| `.cursor/mcp.json` | URL Vanessa MCP для Cursor (`127.0.0.1`, порт сверить с формой) |

Платформа: смотри `PLATFORM_PATH` в `.dev.env`.

`*.epf` и `*.cfe` в git не входят — держите локально или скачайте снова скриптом каркаса.

---

## 2. Подготовка ИБ менеджера тестирования

1. Убедись, что в `_INFOBASE` есть рабочая файловая база (`1Cv8.1CD`).
2. Открой базу в **Конфигураторе**.
3. Конфигурация → Расширения конфигурации → добавить из файла `tools/neurofish-mcp/client_mcp.cfe`.
4. Сними «безопасный режим» / ограничения, если Конфигуратор предупреждает (MCP слушает порт и вызывает внешние компоненты).
5. Обнови конфигурацию БД (F7). Закрой Конфигуратор.

Каркас **не** загружает расширение в ИБ сам.

---

## 3. Vanessa и VanessaExt

1. В менеджере тестирования: Файл → Открыть → `tools/vanessa/vanessa-automation-single.epf`.
2. В настройках Vanessa включи внешнюю компоненту **VanessaExt** (идёт внутри single.epf; отдельно с GitHub не скачивается). Нужна для части MCP-инструментов: скриншоты ОС и др.

---

## 4. Клиент тестирования + VAExtension

Нужен **второй** сеанс (или отдельная ИБ) — то, что реально тестируем. На старте может совпадать с менеджером.

1. В ИБ клиента установи `tools/vanessa/VAExtension.cfe`.
2. В Vanessa открой таблицу профилей клиентов тестирования: имя, строка соединения, тип **Тонкий**.
3. Проверь подключение профиля вручную.

Имя профиля **не** зашивай в сценарии заранее — при работе через MCP читай список (`manage_test_client_profiles`) и подключай то имя, которое есть.

Без подключённого клиента большинство UI-инструментов MCP вернут ошибку.

---

## 5. Запуск MCP-сервера

1. Предприятие → менеджер тестирования, Vanessa открыта, VanessaExt включён.
2. В расширении MCP нажми **Запустить**.
3. Запомни порт в форме «Управление MCP» (часто **5431**; в доке Vanessa также 9874 / 9876).

Проверка на той же машине, где слушает 1С:

```bash
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:5431/mcp
# Ожидание: 406 (без Accept: text/event-stream — норма)
```

Пока сеанс 1С закрыт или MCP не «Запущен» — Cursor MCP не заработает.

Если Cursor в другом network namespace и не видит `127.0.0.1` хоста — это настройка машины, не каркаса. В `.cursor/mcp.json` для обычного случая оставляй `http://127.0.0.1:<порт>/mcp`.

---

## 6. Cursor

Проектный `.cursor/mcp.json`:

```json
"vanessaAutomation": {
  "type": "remote",
  "url": "http://127.0.0.1:5431/mcp"
}
```

Порт в URL **должен** совпасть с формой «Управление MCP». После правки: Settings → MCP → Reload.

Написание и прогон `.feature` — по скиллу `vanessa-mcp` (`.cursor/skills/vanessa-mcp/SKILL.md`): состояние → шаги из библиотеки → `check_syntax` → `run_scenario`. Шаги Gherkin не выдумывать.

---

## 7. Каталоги Vanessa

В Vanessa (UI или VAParams) укажи:

| Параметр | Путь |
|----------|------|
| Каталог фич | `<корень проекта>/tests/features` |
| Каталог отчётов | `<корень проекта>/tests/reports` |
| Каталог скриншотов | `<корень проекта>/tests/screenshots` |

Каталоги в метаданных конфигурации **не** регистрируются.

---

## 8. Чеклист готовности

| # | Проверка |
|---|----------|
| 1 | Есть `vanessa-automation-single.epf` |
| 2 | В ИБ менеджера установлено `client_mcp.cfe`, БД обновлена |
| 3 | VanessaExt включён |
| 4 | VAExtension в клиенте тестирования |
| 5 | Профиль клиента тестирования подключается из Vanessa |
| 6 | MCP «Запущен», `curl http://127.0.0.1:<порт>/mcp` → HTTP 406 |
| 7 | Cursor видит `vanessaAutomation` и tools |
| 8 | Каталог фич = `tests/features` |

---

## 9. Что не путать

| Компонент | Роль |
|-----------|------|
| Vanessa EPF | Движок сценариев Gherkin |
| `client_mcp.cfe` (нейрофиш) | MCP-сервер **для Vanessa** |
| VAExtension | Расширение **клиента** тестирования |
| VanessaExt | Внешняя компонента (скрин/OS и др.) |
| `1c_mcp` / `1c-data-mcp` | Другой MCP: данные ИБ, не UI Vanessa |
