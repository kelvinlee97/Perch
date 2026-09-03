"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useSyncExternalStore } from "react";

import { Brand } from "@/components/brand";
import { LanguageSwitcher } from "@/components/language-switcher";
import {
  getLocaleSnapshot,
  getServerLocaleSnapshot,
  setLocale,
  subscribeToLocale,
  type Locale,
} from "@/lib/locale";

import { WorkspacePreview } from "./workspace-preview";

const copy: Record<
  Locale,
  {
    documentTitle: string;
    description: string;
    htmlLang: string;
    brandLabel: string;
    navigationLabel: string;
    languageLabel: string;
    english: string;
    chinese: string;
    login: string;
    getStarted: string;
    heroTitle: [string, string];
    heroDescription: string;
    footer: string;
  }
> = {
  en: {
    documentTitle: "Perch | Let one thing land first",
    description:
      "Perch is a quiet task companion that remembers what matters—one reminder at a time.",
    htmlLang: "en",
    brandLabel: "Perch home",
    navigationLabel: "Primary navigation",
    languageLabel: "Language",
    english: "EN",
    chinese: "中文",
    login: "Log in",
    getStarted: "Get started",
    heroTitle: ["Let one thing", "land first"],
    heroDescription: "One reminder at a time, so the next thing gets done.",
    footer: "Quietly, get things done.",
  },
  zh: {
    documentTitle: "Perch｜让一件事先落地",
    description: "一个安静的待办伴侣，帮你记住要做的事，一次只提醒一件。",
    htmlLang: "zh-CN",
    brandLabel: "Perch 首页",
    navigationLabel: "主导航",
    languageLabel: "语言",
    english: "EN",
    chinese: "中文",
    login: "登录",
    getStarted: "开始使用",
    heroTitle: ["让一件事", "先落地"],
    heroDescription: "一次只提醒一件，让下一件事真正完成。",
    footer: "安静地，把事情做完。",
  },
};

export function LandingPage() {
  const locale = useSyncExternalStore(
    subscribeToLocale,
    getLocaleSnapshot,
    getServerLocaleSnapshot,
  );
  const content = copy[locale];

  useEffect(() => {
    document.documentElement.lang = content.htmlLang;

    const updateHead = () => {
      document.title = content.documentTitle;
      document
        .querySelector('meta[name="description"]')
        ?.setAttribute("content", content.description);
    };

    updateHead();
    const timeout = window.setTimeout(updateHead, 100);

    return () => window.clearTimeout(timeout);
  }, [content, locale]);

  return (
    <main className="landing-page">
      <header className="landing-header">
        <Brand homeLabel={content.brandLabel} />
        <nav className="landing-nav" aria-label={content.navigationLabel}>
          <Link href="/login">{content.login}</Link>
          <LanguageSwitcher
            locale={locale}
            labels={content}
            onChange={setLocale}
          />
          <Link className="nav-cta" href="/signup">
            {content.getStarted}
          </Link>
        </nav>
      </header>

      <section className="landing-hero" aria-labelledby="landing-title">
        <div className="landing-copy">
          <h1 id="landing-title" className="font-display">
            {content.heroTitle[0]}
            <br />
            {content.heroTitle[1]}
          </h1>
          <p>{content.heroDescription}</p>
          <div className="landing-actions">
            <Link className="primary-link" href="/signup">
              {content.getStarted}
            </Link>
            <Link className="secondary-link" href="/login">
              {content.login}
            </Link>
          </div>
          <div className="landing-bird-stage" aria-hidden="true">
            <div className="bird-platform" />
            <Image
              src="/brand/bird-companion.png"
              alt=""
              width={560}
              height={560}
              className="landing-bird"
              priority
              sizes="(max-width: 767px) 70vw, 32vw"
            />
          </div>
        </div>
        <WorkspacePreview locale={locale} />
      </section>

      <footer className="landing-footer">
        <Brand compact homeLabel={content.brandLabel} />
        <span>{content.footer}</span>
      </footer>
    </main>
  );
}
