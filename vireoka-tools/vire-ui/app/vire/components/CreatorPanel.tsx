"use client";

import { useMemo, useState } from "react";

type Draft = {
  ok?: boolean;
  title?: string;
  excerpt?: string;
  content_html?: string;
  keywords?: string[];
  slug?: string;
  meta_description?: string;
  warnings?: string[];
  error?: string;
};

async function postJson(url: string, body: any) {
  const r = await fetch(url, {
    method: "POST",
    headers: { "content-type": "application/json" },
    credentials: "include",
    cache: "no-store",
    body: JSON.stringify(body),
  });
  const text = await r.text();
  try {
    const json = JSON.parse(text);
    return { ok: r.ok, json, raw: text };
  } catch {
    return { ok: r.ok, json: null, raw: text };
  }
}

function Hint({ children }: { children: React.ReactNode }) {
  return (
    <div style={{
      marginTop: 10,
      padding: "10px 12px",
      border: "1px solid rgba(255,255,255,.10)",
      borderRadius: 12,
      background: "rgba(2,6,23,.25)",
      color: "rgba(229,231,235,.85)",
      fontSize: 13,
      lineHeight: 1.55
    }}>
      {children}
    </div>
  );
}

export default function CreatorPanel({ apiBase }: { apiBase: string }) {
  const [prompt, setPrompt] = useState<string>(
    "Write a technical blog post for CTOs: 'Autonomous Agents vs Chatbots: The Enterprise Migration Path'. Include a maturity model and security notes."
  );
  const [tone, setTone] = useState<string>("Authoritative, technical, concise");
  const [draft, setDraft] = useState<Draft | null>(null);
  const [busy, setBusy] = useState<string>("");

  const preview = useMemo(() => {
    if (!draft) return null;
    return {
      title: draft.title || "(no title)",
      excerpt: draft.excerpt || "(no excerpt)",
      html: draft.content_html || "<p>(no content)</p>",
    };
  }, [draft]);

  async function generate() {
    setBusy("Generating draft…");
    setDraft(null);
    const { ok, json, raw } = await postJson(`${apiBase}/content/generate`, {
      prompt,
      mode: "Creator",
      tone,
    });
    setBusy("");
    if (!ok) {
      setDraft({ ok: false, error: json?.error || raw || "Generate failed" });
      return;
    }
    setDraft(json || { ok: false, error: "Invalid JSON response" });
  }

  async function saveDraft() {
    if (!draft?.title || !draft?.content_html) {
      alert("Generate a draft first.");
      return;
    }
    setBusy("Saving WP draft…");
    const { ok, json, raw } = await postJson(`${apiBase}/content/draft`, {
      title: draft.title,
      excerpt: draft.excerpt || "",
      content: draft.content_html,
      slug: draft.slug || "",
      meta_description: draft.meta_description || "",
      keywords: draft.keywords || [],
    });
    setBusy("");
    if (!ok) {
      alert(`Draft save failed: ${json?.error || raw}`);
      return;
    }
    alert(`Saved draft in WordPress. post_id=${json?.post_id}`);
    setDraft((d) => ({ ...(d || {}), ok: true, post_id: json?.post_id } as any));
  }

  async function publish() {
    const postId = (draft as any)?.post_id;
    if (!postId) {
      alert("Save as draft first (needs post_id).");
      return;
    }
    setBusy("Publishing…");
    const { ok, json, raw } = await postJson(`${apiBase}/content/publish`, {
      post_id: postId,
    });
    setBusy("");
    if (!ok) {
      alert(`Publish failed: ${json?.error || raw}`);
      return;
    }
    alert(`Published ✅ post_id=${postId}`);
  }

  return (
    <div style={{
      marginTop: 14,
      border: "1px solid rgba(255,255,255,.10)",
      borderRadius: 18,
      padding: 16,
      background: "rgba(2,6,23,.18)"
    }}>
      <h2 style={{marginTop:0}}>✍️ Creator Mode — Prompt → Draft → Publish</h2>

      <div style={{display:"grid", gridTemplateColumns:"1fr 1fr", gap:12}}>
        <div>
          <label style={{display:"block", fontSize:12, opacity:.8}}>Prompt</label>
          <textarea
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            rows={8}
            style={{
              width: "100%",
              marginTop: 6,
              borderRadius: 14,
              padding: 12,
              background: "rgba(0,0,0,.25)",
              border: "1px solid rgba(255,255,255,.12)",
              color: "#E5E7EB",
              fontSize: 13,
              lineHeight: 1.5
            }}
          />
          <label style={{display:"block", fontSize:12, opacity:.8, marginTop:10}}>Tone</label>
          <input
            value={tone}
            onChange={(e) => setTone(e.target.value)}
            style={{
              width: "100%",
              marginTop: 6,
              borderRadius: 14,
              padding: 12,
              background: "rgba(0,0,0,.25)",
              border: "1px solid rgba(255,255,255,.12)",
              color: "#E5E7EB",
              fontSize: 13
            }}
          />
          <div style={{display:"flex", gap:10, flexWrap:"wrap", marginTop:12}}>
            <button
              onClick={generate}
              disabled={!!busy}
              style={{
                cursor: "pointer",
                padding: "10px 12px",
                borderRadius: 12,
                border: "1px solid rgba(58,244,211,.45)",
                background: "rgba(58,244,211,.18)",
                color: "#E5E7EB",
                fontWeight: 900
              }}
            >
              🤖 Generate Draft
            </button>

            <button
              onClick={saveDraft}
              disabled={!!busy}
              style={{
                cursor: "pointer",
                padding: "10px 12px",
                borderRadius: 12,
                border: "1px solid rgba(255,255,255,.14)",
                background: "rgba(2,6,23,.15)",
                color: "#E5E7EB",
                fontWeight: 900
              }}
            >
              💾 Save WP Draft
            </button>

            <button
              onClick={publish}
              disabled={!!busy}
              style={{
                cursor: "pointer",
                padding: "10px 12px",
                borderRadius: 12,
                border: "1px solid rgba(228,180,72,.45)",
                background: "rgba(228,180,72,.18)",
                color: "#E5E7EB",
                fontWeight: 900
              }}
            >
              🚀 Publish
            </button>
          </div>

          {busy && <p style={{marginTop:10, opacity:.8}}>⏳ {busy}</p>}

          <Hint>
            <b>How this works</b><br/>
            1) Generate creates a structured draft (title, excerpt, slug, keywords, meta).<br/>
            2) Save WP Draft stores it in WordPress as a draft post.<br/>
            3) Publish flips status to <code>publish</code>.<br/>
            <br/>
            If LLM is not configured, your backend should return a fallback draft so you can still test the pipeline.
          </Hint>
        </div>

        <div>
          <label style={{display:"block", fontSize:12, opacity:.8}}>Preview</label>

          {!preview && (
            <div style={{
              marginTop: 6,
              padding: 14,
              borderRadius: 14,
              border: "1px dashed rgba(255,255,255,.14)",
              opacity: .7
            }}>
              Generate a draft to see a live preview here.
            </div>
          )}

          {preview && (
            <div style={{
              marginTop: 6,
              borderRadius: 14,
              border: "1px solid rgba(255,255,255,.12)",
              background: "rgba(0,0,0,.20)",
              overflow: "hidden"
            }}>
              <div style={{padding:12, borderBottom:"1px solid rgba(255,255,255,.10)"}}>
                <div style={{fontWeight: 900, fontSize: 18}}>{preview.title}</div>
                <div style={{opacity:.8, marginTop:6, fontSize: 13}}>{preview.excerpt}</div>
              </div>
              <div style={{padding:12}}>
                <div
                  style={{fontSize: 13, lineHeight: 1.65, color: "rgba(229,231,235,.92)"}}
                  dangerouslySetInnerHTML={{ __html: preview.html }}
                />
              </div>
            </div>
          )}

          {draft?.error && (
            <div style={{marginTop:10, color:"#FCA5A5"}}>
              Error: {draft.error}
            </div>
          )}

          {draft?.warnings?.length ? (
            <div style={{marginTop:10, color:"#FDE68A"}}>
              <b>Warnings</b>
              <ul>
                {draft.warnings.map((w, i) => <li key={i}>{w}</li>)}
              </ul>
            </div>
          ) : null}
        </div>
      </div>
    </div>
  );
}
