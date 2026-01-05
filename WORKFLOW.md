# Autonomous Agentic Workflow

## Overview

This project uses an **autonomous multi-agent orchestration system** where specialized AI agents collaborate to build, test, and deploy the No Nonsense Meditation iOS app across multiple sessions. The workflow is designed for minimal human intervention while maintaining high quality through evidence-based validation gates.

## Core Principles

1. **Autonomous Coordination**: Agents work independently with clear ownership and handoffs
2. **Evidence-Based Quality**: All features require proof (screenshots, test results, benchmarks)
3. **Session Persistence**: State tracked via files (PROJECT.md, PROGRESS.md) + agent resume capability
4. **Phase-Gated Progress**: Must pass quality gates before advancing to next phase
5. **Hybrid State Management**: File-based tracking + agent memory for continuity

---

## Agent Roster

### Orchestration Layer

#### Studio Producer
- **Role**: High-level project orchestration and resource allocation
- **Responsibilities**:
  - Monitor overall project health across sessions
  - Allocate agents to phases based on current needs
  - Escalate blockers and coordinate complex dependencies
  - Transition between project phases
- **When to invoke**: Start of each session, phase transitions, major blockers

#### Project Shepherd
- **Role**: Day-to-day coordination and task management
- **Responsibilities**:
  - Break down phase goals into actionable tasks
  - Monitor daily progress and agent workloads
  - Update PROGRESS.md with session outcomes
  - Coordinate handoffs between agents
- **When to invoke**: Within-session task coordination

---

### Development Layer

#### swift-expert
- **Role**: Primary iOS/Swift development specialist
- **Responsibilities**:
  - Implement SwiftUI views and ViewModels
  - Build App Intents for Shortcuts integration
  - Write Swift code following spec naming conventions
  - Conduct code reviews for Swift best practices
  - Ensure proper @Observable, @MainActor usage
- **Quality Standards**:
  - All code must compile without warnings
  - Follow spec naming patterns exactly
  - Use structured concurrency (async/await, actors)
  - No external dependencies (iOS SDK only)

#### Backend Architect
- **Role**: Data layer and service architecture
- **Responsibilities**:
  - Design and implement CoreData schema with CloudKit
  - Build HealthKit integration (authorization, sync)
  - Create actor-based services (SessionManager, HealthKitService)
  - Implement PersistenceController with iCloud sync
  - Design data migration strategies
- **Quality Standards**:
  - Thread-safe actor implementations
  - Proper CoreData concurrency handling
  - CloudKit sync with conflict resolution

#### DevOps Automator
- **Role**: Build configuration and deployment automation
- **Responsibilities**:
  - Initialize and configure Xcode project
  - Set up entitlements (HealthKit, CloudKit, iCloud)
  - Create build schemes (Debug/Release)
  - Configure code signing for local device testing
  - Manage build scripts and automation
- **Quality Standards**:
  - Project builds without errors
  - All capabilities properly configured
  - Clean build architecture

---

### Quality Assurance Layer

#### EvidenceQA
- **Role**: Screenshot-obsessed QA specialist
- **Responsibilities**:
  - Demand visual proof for every implemented feature
  - Default to finding 3-5 issues per review
  - Validate UI against spec (colors, typography, spacing)
  - Verify user flows match Product Specification
  - Check accessibility features (VoiceOver labels, contrast)
- **Quality Standards**:
  - **Default stance**: "NEEDS WORK" until proven otherwise
  - **Evidence required**: Screenshots or screen recordings
  - **No fantasy approvals**: Must see it running
- **When to invoke**: After any UI implementation, before phase completion

#### testing-reality-checker
- **Role**: Evidence-based test certification
- **Responsibilities**:
  - Validate that tests actually run and pass
  - Verify test coverage meets 70% threshold
  - Check test quality (not just passing, but meaningful)
  - Ensure no flaky or fake tests
  - Certify test suites before production readiness
