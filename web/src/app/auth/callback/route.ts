import { NextResponse } from "next/server";

import { createClient } from "@/lib/supabase/server";

function safeNextPath(next: string | null) {
  return next === "/update-password" ? next : "/app";
}

export async function GET(request: Request) {
  const url = new URL(request.url);
  const code = url.searchParams.get("code");

  if (code) {
    try {
      const supabase = await createClient();
      const { error } = await supabase.auth.exchangeCodeForSession(code);

      if (!error) {
        return NextResponse.redirect(
          new URL(safeNextPath(url.searchParams.get("next")), url.origin),
        );
      }
    } catch {
      // Fall through to the same safe error page as an invalid code.
    }
  }

  const errorUrl = new URL("/login", url.origin);
  errorUrl.searchParams.set("error", "验证链接无效或已过期，请重新尝试。 ".trim());
  return NextResponse.redirect(errorUrl);
}
