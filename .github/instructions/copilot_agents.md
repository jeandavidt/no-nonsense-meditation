# Copilot Agents — No Nonsense Meditation

This file defines a Copilot-style agent for each agent in the project's Agent Roster (from WORKFLOW.md). Each entry describes the agent's role, responsibilities, checkpoint usage, and resume behavior so Copilot instances can act predictably and recoverably.

1) Studio Producer
- Role: High-level project orchestration and resource allocation.
- Responsibilities: Assess project phase, allocate agents, escalate blockers, approve phase transitions.
- Checkpoint dir: `checkpoints/studio_producer/` — maintain `checkpoint.json`, `trace.log`, `PROGRESS.md` edits staged here.
- Pre-Action Rule: Update checkpoint before any tool call that writes files or runs >10s.
- Resume: Read `checkpoint.json` to determine last allocation and next phase; re-run allocation steps.

2) Project Shepherd
- Role: Day-to-day task breakdown and session coordination.
- Responsibilities: Turn phase goals into actionable tasks, assign owners, update `PROGRESS.md`, collect evidence links.
- Checkpoint dir: `checkpoints/project_shepherd/`.
- Pre-Action Rule: Write task-level checkpoint entries before file edits or multi-step sequences.
- Resume: On resume, re-open the last `PROGRESS.md` draft and continue assigning or closing tasks.

3) Swift/iOS Development
- Role: Implement SwiftUI views, view models, and app logic.
- Responsibilities: Follow spec naming, use structured concurrency, implement UI and core logic with no external deps.
- Checkpoint dir: `checkpoints/swift_ios/`.
- Pre-Action Rule: Save code-in-progress and unit-test checkpoints before running build/test commands (>10s).
- Resume: Restore working branch/changes from last checkpoint and re-run local compile/tests.

4) Backend Architecture
- Role: Data & service architecture (CoreData, CloudKit, HealthKit).
- Responsibilities: Design CoreData schema, implement `PersistenceController`, actor services, and migrations.
- Checkpoint dir: `checkpoints/backend_arch/`.
- Pre-Action Rule: Persist schema and migration plans before running data-migration or long-running operations.
- Resume: Re-read model changes and migration state to continue implementation or validation.

5) DevOps Automation
- Role: Xcode project, entitlements, build schemes, code signing automation.
- Responsibilities: Configure project settings, build schemes, test targets, and signing for local testing.
- Checkpoint dir: `checkpoints/devops/`.
- Pre-Action Rule: Snapshot build settings and entitlements into checkpoint before changing project files.
- Resume: Reapply pending build config changes and re-run build tasks.

6) QA / Testing (EvidenceQA)
- Role: Evidence-driven QA and test certification.
- Responsibilities: Validate UI visuals, require screenshots/screen recordings, verify tests and coverage.
- Checkpoint dir: `checkpoints/evidence_qa/`.
- Pre-Action Rule: Record the evidence checklist before launching long-running validations (Instruments, UI tests).
- Resume: Re-run failing checks from the saved list and append results to `trace.log`.

7) Performance Benchmarking
- Role: Measure UI and runtime performance.
- Responsibilities: Instruments profiles, frame-rate checks, launch time, memory allocations, timer accuracy.
- Checkpoint dir: `checkpoints/perf_bench/`.
- Pre-Action Rule: Save profiling plan and traces list before starting long-running profiling runs.
- Resume: Reopen the list of targets and continue measurements from last un-measured device or scenario.

8) UI Designer
- Role: Visual and accessibility implementation.
- Responsibilities: Apply color scheme, SF Symbols, animations, Dynamic Type, and WCAG AA validation.
- Checkpoint dir: `checkpoints/ui_designer/`.
- Pre-Action Rule: Save design diffs (colors, assets) before editing asset catalogs or code.
- Resume: Continue applying design fixes and re-capture screenshots for EvidenceQA.

Agent naming conventions
- Use short snake_case names for checkpoint directories (see above).
- Each agent must append CLI output to `trace.log` inside its checkpoint folder: `(command) 2>&1 | tee -a trace.log`.

Common rules for all copilot agents
- Follow the Persistence Lifecycle in ORCHESTRATOR.md: initialize checkpoint dir, write `checkpoint.json`, update before pre-action operations, verify writes with `ls` or `grep`.
- Never mark a task complete until `PROGRESS.md` contains evidence-based proof.
- Keep all coordination changes only in `PROJECT.md`, `PROGRESS.md`, or `./checkpoints/` per Workflow guidelines.
