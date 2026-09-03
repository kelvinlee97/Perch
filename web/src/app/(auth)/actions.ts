"use server";

import { headers } from "next/headers";
import { redirect } from "next/navigation";

import type { Locale } from "@/lib/locale";
import { createClient } from "@/lib/supabase/server";

export type AuthField = "email" | "password" | "confirmation";

export type AuthActionState = {
  error?: string;
  errorField?: AuthField;
  message?: string;
};

function formValue(formData: FormData, key: string) {
  const value = formData.get(key);
  return typeof value === "string" ? value.trim() : "";
}

function formLocale(formData: FormData): Locale {
  return formData.get("locale") === "zh" ? "zh" : "en";
}

function authMessage(message: string, locale: Locale) {
  if (message.includes("Invalid login credentials")) {
    return locale === "zh" ? "邮箱或密码不正确。" : "The email or password is incorrect.";
  }
  if (message.includes("User already registered")) {
    return locale === "zh"
      ? "这个邮箱已经注册过了，请直接登录。"
      : "This email is already registered. Try logging in.";
  }
  if (message.includes("Password should be at least")) {
    return locale === "zh"
      ? "密码至少需要 6 位。"
      : "Password must be at least 6 characters.";
  }
  return locale === "zh" ? "操作没有完成，请稍后再试。" : "Something went wrong. Please try again.";
}

function authFailure(message: string, locale: Locale): AuthActionState {
  const error = authMessage(message, locale);

  if (message.includes("User already registered")) {
    return { error, errorField: "email" };
  }
  if (message.includes("Password should be at least")) {
    return { error, errorField: "password" };
  }

  return { error };
}

async function siteOrigin() {
  const origin = (await headers()).get("origin");
  return origin ?? "http://localhost:3000";
}

export async function signIn(
  _previousState: AuthActionState,
  formData: FormData,
): Promise<AuthActionState> {
  const locale = formLocale(formData);
  const email = formValue(formData, "email");
  const password = formData.get("password");

  if (!email) {
    return {
      error: locale === "zh" ? "请输入邮箱。" : "Enter your email.",
      errorField: "email",
    };
  }
  if (typeof password !== "string" || !password) {
    return {
      error: locale === "zh" ? "请输入密码。" : "Enter your password.",
      errorField: "password",
    };
  }

  try {
    const supabase = await createClient();
    const { error } = await supabase.auth.signInWithPassword({ email, password });

    if (error) {
      return authFailure(error.message, locale);
    }
  } catch {
    return {
      error:
        locale === "zh"
          ? "登录服务尚未配置，请先完成 Supabase 设置。"
          : "Login is not configured yet. Finish setting up Supabase first.",
    };
  }

  redirect("/app");
}

export async function signUp(
  _previousState: AuthActionState,
  formData: FormData,
): Promise<AuthActionState> {
  const locale = formLocale(formData);
  const email = formValue(formData, "email");
  const password = formData.get("password");
  const confirmation = formData.get("confirmation");

  if (!email) {
    return {
      error: locale === "zh" ? "请输入邮箱。" : "Enter your email.",
      errorField: "email",
    };
  }
  if (typeof password !== "string" || !password) {
    return {
      error: locale === "zh" ? "请输入密码。" : "Enter your password.",
      errorField: "password",
    };
  }
  if (typeof confirmation !== "string" || !confirmation) {
    return {
      error: locale === "zh" ? "请确认密码。" : "Confirm your password.",
      errorField: "confirmation",
    };
  }
  if (password.length < 6) {
    return {
      error:
        locale === "zh" ? "密码至少需要 6 位。" : "Password must be at least 6 characters.",
      errorField: "password",
    };
  }
  if (password !== confirmation) {
    return {
      error: locale === "zh" ? "两次输入的密码不一致。" : "The passwords do not match.",
      errorField: "confirmation",
    };
  }

  let hasSession = false;

  try {
    const supabase = await createClient();
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        emailRedirectTo: `${await siteOrigin()}/auth/callback`,
      },
    });

    if (error) {
      return authFailure(error.message, locale);
    }
    hasSession = Boolean(data.session);
  } catch {
    return {
      error:
        locale === "zh"
          ? "注册服务尚未配置，请先完成 Supabase 设置。"
          : "Sign-up is not configured yet. Finish setting up Supabase first.",
    };
  }

  if (hasSession) {
    redirect("/app");
  }

  return {
    message:
      locale === "zh"
        ? "注册成功，请查收邮箱完成验证。"
        : "Account created. Check your email to verify it.",
  };
}

export async function requestPasswordReset(
  _previousState: AuthActionState,
  formData: FormData,
): Promise<AuthActionState> {
  const locale = formLocale(formData);
  const email = formValue(formData, "email");

  if (!email) {
    return {
      error: locale === "zh" ? "请输入注册邮箱。" : "Enter your signup email.",
      errorField: "email",
    };
  }

  try {
    const supabase = await createClient();
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${await siteOrigin()}/auth/callback?next=/update-password`,
    });

    if (error) {
      return authFailure(error.message, locale);
    }
  } catch {
    return {
      error:
        locale === "zh"
          ? "找回密码服务尚未配置，请先完成 Supabase 设置。"
          : "Password reset is not configured yet. Finish setting up Supabase first.",
    };
  }

  return {
    message:
      locale === "zh"
        ? "如果这个邮箱已注册，你会收到重置密码邮件。"
        : "If this email is registered, you will receive a password reset email.",
  };
}

export async function updatePassword(
  _previousState: AuthActionState,
  formData: FormData,
): Promise<AuthActionState> {
  const locale = formLocale(formData);
  const password = formData.get("password");
  const confirmation = formData.get("confirmation");

  if (typeof password !== "string" || !password) {
    return {
      error: locale === "zh" ? "请输入新密码。" : "Enter a new password.",
      errorField: "password",
    };
  }
  if (typeof confirmation !== "string" || !confirmation) {
    return {
      error: locale === "zh" ? "请确认密码。" : "Confirm your password.",
      errorField: "confirmation",
    };
  }
  if (password.length < 6) {
    return {
      error:
        locale === "zh" ? "密码至少需要 6 位。" : "Password must be at least 6 characters.",
      errorField: "password",
    };
  }
  if (password !== confirmation) {
    return {
      error: locale === "zh" ? "两次输入的密码不一致。" : "The passwords do not match.",
      errorField: "confirmation",
    };
  }

  try {
    const supabase = await createClient();
    const { error } = await supabase.auth.updateUser({ password });

    if (error) {
      return authFailure(error.message, locale);
    }
  } catch {
    return {
      error:
        locale === "zh"
          ? "更新密码服务尚未配置，请先完成 Supabase 设置。"
          : "Password update is not configured yet. Finish setting up Supabase first.",
    };
  }

  redirect("/app");
}

export async function signOut() {
  try {
    const supabase = await createClient();
    await supabase.auth.signOut();
  } finally {
    redirect("/");
  }
}
