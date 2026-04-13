# Agent Coordination

## Working on: Calo iOS App (SwiftUI)
## Repo: ~/calo-swift
## Primary reference: TODO.md

## Rules for ALL agents (Claude Code terminal + Claude Agent in Xcode):
1. Always read TODO.md before starting work
2. After completing tasks, update TODO.md checkboxes
3. Never create a new Xcode project — work in the existing one
4. Never modify Config.xcconfig (contains real API keys)
5. Build verify after every change: xcodebuild -project Calo.xcodeproj -scheme Calo -destination 'platform=iOS Simulator,name=iPhone 17' build
6. Commit after every completed task group
7. Design language: dark mode, coral #E26D5A accent, SF Pro, minimal, Apple Health aesthetic
8. Minimum deployment target: iOS 17.0
9. No backend server — all API calls on-device
10. SwiftData for persistence, no Core Data

## Agent roles:
- Claude Code (terminal): architecture, new files, complex logic, multi-file refactors, debugging
- Claude Agent (Xcode): UI tweaks, single-file edits, quick fixes, design polish

## Current state:
- All 4 tabs render and are interactive
- Gemini + USDA pipeline works for image analysis
- Text-only Gemini analysis returns 503 (needs fix)
- Paywall UI exists but is placeholder (no RevenueCat)
- SwiftData persistence works
- No real camera on simulator (works as placeholder)
