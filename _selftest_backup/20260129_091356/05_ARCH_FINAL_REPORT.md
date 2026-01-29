# 05_ARCH_FINAL_REPORT (iter=5)

## SUMMARY
Этап 1 (scaffolding + `config.py` как единственный источник настроек + jsonl-логирование) в целом собран и запускается, но итоговая приёмка **не может быть выдана** из‑за двух незакрытых решений уровня P1:
1) **Gate 1 BTC Risk-Off**: в White Paper есть противоречие на границе ровно **-1.0% за 60 минут** (строгое `< -0.010` по §4.1 vs нестрогое `<= -0.010` по §4.4). В `config.py` это корректно отражено как **“не выбираем победителя”** (`BTC_RISK_OFF_COMPARATOR = None` + оба кандидата), но до решения PM стратегия остаётся неопределённой на границе.
2) **Политика runtime-артефактов вне `.opencode/workflow/*`** (логи, `_selftest_backup/`, `__pycache__/*.pyc`) не утверждена, что создаёт риск гигиены/приёмки и “dual source of truth”.

Вердикт по критикам/аудиту: оба дают **request changes** до принятия решений.

## EVIDENCE (из отчётов исполнителя/критика/аудитора)

### 1) Структура Stage1-spec (scaffolding)
Исполнитель приложил дерево проекта, включающее требуемые компоненты:
- `config.py`, `main.py`
- `core/{engine.py,market_data.py,shadow_lab.py,__init__.py}`
- `infrastructure/{logger.py,telegram_bot.py,__init__.py}`
- `logs/.gitkeep` и рабочий `logs/events.jsonl`

Источник: `.opencode/workflow/02_EXECUTOR_REPORT.md` (TREE, строки ~15–43).

### 2) Запускаемость и минимальные проверки
Исполнитель зафиксировал:
- `python3 -m py_compile config.py main.py core/*.py infrastructure/*.py` (stderr пуст)
- `python3 main.py` (stderr пуст)
- наличие и наполнение `logs/events.jsonl`

Источник: `.opencode/workflow/02_EXECUTOR_REPORT.md` (COMMANDS + `ls -la logs` + excerpt jsonl).

### 3) jsonl-логирование (канон WP §7)
Есть фактические строки jsonl “decision” в `logs/events.jsonl`, включая старт приложения и “Stage1 wiring only”.

Источник: `.opencode/workflow/02_EXECUTOR_REPORT.md`, excerpt:
- `{"event": "decision", "message": "SOL Liquidity Navigator starting", ...}`
- `{"event": "decision", "message": "Stage1 wiring only: no strategy evaluation", ...}`

### 4) Gate 1 (BTC Risk-Off) оформлен как “UNDECIDED”
В `config.py` (встроен в executor report) зафиксировано:
- `BTC_RISK_OFF_RETURN_60M = -0.010`
- `BTC_RISK_OFF_COMPARATOR = None`
- `BTC_RISK_OFF_COMPARATOR_PSEUDOCODE = "<="`
- `BTC_RISK_OFF_COMPARATOR_PROSE = "<"`
- отдельная маркировка edge-case `btc_return_60m == -0.010`

Источник: `.opencode/workflow/02_EXECUTOR_REPORT.md` (блок Risk Gates).

### 5) Несоответствие/устаревание внутри ISSUES.md
Критик фиксирует, что в `.opencode/workflow/ISSUES.md` осталось утверждение, будто дефолтный компаратор Gate 1 — `"<="`, тогда как каноническая текущая реализация в `config.py` — `None`.

