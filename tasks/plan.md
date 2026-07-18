# Implementation Plan: Bird Todo macOS MVP

## Overview

Build a local-first macOS desktop companion for capturing short to-dos and gently surfacing a single due reminder. The app consists of a transparent desktop bird, a compact task panel, and a minimal settings window. The first release validates one loop: capture a task, schedule it, see it at the right time, then complete or defer it.

## Architecture Decisions

- Use native SwiftUI for the macOS-only MVP. It keeps the app light and gives reliable control over transparent windows, window level, menu-bar integration, and local notifications.
- Store all tasks locally. No account, sync service, or network dependency is needed to validate daily use.
- Use one reminder queue: show only the oldest actionable due task on the bird; retain later due tasks in the task panel.
- Ship the bird in a fixed corner by default. Dragging, transparency, and quiet hours are supported; free roaming is deferred until the core loop proves useful.

## Interaction Specification

### A. Resting bird

- The bird rests in the bottom-right corner after launch.
- It has a small idle animation but no text by default.
- Clicking it opens the compact task panel without stealing focus from the current app until the user types.
- The user may drag it to another screen corner.

### B. Quick capture

- A global shortcut opens a single-line capture field.
- Entering a title and pressing Return creates an inbox task immediately.
- The capture field offers four reminder choices: none, 10 minutes, tonight, tomorrow; a custom picker is available after choosing more options.
- Escape closes capture without changing existing tasks.

### C. Due reminder

- When a task becomes due outside quiet hours, the bird briefly flies into its resting position and displays the task title.
- Clicking the title completes the task.
- A secondary action menu offers: defer 10 minutes, tonight, tomorrow, edit, and delete.
- The displayed task remains until handled. Other due tasks increment a small count badge and stay queued.

### D. Compact task panel

- The panel contains only Inbox, Today, and Completed sections.
- Users can complete, edit, change reminder time, or delete a task in place.
- Closing the panel returns the bird to its idle state.

### E. Quiet mode and settings

- Quiet mode suppresses animation and interruption while continuing to capture tasks.
- When quiet mode ends, the bird surfaces only the first queued task.
- Settings include bird position, size, opacity, animation intensity, quiet-hours schedule, and launch at login.

## Task List

### Phase 1: Prove the core loop

- [ ] Task 1: Create the macOS shell with a menu-bar entry and transparent bird window.
- [ ] Task 2: Add a local task model and persistence layer.
- [ ] Task 3: Implement quick capture and create an inbox task.

### Checkpoint: Capture

- [ ] The app launches into a resting bird.
- [ ] A user can add a task in two seconds and still see it after relaunch.

### Phase 2: Make reminders actionable

- [ ] Task 4: Implement scheduling and due-task selection.
- [ ] Task 5: Implement the bird reminder state and complete/defer/delete actions.
- [ ] Task 6: Build the compact task panel for Inbox, Today, and Completed.

### Checkpoint: Reminder loop

- [ ] A scheduled task is surfaced at its due time.
- [ ] The user can complete or defer it without opening a full window.
- [ ] Only one due task is presented at a time.

### Phase 3: Make it safe to live with

- [ ] Task 7: Add quiet mode, settings, and per-user bird placement.
- [ ] Task 8: Add global quick-capture shortcut and first-run guidance.
- [ ] Task 9: Add lightweight animation polish and accessibility review.

### Checkpoint: Usability test

- [ ] Five people can use capture and reminder handling without explanation.
- [ ] No tester reports that the bird is visually intrusive or difficult to silence.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| The overlay distracts from work | High | Default to a small, fixed, low-motion bird; provide opacity and quiet controls. |
| Reminders pile up | High | Present one actionable reminder at a time and queue the rest. |
| Transparent overlay behaves poorly in full-screen apps | Medium | Treat regular desktop windows as the MVP target and document full-screen behavior before promising it. |
| Bird animation feels decorative rather than useful | Medium | Make every animation correspond to a task state or a user action. |

## Definition of Done for the MVP

- A task can be captured, persisted, scheduled, surfaced, deferred, and completed locally.
- The bird remains unobtrusive and can be quieted immediately.
- The application runs as a signed macOS app without requiring a user account.
