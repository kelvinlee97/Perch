import { describe, expect, it, beforeAll } from "vitest";

import { reminderDateFor } from "./reminders";

describe("reminderDateFor", () => {
    beforeAll(() => {
        process.env.TZ = "Asia/Kuala_Lumpur";
    });

    it("returns no date for an inbox task", () => {
        expect(reminderDateFor("none", new Date(2026, 7, 25, 10, 30))).toBeNull();
    });

    it("adds ten minutes", () => {
        expect(reminderDateFor("tenMinutes", new Date(2026, 7, 25, 10, 30))).toEqual(
            new Date(2026, 7, 25, 10, 40),
        );
    });

    it("uses 7pm for tonight and rolls to the next day after 7pm", () => {
        expect(reminderDateFor("tonight", new Date(2026, 7, 25, 10, 30))).toEqual(
            new Date(2026, 7, 25, 19, 0),
        );
        expect(reminderDateFor("tonight", new Date(2026, 7, 25, 20, 0))).toEqual(
            new Date(2026, 7, 26, 19, 0),
        );
    });

    it("uses 9am on the next local day for tomorrow", () => {
        expect(reminderDateFor("tomorrow", new Date(2026, 7, 25, 10, 30))).toEqual(
            new Date(2026, 7, 26, 9, 0),
        );
    });
});
