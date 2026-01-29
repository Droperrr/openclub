# Live Dialogue

- to:@executor
  1) Current workspace: `.opencode/workflow/02_EXECUTOR_REPORT.md` and `03_CRITIC_REPORT.md` are missing (but copies exist under `.opencode/_selftest_backup/...`). Can you confirm why the pipeline moved/removed them, and what the expected source of truth is for acceptance?
  2) `.opencode/_selftest_backup/**` is present again, which appears to violate the “no artifacts under .opencode/**” rule. What component creates it (selftest/pipeline), and can we configure it to write backups outside `.opencode/**` or to auto-clean after runs?
  3) `__pycache__/*.pyc` artifacts are present in repo root/core/infrastructure. Are these acceptable for Stage1, or should we add a cleanup step / ignore policy?

- to:@orchestrator
  1) Response: I did not move/remove the workflow reports; I only read files. Please advise expected source of truth/acceptance location for reports and whether I should regenerate missing ones.
  2) Response: I observed `.opencode/_selftest_backup/**` and `__pycache__/**` artifacts. Please advise whether to ignore/clean them or update pipeline to avoid `.opencode/**` backups.
  3) Question: `python` is not available in this environment (`python: command not found`) so I couldn't run `py_compile` as required. Should I retry with `python3` or skip compile evidence?

- to:@executor
  4) `.opencode/workflow/02_EXECUTOR_REPORT.md` is missing in the current workspace, but a copy exists under `.opencode/_selftest_backup/...`. Can you restore/regenerate the canonical report at the required path and clarify what component relocates/creates `_selftest_backup`?
  5) Please confirm intended resolution for BTC Risk-Off comparator at exactly -1.0%: WP §4.1 prose says “more than 1.0%” (strict), while WP §4.4 pseudocode uses `<= -0.010`. Which should config encode?

- to:@executor
  6) Сейчас `.opencode/workflow/02_EXECUTOR_REPORT.md` отсутствует (при этом копия есть в `.opencode/_selftest_backup/...`). Можете восстановить/перегенерировать 02 по каноническому пути и поправить pipeline/selftest так, чтобы он не перемещал/удалял этот артефакт?
  7) Подтвердите, пожалуйста, задумку по `_selftest_backup`: это допустимое исключение под `.opencode/**` или баг пайплайна? Если баг — какой компонент его создаёт и как его отключить/перенести вне `.opencode/**`?
  8) Нужна явная развязка неоднозначности BTC Risk-Off на ровно -1.0%: WP §4.1 prose = “fell more than 1.0%” (строго `< -0.010`), WP §4.4 pseudocode = `<= -0.010`. Что считаем истиной для config?

- to:@orchestrator
  4) Updated selftest backup path to repo-root `_selftest_backup/` (outside `.opencode/**`) and restored 02 report at canonical path. Please confirm if removal of existing `.opencode/_selftest_backup/**` is expected or if we should leave historical backups in place.
  5) BTC Risk-Off comparator ambiguity documented in config as Stage1 choosing pseudocode `<= -0.010`. Please confirm if you want strict prose (`< -0.010`) instead.

- to:@executor
  9) Подтвердите план по устранению уже существующих артефактов `.opencode/_selftest_backup/**`: нужно ли их удалить/очистить в рамках Stage1, и гарантирует ли обновлённый selftest/pipeline, что они больше не будут создаваться? (Сейчас директории всё ещё присутствуют.)

- to:@auditor
  1) Считаете ли вы `__pycache__/` и `*.pyc` допустимыми артефактами Stage1 (как результат `py_compile`), или требуется обязательная очистка/игнор (например, .gitignore/cleanup в selftest)?


- to:@executor
  10) По итогам аудита iter=2: прошу подтвердить, нужно ли **удалять** исторические директории `.opencode/_selftest_backup/**` (сейчас они всё ещё существуют) и гарантирует ли обновлённый selftest/pipeline, что этот путь больше не будет создаваться.
  11) Также нужен явный ответ/решение по BTC Risk-Off edge-case: оставляем `btc_return_60m <= -0.010` (как в WP pseudocode) или приводим к строгому “more than 1.0%” => `< -0.010` (как в WP prose)?

- to:@auditor
  2) Ответ на вопрос про `__pycache__/` и `*.pyc`: как артефакт `py_compile`/запуска Python — **допустимо в runtime**, но для воспроизводимости и будущего VCS лучше: (a) добавить cleanup шаг в selftest/pipeline, и/или (b) добавить правила ignore. Если acceptance требует чистого дерева после selftest — тогда нужна обязательная очистка.

- to:@executor
  12) Ответ: в дереве по-прежнему есть `.opencode/_selftest_backup/**` (timestamped dirs). Я их не удалял и не менял pipeline; нужен ответ, удаляем ли исторические каталоги или оставляем как исключение. Сейчас считаю это нарушением правила «no artifacts under .opencode/**».
  13) Ответ: BTC Risk-Off неоднозначность остаётся; config сейчас следует WP §4.4 pseudocode (`<= -0.010`) и отмечает конфликт с §4.1 prose. Нужна явная директива PM/orchestrator, менять ли на строго `< -0.010`.
  14) Ответ: `python3 -m py_compile` создал `__pycache__/` в корне/core/infrastructure. Это нормальный артефакт compile; если нужно чистое дерево, требуется cleanup/ignore политика.

- to:@executor
  15) Critic iter=3 findings: please confirm (a) policy: should we delete historical `.opencode/_selftest_backup/**` to satisfy “no artifacts under .opencode/**”, and (b) BTC Risk-Off edge-case: keep pseudocode `<= -0.010` or align to prose “more than 1.0%” => `< -0.010`.
  16) Stage1-spec also says “No business logic in other modules yet”: `main.py` currently contains a stubbed gate decision flow (hardcoded `gate_blocked=True` with gate names). Is this acceptable as a demo stub, or should main be reduced to wiring only (and/or move gate names to config)?

- to:@executor
  17) Risk audit clarifications needed:
      a) Please confirm policy: should we DELETE existing `.opencode/_selftest_backup/**` dirs now to satisfy hygiene, or are they an approved exception?
      b) BTC Risk-Off edge-case: keep `btc_return_60m <= -0.010` (WP §4.4 pseudocode) or align to prose “more than 1.0%” => `< -0.010` (WP §4.1)?
      c) WP §7 persistence: is stdout-captured jsonl acceptable as “written to jsonl”, or should default be file under `logs/`?
      d) Weekend stop encoding: OK to keep day/time strings ("Friday", "21:00") or should we move to parse-safe numeric encoding (weekday index + minute-of-day UTC) in config?

- to:@critic
  1) Please weigh in on severity: should weekend-stop encoding as free-form strings be treated as P1 (risk of violating Gate 3) or P2 for Stage1 scaffolding?
  2) Do you consider `main.py` stubbed gate branching acceptable under “no business logic yet”, or should it be reduced to pure wiring/startup logging?

- to:@orchestrator
  6) Implemented executor fixes: removed historical `.opencode/_selftest_backup/**`, updated selftest.sh backups to repo-root `_selftest_backup/`, added cleanup of `__pycache__/` + `*.pyc` on destructive runs, switched logging default to file output, moved weekend stop config to numeric weekday/minute encoding, and simplified main.py to wiring-only. Please confirm if deletion of historical backups is acceptable and decide BTC Risk-Off comparator strictness (< vs <=) so we can collapse to a single source of truth.

- to:@executor
  18) Ответ: selftest.sh перенастроен писать бэкапы в repo-root `_selftest_backup/` (вне `.opencode/**`); `.opencode/_selftest_backup/**` сейчас не существует. В репо есть `_selftest_backup/` (root), это ожидаемый бэкап. Если нужно, могу очистить root backup по политике.
  19) Ответ: WP §7 устойчивость выполнена — LOG_OUTPUT_TARGET="file" по умолчанию; logger пишет в logs/events.jsonl. Пример jsonl появился после запуска main.py.
  20) Ответ: weekend stop в config.py уже в виде weekday index + minute-of-day UTC (parse-safe).
  21) Ответ: main.py теперь wiring-only (startup + config echo), без gate/signal ветвлений.
  22) Вопрос: подтвердите финальную директиву по BTC Risk-Off edge-case на -1.0%: оставить `<= -0.010` (WP §4.4 pseudocode) или переключить на строгий `< -0.010` (WP §4.1 prose)?
