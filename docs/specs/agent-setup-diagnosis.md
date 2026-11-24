# Spec: diagnóstico y mejoras del setup de programación con agentes

**Estado**: en curso. Revisado el 2026-11-18. Resueltos: R1, R4, R5, R6, R7, R8, R9 (parcial),
R12 (nuevo). Pendientes: R2, R3 (verificar), R10, R11.
**Fecha**: 2026-11-14 (diagnóstico original, revisado el 2026-11-18)
**Alcance**: `opencode/` (config, agentes, skills, plugins), `agent-manager/`, `AGENTS.md` raíz y de
`opencode/`, `docs/`, `scripts/`, `Makefile`, y lo que el repo no versiona pero está en el flujo.
**Fuera de alcance**: nvim, tmux, yazi, lazygit, fish (salvo cuando afectan a agentes).

---

## 1. Resumen

El diagnóstico original encontró problemas de **coherencia** más que de diseño. Desde entonces se han
resuelto la mayoría: secretos fuera del repo, rutas absolutas, agentes duplicados, convención de
worktrees, y el inventario de skills, que pasa de 45 a 18 (solo las de Matt Pocock). Quedan
pendientes la verificación de permisos de subagentes (R2, R3) y la documentación (README, ADR).

## 2. Qué funciona (no tocar)

| Área | Evidencia |
|---|---|
| Permisos por comando con "última regla gana" | `opencode.jsonc`: `git push`, `reset --hard`, `clean`, `rm -rf`, `sudo` en `deny`. |
| Subagentes de solo lectura | `reviewer`, `auditor`, `refactor`, `planner` tienen `edit`/`write` en `deny`. |
| Config válida | `opencode.jsonc` parsea como JSON tras quitar comentarios. |
| Estado del toolchain | `make doctor` → `all checks passed` (2026-11-18). |
| Flujo de planificación en GitHub | `docs/agents/issue-tracker.md` define issues, sub-issues y dependencias. |
| ADRs con historia | `docs/adr/003` (superseded) y `004`. |
| `make push` seguro | `scripts/push.sh` no hace push si un submódulo está sucio o sin upstream. |
| Hooks de commit y push | `prek`: gitleaks en commit; shellcheck y `make doctor` en push. |

## 3. Estado de los hallazgos

Severidad: **alta** = pérdida de datos o permisos rotos; **media** = comportamiento incorrecto o
engañoso; **baja** = higiene.

| ID | Sev. | Hallazgo | Estado |
|---|---|---|---|
| H1 | alta | Secretos no ignorados por git | **Resuelto**: `.env` y `service.json` eliminados; `doctor.sh` falla si aparece un fichero de credenciales sin ignorar (R12). |
| H2 | alta | Permisos de `writer` anulados por `shell * deny` | **Pendiente de verificar** (R2). |
| H3 | media | `git status` sin argumentos denegado en subagentes | **Pendiente de verificar** (R3). |
| H4 | media | `*-prompt.md` duplicados como agentes primarios | **Resuelto**: ficheros borrados; reglas movidas al campo `system`. |
| H5 | media | `make push` no hace lo que dice AGENTS.md | **Resuelto**: AGENTS.md ya dice que solo valida submódulos (R5). |
| H6 | media | Estado sin propietario dentro del repo | **Resuelto**: `compose.yml` eliminado; `data/` ignorado; `cli.json` commiteado. |
| H7 | media | Rutas absolutas `/home/afkale/...` | **Resuelto**: `tui.ts` y `mcp-opencode.json` usan `agent-manager` por PATH. |
| H8 | media | Dos convenciones de worktrees | **Resuelto**: AGENTS.md ya no menciona `orchestrator-worktrees/`. |
| H9 | media | Solapamiento de skills | **Resuelto en parte**: 45 → 18 skills (R9). |
| H10 | baja | Polling de 250 ms en `plugins/agent-manager/tui.ts` | **Abierto**, sin decidir. |
| H11 | baja | Formato de ADR (3 o 4 dígitos) y README sin `agent-manager/` ni `docs/` | **Abierto** (R10). |
| H12 | baja | Hooks de git y `prek` | **Resuelto**: `prek` activo y documentado en AGENTS.md. |
| H13 | baja | `Explore` tiene `shell allow` sin efecto | **Abierto**, sin decidir. |

## 4. Requisitos

### R1 · Ignorar secretos y runtime (H1, H6): **resuelto**

- `.env`, `.env.*` (salvo `.env.example`) y `data/` están ignorados en
  `opencode/.config/opencode/.gitignore` y `.gitignore` raíz.
- `opencode/.config/opencode/.env` eliminado (2026-11-18).

### R2 · Precedencia de reglas de `writer` (H2): **pendiente de verificar**

- Reordenar las reglas `shell git *`, `shell rg *`, `shell fd *` después de `shell * deny`.
- **Verificación**: `opencode debug agents` → para `writer`, `git diff HEAD` evalúa a `allow` y
  `npm test` a `deny`.

### R3 · `git status` sin argumentos en subagentes (H3): **pendiente de verificar**

- Ejecutar `git status` desde un subagente. Si se deniega, añadir `git status` (sin `*`) junto a
  `git status *` en `reviewer`, `refactor`, `auditor`, `writer`.

### R4 · Quitar los `*-prompt` duplicados (H4): **resuelto**

- Reglas de `planner-prompt.md`, `reviewer-prompt.md` y `refactor-prompt.md` movidas a los campos
  `system` de `opencode.jsonc`. Los tres ficheros borrados (commit `7cb93be`).

