# StatisticsHeaderView Integration Guide

Quick start guide for integrating the StatisticsHeaderView component into your views.

## Quick Start (30 seconds)

### Step 1: Import the Component
The component is automatically available in your SwiftUI views. No import needed beyond SwiftUI.

### Step 2: Add to Your View
```swift
struct MyView: View {
    @StateObject private var sessionManager = SessionManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                StatisticsHeaderView(
                    statistics: sessionManager.statistics
                )

                // Your other content...
            }
            .padding()
        }
    }
}
```

### Step 3: Done!
That's it. The component will automatically:
- Display current statistics
- Animate on appear
- Adapt to light/dark mode
- Update when statistics change

## Common Use Cases

### 1. Main Dashboard
Display at the top of your main view:

```swift
struct DashboardView: View {
    @StateObject private var sessionManager = SessionManager()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.large) {
                    // Statistics header at top
                    StatisticsHeaderView(
                        statistics: sessionManager.statistics
                    )

                    // Quick start button
                    Button("Start Meditation") {
                        // Navigate to timer
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    // Recent sessions, etc.
                }
                .padding()
            }
            .navigationTitle("Meditation")
        }
    }
}
```

### 2. History View
Use without weekly breakdown for cleaner look:

```swift
struct HistoryView: View {
    @StateObject private var sessionManager = SessionManager()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.large) {
                    // Compact statistics
                    StatisticsHeaderView(
                        statistics: sessionManager.statistics,
                        showWeeklyBreakdown: false
                    )

                    // List of past sessions
                    sessionsList
                }
                .padding()
            }
            .navigationTitle("History")
        }
    }

    private var sessionsList: some View {
        // Your sessions list implementation
        Text("Sessions list...")
    }
}
```

### 3. Profile/Settings Tab
Combine with user info:

```swift
struct ProfileView: View {
    @StateObject private var sessionManager = SessionManager()

    var body: some View {
        NavigationView {
            List {
                Section {
                    StatisticsHeaderView(
                        statistics: sessionManager.statistics
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Settings") {
                    // Your settings rows
                }
            }
            .navigationTitle("Profile")
        }
    }
}
```

### 4. Post-Session Recap
Show updated stats after meditation:

```swift
struct SessionRecapView: View {
    let completedSession: MeditationSession
    @StateObject private var sessionManager = SessionManager()

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Spacing.large) {
                // Completion message
                Text("Great Session!")
                    .font(.title)
                    .fontWeight(.bold)

                // Updated statistics
                StatisticsHeaderView(
                    statistics: sessionManager.statistics
                )

                // Session details
                sessionDetails
            }
            .padding()
        }
    }

    private var sessionDetails: some View {
        // Your session details implementation
        Text("Session details...")
    }
}
```

## Fetching Statistics

### Option 1: Using SessionManager (Recommended)
```swift
@StateObject private var sessionManager = SessionManager()

// Access statistics
sessionManager.statistics
```

### Option 2: Using MeditationSessionService
```swift
@State private var statistics = SessionStatistics.empty
@Environment(\.managedObjectContext) private var viewContext

var body: some View {
    StatisticsHeaderView(statistics: statistics)
        .onAppear {
            fetchStatistics()
        }
}

private func fetchStatistics() {
    let service = MeditationSessionService(context: viewContext)
    statistics = service.fetchStatistics()
}
```

### Option 3: Manual/Custom Statistics
```swift
@State private var statistics = SessionStatistics(
    todayMinutes: 20,
    thisWeekMinutes: 95,
    currentStreak: 7,
    totalMinutes: 1250,
    totalSessions: 42,
    averageSessionDuration: 15,
    longestSessionDuration: 30,
    lastSessionDate: Date()
)

var body: some View {
    StatisticsHeaderView(statistics: statistics)
}
```

## Customization Options

### Toggle Weekly Breakdown
```swift
// With weekly breakdown (default)
StatisticsHeaderView(statistics: stats)

// Without weekly breakdown
StatisticsHeaderView(
    statistics: stats,
    showWeeklyBreakdown: false
)
```

### Styling with View Modifiers
```swift
StatisticsHeaderView(statistics: stats)
    .padding(.horizontal, 20)
    .padding(.top, 10)
```

### Embedding in Cards
```swift
VStack {
    StatisticsHeaderView(statistics: stats)
}
.padding()
.background(Color(.systemBackground))
.cornerRadius(16)
.shadow(radius: 5)
```

## Reactive Updates

The component automatically updates when statistics change:

```swift
struct LiveStatsView: View {
    @StateObject private var sessionManager = SessionManager()

    var body: some View {
        VStack {
            StatisticsHeaderView(statistics: sessionManager.statistics)
                .id(sessionManager.statistics.totalSessions) // Force update

            Button("Complete Test Session") {
                sessionManager.completeTestSession()
                // Statistics automatically update!
            }
        }
    }
}
```

