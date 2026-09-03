import type { Metadata } from "next";

import { AuthForm } from "../auth-form";
import { updatePassword } from "../actions";

export const metadata: Metadata = {
  title: "Set a new password",
};

export default function UpdatePasswordPage() {
  return <AuthForm mode="update" action={updatePassword} />;
}
