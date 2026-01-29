# 05_ARCH_FINAL_REPORT (Architect -> PM)

## SUMMARY
Этап 1 по scaffolding + вынос параметров в `config.py` в целом выполнен: структура проекта соответствует stage1-spec, а числовые пороги/условия из White Paper (STRATEGY_KNOWLEDGE_BASE.md) перенесены в `config.py` с пояснениями `why` и ссылками на WP.

При этом принять работу как «approve» нельзя из‑за P0 рисков по сохранности канонических артефактов workflow и целостности `ISSUES.md`, а также из‑за незакрытого решения по границе Gate 1 (BTC Risk-Off) и недоказуемости требования WP §7 про логирование заблокированных/подавленных сигналов в Stage1 (сейчас стратегия не исполняется, пишутся только `decision`).

## EVIDENCE (факты и ссылки)
### 1) Структура Stage1 scaffolding
В отчёте исполнителя приведён tree, в котором присутствуют все файлы/папки из stage1-spec:
- `config.py`, `main.py`
- `core/{__init__.py, engine.py, market_data.py, shadow_lab.py}`
- `infrastructure/{__init__.py, logger.py, telegram_bot.py}`
- `logs/.gitkeep`

Доказательство: `.opencode/workflow/02_EXECUTOR_REPORT.md` TREE (строки 7–24).

### 2) `config.py` как единственный источник настроек (WP → config)
Исполнитель привёл полный фрагмент `config.py` с переменными и комментариями вида `# why: ...; WP ref: ...`.
Покрытие ключевых чисел/условий WP подтверждено critic’ом:
- Кластер ликвидаций: `> $20M` (WP §3.1)
- Sweep buffer: `0.15%` → `0.0015` (WP §3.2/§3.4)
- Confirm candles: `3` (WP §3.3)
- Gate 1: `-1.0% / 60m` (WP §4.1/§4.4)
- Gate 2: `ADX(14) H1 > 25` (WP §4.2/§4.4)
- Gate 3: `Fri 21:00 UTC → Mon 06:00 UTC` (WP §4.3)
- Risk: `$10`, Daily stop: `-$20` (WP §5.3)
- Shadow Lab leaders: `BTC, ETH, JUP, WIF` (WP §6.1)
- jsonl logging + include blocked signals (WP §7)

Доказательства:
- `.opencode/workflow/03_CRITIC_REPORT.md` SUMMARY (строка 2)
- `.opencode/workflow/02_EXECUTOR_REPORT.md` фрагмент config (особенно строки 224–284)
- White Paper: `STRATEGY_KNOWLEDGE_BASE.md` §3–§7 (строки 18–136)

### 3) Runtime-доказательство jsonl-логирования и UTC
Есть атомарный прогон: `python3 main.py && ls -la logs && head -n 5 logs/events.jsonl`, где:
- `logs/events.jsonl` реально существует и содержит записи
- `ts` содержит `+00:00` (UTC)

Доказательства:
- `.opencode/workflow/02_EXECUTOR_REPORT.md` (строки 443–456)
- `.opencode/workflow/DIALOGUE.md` (строки 34–44)
- `.opencode/workflow/04_AUDITOR_REPORT.md` UTC correctness: pass (строка 5)

### 4) Нефункциональные/процессные риски вокруг workflow артефактов
Auditor установил root-cause пропажи канонических отчётов: в `.opencode/workflow/selftest.sh` при `DESTRUCTIVE=1` происходит бэкап в `_selftest_backup/$ts`, затем удаление `.opencode/workflow/0{1,2,3,4,5}_*.md`.

Доказательства:
- `.opencode/workflow/04_AUDITOR_REPORT.md` checklist: retention fail (строка 3)
- `.opencode/workflow/DIALOGUE.md` (строки 45–46)
- `.opencode/workflow/ISSUES.md` (строки 96–112)

## CANON MATCH (соответствие White Paper)
- Сигнал-механика и параметры (sweep buffer 0.0015, confirm 3 свечи, cluster >$20M) вынесены в config и снабжены WP ссылками: соответствует WP §3.
- Gate’ы (BTC risk-off, ADX trend, weekend stop) отражены в config: соответствует WP §4.
- Execution: фиксированный риск $10 и daily stop -$20 отражены: соответствует WP §5.3.
- Shadow Lab leaders (BTC/ETH/JUP/WIF) отражены и модуль помечен как log-only/no-trade: соответствует WP §6.
- Logging jsonl как обязательный формат реализован на уровне инфраструктуры и подтверждён запуском: соответствует WP §7 частично.

