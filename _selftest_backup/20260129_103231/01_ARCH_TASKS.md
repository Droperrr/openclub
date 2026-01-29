# 01_ARCH_TASKS (Architect → Team)

iter=4

## Контекст (PM-facing)
- Этап 1: scaffolding + `config.py` строго по White Paper (`STRATEGY_KNOWLEDGE_BASE.md`).
- `config.py` — единственный источник настроек (stage1-spec).
- Стратегию не меняем без PM APPROVED; `STRATEGY_KNOWLEDGE_BASE.md` не правим.

## Evidence-based статус (по входным артефактам)
- По `ISSUES.md` и `DIALOGUE.md` наблюдается повторяющаяся **нестабильность workflow-артефактов** (репорты 02/03/04 иногда «пропадают» на каноническом пути), а также инфра-selftest может упираться в single-flight (`another run is active`) и таймаут.
- Ключевые незакрытые решения, блокирующие финальный вердикт (request changes до решения):
  1) Gate 1 BTC Risk-Off boundary на ровно -1.0%: strict `< -0.010` (WP §4.1 prose) vs non-strict `<= -0.010` (WP §4.4 pseudocode).
  2) Stage1 policy по runtime-artifacts вне `.opencode/workflow/*` (как минимум: `logs/events.jsonl`, repo-root `_selftest_backup/`, `__pycache__/`/`*.pyc`).

---

## TASKS:

### @executor (Implementation + Evidence)
1) **Workflow artifact stability (P0)**
   - Обеспечить, что канонические артефакты существуют и сохраняются на месте после прогонов:
     - `.opencode/workflow/02_EXECUTOR_REPORT.md`
     - `.opencode/workflow/03_CRITIC_REPORT.md`
     - `.opencode/workflow/04_AUDITOR_REPORT.md`
   - Если какой-либо скрипт/проектная автоматика их удаляет/перемещает (в т.ч. в любые backup-папки) — устранить причину.
   - Доказательства: before/after `ls -la .opencode/workflow` вокруг selftest/pipeline прогонов.

2) **Stage1 scaffolding verification (stage1-spec strict)**
   - Подтвердить, что дерево проекта соответствует stage1-spec:
     - `STRATEGY_KNOWLEDGE_BASE.md` (exists)
     - `config.py`, `main.py`
     - `core/{__init__.py,engine.py,market_data.py,shadow_lab.py}`
     - `infrastructure/{__init__.py,logger.py,telegram_bot.py}`
     - `logs/.gitkeep`
   - Evidence: `tree -a -L 4` + `ls -la logs`.

3) **config.py completeness vs WP (no missing numbers/conditions)**
   - Вынести в `config.py` ВСЕ числа/условия из WP, и для каждой переменной добавить комментарии:
     - `why:` (зачем параметр)
     - `WP ref:` (ссылка на раздел/пункт WP)
   - Минимальный чек-лист WP→config:
     - Cluster threshold: liquidation cluster volume `> $20M` (WP §3.1)
     - Sweep buffer: `0.15%` (WP §3.2)
     - Confirm candles: `3` (WP §3.3)
     - Gate 1: `1.0%` drop over `60m` (WP §4.1)
     - Gate 2: `ADX(14) H1 > 25` (WP §4.2)
     - Gate 3: Fri `21:00 UTC` → Mon `06:00 UTC` (WP §4.3)
     - Risk per trade: `$10` (WP §5.3)
     - Daily stop loss: `-$20` (WP §5.3)
     - Shadow lab leaders: `BTC, ETH, JUP, WIF` (WP §6.1)
     - Logging: every decision (incl. blocked) to jsonl (WP §7)

4) **Gate 1 ambiguity: document, do not pick a winner (P1)**
   - Конфликт WP: prose vs pseudocode. До решения PM/Orchestrator:
     - prose comparator candidate: `< -0.010` (WP §4.1)
     - pseudocode comparator candidate: `<= -0.010` (WP §4.4)
   - Требование: активный comparator в config должен быть `None/UNDECIDED` (не выбирать поведение молча).

5) **Operational proof (Stage1 runnability)**
   - Выполнить и вставить в 02-репорт точные команды + вывод (stdout/stderr + exit codes):
     - `python3 -m py_compile config.py main.py core/*.py infrastructure/*.py`
     - `python3 main.py`
   - Доказательство durability для jsonl:
     - `ls -la logs`
     - фрагмент `logs/events.jsonl` (или выбранного persistent target) с 1–2 событиями.

