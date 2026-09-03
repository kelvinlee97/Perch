import { beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
    redirect: vi.fn(() => {
        throw new Error("NEXT_REDIRECT");
    }),
    signUp: vi.fn(),
}));

vi.mock("next/headers", () => ({
    headers: vi.fn(async () => new Headers({ origin: "https://perch.example" })),
}));

vi.mock("next/navigation", () => ({
    redirect: mocks.redirect,
}));

vi.mock("@/lib/supabase/server", () => ({
    createClient: vi.fn(async () => ({
        auth: { signUp: mocks.signUp },
    })),
}));

import { signUp } from "./actions";

function signupForm() {
    const formData = new FormData();
    formData.set("email", "person@example.com");
    formData.set("password", "secret1");
    formData.set("confirmation", "secret1");
    return formData;
}

describe("signUp", () => {
    beforeEach(() => {
        mocks.redirect.mockClear();
        mocks.signUp.mockReset();
    });

    it("preserves Next.js redirect control flow when signup returns a session", async () => {
        mocks.signUp.mockResolvedValue({
            data: { session: { access_token: "token" } },
            error: null,
        });

        await expect(signUp({}, signupForm())).rejects.toThrow("NEXT_REDIRECT");
        expect(mocks.redirect).toHaveBeenCalledWith("/app");
    });

    it("returns the verification message when signup requires email confirmation", async () => {
        mocks.signUp.mockResolvedValue({ data: { session: null }, error: null });

        await expect(signUp({}, signupForm())).resolves.toEqual({
            message: "Account created. Check your email to verify it.",
        });
        expect(mocks.redirect).not.toHaveBeenCalled();
    });
});
