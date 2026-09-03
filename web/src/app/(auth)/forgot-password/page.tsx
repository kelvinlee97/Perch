import type { Metadata } from "next";

import { AuthForm } from "../auth-form";
import { requestPasswordReset } from "../actions";

export const metadata: Metadata = {
  title: "Reset your password",
};

export default function ForgotPasswordPage() {
  return <AuthForm mode="forgot" action={requestPasswordReset} />;
}
