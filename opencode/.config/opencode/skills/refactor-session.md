# Refactor Session Workflow

Use this skill when you want to run a refactoring analysis → plan → implement cycle
on a specific part of the codebase.

## Workflow

1. **Analyze** — Run the `refactor` agent on the target code:
   ```
   ai run refactor "Analyze src/lib/parser.ts for code smells and design issues"
   ```

2. **Plan** — Feed the refactor findings into the `planner` agent:
   ```
   ai run planner "Plan the refactor for src/lib/parser.ts based on these findings: <paste findings>"
   ```

3. **Implement (optional)** — Run the `build` agent phase by phase:
   ```
   ai run build "Phase 1: safe mechanical changes on src/lib/parser.ts per the plan"
   ```

4. **Review** — After each phase, run the `reviewer` agent:
   ```
   ai run reviewer "Review the changes from the refactor of src/lib/parser.ts"
   ```

5. **Repeat** — Move to the next phase until the refactor is complete.

## Best practices

- **Start small.** Refactor one file or one smell at a time. Avoid large coupled changes.
- **Test between every phase.** Run the project's test suite after each phase.
- **Commit after each phase.** This keeps the git history clean and makes `git bisect` useful.
- **Do not mix refactoring with feature work.** If you see a feature request during analysis, note it but don't implement it.
- **Use the strangler fig pattern** for large refactors: build the new structure alongside the old, route traffic gradually, remove the old when nothing depends on it.
