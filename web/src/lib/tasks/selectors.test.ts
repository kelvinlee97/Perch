import { describe, expect, it } from "vitest";

import {
    dueTasks,
    statusForReminder,
    workspaceSections,
} from "./selectors";
import type { Task } from "./types";

const task = (overrides: Partial<Task>): Task => ({
    id: "00000000-0000-0000-0000-000000000001",
    title: "Task",
    createdAt: "2026-08-25T01:00:00.000Z",
    reminderAt: null,
    status: "inbox",
    ...overrides,
});

describe("task selectors", () => {
    it("maps reminder presence to the active task status", () => {
        expect(statusForReminder(null)).toBe("inbox");
        expect(statusForReminder("2026-08-25T02:00:00.000Z")).toBe("today");
    });

    it("returns only due today tasks in deterministic order", () => {
        const now = new Date("2026-08-25T03:00:00.000Z");
        const result = dueTasks([
            task({
                id: "00000000-0000-0000-0000-000000000003",
                title: "Later",
                status: "today",
                reminderAt: "2026-08-25T02:50:00.000Z",
            }),
            task({
                id: "00000000-0000-0000-0000-000000000002",
                title: "Future",
                status: "today",
                reminderAt: "2026-08-25T03:10:00.000Z",
            }),
            task({
                id: "00000000-0000-0000-0000-000000000004",
                title: "Inbox",
            }),
            task({
                id: "00000000-0000-0000-0000-000000000005",
                title: "Completed",
                status: "completed",
                reminderAt: "2026-08-25T02:30:00.000Z",
            }),
            task({
                id: "00000000-0000-0000-0000-000000000001",
                title: "Earliest",
                status: "today",
                reminderAt: "2026-08-25T02:30:00.000Z",
            }),
        ], now);

        expect(result.map(({ title }) => title)).toEqual(["Earliest", "Later"]);
    });

    it("builds the three workspace sections and due count", () => {
        const now = new Date("2026-08-25T03:00:00.000Z");
        const tasks = [
            task({ title: "Inbox" }),
            task({
                id: "00000000-0000-0000-0000-000000000002",
                title: "Due",
                status: "today",
                reminderAt: "2026-08-25T02:00:00.000Z",
            }),
            task({
                id: "00000000-0000-0000-0000-000000000003",
                title: "Completed",
                status: "completed",
            }),
        ];

        const result = workspaceSections(tasks, now);

        expect(result.inbox.map(({ title }) => title)).toEqual(["Inbox"]);
        expect(result.today.map(({ title }) => title)).toEqual(["Due"]);
        expect(result.completed.map(({ title }) => title)).toEqual(["Completed"]);
        expect(result.dueTask?.title).toBe("Due");
        expect(result.additionalDueCount).toBe(0);
    });
});
