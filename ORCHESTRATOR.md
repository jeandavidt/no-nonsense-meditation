# Workflow Orchestrator Guide

Manage autonomous subagents with zero-loss persistence. Every subagent must be recoverable if its process is terminated or hits a limit.

## 1. The Persistence Lifecycle (Mandatory)
Before a subagent performs any task, the Coordinator must enforce this lifecycle:
1. **Initialize:** Create `./checkpoints/[agent_name]/` and an initial `checkpoint.json`.
2. **Context Injection:** Pass the path of this directory to the subagent as its primary state-store.
3. **The Pre-Action Rule:** Subagents MUST update their checkpoint *before* executing any tool call that takes >10 seconds or involves file modifications.

## 2. Checkpoint Schema
All subagents must maintain `checkpoint.json` using this structure:
- `current_task`: Description of the immediate micro-goal.
- `completed_steps`: List of verified actions taken.
- `remaining_work`: List of pending actions from the original plan.
- `last_known_state`: Technical breadcrumbs (e.g., "Line 45 of auth.py modified," "Server running on port 3000").

## 3. Defensive Execution Rules
* **Atomic Saves:** Do not write large files in one go. Subagents must save progress file-by-file.
* **Verification:** After updating a checkpoint or PROGRESS.md, the agent must briefly `ls` or `grep` the file to confirm the write was flushed to disk.
* **The "Breadcrumb" Constraint:** Append all CLI output to `./checkpoints/[agent_name]/trace.log`. Use `(command) 2>&1 | tee -a trace.log` for shell tasks to ensure logs exist even if the agent process is killed.

## 4. Continuity & Recovery
* **Resume First:** Before starting a task, check `./checkpoints/`. If a checkpoint exists for a task, use `resume_agent(agent_id)` or read the JSON to pick up exactly where the last process died.
* **Quality Gates:** Never mark a task "Complete" until `PROGRESS.md` reflects the evidence-based proof of the subagent's work.
* **Parallel Coordination:** When running multiple instances, use the `agent_name` to prevent filename collisions in the `./checkpoints/` directory.

## 5. Heartbeat Monitoring
Every 5 iterations, the Coordinator must run ./agent_status.sh. If an agent is marked as STALE (except the coordinator itself), the Coordinator must read that agent's trace.log, summarize the failure, and relaunch a new agent using the existing checkpoint.json.

## 5. Reporting Constraints
- **Source of Truth:** `PROGRESS.md` is the master ledger.
- **No Litter:** Keep all coordination within `PROJECT.md`, `PROGRESS.md`, or the specific `./checkpoints/` folder.