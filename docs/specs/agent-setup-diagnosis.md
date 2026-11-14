# Spec: diagnóstico y mejoras del setup de programación con agentes

**Estado**: en curso. Aplicado: R1 (`.env` ignorado), R2 (`writer`), R6 (eliminados `compose.yml`
y `data/`), R8 (worktrees gestionados por agent-manager), R5 opción B (AGENTS.md corregido).
Decidido: no hay pre-commit en dotfiles. Pendiente: R4 (`*-prompt`), R7 (rutas absolutas), R9 (skills).
**Fecha**: 2026-11-14
**Alcance**: `opencode/` (config, agentes, skills, plugins), `agent-manager/`, `AGENTS.md` raíz y de
`opencode/`, `docs/`, `scripts/`, `Makefile`, y lo que el repo no versiona pero está en el flujo.
**Fuera de alcance**: nvim, tmux, yazi, lazygit, fish (salvo cuando afectan a agentes).

---

## 1. Resumen

El setup está bien pensado: hay una capa de permisos por comando, agentes de solo lectura, un flujo
de planificación (grill → spec → tickets) apoyado en GitHub, y `make doctor` pasa. Los problemas
son de **coherencia** más que de diseño:

1. Una regla de permisos del agente `writer` queda **anulada** por una `deny` posterior: el agente
   no puede ejecutar `git`, `rg` ni `fd` pese a estar declarado.
2. **Secretos y artefactos sin proteger**: `.env` (contraseña de 9router) y `data/` no están en
   `.gitignore`. Un `git add -A` los commitea.
3. **La documentación promete cosas que el código no hace**: `make push` "checks everything" pero no
   ejecuta doctor ni shellcheck.
4. **Ruido en la lista de agentes**: los `*-prompt.md` aparecen como agentes primarios duplicados.
5. **Inventario de skills redundante**: ~45 skills con solapamiento de disparadores, varios con
   nombres de origen (`grill-me`, `grilling`, `grill-with-docs`).
6. **Rutas absolutas y estado huérfano**: `/home/afkale/...` hardcodeado en 3 sitios; `compose.yml`
   de 9router sin uso; `data/model-catalog*.json` (1,3 MB) dentro del repo.

---

## 2. Qué funciona (no tocar)

| Área | Evidencia |
|---|---|
| Permisos por comando con "última regla gana" | `opencode/.config/opencode/opencode.jsonc`: `git push`, `reset --hard`, `clean`, `rm -rf`, `sudo` en `deny`. `opencode debug agents` confirma que el global se aplica a todos los agentes. |
| Subagentes de solo lectura | `reviewer`, `auditor`, `refactor`, `planner` tienen `edit`/`write` en `deny`. Verificado con `opencode debug agents`. |
| Config válida contra el esquema | `opencode debug config` carga `agents` y `permissions` (arrays) sin error. El esquema oficial (`opencode.ai/config.json`) los admite. |
| Estado del toolchain | `make doctor` → `all checks passed` (nvim 0.12.6, fzf 0.75.0, tree-sitter 0.26.9, opencode y agent-manager presentes). |
| Flujo de planificación en GitHub | `docs/agents/issue-tracker.md` define issues, sub-issues y dependencias nativas. `docs/agents/domain.md` y `GLOSSARY.md` están enlazados. |
| ADRs con historia | `docs/adr/003` (superseded) y `004` documentan la vuelta de herdr a tmux. |
| `make push` seguro | `scripts/push.sh` no hace push si un submódulo está sucio o sin upstream. |

---

## 3. Hallazgos

Severidad: **alta** = pérdida de datos o permisos rotos; **media** = comportamiento incorrecto o
engañoso; **baja** = higiene.

### H1 (alta) · Secretos no ignorados por git