### R5 · `make push` y AGENTS.md (H5): **resuelto sin cambio de código**

- AGENTS.md dice que `make push` solo comprueba submódulos. `pre-push` (prek) ejecuta shellcheck y
  `make doctor`. La promesa ya es exacta. No se añade validación a `push.sh`.

### R6 · Estado huérfano (H6): **resuelto**

- `compose.yml` eliminado (9router retirado). `data/` ignorado (commit `ba3045a`).
- `cli.json`: bloque `tabs` commiteado (commit `fcfdc4a`).

### R7 · Rutas absolutas (H7): **resuelto**

- `plugins/agent-manager/tui.ts` ejecuta `agent-manager` por PATH (commit `dbc23fb`).
- `agent-manager/.config/agent-manager/hooks/mcp-opencode.json` usa `agent-manager` por PATH.
  Se conserva porque el binario de agent-manager referencia ese nombre de fichero (no verificado
  en ejecución). La copia antigua de `~/.config/agent-manager/hooks/`
  se movió a `/tmp/opencode/mcp-opencode.json.bak` y el enlace de stow se restauró.
- **Verificación**: `grep -rn "/home/afkale" opencode agent-manager` solo devuelve documentación.

### R8 · Una sola convención de worktrees (H8): **resuelto**

- AGENTS.md no menciona `orchestrator-worktrees/`. Los worktrees van en `~/worktrees/`
  (`opencode.jsonc`), gestionados por agent-manager.

### R9 · Reducir skills (H9): **resuelto en parte**

- Se mantienen 25 skills de Matt Pocock (copia de `mattpocock/skills` @ `abeeaf9`): `setup-matt-pocock-skills`,
  `grilling`, `grill-with-docs`, `grill-me`, `domain-modeling`, `diagnosing-bugs`, `tdd`, `to-spec`,
  `to-tickets`, `to-questionnaire`, `triage`, `improve-codebase-architecture`, `codebase-design`,
  `prototype`, `setup-pre-commit`, `setup-ts-deep-modules`, `migrate-to-shoehorn`, `wayfinder`,
  `handoff`, `teach`, `wait-what` (productividad) y `ask-matt`, `implement`, `implement-spec`,
  `retro` (restaurados el 2026-11-23 tras el borrado de `99e7fe2`).
- Se eliminan 27 skills (commit `git rm` del 2026-11-18). Quedan en el historial de git.
- No se ha medido la reducción de caracteres de descripciones (criterio original: ≥ 30 %).

### R10 · Documentación al día (H11): **pendiente**

- Añadir `agent-manager/` y `docs/` a `README.md`.
- Unificar el formato de ADR a `NNN-` o `NNNN-` y actualizar `domain-modeling/ADR-FORMAT.md`.

### R11 · Limpieza de nvim: **resuelto parcialmente**

- AGENTS.md describe `vim.pack.add` en vez de packer (commit `8c45538`).
- `lazy-lock.json` local eliminado. Sigue ignorado en `nvim/.config/nvim/.gitignore`; no se ha
  tocado el submódulo.

### R12 · Comprobación de secretos en `doctor.sh` (nuevo): **resuelto**

- `doctor.sh` falla si un fichero que parece credencial (`.env*`, `*secret*`, `*credential*`,
  `*password*`, `service.json`) bajo `opencode/` no está ignorado (commit `b50e3d8`).
- **Verificación**: crear `opencode/.config/opencode/test-password.json` → `make doctor` falla.

---

## 5. Plan de implementación

1. **Seguridad (R1, R12)**: hecho.
2. **Permisos (R2, R3)**: pendiente. Ejecutar `opencode debug agents` antes de editar.
3. **Agentes (R4)**: hecho.
4. **Rutas y worktrees (R7, R8)**: hecho.
5. **Estado huérfano (R6)**: hecho.
6. **Push y docs (R5, R10)**: R5 hecho; R10 pendiente.
7. **Skills (R9)**: hecho en parte; falta medir caracteres de descripción.

## 6. Decisiones

| Decisión | Resultado |
|---|---|
| 9router | Retirado. Se eliminan `.env`, `service.json` y `compose.yml`. |
| `data/model-catalog*.json` | Ignorado; no se versiona. |
| Skills a mantener | Las 25 de Matt Pocock (lista en R9). Revertido el 2026-11-23: se restauraron `ask-matt`, `implement`, `implement-spec` y `retro`, y se añadieron `handoff`, `teach` y `wait-what`. |
| Worktrees | `~/worktrees/` (lo que hace `opencode.jsonc`). |
| Pre-commit en dotfiles | Sí: `prek` con gitleaks, shellcheck y `make doctor`. |
| `make push` | Solo comprueba submódulos. No se añade validación. |
| Repo | Uso personal en máquinas propias: las rutas absolutas son un error. |

## 7. Criterios de aceptación

- [x] `git check-ignore` confirma que `.env` y `data/` no aparecen en `git status`.
- [ ] `opencode debug agents`: `writer` ejecuta `git diff` y `rg`, y no ejecuta `git push`.
- [ ] `opencode debug agents`: no aparecen `*-prompt` como agentes primarios (ficheros borrados;
      falta ejecutar el comando).
- [x] `grep -rn "/home/afkale" opencode agent-manager` solo devuelve documentación.
- [x] Una sola convención de worktrees en AGENTS.md.
- [x] `make doctor` pasa tras los cambios de 2026-11-18.
- [ ] README y ADRs reflejan la estructura real del repo.
- [ ] Las decisiones de §6 están registradas en `docs/adr/` o en AGENTS.md.
