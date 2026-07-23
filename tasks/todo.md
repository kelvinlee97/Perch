# Perch MVP Task Checklist

## Task 1: macOS shell and resting bird

**Description:** Create the native app shell, menu-bar entry, and transparent window that hosts a fixed resting bird.

**Acceptance criteria:**
- [ ] Launching the app shows a small bird in the selected screen corner.
- [ ] The menu bar can show, hide, and quit the app.
- [ ] The bird does not steal focus during ordinary use.

**Verification:**
- [ ] Manual check: launch, hide, show, and quit the app.
- [ ] Manual check: work in another application while the bird is visible.

**Dependencies:** None

**Estimated scope:** Medium

## Task 2: Local task persistence

**Status:** Implementation complete; manual verification remains.

**Description:** Define a task record with title, optional reminder time, status, and creation time; persist it locally.

**Acceptance criteria:**
- [x] A newly created task survives an app restart.
- [x] Completed tasks remain available in the Completed section.
- [x] Deleting a task removes it permanently.

**Verification:**
- [ ] Manual check: create, restart, complete, and delete tasks.

**Dependencies:** Task 1

**Estimated scope:** Small

## Task 3: Quick capture

**Description:** Let users create a task from the bird panel or a global shortcut.

**Acceptance criteria:**
- [ ] The panel can create an inbox task with title only.
- [ ] A task can be given one of the four quick reminder choices.
- [ ] Return saves the task; Escape cancels capture.

**Verification:**
- [ ] Manual check: create five tasks using both entry points.

**Dependencies:** Task 2

**Estimated scope:** Medium

## Task 4: Scheduling and due queue

**Description:** Identify due tasks and select one task to display at a time.

**Acceptance criteria:**
- [ ] A due task enters the actionable queue at its scheduled time.
- [ ] Only the oldest due task is active.
- [ ] Other due tasks are reflected in a count badge.

**Verification:**
- [ ] Manual check: schedule three near-term tasks and confirm their order.

**Dependencies:** Task 2

**Estimated scope:** Medium

## Task 5: Reminder actions

**Description:** Present the active due task on the bird and allow completion or deferral.

**Acceptance criteria:**
- [ ] The active task title appears with the bird.
- [ ] Clicking the title completes the task.
- [ ] The action menu can defer, edit, or delete the task.

**Verification:**
- [ ] Manual check: process each action for a due task.

**Dependencies:** Task 4

**Estimated scope:** Medium

## Task 6: Compact task panel

**Description:** Display Inbox, Today, and Completed tasks in a compact editable panel.

**Acceptance criteria:**
- [ ] Each section contains the correct tasks.
- [ ] A task can be edited, completed, or deleted in place.
- [ ] Closing the panel returns to the resting bird.

**Verification:**
- [ ] Manual check: move a task through all three sections.

**Dependencies:** Tasks 3 and 5

**Estimated scope:** Medium

## Task 7: Quiet mode and basic settings

**Description:** Let users control interruption and the bird's visual footprint.

**Acceptance criteria:**
- [ ] Quiet mode suppresses reminder animation.
- [ ] Quiet hours resume with only one queued reminder.
- [ ] The user can change bird position, size, opacity, and animation strength.

**Verification:**
- [ ] Manual check: trigger a reminder in and out of quiet mode.

**Dependencies:** Task 5

**Estimated scope:** Medium

## Task 8: Global quick-capture shortcut

**Description:** Register a configurable shortcut that opens the capture field from another application.

**Acceptance criteria:**
- [ ] The shortcut opens capture while another app is active.
- [ ] The user can type and save without losing the active workflow.
- [ ] Shortcut registration failure is explained clearly.

**Verification:**
- [ ] Manual check: capture tasks while using three different applications.

**Dependencies:** Task 3

**Estimated scope:** Medium

## Task 9: Animation, accessibility, and first-run guidance

**Description:** Add restrained state animations and ensure the core flow remains accessible.

**Acceptance criteria:**
- [ ] Reduced animation is respected when chosen in app settings.
- [ ] Core actions have clear labels and keyboard access.
- [ ] First launch explains capture, reminder handling, and quiet mode in three steps or fewer.

**Verification:**
- [ ] Manual check: complete the core loop using keyboard navigation.
- [ ] Manual check: test with animations minimized.

**Dependencies:** Tasks 5 through 8

**Estimated scope:** Medium
