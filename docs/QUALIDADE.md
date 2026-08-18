# Qualidade — oficina-mecanico-ios

## Escopo de cobertura (meta ≥ 90%)

| Incluído | Excluído |
|----------|----------|
| `ViewModels/` | `Views/` (SwiftUI) |
| `Services/` | `*App.swift`, `ContentView` |
| `Models/` | Previews, assets |
| `Utils/` | |

Medição: linhas cobertas pelo target **TodoList** nos arquivos acima, via `xcrun xccov` após `TodoListTests`.

## Verificação local

```bash
./scripts/verify.sh
```

Equivalente manual:

```bash
xcodebuild build -scheme TodoList -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild test -scheme TodoList -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:TodoListTests -enableCodeCoverage YES \
  -resultBundlePath build/TestResults.xcresult
```

## Commits pequenos

- Um commit = uma mudança lógica (ViewModel, service, tela isolada).
- Rode `./scripts/verify.sh` antes de cada commit.
- Código novo no escopo exige teste unitário no mesmo commit.

## Baseline

Se a cobertura estiver abaixo de 90%, incrementos que tocam o escopo devem **aumentar** a cobertura até atingir o threshold; não commite regressão.
