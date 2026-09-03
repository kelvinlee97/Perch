import type { Metadata } from "next";

import { AuthForm } from "../auth-form";
import { signIn } from "../actions";

export const metadata: Metadata = {
  title: "Log in",
};

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const params = await searchParams;

  return (
    <AuthForm
      mode="login"
      action={signIn}
      initialState={params.error ? { error: params.error } : undefined}
    />
  );
}
