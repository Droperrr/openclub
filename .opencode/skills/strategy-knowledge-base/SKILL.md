---
name: strategy-knowledge-base
description: Каноническая White Paper стратегии SOL Liquidity Navigator. Используй как единственный источник истинных правил сигналов, гейтов, риск-лимитов и формата алертов.
---

# Canon: STRATEGY_KNOWLEDGE_BASE

Источник: STRATEGY_KNOWLEDGE_BASE.md (в корне репозитория).

## Правила использования
1) Перед любыми архитектурными решениями/тасками: сверяться с White Paper.
2) Любые изменения стратегии = изменения в STRATEGY_KNOWLEDGE_BASE.md (только после подтверждения PM).
3) Любые несоответствия кода канону — фиксировать как ISSUE/риски в отчёте архитектора.

## Что в каноне (коротко)
- Сигнал: Sweep + reclaim + 3 свечи удержания.
- Gate’ы: BTC risk-off, ADX trend, weekend stop.
- Execution: human-in-the-loop, директивные алерты.
- Логи: jsonl, включая блокировки.