- `git check-ignore -v opencode/.config/opencode/.env` → sin salida, exit 1: **no está ignorado**.
- Mismo resultado para `data/model-catalog.json` y `compose.yml` (ver H6).
- `opencode/.config/opencode/.gitignore` solo contiene `*.agent`.
- El `.env` contiene `NINEROUTER_PASSWORD`. `git status` lo muestra como `??`, a un `git add -A` de
  publicarse.
- Aunque el permiso `read *.env → ask` evita que el agente lo lea, no evita que se commitee.

### H2 (alta) · Permisos del agente `writer` anulados

`opencode debug agents` muestra que el orden efectivo de reglas de `writer` pone `shell * deny` al
final. Evaluando las reglas con "última regla gana":

| Comando | Declarado | Efectivo |
|---|---|---|
| `git diff HEAD` | allow | **deny** |
| `git log -5` | allow | **deny** |
| `rg foo` | allow | **deny** |
| `fd x` | allow | **deny** |

Las reglas `allow` de `git *`, `rg *`, `fd *` son código muerto. El agente documenta, pero no puede
investigar con shell. `reviewer`, `refactor` y `auditor` no tienen este problema porque su `shell *
deny` va antes de sus allows.

### H3 (media) · `git status` sin argumentos denegado en subagentes

Las reglas de subagentes usan `git status *`. Esa forma exige un argumento tras `status`, así que
`git status` a secas cae en `shell * deny` (en `reviewer`, `refactor`, `auditor`). **Pendiente de
verificar** con una ejecución real del agente; el matcher de OpenCode podría aceptar el caso sin
argumentos.

### H4 (media) · Agentes duplicados como primarios

`opencode debug agents` lista `planner-prompt`, `reviewer-prompt`, `refactor-prompt` como
`mode: primary`, sin descripción, con los mismos permisos base. Son ficheros de `agents/` (no
`agent` en el JSON), que OpenCode carga como agentes propios. Resultado: tres entradas extra
en el selector de agentes que no hacen nada distinto de `reviewer`, `planner` y `refactor`.

### H5 (media) · `make push` no comprueba lo que dice AGENTS.md

`opencode/.config/opencode/AGENTS.md` dice: "`make push` checks everything before pushing". Pero
`scripts/push.sh` solo valida submódulos (upstream, cambios sin commitear, commits sin publicar) y
después hace `git push --dry-run` y `git push`. No ejecuta `make doctor`, `shellcheck` ni
`bash -n`. Un agente que lea AGENTS.md asumirá una garantía que no existe.

### H6 (media) · Estado sin propietario dentro del repo

| Ruta | Estado | Problema |
|---|---|---|
| `opencode/.config/opencode/compose.yml` | sin trackear | Define 9router (proxy de LLM, puerto 20128). Ninguna referencia en `opencode.jsonc` ni en docs. |
| `opencode/.config/opencode/data/` | sin trackear, 1,3 MB | Catálogo de modelos generado en la fecha de hoy. No hay script que lo genere en el repo. Va a `~/.config/opencode/` vía stow. |
| `opencode/.config/opencode/cli.json` | modificado sin commitear | Añade `tabs`. Permisos de fichero `0600` en un fichero que el resto de la config tiene `0644`. |

### H7 (media) · Rutas absolutas y no portables

- `opencode/.config/opencode/opencode.jsonc` → `"command": ["agent-manager", "mcp"]` (bien, usa PATH).
- `agent-manager/.config/agent-manager/hooks/mcp-opencode.json` → `/home/afkale/.local/bin/agent-manager`.
- `opencode/.config/opencode/plugins/agent-manager/tui.ts` → `execFileSync("/home/afkale/.local/bin/agent-manager", ...)`.

El README promete "fresh machine path". Estas tres rutas rompen eso. Además, `mcp-opencode.json` y
`opencode.jsonc` declaran el mismo MCP dos veces: el riesgo es que diverjan.

### H8 (media) · Dos convenciones de worktrees contradictorias

