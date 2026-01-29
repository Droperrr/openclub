---
name: stage1-spec
description: Внешнее ТЗ Этапа 1: scaffolding + config.py как единственный источник настроек + DoD.
---

# Stage 1 Spec (External Architect)

## Scaffolding (strict)
 /project_root/
 ├── STRATEGY_KNOWLEDGE_BASE.md  # already exists
 ├── config.py                   # ONLY source of settings
 ├── main.py                     # entry point
 ├── core/
 │   ├── __init__.py
 │   ├── engine.py
 │   ├── market_data.py
 │   └── shadow_lab.py
 ├── infrastructure/
 │   ├── __init__.py
 │   ├── logger.py
 │   └── telegram_bot.py
 └── logs/
     └── .gitkeep

## config.py requirements
- Extract EVERY number/condition from STRATEGY_KNOWLEDGE_BASE.md into config.py.
- Sections: System / Strategy Core / Risk Gates / Execution / Shadow Lab
- Comment each variable: why + WP section reference.
- No business logic in other modules yet.

## DoD
- Show tree (or find listing)
- Provide full config.py for review
