import type { Metadata } from "next";

import { AuthForm } from "../auth-form";
import { signUp } from "../actions";

export const metadata: Metadata = {
  title: "Create an account",
};

export default function SignupPage() {
  return <AuthForm mode="signup" action={signUp} />;
}
