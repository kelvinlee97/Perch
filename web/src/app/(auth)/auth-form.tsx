"use client";

import Link from "next/link";
import { useActionState, useEffect, useRef, useSyncExternalStore } from "react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  getLocaleSnapshot,
  getServerLocaleSnapshot,
  subscribeToLocale,
  type Locale,
} from "@/lib/locale";

import type { AuthActionState, AuthField } from "./actions";

type AuthMode = "login" | "signup" | "forgot" | "update";
type AuthAction = (
  previousState: AuthActionState,
  formData: FormData,
) => Promise<AuthActionState>;

function errorIdFor(state: AuthActionState, field: AuthField) {
  return state.error && state.errorField === field ? `auth-${field}-error` : undefined;
}

function AuthFieldError({
  field,
  state,
  errorRef,
}: {
  field: AuthField;
  state: AuthActionState;
  errorRef: React.RefObject<HTMLParagraphElement | null>;
}) {
  if (!state.error || state.errorField !== field) {
    return null;
  }

  return (
    <p
      id={`auth-${field}-error`}
      ref={errorRef}
      className="auth-field-error"
      role="alert"
      tabIndex={-1}
    >
      {state.error}
    </p>
  );
}

const copy: Record<
  Locale,
  {
    htmlLang: string;
    email: string;
    password: string;
    newPassword: string;
    confirmation: string;
    passwordHint: string;
    pending: string;
    forgotPassword: string;
    noAccount: string;
    createAccount: string;
    hasAccount: string;
    logInDirectly: string;
    remembered: string;
    backToLogin: string;
    modes: Record<
      AuthMode,
      { documentTitle: string; title: string; description: string; submit: string }
    >;
  }
> = {
  en: {
    htmlLang: "en",
    email: "Email",
    password: "Password",
    newPassword: "New password",
    confirmation: "Confirm password",
    passwordHint: "At least 6 characters.",
    pending: "Please wait…",
    forgotPassword: "Forgot your password?",
    noAccount: "Don't have an account?",
    createAccount: "Create an account",
    hasAccount: "Already have an account?",
    logInDirectly: "Log in directly",
    remembered: "Remembered it?",
    backToLogin: "Back to login",
    modes: {
      login: {
        documentTitle: "Log in｜Perch",
        title: "Welcome back",
        description: "Log in to keep your tasks in order.",
        submit: "Log in",
      },
      signup: {
        documentTitle: "Create an account｜Perch",
        title: "Start with Perch",
        description: "Create a quiet space for your tasks.",
        submit: "Create account",
      },
      forgot: {
        documentTitle: "Reset your password｜Perch",
        title: "Reset your password",
        description: "Enter your email and we’ll send a reset link.",
        submit: "Send reset email",
      },
      update: {
        documentTitle: "Set a new password｜Perch",
        title: "Set a new password",
        description: "Choose a new password for your Perch account.",
        submit: "Save new password",
      },
    },
  },
  zh: {
    htmlLang: "zh-CN",
    email: "邮箱",
    password: "密码",
    newPassword: "新密码",
    confirmation: "确认密码",
    passwordHint: "至少 6 位。",
    pending: "请稍候…",
    forgotPassword: "忘记密码？",
    noAccount: "还没有账号？",
    createAccount: "创建账号",
    hasAccount: "已有账号？",
    logInDirectly: "直接登录",
    remembered: "想起来了？",
    backToLogin: "返回登录",
    modes: {
      login: {
        documentTitle: "登录｜Perch",
        title: "欢迎回来",
        description: "登录后继续整理手边的事。",
        submit: "登录",
      },
      signup: {
        documentTitle: "创建账号｜Perch",
        title: "开始使用 Perch",
        description: "创建一个安静的待办空间。",
        submit: "创建账号",
      },
      forgot: {
        documentTitle: "找回密码｜Perch",
        title: "找回密码",
        description: "输入注册邮箱，我们会发一封重置邮件。",
        submit: "发送重置邮件",
      },
      update: {
        documentTitle: "设置新密码｜Perch",
        title: "设置新密码",
        description: "为你的 Perch 账号设置一个新密码。",
        submit: "保存新密码",
      },
    },
  },
};

