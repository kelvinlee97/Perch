"use client";

import type { Locale } from "@/lib/locale";

type LanguageSwitcherLabels = {
  languageLabel: string;
  english: string;
  chinese: string;
};

export function LanguageSwitcher({
  locale,
  labels,
  onChange,
}: {
  locale: Locale;
  labels: LanguageSwitcherLabels;
  onChange: (locale: Locale) => void;
}) {
  return (
    <div className="language-switcher" role="group" aria-label={labels.languageLabel}>
      <button
        type="button"
        aria-pressed={locale === "en"}
        onClick={() => onChange("en")}
      >
        {labels.english}
      </button>
      <button
        type="button"
        aria-pressed={locale === "zh"}
        onClick={() => onChange("zh")}
      >
        {labels.chinese}
      </button>
    </div>
  );
}
