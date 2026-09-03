import { describe, expect, it } from "vitest";

import { taskFromRow } from "./mapper";

describe("taskFromRow", () => {
    it("maps database fields to the task model", () => {
        expect(
            taskFromRow({
                id: "task-id",
                user_id: "user-id",
                title: "整理发票",
                created_at: "2026-08-25T01:00:00.000Z",
                reminder_at: "2026-08-25T02:00:00.000Z",
                status: "today",
            }),
        ).toEqual({
            id: "task-id",
            title: "整理发票",
            createdAt: "2026-08-25T01:00:00.000Z",
            reminderAt: "2026-08-25T02:00:00.000Z",
            status: "today",
        });
    });
});
