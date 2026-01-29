---
name: orchestration-protocol
description: Протокол дирижирования: как Architect ставит задачи агентам и как собирает отчёты в один финальный репорт.
---

# Orchestration Protocol

## Roles
- Architect: дирижёр, ставит задачи, собирает отчёты, даёт финальный вердикт.
- Executor: реализует, даёт доказательства.
- Critic: сверяет с каноном/ТЗ.
- Auditor: проверяет риски/защиты/гигиену.

## Architect Output Contract
Architect обязан отвечать в формате:

TASKS:
- @executor: ...
- @critic: ...
- @auditor: ...

COLLECT:
- перечисли, какие отчёты ожидаешь получить (executor/critic/auditor)

FINAL REPORT (когда отчёты получены):
SUMMARY
EVIDENCE (tree, фрагменты, ключевые файлы)
CANON MATCH (что совпало с White Paper)
ISSUES (если есть)
VERDICT (approve / request changes)
NEXT STEPS

## Executor Report Contract
STATUS / FILES / TREE / OUTPUT / COMMANDS / NOTES-RISKS

## Critic Report Contract
SUMMARY / MISSING / MISMATCHES / RISKS / VERDICT

## Auditor Report Contract
CHECKLIST / FINDINGS / RECOMMENDATIONS
