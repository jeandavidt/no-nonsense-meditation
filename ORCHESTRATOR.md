# Workflow Orchestrator Guide

This guide explains how to run the autonomous agentic workflow for the No Nonsense Meditation project.

---

## Quick Start Commands

### Starting a New Session

```
Start a new development session. Continue from where we left off.
```

This will:
1. Read PROJECT.md and PROGRESS.md to understand current state
2. Auto-invoke Studio Producer to assess phase and allocate agents
3. Execute next phase tasks autonomously
4. Update PROGRESS.md with session results

### Continuing Specific Work

```
Continue Phase [N] work. Focus on [specific area].
```

Example:
```
Continue Phase 2 work. Focus on Timer UI implementation.
```

### Starting a Specific Phase

```
Start Phase [N]: [Phase Name]
```

Examples:
```
Start Phase 1: Setup & Infrastructure
Start Phase 2: Core Features
Start Phase 3: Testing & QA
Start Phase 4: Polish & Deployment
```

---

## Agent Invocation Commands

### Studio Producer (Orchestration)

**When to use**: Start of session, phase transitions, major blockers

```
Invoke Studio Producer to assess current project state and allocate resources for the next phase.
```

What it does:
- Reads PROJECT.md and PROGRESS.md
- Assesses current phase completion
- Identifies blockers
- Allocates appropriate agents
- Sets session goals

### Project Shepherd (Coordination)

**When to use**: Task breakdown, daily coordination

```
Invoke Project Shepherd to break down [Phase/Task] into actionable items and coordinate agents.
```

What it does:
- Breaks phases into specific tasks
- Coordinates agent handoffs
- Updates PROGRESS.md
- Monitors task completion

### Development Agents

#### swift-expert

**When to use**: Swift code, SwiftUI views, ViewModels, App Intents

```
Invoke swift-expert to implement [specific feature/component].
```

Examples:
```
Invoke swift-expert to implement TimerViewModel with @Observable macro.
Invoke swift-expert to create CircularTimerDial SwiftUI component.
Invoke swift-expert to build App Intents for Shortcuts integration.
```

#### Backend Architect

**When to use**: CoreData, CloudKit, HealthKit, service architecture

```
Invoke Backend Architect to [design/implement] [specific backend component].
```

Examples:
```
Invoke Backend Architect to set up CoreData schema with CloudKit integration.
Invoke Backend Architect to implement HealthKitService actor.
Invoke Backend Architect to design SessionManager actor for session lifecycle.
```

#### DevOps Automator

**When to use**: Project setup, build configuration, deployment

```
Invoke DevOps Automator to [configure/setup] [build/deployment aspect].
```

Examples:
```
Invoke DevOps Automator to initialize Xcode project with proper capabilities.
Invoke DevOps Automator to configure release build settings and code signing.
Invoke DevOps Automator to set up build schemes for Debug and Release.
```

### Quality Agents

#### EvidenceQA

**When to use**: After UI implementation, before phase completion

```
Invoke EvidenceQA to validate [feature/UI] with evidence requirements.
```

What it does:
- Demands screenshots/recordings
- Validates against spec
- Defaults to "NEEDS WORK"
- Finds 3-5 issues per review
- Approves only with overwhelming evidence

Examples:
```
Invoke EvidenceQA to validate Timer UI implementation against spec.
Invoke EvidenceQA to review all Phase 2 features before advancing to Phase 3.
```

#### testing-reality-checker

**When to use**: After writing tests, before test certification

```
Invoke testing-reality-checker to certify test suite with evidence.
```

What it does:
- Validates tests actually run and pass
- Checks coverage meets 70% threshold
- Requires Xcode test result screenshots
- Defaults to "NEEDS WORK"
- Grants certification only with proof

Examples:
```
Invoke testing-reality-checker to certify unit test suite for Phase 3.
Invoke testing-reality-checker to validate test coverage report.
```

#### Performance Benchmarker

**When to use**: Performance validation, optimization

```
Invoke Performance Benchmarker to validate [performance aspect].
```

