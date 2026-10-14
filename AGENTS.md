# Lamb-fundamental-solver — instrucciones para agentes

Antes de modificar código, leer el estándar común fijado en `.research-automation/standards/engineering.md`. Si falta el submódulo privado, detener la edición e inicializarlo; no sustituirlo por una copia informal o una URL de `main`.

## Invariantes locales

- `src/+lamb/+models/` posee forward physics, tracking, políticas, calidad y resultados; `src/+lamb/+fitting/` posee fitting inverso, optimización y métricas. `app/` coordina y presenta; los modelos no dependen de fitting, app, studies ni tests. Propietarios en [arquitectura](docs/repository/final_architecture.md).
- Rayleigh-Lamb, mRLFE y AE IOP/HGO tienen física y estructura distintas. La dependencia científica intencional entre familias es la semilla mRLFE mediante la API pública Rayleigh-Lamb. No forzar paquetes simétricos.
- `experimental.validMask` es fijo en fitting: no descartar observaciones según parámetros candidatos ni modificar la máscara para fabricar métricas o sensibilidades. El modelo debe cubrir con velocidad de fase finita las observaciones seleccionadas, salvo rechazo de soporte declarado antes de optimizar.
- Separar parámetros físicos, opciones numéricas, perfiles de ejecución y UI. `executionProfile` es el campo canónico; `robustness` existe solo en normalización de la app. Los perfiles cambian costo, no física.
- AE entrega `atlasA0` como resultado oficial. Diagnósticos y fallback no sustituyen esa curva. La calidad evalúa una curva ya seleccionada: no la reconecta, interpola, reemplaza ni selecciona otra rama.
- Conservar prefijos de implementación `rl*`, `mrlfe*`, `ae*`; leer los `AGENTS.md` locales de las familias afectadas bajo `src/+lamb/+models/`.
- Preservar métodos, presets, tracking, validez, tolerancias y benchmarks sin alterar snapshots para pasar tests. El gate y catálogo canónico están en [validación](docs/repository/validation_status.md).

Las invariantes físicas locales tienen prioridad sobre generalizaciones del estándar. No integrar ni modificar `main` sin autorización.