## Layout Considerations

### Horizontal Padding
Add horizontal padding in the parent view:
```swift
StatisticsHeaderView(statistics: stats)
    .padding(.horizontal)
```

### Vertical Spacing
Control spacing between header and content:
```swift
VStack(spacing: 24) {
    StatisticsHeaderView(statistics: stats)
    // Other content
}
```

### Full Width Container
For edge-to-edge layouts:
```swift
VStack(spacing: 0) {
    StatisticsHeaderView(statistics: stats)
        .padding()
        .background(Color.accentColor.opacity(0.1))

    // Other content
}
```

## Performance Tips

1. **Reuse SessionManager**: Don't create multiple instances
2. **Avoid Frequent Fetches**: Fetch statistics once, update reactively
3. **Use @StateObject**: For ViewModels that manage statistics
4. **Lazy Loading**: Only fetch when view appears

```swift
struct OptimizedView: View {
    @StateObject private var sessionManager = SessionManager()

    var body: some View {
        StatisticsHeaderView(statistics: sessionManager.statistics)
            .onAppear {
                // Only fetch if needed
                if sessionManager.statistics.totalSessions == 0 {
                    sessionManager.refreshStatistics()
                }
            }
    }
}
```

## Testing Your Integration

### 1. Preview with Sample Data
```swift
#Preview {
    YourView(
        // Provide test data
    )
}
```

### 2. Test Different States
- Zero state (new user)
- Active user with streak
- Long-time user with high numbers
- Edge cases (very large numbers)

### 3. Test Animations
- View appearance animation
- Statistics updates
- Progress bar animation

## Troubleshooting

### Statistics Not Updating
**Problem**: Statistics show old data
**Solution**: Ensure you're using `@StateObject` or `@ObservedObject` for reactive updates

```swift
// Wrong
let sessionManager = SessionManager()

// Correct
@StateObject private var sessionManager = SessionManager()
```

### Component Not Visible
**Problem**: Component doesn't appear
**Solution**: Check padding and container constraints

```swift
ScrollView {
    StatisticsHeaderView(statistics: stats)
        .padding() // Add this!
}
```

### Layout Issues on Different Devices
**Problem**: Text truncated or cards misaligned
**Solution**: Component handles this automatically, but ensure parent view allows enough width

### Dark Mode Issues
**Problem**: Colors don't look right in dark mode
**Solution**: Component uses `Constants.Colors` which adapt automatically. Ensure your parent view doesn't override color scheme.

## Best Practices

1. **Use at the Top**: Place as first element in scrollable content
2. **Single Instance**: One statistics header per view
3. **Consistent Padding**: Use `Constants.Spacing` values
4. **Reactive Data**: Connect to live data sources
5. **Preview Testing**: Always test in previews with different data

## Complete Example

Here's a complete, production-ready example:

```swift
import SwiftUI

struct MeditationDashboard: View {
    @StateObject private var sessionManager = SessionManager()
    @State private var showTimer = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.large) {
                    // Statistics Header
                    StatisticsHeaderView(
                        statistics: sessionManager.statistics
                    )

                    // Quick Actions
                    VStack(spacing: Constants.Spacing.medium) {
                        Button("Start Meditation") {
                            showTimer = true
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button("View History") {
                            // Navigate to history
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }

                    // Recent Activity
                    if !sessionManager.recentSessions.isEmpty {
                        recentActivitySection
                    }
                }
                .padding()
            }
            .navigationTitle("Meditation")
            .sheet(isPresented: $showTimer) {
                TimerSetupView()
            }
            .onAppear {
                sessionManager.refreshStatistics()
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("Recent Sessions")
                .font(.headline)

            ForEach(sessionManager.recentSessions.prefix(3)) { session in
                SessionRowView(session: session)
            }
        }
    }
}

#Preview {
    MeditationDashboard()
}
```

## Next Steps

1. **Test the component** using the example file: `StatisticsHeaderViewExample.swift`
2. **Integrate** into your main views following the examples above
3. **Customize** as needed for your specific use case
4. **Review** the full documentation in `README_StatisticsHeaderView.md`

## Support

For issues or questions:
- Review the main README: `README_StatisticsHeaderView.md`
- Check examples: `StatisticsHeaderViewExample.swift`
- Test component: Run Xcode previews
- Verify data: Ensure `SessionStatistics` is populated correctly

---

**Quick Reference Card**

```swift
// Minimal usage
StatisticsHeaderView(statistics: sessionManager.statistics)

// Without weekly
StatisticsHeaderView(statistics: stats, showWeeklyBreakdown: false)

// With padding
StatisticsHeaderView(statistics: stats)
    .padding()

// Zero state
StatisticsHeaderView(statistics: .empty)
```

---

**Created**: 2026-01-05
**Last Updated**: 2026-01-05
