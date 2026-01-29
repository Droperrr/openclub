# Архитекторский финальный отчёт (iter=5)

## SUMMARY (для PM)
На этапе Stage 1 каркас проекта и принцип «config.py = единственный источник настроек» в целом выполнены и подтверждены артефактами. Однако финальная приёмка **блокируется** двумя вопросами: (1) **P1** — не закрыта (и фактически преждевременно «выбрана») трактовка гейта BTC Risk-Off на границе ровно -1.0% (строго `<` vs нестрого `<=`); (2) **P2** — отсутствует утверждённая политика по runtime-артефактам (логи/бэкапы/pycache), что создаёт риск «двойного источника истины» и спорной гигиены.

## EVIDENCE (факты из отчётов)

### 1) Stage1 scaffolding (структура)
Executor показывает дерево, совпадающее со Stage1-spec (config.py, main.py, core/*, infrastructure/*, logs/.gitkeep) — см. `.opencode/workflow/02_EXECUTOR_REPORT.md` строки 16–31 и повтор в TREE/COMMANDS (строки 250–267) и `tree -a` (строки 250–267), а также наличие `logs/.gitkeep` (строки 28–30, 263–266).

### 2) config.py как единственный источник настроек
Executor прямо фиксирует: «Config is only settings source: other modules reference config; no strategy thresholds hardcoded elsewhere.» — `.opencode/workflow/02_EXECUTOR_REPORT.md` строки 400–401.
Critic подтверждает соответствие Stage1-spec по этому пункту: «config.py is treated as the only settings source» — `.opencode/workflow/03_CRITIC_REPORT.md` строка 3.

### 3) WP §7: jsonl-логирование и логирование блокировок
Executor:
- дефолт — запись в файл (`LOG_OUTPUT_TARGET = "file"`) и расширение jsonl — `.opencode/workflow/02_EXECUTOR_REPORT.md` строки 140–145.
- наличие персистентного файла `logs/events.jsonl` и его размер — вывод `ls -la logs` — строки 373–381.
- пример первых строк jsonl с событиями decision — строки 887–892.
Auditor помечает пункт «WP §7 jsonl logging durability + includes blocked decisions config» как pass — `.opencode/workflow/04_AUDITOR_REPORT.md` строки 6–8.

### 4) Выполнимость Stage 1 (smoke)
Executor даёт evidence выполнения:
- `python3 -m py_compile config.py main.py core/*.py infrastructure/*.py` без stderr/stdout — `.opencode/workflow/02_EXECUTOR_REPORT.md` строки 363–367.
- `python3 main.py` без stderr/stdout — строки 368–372.

## CANON MATCH (соответствие White Paper / канону)
- Сигнал/гейты/исполнение не реализованы логикой (Stage1 wiring-only), что соответствует заявленной цели этапа 1.
- Канонические константы и условия из WP вынесены в config.py (примерно: LIQUIDATION_CLUSTER_USD=20_000_000, SWEEP_BUFFER=0.0015, CONFIRM_CANDLES=3, ADX(14) и порог 25, окно weekend stop Fri 21:00 UTC → Mon 06:00 UTC, риск $10/сделку, дневной стоп -$20) — всё это явно присутствует в конфиге, см. вложенный текст config.py в `.opencode/workflow/02_EXECUTOR_REPORT.md` (начиная со строки 128 и далее).
- WP §7: jsonl-логирование и «включая блокировки» — настройки событий и флаг `LOG_INCLUDE_BLOCKED_SIGNALS=True` есть — `.opencode/workflow/02_EXECUTOR_REPORT.md` строки 145–150.

## ISSUES / RISKS (актуальные)

### P1 — Gate 1 BTC Risk-Off: граница ровно -1.0% и «выбор победителя»
**Суть:** White Paper конфликтует сам с собой:
- WP §4.1 (prose): «fell more than 1.0%» ⇒ строгое условие (логически) `btc_return_60m < -0.010`.
- WP §4.4 (pseudocode): `btc_return_60m <= -0.010`.

**Почему блокирует приёмку:**
- 01_ARCH_TASKS требует «не выбирать победителя» до решения PM.
- Но в текущем config.py задано активное поведение по умолчанию: `BTC_RISK_OFF_COMPARATOR = "<="` (плюс сохранён вариант prose как отдельная переменная), что Critic и Auditor квалифицируют как несоответствие.

**Evidence:**
- Critic: mismatch #1 и вердикт request changes — `.opencode/workflow/03_CRITIC_REPORT.md` строки 12–15 и 25.
- Auditor: finding P1 — `.opencode/workflow/04_AUDITOR_REPORT.md` строки 12–21.
- Executor: `BTC_RISK_OFF_COMPARATOR = "<="` — `.opencode/workflow/02_EXECUTOR_REPORT.md` строки 213–217.
- ISSUES фиксирует ту же проблему многократно, последняя формулировка — `.opencode/workflow/ISSUES.md` строки 66–73 и 92–100.

### P2 — Политика runtime-артефактов (гигиена / «source of truth»)
**Суть:** в рабочем дереве создаются/поддерживаются артефакты вне `.opencode/workflow/*`, в частности:
- `logs/events.jsonl` (ожидаемо по WP §7, но должно быть согласовано как допустимый runtime-output),
- repo-root `_selftest_backup/` (есть в дереве executor),
- `__pycache__/` и `*.pyc` (созданы после `py_compile`, перечислены в executor FILES).

**Почему важно:** без явной политики это может стать спором при acceptance/CI (требование «чистого дерева» vs допустимые runtime outputs).

**Evidence:**
- Executor FILES перечисляет `logs/events.jsonl` и множество `__pycache__/*.pyc` — `.opencode/workflow/02_EXECUTOR_REPORT.md` строки 6–15.
- Critic: runtime artifacts policy missing — `.opencode/workflow/03_CRITIC_REPORT.md` строки 8–10 и 16–18.
- Auditor: P2 про policy — `.opencode/workflow/04_AUDITOR_REPORT.md` строки 41–47.

## VERDICT
**request changes (не утверждать)**

Причины (только факты):
1) Открытый **P1** по Gate 1 BTC Risk-Off на границе -1.0% + текущее нарушение требования «не выбирать победителя» (config сейчас задаёт дефолт `<=`).
2) Не утверждена политика по runtime-артефактам (**P2**), что может ломать договорённость по гигиене/источнику истины.

## NEXT STEPS (что нужно решить/сделать дальше)
1) **PM решение по Gate 1 (P1, обязательное):** выбрать каноническое сравнение для BTC Risk-Off на ровно -1.0%:
   - вариант A (строгое): `btc_return_60m < -0.010` (следуем букве prose «more than 1.0%»), или
   - вариант B (нестрогое): `btc_return_60m <= -0.010` (следуем псевдокоду).
   После решения: 
   - схлопнуть конфиг до **одного** компаратора (single source of truth);
   - добавить/зафиксировать edge-case тест для `btc_return_60m == -0.010` (даже если тесты ещё не в Stage1 — записать как обязательство Stage2).

2) **Политика runtime-артефактов (P2, утвердить):** одним решением закрепить:
   - `logs/events.jsonl` — допустимый runtime output (соответствует WP §7);
   - `_selftest_backup/` — либо разрешён и игнорируется, либо запрещён и должен чиститься;
   - `__pycache__/` и `*.pyc` — либо допускаются как runtime, либо selftest/CI обязаны чистить.

3) После (1)-(2): критик/аудитор могут перевести вердикт в approve при отсутствии новых блокеров.