6) **Pipeline/selftest evidence (single-flight timeout) (P1)**
   - Если selftest/pipeline может зависать на `another run is active`, предоставить:
     - чёткое воспроизведение/причину (какой процесс держит lock)
     - рекомендацию по детерминированному прогону для доказательств (без параллельного run)
     - минимальное доказательство, что артефакты не «исчезают» в процессе.

7) **02 report contract (deliverable quality gate)**
   - `.opencode/workflow/02_EXECUTOR_REPORT.md` должен содержать:
     - STATUS
     - FILES changed/verified
     - TREE (with dotfiles)
     - COMMANDS + OUTPUT
     - NOTES/RISKS (Gate 1 decision pending; runtime-artifacts policy pending; artifact stability; selftest single-flight)
     - Полный `config.py` (verbatim) внутри репорта (stage1-spec DoD).


### @critic (Spec + Canon Review)
1) **Canonical critic artifact present & stable (P0)**
   - Обеспечить существование и устойчивость `.opencode/workflow/03_CRITIC_REPORT.md`.

2) **Scaffold vs stage1-spec**
   - Проверить наличие всех требуемых файлов/папок и отсутствие лишних.

3) **config.py review vs White Paper**
   - Проверить, что каждое число/условие из WP реально присутствует в config.
   - Проверить, что у каждой переменной есть `why:` + `WP ref:`.

4) **Stage1 scope discipline**
   - Подтвердить, что нет бизнес-логики (сигналы/гейты/ветвления стратегии) вне будущего engine; только wiring/stubs.
   - Подтвердить, что по Gate 1 не выбран winner до решения PM/Orchestrator.

5) **Staleness check for ISSUES**
   - Если в `ISSUES.md` есть устаревшие утверждения (например, про default comparator или наличие/отсутствие артефактов), отметить как “stale/superseded” в 03 отчёте с доказательствами.

6) **03 report contract**
   - SUMMARY / MISSING / MISMATCHES (with WP refs) / RISKS / VERDICT (approve/request changes)


### @auditor (Risk + Hygiene + Workflow)
1) **Canonical auditor artifact present & stable (P0)**
   - Обеспечить существование и устойчивость `.opencode/workflow/04_AUDITOR_REPORT.md`.

2) **Workflow integrity audit**
   - Подтвердить, что `.opencode/workflow/{02,03,04}_*.md` не перемещаются/не удаляются selftest/pipeline.
   - Указать, что запрещено создавать `.opencode/_selftest_backup/**` (исторически это было проблемой), и рекомендовать enforcement.

3) **WP §7 logging durability**
   - Подтвердить, что jsonl логирование по умолчанию даёт durable storage (файл или гарантированный capture).
   - Подтвердить, что логируются также “blocked/suppressed” решения.

4) **Runtime-artifacts policy recommendation (Stage1) (P1/P2)**
   - Сформулировать чёткую политику (рекомендацию для PM/Orchestrator) по:
     - `logs/events.jsonl`
     - repo-root `_selftest_backup/`
     - `__pycache__/` и `*.pyc`
   - Явно: `.opencode/_selftest_backup/**` запрещён.

5) **04 report contract**
   - CHECKLIST / FINDINGS / RECOMMENDATIONS

---

## COLLECT:
Expected canonical artifacts:
1) `.opencode/workflow/02_EXECUTOR_REPORT.md`
2) `.opencode/workflow/03_CRITIC_REPORT.md`
3) `.opencode/workflow/04_AUDITOR_REPORT.md`

Also collect PM/Orchestrator decisions needed to unblock final approval:
- Gate 1 BTC Risk-Off comparator at exactly -1.0%: strict `< -0.010` (WP §4.1 prose) vs non-strict `<= -0.010` (WP §4.4 pseudocode).
- Stage1 runtime-artifacts policy for outputs outside `.opencode/workflow/*` (logs/events.jsonl, repo-root `_selftest_backup/`, `__pycache__/`/`*.pyc`).
- Guidance on how to produce deterministic pipeline/selftest completion evidence if single-flight blocks runs (`another run is active`).