## ISSUES / RISKS (консолидировано)
### P0
1) **Удаление канонических workflow-артефактов selftest’ом**
- Факт: при `DESTRUCTIVE=1` удаляются `.opencode/workflow/01..05_*.md`.
- Влияние: ломается «chain-of-custody», ревью становится недетерминированным.
- Evidence: `04_AUDITOR_REPORT.md:3`, `DIALOGUE.md:45-46`, `ISSUES.md:105-112`.

2) **Отсутствие доказанной append-only целостности `ISSUES.md`**
- Факт: ранее наблюдалась усечённость/перезапись; защитный механизм не подтверждён.
- Влияние: потеря аудита/трассировки решений.
- Evidence: `ISSUES.md:6-13` и `ISSUES.md:69-76`, `04_AUDITOR_REPORT.md:4`.

### P1
3) **Gate 1 BTC Risk-Off: неоднозначность границы (< vs <= на -1.0%)**
- Факт: WP prose (§4.1) «fell more than 1.0%» конфликтует с pseudocode (§4.4) `<= -0.010`.
- Сейчас: `BTC_RISK_OFF_COMPARATOR = None`, в config оставлены оба кандидата.
- Влияние: неопределённое поведение на границе.
- Evidence: `STRATEGY_KNOWLEDGE_BASE.md:59-60` vs `:76-77`; `02_EXECUTOR_REPORT.md:247-252`; `04_AUDITOR_REPORT.md:31-33`.

4) **WP §7: “log blocked signals too” не демонстрируется end-to-end на Stage1**
- Факт: в `events.jsonl` видны `decision` события, но нет `gate_blocked`/`signal_suppressed`, т.к. Stage1 «wiring only: no strategy evaluation».
- Влияние: невозможно доказать выполнение требования WP §7 в части blocked/suppressed.
- Evidence: `04_AUDITOR_REPORT.md:10`, `DIALOGUE.md:40-44`, `ISSUES.md:123-130`, WP `STRATEGY_KNOWLEDGE_BASE.md:135-136`.

5) **Доказательная база в 02 отчёте исторически была не self-contained**
- Факт: critic фиксировал отсутствие raw output; в текущей итерации raw output уже вставлен (см. 02 отчёт), но сам риск отмечаем как процессный.
- Evidence: `03_CRITIC_REPORT.md:5-11`.

### P2
6) **Секреты/санитизация логов не доказаны**
- Факт: секреты Telegram берутся из env, но нет доказательств, что они никогда не попадут в логи.
- Evidence: `04_AUDITOR_REPORT.md:11, 43-45`.

7) **Гигиена runtime-артефактов** (`__pycache__`, `_selftest_backup`, `logs/events.jsonl`) — политика не зафиксирована PM.
- Evidence: `ISSUES.md:33-40`, `03_CRITIC_REPORT.md:16`.

## VERDICT
**request changes** (из‑за P0 по retention workflow и целостности ISSUES + P1 по gate boundary и blocked-signal logging доказуемости).

## NEXT STEPS (конкретно)
1) **Зафиксировать каноничность `.opencode/workflow/*` и убрать destructive cleanup**
- Исправить `.opencode/workflow/selftest.sh`: `cleanup_state()` не должен удалять `.opencode/workflow/0{1..5}_*.md` и не должен трогать `ISSUES.md`/`DIALOGUE.md`. `_selftest_backup` оставить как backup-only.

2) **Append-only guard для `ISSUES.md`**
- Добавить проверку в pipeline/selftest: если количество строк/хэш `ISSUES.md` уменьшается — падать (fail-closed). Опционально: явный монотонный `issue_id`.

3) **Решение PM по Gate 1 comparator**
- Выбрать строгое `< -0.010` (по prose «more than 1%») или нестрогое `<= -0.010` (по pseudocode). После решения: установить единое значение `BTC_RISK_OFF_COMPARATOR` и добавить тест/смоук на границе `btc_return_60m == -0.010`.

4) **WP §7 blocked/suppressed logging — сделать демонстрируемым**
- Вариант A (предпочтительно): добавить детерминированный smoke path, который (без торговли) симулирует срабатывание gate и пишет `gate_blocked` + `signal_suppressed` в jsonl.
- Вариант B: явно зафиксировать как ограничение Stage1 и добавить обязательство Stage2 с тестами.

5) **Secrets hygiene**
- Явно запретить логирование `TELEGRAM_BOT_TOKEN/CHAT_ID` (policy + минимальный тест/ассерты).
