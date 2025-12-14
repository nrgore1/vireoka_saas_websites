"use client";

import { useEffect, useState } from "react";

export function useVireFetch<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let alive = true;

    fetch(url, { credentials: "include", cache: "no-store" })
      .then(r => {
        if (!r.ok) throw new Error(r.statusText);
        return r.json();
      })
      .then(j => alive && setData(j))
      .catch(e => alive && setError(e.message))
      .finally(() => alive && setLoading(false));

    return () => { alive = false; };
  }, [url]);

  return { data, loading, error };
}
