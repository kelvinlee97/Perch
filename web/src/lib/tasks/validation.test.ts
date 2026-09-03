import { describe, expect, it } from "vitest";

import { normalizeTaskTitle } from "./validation";

describe("normalizeTaskTitle", () => {
    it("trims surrounding whitespace", () => {
        expect(normalizeTaskTitle("  Buy milk  ")).toBe("Buy milk");
    });

    it("rejects an empty title", () => {
        expect(() => normalizeTaskTitle(" \n ")).toThrow("请输入待办内容。");
    });
});
