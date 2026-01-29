// Locale is a dictionary of translation keys -> strings.
// Many components expect that accessing a missing key returns the key itself
// (previously done via a `t()` helper). To preserve that behavior when
// using dot-access (Locale.some_key), we export a Proxy which falls back to
// the raw key string when a translation is missing.
const rawLocale: { [key: string]: string } = {};

// subscribers will be notified whenever a locale key is set
const subscribers = new Set<() => void>();

export function subscribeLocale(cb: () => void) {
  subscribers.add(cb);
  return () => { subscribers.delete(cb); };
}

export const Locale: { [key: string]: string } = new Proxy(rawLocale, {
  get(target, prop: string | symbol) {
    if (typeof prop === 'string') {
      // return the translation if present, otherwise return the key itself
      return target[prop] ?? prop;
    }
    return undefined as any;
  },
  // allow setting new keys at runtime; notify subscribers
  set(target, prop: string | symbol, value) {
    if (typeof prop === 'string') {
      target[prop] = String(value);
      // notify listeners (do this async to avoid surprising sync effects)
      setTimeout(() => {
        subscribers.forEach((cb) => cb());
      }, 0);
      return true;
    }
    return false;
  },
});
