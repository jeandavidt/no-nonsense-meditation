# Copilot Project Instructions — No Nonsense Meditation

Purpose
- Provide concrete, project-wide instructions for Copilot agents to operate within this repository, using the agent roster and the orchestrator rules (`ORCHESTRATOR.md` and `PROJECT.md`) as the source of truth.

Core principles (must follow)
- Persistence lifecycle: Before any agent performs a task, initialize `./checkpoints/[agent_name]/` and an initial `checkpoint.json`.
- Pre-action rule: Update checkpoint before any tool call that takes >10s or modifies files.
- Trace logging: Append all CLI output to `./checkpoints/[agent_name]/trace.log` using `2>&1 | tee -a trace.log`.
- Single source of truth: All coordination and progress live in `PROJECT.md` and `PROGRESS.md`.

How Copilot should operate (workflow)
1. Read `PROJECT.md` and `WORKFLOW.md` to determine current phase and outstanding tasks.
2. Choose the appropriate Copilot agent from `.github/instructions/copilot_agents.md` for the task.
3. Create or resume the agent checkpoint: `checkpoints/[agent_name]/checkpoint.json`.
4. Record `current_task`, `completed_steps`, `remaining_work`, and `last_known_state` before starting actionable steps.
5. Execute small, focused tasks (target 1–2 hours). For multi-step tasks, checkpoint between steps.
6. After task completion, append evidence to `PROGRESS.md` and commit only the changed project files and `PROGRESS.md`.

Evidence and Quality Gates
- Always collect evidence required by the Workflow (screenshots, recordings, test results, coverage reports) into `evidence/` organized by session and task.
- Do not mark a phase or task complete without EvidenceQA or testing-reality-checker evidence as required in `WORKFLOW.md`.

Checkpoints and recovery
- Checkpoint format: JSON with `current_task`, `completed_steps`, `remaining_work`, `last_known_state`.
- Verification: After writing a checkpoint or evidence file, run `ls` or `grep` to ensure the write flushed to disk.
- Recovery: On start, always inspect `./checkpoints/` for agent checkpoints and resume from the last saved `current_task`.

Agent invocation patterns
- For allocation and phase transitions use `Studio Producer`.
- For daily task breakdowns and `PROGRESS.md` updates use `Project Shepherd`.
- For Swift code, UI and view models use `Swift/iOS Development`.
- For CoreData and HealthKit use `Backend Architecture`.
- For build configuration, entitlements, and signing use `DevOps Automation`.
- For QA evidence and test certification use `QA / Testing (EvidenceQA)`.
- For performance profiling use `Performance Benchmarking`.
- For visual and accessibility work use `UI Designer`.

Task format (use this template as a commit message and `PROGRESS.md` entry)
- Title: short summary
- Owner: agent_name
- Description: one-line scope
- Evidence: list of evidence files/paths (in `evidence/`)

Automation & commits
- Keep commits small and focused; include `PROGRESS.md` updates in the same commit that completes the task.
- Use descriptive commit messages: `[agent_name] Implement <feature> — evidence: evidence/session_x/…`.

When stuck or blocked
- Agents must record blockers into `PROGRESS.md` and their `checkpoint.json` and escalate to `Studio Producer`.

Where to find more
- Agent definitions: [/.github/instructions/copilot_agents.md](.github/instructions/copilot_agents.md)
- Orchestrator rules: [ORCHESTRATOR.md](ORCHESTRATOR.md)
- Project plan: [PROJECT.md](PROJECT.md)