- **Quality Standards**:
  - **Default stance**: "NEEDS WORK"
  - **Evidence required**: Test run output, coverage reports
  - **Overwhelming proof needed**: Screenshots of Xcode test results
- **When to invoke**: After writing tests, before phase 3 completion

#### Performance Benchmarker
- **Role**: Performance validation and optimization
- **Responsibilities**:
  - Measure UI performance (must maintain 60fps)
  - Validate app launch time (<2s cold start)
  - Profile memory usage during meditation sessions
  - Check CoreData fetch performance
  - Verify timer accuracy over extended periods
- **Quality Standards**:
  - 60fps UI throughout app (measured with Instruments)
  - <2s cold launch time
  - No memory leaks
  - Timer drift <1s over 60 minutes

---

### Design Layer

#### UI Designer
- **Role**: Visual design implementation and accessibility
- **Responsibilities**:
  - Implement color scheme per spec (accent, timer, success colors)
  - Apply SF Symbol icons correctly
  - Create animations (.spring, .linear, .easeInOut)
  - Validate WCAG AA contrast ratios (4.5:1 minimum)
  - Implement Dynamic Type and Reduce Motion support
- **Quality Standards**:
  - All colors meet WCAG AA contrast
  - Animations match spec timing
  - Full Dynamic Type support
  - Accessibility Inspector validation

---

## Workflow Phases

### Phase 1: Setup & Infrastructure
**Goal**: Project initialized, builds successfully, basic infrastructure in place

**Agent Sequence**:
1. **DevOps Automator**: Initialize Xcode project
   - Create NoNonsenseMeditation.xcodeproj
   - Set bundle ID: `com.yourteam.NoNonsenseMeditation`
   - Configure deployment target: iOS 16.0
   - Add HealthKit, iCloud, CloudKit capabilities

2. **Backend Architect**: Set up CoreData schema
   - Create NoNonsenseMeditation.xcdatamodeld
   - Define MeditationSession entity with all attributes
   - Configure CloudKit container options
   - Implement PersistenceController.swift

3. **swift-expert**: Create base file structure
   - Generate folder hierarchy per spec
   - Create stub files for main components
   - Set up dependency injection patterns
   - Create Constants.swift and AppLogger.swift

4. **DevOps Automator**: Initialize test infrastructure
   - Create test targets
   - Set up test schemes
   - Configure code coverage reporting

**Quality Gate**:
- ✓ Project builds without errors (checked by DevOps Automator)
- ✓ CoreData model compiles and generates classes (checked by Backend Architect)
- ✓ Test targets run (even if empty) (checked by testing-reality-checker)

**Output**: PROJECT.md updated, PROGRESS.md logged, ready for Phase 2

---

### Phase 2: Core Features
**Goal**: All major features implemented and functional

**Parallel Workstreams**:

**Stream A - Timer Core** (swift-expert + Backend Architect):
1. MeditationTimerService (timer countdown logic)
2. SessionManager (session lifecycle)
3. AudioService + NotificationService
4. TimerViewModel with @Observable

**Stream B - Timer UI** (swift-expert + UI Designer):
1. TimerSetupView with duration picker
2. CircularTimerDial component
3. ActiveMeditationView with progress ring
4. SessionRecapView with statistics

**Stream C - Data Layer** (Backend Architect):
1. Complete PersistenceController implementation
2. MeditationSession CRUD operations
3. StreakCalculator implementation
4. iCloud sync validation

**Stream D - HealthKit** (Backend Architect + swift-expert):
1. HealthKitService actor
2. Authorization flow UI
3. Mindful minutes sync
4. Permission denied handling

**Stream E - Settings** (swift-expert + UI Designer):
1. SettingsViewModel
2. SettingsTabView with all sections
3. StatisticsHeaderView
4. UserDefaults integration