Examples:
```
Invoke Performance Benchmarker to validate 60fps UI performance.
Invoke Performance Benchmarker to measure app launch time.
Invoke Performance Benchmarker to profile memory usage during meditation sessions.
```

### Design Agents

#### UI Designer

**When to use**: Visual design, colors, animations, accessibility

```
Invoke UI Designer to implement [design aspect].
```

Examples:
```
Invoke UI Designer to apply color scheme per spec.
Invoke UI Designer to implement animations for timer controls.
Invoke UI Designer to validate WCAG AA contrast ratios.
```

---

## Workflow Execution Patterns

### Pattern 1: Autonomous Phase Execution

**Use case**: Let agents work independently to complete a phase

```
Execute Phase [N] autonomously. Use Studio Producer to orchestrate agent coordination.
```

What happens:
1. Studio Producer reads state and allocates agents
2. Agents work in parallel on phase tasks
3. Quality agents validate work with evidence
4. Project Shepherd updates PROGRESS.md
5. Human approval at quality gates

### Pattern 2: Focused Feature Implementation

**Use case**: Implement a specific feature with appropriate agents

```
Implement [Feature Name] using appropriate agents. Coordinate with Project Shepherd.
```

Example:
```
Implement Timer Core functionality using swift-expert and Backend Architect. Coordinate with Project Shepherd.
```

What happens:
1. Project Shepherd breaks down feature into tasks
2. swift-expert implements UI/ViewModel
3. Backend Architect implements services
4. EvidenceQA validates with screenshots
5. PROGRESS.md updated with evidence

### Pattern 3: Quality Validation

**Use case**: Validate completed work against quality gates

```
Run quality validation for [Phase/Feature]. Use EvidenceQA and testing-reality-checker.
```

What happens:
1. EvidenceQA reviews UI with evidence requirements
2. testing-reality-checker certifies tests
3. Performance Benchmarker validates performance
4. Issues documented in PROGRESS.md
5. Remediation tasks created if needed

### Pattern 4: Agent Resume

**Use case**: Continue work from previous session

```
Resume agent [agent_id] to continue [work description].
```

Example:
```
Resume swift-expert agent_abc123 to continue Timer UI implementation from Session 2.
```

What happens:
- Agent resumes with full context from previous session
- Continues work from where it left off
- Updates PROGRESS.md with new progress

---

## Phase-Specific Commands

### Phase 1: Setup & Infrastructure

```
Execute Phase 1: Initialize project, set up CoreData schema, configure capabilities, and establish test infrastructure.
```

**Agents used**:
- DevOps Automator (Xcode project init)
- Backend Architect (CoreData schema)
- swift-expert (file structure)
- DevOps Automator (test setup)

**Quality gate check**:
```
Validate Phase 1 completion: Ensure project builds, CoreData compiles, test targets run.
```

### Phase 2: Core Features

```
Execute Phase 2: Implement all core features (Timer, UI, Data, HealthKit, Settings) with parallel agent coordination.
```

**Agents used**:
- swift-expert (Timer Core, Timer UI, Settings)
- Backend Architect (Data Layer, HealthKit)
- UI Designer (UI components, visual design)

**Quality gate check**:
```
Invoke EvidenceQA to validate all Phase 2 features with comprehensive screenshot evidence.
```

### Phase 3: Testing & QA

```
Execute Phase 3: Write comprehensive test suite, validate performance, achieve quality certification.
```

**Agents used**:
- swift-expert (Unit & UI tests)
- Backend Architect (Integration tests)
- Performance Benchmarker (Performance validation)
- testing-reality-checker (Test certification)
- EvidenceQA (Feature validation)

**Quality gate check**:
```
Invoke testing-reality-checker to certify test suite with >70% coverage evidence.
Invoke Performance Benchmarker to validate 60fps UI and <2s launch time.
```

### Phase 4: Polish & Deployment

```
Execute Phase 4: Final polish, accessibility validation, build configuration, device testing.
```