Источник: `.opencode/workflow/03_CRITIC_REPORT.md` (MISMATCHES #1).

## CANON MATCH (соответствие White Paper)
Подтверждено критиком и (частично) аудитором:
- Логика сигнала в Stage1 пока не реализуется (wiring only), но параметры извлечены в `config.py`.
- Извлечены ключевые числа/условия из WP:
  - кластер ликвидаций `> $20M` (WP §3.1)
  - sweep buffer `0.15%` (WP §3.2)
  - confirm candles `3` (WP §3.3)
  - ADX фильтр: `ADX(14) H1 > 25` (WP §4.2/§4.4)
  - weekend stop: Fri 21:00 UTC → Mon 06:00 UTC (WP §4.3)
  - риск: `$10` на сделку, дневной стоп `-$20` (WP §5.3)
  - Shadow Lab лидеры: BTC/ETH/JUP/WIF и “log-only” (WP §6)
- Логирование решений в jsonl как обязательное требование (WP §7) — обеспечено по умолчанию на файл (`LOG_OUTPUT_TARGET="file"`) и подтверждено реальным `logs/events.jsonl`.

Источники:
- `.opencode/workflow/03_CRITIC_REPORT.md` SUMMARY
- `.opencode/workflow/04_AUDITOR_REPORT.md` CHECKLIST + FINDINGS
- `.opencode/workflow/02_EXECUTOR_REPORT.md` (встроенный `config.py` + logs excerpt)

## ISSUES / RISKS (evidence-based)

### P1 — Gate 1 BTC Risk-Off: неопределённая граница -1.0%
**Факт:** WP противоречив:
- §4.1: “fell more than 1.0%” ⇒ строгое `< -0.010`
- §4.4 pseudocode: `btc_return_60m <= -0.010` ⇒ нестрогое `<= -0.010`

**Текущее состояние:** `config.py` сознательно не выбирает компаратор (`BTC_RISK_OFF_COMPARATOR=None`), чтобы не закреплять поведение без решения PM.

**Риск/импакт:** на границе `btc_return_60m == -0.010` поведение “блокировать/не блокировать” не определено, что является материалным изменением safety-гейта.

Источники:
- `.opencode/workflow/04_AUDITOR_REPORT.md` FINDINGS P1
- `.opencode/workflow/03_CRITIC_REPORT.md` MISSING/RISKS
- `STRATEGY_KNOWLEDGE_BASE.md` §4.1 vs §4.4

### P1/P2 — Политика runtime-артефактов вне `.opencode/workflow/*`
**Факт:** В дереве/изменениях присутствуют:
- `logs/events.jsonl` (нужен по WP §7)
- repo-root `_selftest_backup/` (копии отчётов/логов)
- `__pycache__/` и `*.pyc` (создаются компиляцией)

**Риск/импакт:** спор при приёмке (“должно быть чисто” vs “артефакты допустимы”), риск разрастания бэкапов как потенциального вторичного источника истины.

Источник: `.opencode/workflow/04_AUDITOR_REPORT.md` (fail по hygiene), `.opencode/workflow/02_EXECUTOR_REPORT.md` (FILES/TREE), `.opencode/workflow/DIALOGUE.md` (запрос решения у orchestrator).

### P2 — Несинхронизированный ISSUES.md по Gate 1
ISSUES содержит устаревшее утверждение про дефолт `"<="` в Gate 1, хотя в текущем `config.py` дефолта нет (`None`).

Импакт: риск неверной интерпретации статуса и лишнего “rework”.

Источник: `.opencode/workflow/03_CRITIC_REPORT.md` MISMATCHES #1.

### P2 — Конвенция reset timezone для daily stop
`DAILY_STOP_RESET_TZ = "UTC"` помечено как Stage1 convention (WP не задаёт явно). Нужно либо подтвердить PM, либо позже привязать к операционному стандарту.

Источник: `.opencode/workflow/04_AUDITOR_REPORT.md` FINDINGS.

## VERDICT
**REQUEST CHANGES** (блокируют P1):
1) Решение PM по Gate 1 на границе -1.0% (`<` vs `<=`).
2) Утверждение политики runtime-артефактов (что разрешено/игнорируется, что чистится; запрет `.opencode/_selftest_backup/**`).

## NEXT STEPS (конкретные действия)
1) PM/Orchestrator: зафиксировать каноническое правило Gate 1:
   - либо строгое: `btc_return_60m < -0.010` (интерпретация §4.1 “more than 1.0%”),
   - либо нестрогое: `btc_return_60m <= -0.010` (как в §4.4).
   После решения: свернуть `config.py` до **одного** компаратора + добавить тест-кейс/проверку на `btc_return_60m == -0.010` (когда появится слой тестов).
2) PM/Orchestrator: утвердить policy для:
   - `logs/events.jsonl` (разрешён, обязателен по WP §7, не коммитится)
   - `_selftest_backup/` (разрешён только в repo-root, selftest-only)
   - `__pycache__/`/`*.pyc` (разрешить как runtime, либо чистить в destructive selftest)
   - явно запретить `.opencode/_selftest_backup/**`.
3) Обновить `.opencode/workflow/ISSUES.md`: отметить устаревшие записи про дефолтный `BTC_RISK_OFF_COMPARATOR="<="` как superseded/исправить фактический статус.