**Quality Gates** (enforced by EvidenceQA):
- ✓ **Timer accuracy**: Screenshot of timer at 10:00, 5:00, 0:00 showing correct countdown
- ✓ **Session flow**: Screen recording of full meditation session
- ✓ **Data persistence**: Screenshot showing saved session in CoreData debugger
- ✓ **HealthKit sync**: Screenshot of mindful minutes in Health app
- ✓ **Streak calculation**: Evidence of correct streak with test data
- ✓ **Settings UI**: Screenshots of all settings sections matching spec

**Default to "NEEDS WORK"**: EvidenceQA will find issues until proven perfect

---

### Phase 3: Testing & QA
**Goal**: Comprehensive test coverage, performance validated, evidence-based certification

**Agent Sequence**:

1. **swift-expert**: Write unit tests
   - StreakCalculator test suite
   - MeditationTimerService tests
   - SessionManager state transition tests
   - HealthKitService mock tests
   - Target: 70%+ coverage on business logic

2. **Backend Architect**: Write integration tests
   - End-to-end timer → session → CoreData → HealthKit flow
   - CloudKit sync with mock container
   - Background timer continuation
   - Notification delivery

3. **swift-expert**: Write UI tests
   - Complete meditation session automation
   - Pause/resume flow
   - Early termination
   - Settings changes
   - VoiceOver navigation

4. **Performance Benchmarker**: Run performance suite
   - Profile with Instruments (Time Profiler, Allocations)
   - Measure 60fps UI performance
   - Validate <2s launch time
   - Check memory usage during 60-min session
   - Verify timer accuracy over time

5. **testing-reality-checker**: Certify test suite
   - **Evidence required**: Xcode test results screenshot showing all green
   - **Evidence required**: Coverage report showing >70%
   - **Evidence required**: Instruments profile showing 60fps
   - **Default stance**: "NEEDS WORK" until overwhelming evidence provided

6. **EvidenceQA**: Final feature validation
   - Re-validate all features with fresh eyes
   - Check for edge cases and error states
   - Verify accessibility with Accessibility Inspector
   - Test on multiple device sizes (iPhone SE, iPhone 15 Pro Max, iPad)

**Quality Gates**:
- ✓ All tests pass (evidence: Xcode screenshot)
- ✓ Coverage >70% (evidence: coverage report)
- ✓ 60fps UI validated (evidence: Instruments profile)
- ✓ No memory leaks (evidence: Allocations instrument)
- ✓ testing-reality-checker certification granted
- ✓ EvidenceQA sign-off with comprehensive evidence

---

### Phase 4: Polish & Deployment
**Goal**: Production-ready app with full polish and local deployment

**Agent Sequence**:

1. **UI Designer**: Final polish
   - Verify all SF Symbols match spec
   - Validate color scheme implementation
   - Test all animations
   - Run Accessibility Inspector
   - Verify WCAG AA contrast (use Color Contrast Analyzer)

2. **swift-expert**: App assets
   - Design app icon (or integrate provided design)
   - Add meditation_bell.wav sound file
   - Create launch screen
   - Add Localizable.strings

3. **DevOps Automator**: Build configuration
   - Configure release build settings
   - Set up code signing for local development
   - Create provisioning profiles
   - Build for simulator
   - Build for connected device

4. **EvidenceQA**: Final validation
   - Install on physical device
   - Test complete app flow on device
   - Verify all features work on hardware
   - Check performance on older devices (if available)
   - **Evidence**: Screen recording on physical iPhone

5. **testing-reality-checker**: Final certification
   - Validate build succeeds
   - Confirm app installs on device
   - Check no runtime crashes
   - **Evidence**: Screenshot of app running on device

**Quality Gates**:
- ✓ All accessibility features validated
- ✓ WCAG AA contrast verified
- ✓ App builds for simulator (evidence: build log)
- ✓ App builds for device (evidence: build log)
- ✓ App installs and runs on physical device (evidence: photo/video)
- ✓ Final EvidenceQA approval with device testing proof

---

## Session Workflow

### Starting a New Session