**Agents used**:
- UI Designer (Final polish, accessibility)
- swift-expert (App assets)
- DevOps Automator (Build configuration)
- EvidenceQA (Final validation)
- testing-reality-checker (Build certification)

**Quality gate check**:
```
Invoke EvidenceQA for final sign-off with device testing evidence.
Run full quality validation suite before declaring project complete.
```

---

## Evidence Management

### Requesting Evidence

```
Provide evidence for [task/feature]: [specific evidence type needed].
```

Examples:
```
Provide evidence for Timer UI: Screenshot showing countdown at 10:00, 5:00, and 0:00.
Provide evidence for test coverage: Xcode coverage report screenshot.
Provide evidence for 60fps UI: Instruments Time Profiler screenshot.
```

### Evidence Formats

- **Screenshots**: For UI features, settings, states
- **Screen recordings**: For user flows, animations
- **Xcode outputs**: For test results, coverage reports, build logs
- **Instruments profiles**: For performance validation
- **Debugger screenshots**: For data flow, CoreData state
- **Device photos/videos**: For physical device testing

### Evidence Organization

Evidence should be referenced in PROGRESS.md:

```markdown
### Tasks Completed

#### 1. Timer UI Implementation ✅
- **Agent**: swift-expert (agent_abc123)
- **Evidence**:
  - Timer setup screen: [screenshot](evidence/timer-setup.png)
  - Active meditation view: [recording](evidence/active-session.mp4)
  - Session recap: [screenshot](evidence/session-recap.png)
- **Validation**: EvidenceQA approved with 2 minor fixes applied
```

---

## Session Management

### Starting a Session

1. **Read current state**:
   ```
   What's the current project status? Read PROJECT.md and PROGRESS.md.
   ```

2. **Assess and plan**:
   ```
   Invoke Studio Producer to assess current state and plan this session.
   ```

3. **Execute**:
   ```
   Execute planned tasks using appropriate agents.
   ```

### During a Session

- Agents work autonomously
- Update PROGRESS.md as tasks complete
- EvidenceQA validates work with screenshots
- testing-reality-checker certifies tests
- Human intervention only for decisions or blockers

### Ending a Session

1. **Update progress**:
   ```
   Invoke Project Shepherd to update PROGRESS.md with session results.
   ```

2. **Quality check**:
   ```
   Run quality validation for completed work.
   ```

3. **Prepare for next session**:
   ```
   Document next session goals and save agent IDs for resume.
   ```

4. **Git commit** (if applicable):
   ```
   git add .
   git commit -m "Session [N]: [Summary of work completed]"
   ```

---

## Blocker Resolution

### When Blocked

```
Blocker encountered: [describe blocker]. Request Studio Producer assessment.
```

What happens:
- Studio Producer analyzes blocker
- Determines if solvable by agents
- Allocates problem-solving resources
- Escalates to human if needed

### Common Blockers

1. **Build errors**: DevOps Automator investigates
2. **Test failures**: testing-reality-checker analyzes
3. **Design ambiguity**: Ask user for clarification
4. **Performance issues**: Performance Benchmarker profiles
5. **Quality gate failures**: EvidenceQA specifies remediation

---

## Multi-Session Continuity

### Resuming Work

```
Resume work from Session [N]. Read PROGRESS.md and continue where we left off.
```

What happens:
1. Reads PROGRESS.md Session N summary
2. Identifies agent IDs to resume
3. Loads agent context from previous session
4. Continues work seamlessly

### Agent Context Preservation

Agents save their context:
```markdown
### Agent IDs for Resume
- swift-expert: agent_abc123 (continuing Timer UI implementation - 60% complete)
- Backend Architect: agent_def456 (CoreData schema complete, ready for HealthKit)
```

Next session:
```
Resume swift-expert agent_abc123 to complete Timer UI implementation.
```

---

## Examples

### Example 1: Starting Fresh