- `opencode/.config/opencode/AGENTS.md`: "Worktrees go in `~/worktrees/<repo>/<name>`".
- Mismo fichero, sección Agent Manager: "worktrees in `orchestrator-worktrees/`".
- `opencode.jsonc` define `"worktree": { "directory": "~/worktrees" }`.
- En esta máquina existe `~/worktrees/` (dotfiles, gohosts, newstruth) y **no** existe
  `orchestrator-worktrees/`.

Un agente tiene dos instrucciones contradictorias sobre dónde crear un worktree.

### H9 (media) · Solapamiento de skills

Hay 45 `SKILL.md` con ~9.100 caracteres de descripción (~2.300 tokens) cargados en cada sesión.
Solapamientos por disparador:

| Grupo | Skills | Observación |
|---|---|---|
| Entrevista | `grill-me`, `grilling`, `grill-with-docs`, `loop-me` | `grill-with-docs` es un puntero que llama a `grilling` y `domain-modeling`. `grill-me` hace casi lo mismo. |
| Handoff | `handoff`, `claude-handoff` | Dos formas de pasar el contexto a otro agente. |
| Git | `merge`, `rebase`, `open-pr`, `pr` | `pr` y `open-pr` escriben PR bodies; `pr` no tiene `disable-model-invocation`. |
| UI | `ui-polish-pro`, `taste-skill`, `ui-ux-pro-max` | Tres skills de diseño con descripciones que se pisan. `taste-skill` tiene 928 caracteres de descripción. |
| Escritura | `writing-beats`, `writing-fragments`, `writing-shape`, `writing-for-agents` | Los tres primeros son de escritura creativa, distinta de la de agentes. |
| Planificación | `to-spec`, `to-tickets`, `implement`, `implement-spec`, `wayfinder`, `chief-of-staff` | Cadena válida, pero `implement` e `implement-spec` solapan. |

`git-guardrails-claude-code` es para Claude Code, no para OpenCode.

### H10 (baja) · Plugins

- `plugins/agent-manager/tui.ts` hace `setInterval(check, 250)` y lee la sesión cada 250 ms. El
  `execFileSync` solo se llama al cambiar de sesión, así que el coste es bajo, pero el polling
  podría ser un evento del router si OpenCode lo expone.
- `plugins/bell/tui.ts` llama a `tmux display-message` para cada aviso. Aceptable.

### H11 (baja) · ADRs y convención de nombres

- `docs/adr/` tiene `003-...` y `004-...` (3 dígitos, sin 001 ni 002). La skill `domain-modeling`
  documenta ejemplos con 4 dígitos (`0001-...`).
- `README.md` no menciona `agent-manager/` ni `docs/` en su tabla ni en el árbol de Layout.

### H12 (baja) · Git hooks y `prek`

`AGENTS.md` pide `--no-verify` porque "the pre-commit hook errors with `prek: not found`". Este repo
no tiene hooks activos (`.git/hooks` solo tiene samples y `core.hooksPath` no está definido). El
problema vive en otro repo. La skill `setup-pre-commit` existe, pero aquí no se usa. Conviene decidir
si el repo de dotfiles debe tener un hook.

### H13 (baja) · Posibles agentes inútiles

`Explore` declara `shell * allow`, pero la regla global `shell * ask` va después y gana. Su
"allow" de shell no tiene efecto. Revisar si se quiere `Explore` sin prompts.

---

## 4. Requisitos

Cada requisito tiene una comprobación verificable.

### R1 · Ignorar secretos y runtime (H1, H6)

- `.env`, `.env.*` (salvo `.env.example`), `data/` y `*.db` quedan ignorados en
  `opencode/.config/opencode/.gitignore` (o en `.gitignore` raíz).
- **Verificación**: `git check-ignore -v opencode/.config/opencode/.env opencode/.config/opencode/data/model-catalog.json` devuelve exit 0 para ambos.

### R2 · Arreglar la precedencia de reglas de `writer` (H2)