```bash
# 1. Read current state
cat PROJECT.md
cat PROGRESS.md

# 2. Studio Producer: Assess current phase and blockers
# - What phase are we in?
# - What tasks are pending?
# - Any blockers from previous session?
# - Which agents need to resume work?

# 3. Project Shepherd: Break down next tasks
# - Convert phase goals into specific actionable items
# - Assign agents to tasks
# - Set session goals

# 4. Execute with appropriate agents
# - Launch agents in parallel when possible
# - Use agent resume for continuing work
# - Update PROGRESS.md throughout session

# 5. End-of-session checkpoint
# - Project Shepherd: Update PROGRESS.md
# - Note completed tasks, blockers, next steps
# - Save agent IDs for resume in next session
```

### Ending a Session

```bash
# 1. Project Shepherd: Update PROGRESS.md
# - Log session date, duration, agents used
# - List completed tasks with evidence links
# - Document any new blockers
# - Set goals for next session
# - Save agent IDs for resume

# 2. Git commit (if applicable)
# - Commit code changes with descriptive message
# - Ensure PROGRESS.md and PROJECT.md are committed

# 3. Quality gate check
# - Are we ready to advance to next phase?
# - Do we need EvidenceQA review?
# - Any testing-reality-checker certification needed?
```

---

## State Management

### File-Based Tracking

**PROJECT.md** (this file):
- Overall project structure and phases
- Agent assignments and responsibilities
- Quality metrics dashboard
- Current blockers

**PROGRESS.md**:
- Session-by-session log
- Completed tasks with timestamps
- Evidence links (screenshots, test results)
- Blockers encountered and resolved
- Agent IDs for resume

**Git History**:
- Code evolution over time
- Commit messages capture work completed
- Enables rollback if needed

### Agent Resume

Agents can be resumed using their IDs:
```markdown
## Session 2024-01-05 (15:30 - 17:00)
Agents used:
- swift-expert: agent_abc123 (implemented TimerViewModel)
- Backend Architect: agent_def456 (set up CoreData schema)

Next session: Resume swift-expert (agent_abc123) to continue Timer UI work
```

---

## Quality Enforcement

### Evidence-Based Validation

**EvidenceQA Standards**:
- All UI features: Screenshots required
- User flows: Screen recordings required
- Integration points: Proof of data flow (debugger screenshots, logs)
- Default stance: Find 3-5 issues per review until perfect

**testing-reality-checker Standards**:
- Test runs: Xcode test results screenshot
- Coverage: Xcode coverage report screenshot
- Performance: Instruments profile screenshots
- Default stance: "NEEDS WORK" until overwhelming proof

### Quality Gate Enforcement

No phase advancement without:
1. All phase tasks completed
2. Evidence provided for each task
3. Quality gates passed with proof
4. Agent sign-off (EvidenceQA or testing-reality-checker)

If quality gate fails:
1. Document specific issues found
2. Create remediation tasks
3. Re-run validation after fixes
4. Require fresh evidence

---

## Agent Invocation Guide

### When to Use Each Agent

**Use Studio Producer when**:
- Starting a new session
- Transitioning between phases
- Major blockers affecting multiple agents
- Resource reallocation needed

**Use Project Shepherd when**:
- Need to break down phase into tasks
- Coordinating multiple agents
- Updating progress tracking
- Daily session management

**Use swift-expert when**:
- Writing Swift code
- Implementing SwiftUI views
- Building ViewModels
- App Intents integration
- Code review for Swift patterns

**Use Backend Architect when**:
- CoreData schema design
- CloudKit sync implementation
- HealthKit integration
- Actor-based service design
- Data architecture decisions

**Use DevOps Automator when**:
- Xcode project configuration
- Build settings and schemes
- Entitlements and capabilities
- Code signing
- Build automation

**Use EvidenceQA when**:
- After implementing any UI feature
- Before phase completion
- Validating against spec
- Final app validation

**Use testing-reality-checker when**:
- After writing test suites
- Before claiming tests pass
- Test coverage validation
- Performance test certification

