import { beforeEach, describe, expect, it, vi } from "vitest";

const exchangeCodeForSession = vi.hoisted(() => vi.fn());

vi.mock("@/lib/supabase/server", () => ({
    createClient: vi.fn(async () => ({
        auth: { exchangeCodeForSession },
    })),
}));

import { GET } from "./route";

async function callbackLocation(query = "") {
    const response = await GET(
        new Request(`https://perch.example/auth/callback?code=valid${query}`),
    );
    return response.headers.get("location");
}

describe("auth callback destination", () => {
    beforeEach(() => {
        exchangeCodeForSession.mockReset();
        exchangeCodeForSession.mockResolvedValue({ error: null });
    });

    it.each([
        "&next=/%5Cevil.example",
        "&next=/%5C%5Cevil.example",
        "&next=%2F%2Fevil.example",
        "&next=https%3A%2F%2Fevil.example",
        "&next=/unknown",
    ])("keeps an untrusted destination on the application origin: %s", async (query) => {
        expect(await callbackLocation(query)).toBe("https://perch.example/app");
    });

    it("allows the password recovery destination", async () => {
        expect(await callbackLocation("&next=/update-password")).toBe(
            "https://perch.example/update-password",
        );
    });

    it("defaults a missing destination to the app", async () => {
        expect(await callbackLocation()).toBe("https://perch.example/app");
    });
});
