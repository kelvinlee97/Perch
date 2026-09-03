export type Locale = "en" | "zh";

const localeStorageKey = "perch-locale";
const listeners = new Set<() => void>();

export function getLocaleSnapshot(): Locale {
  if (typeof window === "undefined") {
    return "en";
  }

  return window.localStorage.getItem(localeStorageKey) === "zh" ? "zh" : "en";
}

export function getServerLocaleSnapshot(): Locale {
  return "en";
}

export function subscribeToLocale(listener: () => void) {
  listeners.add(listener);

  if (typeof window === "undefined") {
    return () => listeners.delete(listener);
  }

  const handleStorage = (event: StorageEvent) => {
    if (event.key === localeStorageKey) {
      listener();
    }
  };

  window.addEventListener("storage", handleStorage);

  return () => {
    listeners.delete(listener);
    window.removeEventListener("storage", handleStorage);
  };
}

export function setLocale(locale: Locale) {
  window.localStorage.setItem(localeStorageKey, locale);
  listeners.forEach((listener) => listener());
}