```
User: "Start Phase 1: Setup & Infrastructure"

1. Studio Producer auto-invoked
   - Reads PROJECT.md: Phase 1 not started
   - Allocates: DevOps Automator, Backend Architect, swift-expert
   - Sets goal: Initialize project and infrastructure

2. DevOps Automator
   - Creates Xcode project
   - Configures capabilities
   - Evidence: Build log

3. Backend Architect
   - Creates CoreData model
   - Implements PersistenceController
   - Evidence: Model compiles

4. swift-expert
   - Creates file structure
   - Generates stub files
   - Evidence: Project navigator screenshot

5. Project Shepherd
   - Updates PROGRESS.md
   - Saves agent IDs
   - Sets next session goals
```

### Example 2: Continuing Work

```
User: "Continue Phase 2 work from Session 3"

1. Reads PROGRESS.md Session 3
   - Last work: Timer Core 70% complete
   - Agent ID: swift-expert agent_abc123

2. Resumes swift-expert agent_abc123
   - Continues TimerViewModel implementation
   - Completes AudioService
   - Evidence: Code compiles

3. EvidenceQA validates
   - Requests timer screenshot
   - Finds 2 issues
   - Status: NEEDS WORK

4. swift-expert fixes issues
   - Provides new evidence
   - EvidenceQA approves

5. Project Shepherd updates PROGRESS.md
```

### Example 3: Quality Validation

```
User: "Run full quality validation for Phase 2"

1. EvidenceQA reviews all features
   - Timer UI: 3 screenshots required
   - Settings: 2 screenshots required
   - Data flow: CoreData debugger screenshot
   - Finds 4 issues total

2. Remediation tasks created
   - swift-expert fixes 3 UI issues
   - Backend Architect fixes 1 data issue

3. EvidenceQA re-validation
   - New evidence provided
   - All issues resolved
   - Status: APPROVED

4. Project Shepherd
   - Updates PROGRESS.md with approval
   - Marks Phase 2 complete
   - Ready for Phase 3
```

---

## Best Practices

1. **Always read state first**: `What's the current status?`
2. **Let agents work autonomously**: Don't micromanage
3. **Demand evidence**: Never accept claims without proof
4. **Use quality gates**: Don't skip validation
5. **Document everything**: PROGRESS.md is the source of truth
6. **Resume agents**: Use agent IDs for continuity
7. **Parallel when possible**: Multiple agents can work simultaneously
8. **Trust the process**: Evidence-based validation ensures quality

---

## Troubleshooting

### "Agent doesn't have enough context"
- Provide spec reference: "See Product Specification Documents.md section X"
- Resume from previous session: Use agent ID
- Be specific: "Implement X according to spec naming conventions"

### "Quality gate keeps failing"
- Provide better evidence: More screenshots, different angles
- Review spec carefully: Ensure exact match
- Ask EvidenceQA: "What specific evidence is needed?"

### "Don't know which agent to use"
- Consult WORKFLOW.md "Agent Invocation Guide"
- Ask Studio Producer: "Which agent should handle X?"
- Default to Project Shepherd for coordination

### "Work is blocked"
- Document in PROGRESS.md
- Invoke Studio Producer for assessment
- Ask for human decision if ambiguous

---

## Success Indicators

You know the workflow is working when:
- ✅ Agents work with minimal human prompting
- ✅ PROGRESS.md updates automatically
- ✅ Evidence provided proactively
- ✅ Quality gates enforced consistently
- ✅ Work continues seamlessly across sessions
- ✅ Project advances through phases systematically

---

## Quick Reference

| Task | Command |
|------|---------|
| Start session | `Start a new development session` |
| Continue work | `Continue from where we left off` |
| Start phase | `Start Phase [N]: [Name]` |
| Validate quality | `Run quality validation for [Phase]` |
| Get status | `What's the current project status?` |
| Invoke agent | `Invoke [Agent Name] to [task]` |
| Resume agent | `Resume agent [ID] to [task]` |
| Update progress | `Update PROGRESS.md with current session results` |

---

**Ready to build!** 🚀

Start with: `Start Phase 1: Setup & Infrastructure`