- Mover las reglas `shell git *`, `shell rg *`, `shell fd *` **después** de `shell * deny`, o
  sustituir `shell * deny` por un `ask`/`deny` más específico.
- **Verificación**: `opencode debug agents` → para `writer`, `git diff HEAD` evalúa a `allow`,
  `npm test` a `deny`.

### R3 · Probar `git status` sin argumentos en subagentes (H3)

- Ejecutar `git status` desde un subagente. Si se deniega, añadir `git status` (sin `*`) junto a
  `git status *` en `reviewer`, `refactor`, `auditor`, `writer`.

### R4 · Quitar los `*-prompt` duplicados de la lista de agentes (H4)

- Opción A: borrar `agents/planner-prompt.md`, `agents/reviewer-prompt.md`,
  `agents/refactor-prompt.md` si su contenido ya está en `opencode.jsonc`.
- Opción B: mover su texto al campo `system` del agente homónimo y borrar los ficheros.
- **Verificación**: `opencode debug agents | jq '.[] | select(.mode=="primary") | .name'` no
  incluye `*-prompt`.

### R5 · Que `make push` haga lo que AGENTS.md dice (H5)

- Opción A: añadir a `scripts/push.sh` un paso previo que ejecute `scripts/doctor.sh` y `shellcheck -x`
  sobre los `.sh` modificados.
- Opción B: corregir AGENTS.md para decir que `make push` solo valida submódulos.
- **Verificación**: la elección queda explícita en el texto de AGENTS.md y coincide con lo que hace
  `make push --dry-run`.

### R6 · Decidir el destino de `compose.yml` y `data/` (H6)

- Si 9router se usa: moverlo a `docs/` o a un directorio propio con README y commitearlo.
  Si no se usa: borrarlo.
- `data/` se regenera o se ignora. Si se regenera, añadir el script al repo.
- `cli.json`: commitear el cambio `tabs` (si se quiere) y dejar los permisos de fichero según el resto
  (`0644`).

### R7 · Eliminar rutas absolutas (H7)

- `plugins/agent-manager/tui.ts`: resolver `agent-manager` por PATH (`execFileSync("agent-manager", ...)`).
- `mcp-opencode.json`: borrar el fichero si `opencode.jsonc` ya declara el MCP, o usar `agent-manager`
  sin ruta.
- **Verificación**: `grep -rn "/home/afkale" opencode agent-manager` no devuelve nada salvo
  documentación.

### R8 · Una sola convención de worktrees (H8)

- Elegir una: `~/worktrees/<repo>/<name>` (lo que hace `opencode.jsonc`).
- Corregir la sección Agent Manager de `AGENTS.md` (o configurar agent-manager para usar la misma
  ruta).
- **Verificación**: la palabra `orchestrator-worktrees` no aparece en AGENTS.md salvo que agent-manager
  la use de verdad.

### R9 · Reducir y separar skills (H9)

- Fusionar `grill-me` en `grilling` (o al revés) y dejar `grill-with-docs` como alias.
- Fusionar `handoff` y `claude-handoff`, o marcar uno como específico de Claude Code.
- Elegir un skill de UI como entrada y dejar los otros dos como referencia interna.
- Revisar `pr` y `open-pr`: uno de los dos debe tener `disable-model-invocation: true`.
- Mover `git-guardrails-claude-code` fuera de `opencode/` si no aplica.
- **Verificación**: `ls opencode/.config/opencode/skills/*/SKILL.md | wc -l` baja de 45 a un número
  acordado, y la suma de caracteres de descripciones baja en al menos un 30 %.

### R10 · Documentación al día (H11, H12)

- Añadir `agent-manager/` y `docs/` a `README.md`.
- Unificar el formato de ADR a `NNN-` (3 dígitos) o a `NNNN-` (4 dígitos) y actualizar
  `domain-modeling/ADR-FORMAT.md` para que coincida.
