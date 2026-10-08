---
name: architecture-porting
version: 1
description: Overall system architecture guide, technical stack mapping, state/routing patterns, and step-by-step cross-language porting strategy.
---

# Architecture & Porting Skill

Use this skill whenever re-architecting, refactoring, or porting `bholix` (Antinna Engine) to another programming language, mobile OS, or web framework.

## Key Architectural Principles
1. **Dynamic Schema Micro-Data**: Treat raw backend posts/entities as dynamic JSON-LD maps.
2. **Reactive Signals**: Use fine-grained reactive primitives (`bloc_signals` in Dart, `StateFlow` in Kotlin, `@Observable` in Swift, `signals` in TypeScript).
3. **Type-Safe Sealed Routing**: Use exhaustive pattern matching over sealed classes or discriminated unions (`kaisel` in Dart, `enum` with associated values in Swift, `sealed class` in Kotlin).
4. **Compile-Time Configuration**: Maintain compile-time constant configuration (`FlavorConfig`, `BuildMode.current`) to avoid runtime configuration overhead.

## Documentation References
- System Architecture: `arch/01_system_architecture.md`
- Data & Domain: `arch/02_data_and_domain.md`
- State & Routing: `arch/03_state_and_routing.md`
- Backend Integrations: `arch/04_backend_and_integrations.md`
- Cross-Language Porting Guide: `docs/04_cross_language_porting_guide.md`
- Master Porting Prompt: `prompts/04_master_app_porting_prompt.md`
