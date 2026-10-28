# Lamb-fundamental-solver — instrucciones para agentes

Antes de modificar código, leer el estándar común fijado en `.research-automation/standards/engineering.md`. Si falta el submódulo privado, detener la edición e inicializarlo; no sustituirlo por una copia informal o una URL de `main`.

For each implementation task, read the main README, `docs/repository/final_architecture.md`, affected domain contracts and dependency tests once before editing. Establish owners and consumers; preserve existing local changes.

## Invariantes locales

- `workflows/` owns section-oriented human Editor scripts, with callable execution functions under `workflows/inversion/`, separate from exploratory `studies/`; MATLAB Editor sections must resolve the actual open file rather than MATLAB's temporary section script. Workflows are opt-in and may consume maintained production/integration/visualization APIs; none of these domains may depend on workflows.
- External observation preparation preserves explicit masks, rows and provenance; reject invalid selected inputs without repairing the mask. Producers own schema validation/I/O; scientific owners retain model-specific validation and inversion.
- New researcher-facing physical configuration and fitting inputs use **one canonical SI vocabulary**: `density_kgpm3` (bulk mass density), `thickness_m` (current full thickness), `poisson_ratio` (dimensionless), and `*_Pa` for dimensional moduli. Do not introduce competing physical names, infer values or silently convert units. Mathematical solver symbols and previously persisted native schemas remain model-owned; preserve their exact meaning and document any boundary normalization.
- Human inverse workflows distinguish `excitationMode` (QH/Pulse), native `branchName`/derived `modelBranch` (A0/S0), reviewed fitting frequencies from presentation targets, and researcher-supplied model-assumption justification from calculated solver support. One reviewed geometry policy owns the input; model-specific effective review is derived. Never silently infer physical validity from fit success.
- Scientific inversion uses only the observations and physical inputs required by the selected model. Available load, mass or external DIC measurements are not automatic fitting constraints; independent validation/comparison must remain separate. See [architecture](docs/repository/final_architecture.md#inverse-inputs-versus-external-validation).
- `src/+lamb/+models/` owns forward science; `src/+lamb/+fitting/` owns inverse algorithms. Integration, visualization, GUI and study owners and permitted dependencies are defined in [architecture](docs/repository/final_architecture.md). Scientific packages never depend on those consumer domains.
- Rayleigh-Lamb, mRLFE y AE IOP/HGO tienen física y estructura distintas. La dependencia científica intencional entre familias es la semilla mRLFE mediante la API pública Rayleigh-Lamb. No forzar paquetes simétricos.
- `experimental.validMask` es fijo en fitting: no descartar observaciones según parámetros candidatos ni modificar la máscara para fabricar métricas o sensibilidades. El modelo debe cubrir con velocidad de fase finita las observaciones seleccionadas, salvo rechazo de soporte declarado antes de optimizar.
- Separar parámetros físicos, opciones numéricas, perfiles de ejecución y UI. `executionProfile` es el campo canónico; `robustness` existe solo en normalización de la app. Los perfiles cambian costo, no física.
- AE entrega `atlasA0` como resultado oficial. Diagnósticos y fallback no sustituyen esa curva. La calidad evalúa una curva ya seleccionada: no la reconecta, interpola, reemplaza ni selecciona otra rama.
- Conservar prefijos de implementación `rl*`, `mrlfe*`, `ae*`; leer los `AGENTS.md` locales de las familias afectadas bajo `src/+lamb/+models/`.
- Preservar métodos, presets, tracking, validez, tolerancias y benchmarks. El gate y catálogo canónico están en [validación](docs/repository/validation_status.md).