- Decidir si el repo de dotfiles debe tener pre-commit (ver §6).

---

## 5. Plan de implementación sugerido

Orden por riesgo. Cada paso es un commit atómico (AGENTS.md: "Keep commits atomic").

1. **Seguridad (R1)**: ignorar `.env` y `data/`. Riesgo bajo, impacto alto. Hacer primero.
2. **Permisos (R2, R3)**: reordenar las reglas de `writer` y probar `git status`.
3. **Agentes (R4)**: quitar los `*-prompt` tras confirmar que su texto está en `system`.
4. **Rutas y worktrees (R7, R8)**: quitar rutas absolutas y unificar la convención.
5. **Estado huérfano (R6)**: decidir sobre 9router y `data/` con el usuario.
6. **Push y docs (R5, R10)**: alinear AGENTS.md y `push.sh`.
7. **Skills (R9)**: el paso más grande. Hacerlo en un PR aparte, con la lista acordada.

Cada paso se verifica con `make doctor` y con los comandos de §4. Tras `make stow`, reejecutar
`opencode debug agents` para confirmar que el estado efectivo coincide con la intención.

---

## 6. Decisiones que necesito del usuario

1. **9router** (`compose.yml`): ¿lo usas? Si sí, ¿lo commiteamos o lo quitamos?
2. **`data/model-catalog*.json`**: ¿qué lo genera? Si es manual, ¿lo ignoramos o lo borramos?
3. **Skills a eliminar**: ¿cuáles de los 45 usas de verdad? Propongo revisar la lista juntos antes de
   borrar nada. Candidatos: `grill-me` (si usas `grilling`), `claude-handoff`, `git-guardrails-claude-code`.
4. **Worktrees**: ¿`~/worktrees/<repo>/<name>` (lo que hace OpenCode) o `orchestrator-worktrees/`
   (lo que AGENTS.md dice para agent-manager)?
5. **Pre-commit en dotfiles**: ¿quieres hook (`setup-pre-commit`) o confías en `make push`?
6. **`make push`**: ¿que valide (R5 opción A) o corregir la promesa de AGENTS.md (R5 opción B)?

---

## 7. Criterios de aceptación

- [ ] `git check-ignore` confirma que `.env`, `data/` y los secretos no están en `git status`.
- [ ] `opencode debug agents`: `writer` ejecuta `git diff` y `rg`, y no ejecuta `git push`.
- [ ] `opencode debug agents`: no aparecen `*-prompt` como agentes primarios.
- [ ] `grep -rn "/home/afkale" opencode agent-manager` solo devuelve documentación.
- [ ] Una sola convención de worktrees en AGENTS.md.
- [ ] `make doctor` pasa tras cada commit.
- [ ] README y ADRs reflejan la estructura real del repo.
- [ ] Las decisiones de §6 están registradas en `docs/adr/` o en AGENTS.md.

---

## 8. Evidencia de la investigación

Comandos ejecutados (sin cambios en el repo):

- `git status --short`, `git log --oneline | head`, `git ls-files`
- `opencode --version` → `opencode v2.2.7`
- `opencode debug config`, `opencode debug agents` (efectivos por agente)
- `curl https://opencode.ai/config.json` → esquema: `agents`, `permissions`, `mcp`, `worktree` existen
- `git check-ignore -v ...` → exit 1 para `.env`, `data/`, `compose.yml`
- `make doctor` → `all checks passed`
- `grep` de `9router|20128|model-catalog` → solo `compose.yml`
- `grep "prek"` → solo `AGENTS.md:25`
- `scripts/push.sh`: sin llamadas a `doctor`, `shellcheck` ni `bash -n`
- Inventario de skills: 45 `SKILL.md`, 9.097 caracteres de descripciones
- `git worktree list` → solo el checkout principal; `~/worktrees/` existe; `~/orchestrator-worktrees/` no