**Use Performance Benchmarker when**:
- UI feels slow or janky
- Need to validate 60fps requirement
- Launch time validation
- Memory profiling
- Timer accuracy verification

**Use UI Designer when**:
- Implementing visual design system
- Color scheme application
- Accessibility implementation
- Animation implementation
- Design system consistency

---

## Example Session Flow

### Session 1: Project Initialization

```
1. User: "Start Phase 1 setup"

2. Studio Producer (auto-invoked):
   - Reads PROJECT.md
   - Assesses: Phase 1 not started
   - Allocates: DevOps Automator, Backend Architect, swift-expert
   - Sets goal: Complete Xcode project setup

3. DevOps Automator:
   - Creates Xcode project
   - Configures bundle ID and capabilities
   - Sets up build schemes
   - Evidence: Build log showing successful compilation

4. Backend Architect:
   - Creates CoreData model file
   - Defines MeditationSession entity
   - Implements PersistenceController.swift
   - Evidence: CoreData model compiles, generates classes

5. swift-expert:
   - Creates folder structure per spec
   - Generates stub files
   - Sets up Constants.swift and AppLogger.swift
   - Evidence: Project navigator screenshot

6. Project Shepherd (end of session):
   - Updates PROGRESS.md with tasks completed
   - Notes agent IDs for resume
   - Sets next session goal: Continue Phase 1 (test infrastructure)
```

### Session 2: Core Timer Implementation

```
1. Studio Producer:
   - Reads PROGRESS.md from Session 1
   - Assesses: Phase 1 complete, moving to Phase 2
   - Allocates: swift-expert, UI Designer

2. swift-expert (resumed from Session 1):
   - Implements MeditationTimerService
   - Creates TimerViewModel with @Observable
   - Builds timer countdown logic
   - Evidence: Code compiles without warnings

3. UI Designer:
   - Creates CircularTimerDial component
   - Implements progress ring animation
   - Applies color scheme
   - Evidence: Screenshot of timer UI

4. EvidenceQA (auto-invoked after UI work):
   - Reviews timer UI screenshot
   - Finds issues: "Progress ring stroke width is 10pt, spec says 12pt"
   - Status: "NEEDS WORK"

5. UI Designer (remediation):
   - Fixes stroke width to 12pt
   - Provides new screenshot
   - Evidence: Updated screenshot showing 12pt stroke

6. EvidenceQA (re-review):
   - Validates fix
   - Status: "APPROVED" (with evidence)

7. Project Shepherd:
   - Updates PROGRESS.md with timer implementation
   - Links evidence (screenshots)
   - Notes: EvidenceQA approval granted
```

---

## Autonomous Operation

### Agent Self-Coordination

Agents are expected to:
1. **Read current state** (PROJECT.md, PROGRESS.md) before starting work
2. **Understand dependencies** (what needs to be done before their work)
3. **Update progress** as they complete tasks
4. **Provide evidence** proactively (screenshots, logs, test results)
5. **Call quality agents** (EvidenceQA, testing-reality-checker) when appropriate
6. **Communicate blockers** clearly in PROGRESS.md

### Minimal Human Intervention

Human input required only for:
1. **Session initiation**: "Start Phase 2" or "Continue work"
2. **Design decisions**: When spec is ambiguous or multiple valid approaches exist
3. **Blocker resolution**: When agents encounter issues they can't resolve
4. **Final approval**: Review evidence and approve phase completions

All other work is autonomous agent collaboration.

---

## Success Criteria

Project is complete when:
- ✓ All phases (1-4) completed with quality gates passed
- ✓ App builds successfully for simulator and device
- ✓ All tests pass with >70% coverage
- ✓ Performance validated at 60fps, <2s launch
- ✓ Accessibility validated with Inspector
- ✓ EvidenceQA final approval granted
- ✓ testing-reality-checker certification received
- ✓ App tested on physical device with proof

**Evidence Required**: Final session with comprehensive evidence package (screenshots, videos, test results, profiles)
