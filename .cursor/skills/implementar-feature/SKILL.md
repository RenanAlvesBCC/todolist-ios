---
name: implementar-feature
description: Guides implementing a product increment for the oficina (mechanic iOS board, manager web, or API). Use when adding a feature, endpoint, screen, or when the user asks to implementar, incrementar, pivotar, or follow the roadmap.
---

# Implementar feature — oficina-mecanico-ios

Este repo é o **app do mecânico**. Não construa pátio do gerente, atribuição de colegas nem gestão de membros.

## Checklist

Copie e marque:

```
- [ ] Li docs/VISAO.md, docs/GLOSSARIO.md, docs/CONTRATO-API.md e as rules
- [ ] Classifiquei: API | web gerente | app mecânico | contrato cruzado
- [ ] Confirmei o papel (owner / manager / editor). editor = mecânico
- [ ] Contrato HTTP inalterado, ou atualizado neste ciclo em todos os clientes
- [ ] Código só na camada certa (View → ViewModel → protocolo/serviço)
- [ ] Testes no mesmo incremento
- [ ] UI no vocabulário da oficina (veículo, serviço, esteira)
- [ ] `./scripts/verify.sh` passou (build + TodoListTests + cobertura ≥ 90% no escopo)
```

## Antes do commit

1. Commit **pequeno** — uma mudança lógica por vez.
2. Rode `./scripts/verify.sh`; se falhar, corrija antes de commitar.
3. Escopo de cobertura: `docs/QUALIDADE.md` (ViewModels, Services, Models, Utils).

## Regras

1. Não ampliar permissão do mecânico sem mudança explícita no contrato.
2. Não inventar endpoint, campo JSON ou role.
3. Mutações permitidas: status (transições de editor), serviços, pendências, orçamento. Proibido: criar/excluir veículo, assign, membros.
4. Strings em `Localizable.xcstrings`. View não chama HTTP.

## Depois

Se o contrato mudou, atualize `docs/CONTRATO-API.md` e avise os outros clientes (API, web, Android).