export function AuthForm({
  mode,
  action,
  initialState = {},
}: {
  mode: AuthMode;
  action: AuthAction;
  initialState?: AuthActionState;
}) {
  const [state, formAction, pending] = useActionState(action, initialState);
  const errorRef = useRef<HTMLParagraphElement | null>(null);
  const locale = useSyncExternalStore(
    subscribeToLocale,
    getLocaleSnapshot,
    getServerLocaleSnapshot,
  );
  const language = copy[locale];
  const content = language.modes[mode];
  const isPasswordOnly = mode === "update";
  const showPasswordHint = mode === "signup" || mode === "update";

  useEffect(() => {
    if (state.error) {
      errorRef.current?.focus();
    }
  }, [state]);

  useEffect(() => {
    document.documentElement.lang = language.htmlLang;

    const updateHead = () => {
      document.title = content.documentTitle;
      document
        .querySelector('meta[name="description"]')
        ?.setAttribute("content", content.description);
    };

    updateHead();
    const timeout = window.setTimeout(updateHead, 100);

    return () => window.clearTimeout(timeout);
  }, [content, language, locale]);

  return (
    <section className="auth-form-section" aria-labelledby="auth-title">
      <h1 id="auth-title" className="font-display">
        {content.title}
      </h1>
      <p className="auth-description">{content.description}</p>

      <form action={formAction} className="auth-form">
        <input type="hidden" name="locale" value={locale} />
        {state.error && !state.errorField && (
          <p
            ref={errorRef}
            className="auth-message is-error"
            role="alert"
            tabIndex={-1}
          >
            {state.error}
          </p>
        )}

        {!isPasswordOnly && (
          <div className="auth-field">
            <Label htmlFor="email">{language.email}</Label>
            <Input
              id="email"
              name="email"
              type="email"
              autoComplete="email"
              placeholder="you@example.com"
              required
              aria-invalid={Boolean(errorIdFor(state, "email"))}
              aria-describedby={errorIdFor(state, "email")}
            />
            <AuthFieldError field="email" state={state} errorRef={errorRef} />
          </div>
        )}

        {mode !== "forgot" && (
          <div className="auth-field">
            <Label htmlFor="password">
              {mode === "update" ? language.newPassword : language.password}
            </Label>
            <Input
              id="password"
              name="password"
              type="password"
              autoComplete={mode === "login" ? "current-password" : "new-password"}
              minLength={6}
              required
              aria-invalid={Boolean(errorIdFor(state, "password"))}
              aria-describedby={
                [
                  showPasswordHint ? "password-hint" : undefined,
                  errorIdFor(state, "password"),
                ]
                  .filter(Boolean)
                  .join(" ") || undefined
              }
            />
            {showPasswordHint && (
              <p id="password-hint" className="auth-helper">
                {language.passwordHint}
              </p>
            )}
            <AuthFieldError field="password" state={state} errorRef={errorRef} />
          </div>
        )}

        {(mode === "signup" || mode === "update") && (
          <div className="auth-field">
            <Label htmlFor="confirmation">{language.confirmation}</Label>
            <Input
              id="confirmation"
              name="confirmation"
              type="password"
              autoComplete="new-password"
              minLength={6}
              required
              aria-invalid={Boolean(errorIdFor(state, "confirmation"))}
              aria-describedby={errorIdFor(state, "confirmation")}
            />
            <AuthFieldError field="confirmation" state={state} errorRef={errorRef} />
          </div>
        )}

        {state.message && (
          <p className="auth-message is-success" role="status">
            {state.message}
          </p>
        )}

        <Button type="submit" className="auth-submit" disabled={pending}>
          {pending ? language.pending : content.submit}
        </Button>
      </form>

      <div className="auth-links">
        {mode === "login" && (
          <>
            <Link href="/forgot-password">{language.forgotPassword}</Link>
            <span aria-hidden="true">·</span>
            <span>{language.noAccount}</span>
            <Link href="/signup">{language.createAccount}</Link>
          </>
        )}
        {mode === "signup" && (
          <>
            <span>{language.hasAccount}</span>
            <Link href="/login">{language.logInDirectly}</Link>
          </>
        )}
        {mode === "forgot" && (
          <>
            <span>{language.remembered}</span>
            <Link href="/login">{language.backToLogin}</Link>
          </>
        )}
      </div>
    </section>
  );
}
