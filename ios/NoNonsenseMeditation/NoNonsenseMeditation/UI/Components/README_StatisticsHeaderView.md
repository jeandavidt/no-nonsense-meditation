# StatisticsHeaderView Component

A beautiful, reusable SwiftUI component for displaying meditation statistics in the No Nonsense Meditation iOS app.

## Overview

`StatisticsHeaderView` is a visually appealing header component that displays key meditation metrics in an elegant card layout. It's designed to be reusable across different views (main screen, history view, settings, etc.) and provides users with a quick glance at their meditation progress.

## Features

- **Three Key Metrics Display**
  - Current streak with flame icon (orange when active)
  - Total sessions completed with checkmark icon
  - Total meditation time with clock icon

- **Weekly Activity Breakdown**
  - Optional weekly progress section
  - Animated progress bar showing weekly activity
  - Target: 150 minutes per week (~21 min/day)

- **Beautiful Animations**
  - Spring animations on appear
  - Smooth transitions for statistics
  - Progress bar animation with delay

- **Adaptive Design**
  - Supports both light and dark mode
  - Responsive layout for different screen sizes
  - Uses app's color scheme (Constants.Colors)
  - Subtle gradient background

- **Zero State Handling**
  - Gracefully displays zero values for new users
  - Inactive streak indicator (gray flame)

## Usage

### Basic Usage

```swift
import SwiftUI

struct MainView: View {
    @StateObject private var sessionManager = SessionManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Display statistics header
                StatisticsHeaderView(
                    statistics: sessionManager.statistics
                )

                // Rest of your content...
            }
            .padding()
        }
    }
}
```

### Without Weekly Breakdown

```swift
StatisticsHeaderView(
    statistics: statistics,
    showWeeklyBreakdown: false
)
```

### With Custom Statistics

```swift
let customStats = SessionStatistics(
    todayMinutes: 20,
    thisWeekMinutes: 95,
    currentStreak: 7,
    totalMinutes: 1250,
    totalSessions: 42,
    averageSessionDuration: 15,
    longestSessionDuration: 30,
    lastSessionDate: Date()
)

StatisticsHeaderView(statistics: customStats)
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `statistics` | `SessionStatistics` | Required | The statistics data to display |
| `showWeeklyBreakdown` | `Bool` | `true` | Whether to show the weekly activity section |

## Design Specifications

### Layout
- **Padding**: `Constants.Layout.cardPadding` (20pt)
- **Corner Radius**: `Constants.Layout.cardCornerRadius` (16pt)
- **Spacing**: `Constants.Spacing.medium` (16pt)
- **Shadow**: Black 10% opacity, radius 8, y-offset 4

### Typography
- **Statistic Value**: System rounded, 26pt bold, monospaced digits
- **Statistic Label**: Caption2, medium weight
- **Section Header**: Caption, semibold

### Colors
- **Streak Icon**: Orange (active) / Gray (inactive)
- **Sessions Icon**: `Constants.Colors.accent(for:)` (adapts to color scheme)
- **Time Icon**: `Constants.Colors.success(for:)` (adapts to color scheme)
- **Background**: Subtle gradient (light/dark mode adaptive)
- **Progress Bar**: Linear gradient from accent to success color

### Animations
- **Card Appearance**: Spring animation (0.6s response, 0.8 damping)
- **Statistics**: Fade and slide up effect
- **Progress Bar**: Spring animation (0.8s response, 0.7 damping, 0.2s delay)

## Component Architecture

### Main View Structure

```
StatisticsHeaderView
├── VStack
│   ├── mainStatisticsGrid (HStack with 3 StatisticCards)
│   └── weeklyActivitySection (conditional)
│       ├── Section Header
│       └── weeklyProgressBar
└── backgroundGradient
```

### Subcomponents

#### StatisticCard (Private)
Individual card displaying a single metric with icon, value, and label.

**Properties:**
- `icon`: String (SF Symbol name)
- `value`: String (formatted number)
- `label`: String (description)
- `iconColor`: Color
- `isAnimated`: Bool

## Integration Points

### Data Source
The component expects a `SessionStatistics` struct, which is typically provided by:
- `SessionManager` (via `sessionManager.statistics`)
- `MeditationSessionService` (via `fetchStatistics()`)
- Custom computed statistics

### Related Components
- **MeditationSessionService**: Provides statistics data
- **SessionManager**: Manages meditation sessions and statistics
- **StreakCalculator**: Calculates streak information

## Accessibility

- All text uses system fonts for Dynamic Type support
- Icons use semantic colors that adapt to color schemes
- Sufficient contrast ratios in both light and dark modes
- VoiceOver-friendly (inherits SwiftUI accessibility)

## Performance Considerations

- **Value Types**: Uses structs for Sendable compliance
- **Efficient Rendering**: Minimal view hierarchy
- **Animation Performance**: Hardware-accelerated animations
- **Memory**: Lightweight, no heavy assets or images

## Examples

### New User (Zero State)
```swift
StatisticsHeaderView(
    statistics: SessionStatistics.empty
)
```
Shows: 0 streak (gray flame), 0 sessions, 0 minutes

### Active User
```swift
StatisticsHeaderView(
    statistics: SessionStatistics(
        todayMinutes: 20,
        thisWeekMinutes: 95,
        currentStreak: 7,
        totalMinutes: 1250,
        totalSessions: 42,
        averageSessionDuration: 15,
        longestSessionDuration: 30,
        lastSessionDate: Date()
    )
)
```
Shows: 7-day streak (orange flame), 42 sessions, 20h 50m total

### Milestone Achieved
```swift
StatisticsHeaderView(
    statistics: SessionStatistics(
        todayMinutes: 45,
        thisWeekMinutes: 180,
        currentStreak: 365,
        totalMinutes: 12500,
        totalSessions: 487,
        averageSessionDuration: 25,
        longestSessionDuration: 60,
        lastSessionDate: Date()
    )
)
```
Shows: 365-day streak (orange flame), 487 sessions, 208h 20m total

## Testing

### Preview Configurations
The component includes comprehensive SwiftUI previews:
- Default statistics
- Zero state
- High numbers
- Without weekly breakdown
- Dark mode

### Visual Regression Testing
Test the component in:
- Different device sizes (iPhone SE, iPhone Pro Max, iPad)
- Light and dark mode
- Dynamic Type sizes (small, large, accessibility sizes)
- RTL languages (if applicable)

## Future Enhancements

Potential improvements:
1. **Tap Gestures**: Make cards tappable for detailed views
2. **Custom Targets**: Allow users to set weekly goals
3. **Trend Indicators**: Show up/down arrows for progress
4. **Animations**: Add celebration animations for milestones
5. **Charts**: Mini sparkline charts for weekly activity
6. **Customization**: Allow users to choose which metrics to display

## File Location

```
ios/NoNonsenseMeditation/NoNonsenseMeditation/UI/Components/StatisticsHeaderView.swift
```

## Dependencies

- **iOS**: 17.0+
- **SwiftUI**: Required
- **Foundation**: Required
- **No external dependencies**

## Related Files

- `SessionStatistics.swift` - Data model
- `Constants.swift` - App-wide constants
- `TimeInterval+Extensions.swift` - Time formatting utilities
- `SessionManager.swift` - Statistics provider
- `MeditationSessionService.swift` - Data service

## License

Part of the No Nonsense Meditation iOS app.

---

**Created**: 2026-01-05
**Author**: Jean-David Therrien
**Version**: 1.0
