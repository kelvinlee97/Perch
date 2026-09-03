"use client";

import Link from "next/link";
import { useSyncExternalStore } from "react";

import { Brand } from "@/components/brand";
import { LanguageSwitcher } from "@/components/language-switcher";
import {
  getLocaleSnapshot,
  getServerLocaleSnapshot,
  setLocale,
  subscribeToLocale,
  type Locale,
} from "@/lib/locale";

const copy: Record<
  Locale,
  { brandLabel: string; languageLabel: string; english: string; chinese: string; home: string }
> = {
  en: {
    brandLabel: "Perch home",
    languageLabel: "Language",
    english: "EN",
    chinese: "中文",
    home: "Back to home",
  },
  zh: {
    brandLabel: "Perch 首页",
    languageLabel: "语言",
    english: "EN",
    chinese: "中文",
    home: "回到首页",
  },
};

export default function AuthLayout({ children }: LayoutProps<"/">) {
  const locale = useSyncExternalStore(
    subscribeToLocale,
    getLocaleSnapshot,
    getServerLocaleSnapshot,
  );
  const content = copy[locale];

  return (
    <main className="auth-page">
      <div className="auth-card">
        <div className="auth-card-header">
          <Brand homeLabel={content.brandLabel} />
          <LanguageSwitcher
            locale={locale}
            labels={content}
            onChange={setLocale}
          />
        </div>
        {children}
        <Link href="/" className="auth-home-link">
          {content.home}
        </Link>
      </div>
    </main>
  );
}
