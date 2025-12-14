"use client";

import { useEffect, useState } from "react";

/**
 * Admin auth rules:
 * 1) If ?vire_token= is present → trusted admin
 * 2) Otherwise → check WP REST auth endpoint
 */
export function useWpAuth() {
  const [isAdmin, setIsAdmin] = useState<boolean | null>(null);

  useEffect(() => {
    // Token-based override (for local dev / split origin)
    const params = new URLSearchParams(window.location.search);
    const token = params.get("vire_token");
    if (token && token.length > 10) {
      setIsAdmin(true);
      return;
    }

    // Cookie-based check (same-origin WordPress)
    fetch("/wp-json/wp/v2/users/me", {
      credentials: "include",
      cache: "no-store",
    })
      .then((r) => {
        if (!r.ok) throw new Error("not logged in");
        return r.json();
      })
      .then((u) => {
        setIsAdmin(!!u?.id);
      })
      .catch(() => setIsAdmin(false));
  }, []);

  return isAdmin;
}
