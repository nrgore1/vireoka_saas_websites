#!/usr/bin/env python3
import subprocess
import pathlib
import os
from datetime import datetime
from flask import Flask, render_template_string, redirect, url_for, request

BASE_DIR = pathlib.Path(__file__).resolve().parent
STATUS_DIR = BASE_DIR / "status"

# Make sure status dir exists
STATUS_DIR.mkdir(parents=True, exist_ok=True)

APP_TITLE = "Vireoka Sync Dashboard"

HTML = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>{{ title }}</title>
  <style>
    body {
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #020617;
      color: #E5E7EB;
      margin: 0;
      padding: 0;
    }
    .page {
      max-width: 1100px;
      margin: 0 auto;
      padding: 24px 16px 40px;
    }
    h1 {
      font-size: 1.8rem;
      margin-bottom: 8px;
    }
    h2 {
      font-size: 1.2rem;
      margin-top: 24px;
      margin-bottom: 8px;
    }
    .subtitle {
      color: #9CA3AF;
      margin-bottom: 20px;
    }
    .row {
      display: flex;
      flex-wrap: wrap;
      gap: 16px;
      margin-bottom: 24px;
    }
    .card {
      flex: 1 1 260px;
      border-radius: 16px;
      padding: 16px 18px;
      background: radial-gradient(circle at top left, rgba(90,47,227,0.35), rgba(15,23,42,0.95));
      border: 1px solid rgba(148,163,184,0.35);
      box-shadow: 0 18px 50px rgba(0,0,0,0.65);
    }
    .card h3 {
      margin-top: 0;
      margin-bottom: 8px;
      font-size: 1rem;
    }
    .tag {
      display: inline-block;
      padding: 2px 8px;
      border-radius: 999px;
      border: 1px solid rgba(148,163,184,0.4);
      font-size: 0.7rem;
      text-transform: uppercase;
      letter-spacing: 0.14em;
      color: #A5B4FC;
      margin-bottom: 6px;
    }
    .meta {
      font-size: 0.8rem;
      color: #9CA3AF;
      margin-top: 4px;
    }
    .btn-row {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 8px;
    }
    .btn {
      border-radius: 999px;
      padding: 7px 16px;
      border: none;
      cursor: pointer;
      font-size: 0.9rem;
      font-weight: 500;
    }
    .btn-primary {
      background: linear-gradient(90deg,#E4B448,#3AF4D3);
      color: #020617;
      box-shadow: 0 10px 30px rgba(0,0,0,0.65);
    }
    .btn-secondary {
      background: transparent;
      color: #E5E7EB;
      border: 1px solid rgba(148,163,184,0.6);
    }
    .btn-danger {
      background: #7F1D1D;
      color: #FEE2E2;
      border: 1px solid #B91C1C;
    }
    pre {
      background: #020617;
      border-radius: 10px;
      padding: 12px;
      font-size: 0.8rem;
      overflow-x: auto;
      border: 1px solid rgba(31,41,55,1);
      max-height: 260px;
    }
    .conflict-line {
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
      font-size: 0.8rem;
      padding: 3px 0;
      border-bottom: 1px solid rgba(31,41,55,0.7);
    }
    .conflict-line:last-child {
      border-bottom: none;
    }
    .conflict-tag-plugins {
      color: #F97316;
      margin-right: 6px;
    }
    .conflict-tag-site {
      color: #22C55E;
      margin-right: 6px;
    }
    .flash {
      padding: 8px 12px;
      border-radius: 8px;
      margin-bottom: 16px;
      font-size: 0.9rem;
    }
    .flash-ok {
      background: rgba(22,163,74,0.15);
      border: 1px solid rgba(34,197,94,0.7);
      color: #BBF7D0;
    }
    .flash-err {
      background: rgba(185,28,28,0.18);
      border: 1px solid rgba(248,113,113,0.9);
      color: #FECACA;
    }
    a, a:visited {
      color: #A5B4FC;
    }
  </style>
</head>
<body>
  <div class="page">
    <h1>{{ title }}</h1>
    <div class="subtitle">
      Local root: <code>{{ local_root }}</code><br>
      Remote: <code>{{ remote_user }}@{{ remote_host }}:{{ remote_root }}</code>
    </div>

    {% if flash %}
      <div class="flash {{ 'flash-ok' if flash.ok else 'flash-err' }}">
        {{ flash.message }}
      </div>
    {% endif %}

    <div class="row">
      <div class="card">
        <div class="tag">Plugins</div>
        <h3>Plugin Sync</h3>
        <div class="meta">
          Two-way sync between <code>vireoka_plugins/</code> and remote <code>wp-content/plugins/</code>.
        </div>
        <form method="post" action="{{ url_for('run_command', cmd='plugins') }}">
          <div class="btn-row">
            <button class="btn btn-primary" type="submit">Run Plugin Sync</button>
          </div>
        </form>
        {% if last_output.plugins %}
          <div class="meta">Last output:</div>
          <pre>{{ last_output.plugins }}</pre>
        {% endif %}
      </div>

      <div class="card">
        <div class="tag">Themes + Uploads</div>
        <h3>Site Sync</h3>
        <div class="meta">
          Syncs <code>themes/</code> and <code>uploads/</code> (remote ↔ local).
        </div>
        <form method="post" action="{{ url_for('run_command', cmd='site') }}">
          <div class="btn-row">
            <button class="btn btn-primary" type="submit">Run Site Sync</button>
          </div>
        </form>
        {% if last_output.site %}
          <div class="meta">Last output:</div>
          <pre>{{ last_output.site }}</pre>
        {% endif %}
      </div>

      <div class="card">
        <div class="tag">Git + Sync</div>
        <h3>Git Deploy</h3>
        <div class="meta">
          Optional commit + push, then runs plugin + site sync.
        </div>
        <form method="post" action="{{ url_for('run_command', cmd='git') }}">
          <div class="btn-row">
            <button class="btn btn-secondary" type="submit">Run Git Deploy</button>
          </div>
        </form>
        {% if last_output.git %}
          <div class="meta">Last output:</div>
          <pre>{{ last_output.git }}</pre>
        {% endif %}
      </div>
    </div>

    <h2>Conflicts</h2>
    <div class="row">
      <div class="card">
        <div class="tag">Plugins</div>
        {% if conflicts.plugins %}
          {% for c in conflicts.plugins %}
            <div class="conflict-line">
              <span class="conflict-tag-plugins">[P]</span>
              <strong>{{ c.path }}</strong><br>
              <span class="meta">
                local: {{ c.local_ts }} &nbsp; | &nbsp; remote: {{ c.remote_ts }}
              </span>
            </div>
          {% endfor %}
        {% else %}
          <div class="meta">No plugin conflicts detected.</div>
        {% endif %}
      </div>

      <div class="card">
        <div class="tag">Themes + Uploads</div>
        {% if conflicts.site %}
          {% for c in conflicts.site %}
            <div class="conflict-line">
              <span class="conflict-tag-site">[S]</span>
              <strong>{{ c.path }}</strong><br>
              <span class="meta">
                local: {{ c.local_ts }} &nbsp; | &nbsp; remote: {{ c.remote_ts }}
              </span>
            </div>
          {% endfor %}
        {% else %}
          <div class="meta">No site conflicts recorded.</div>
        {% endif %}
      </div>
    </div>

  </div>
</body>
</html>
"""

app = Flask(__name__)
app.secret_key = "vireoka-dev-only"  # local only, fine


def _fmt_ts(ts_str: str) -> str:
    """Convert float timestamp string into human-friendly datetime."""
    try:
        ts = float(ts_str)
        return datetime.fromtimestamp(ts).strftime("%Y-%m-%d %H:%M:%S")
    except Exception:
        return ts_str


def read_conflicts(path: pathlib.Path):
    if not path.exists():
        return []
    lines = path.read_text().splitlines()
    out = []
    for line in lines:
        if not line.strip():
            continue
        parts = line.split("|")
        if len(parts) != 3:
            continue
        path_name, ts_local, ts_remote = parts
        out.append({
            "path": path_name,
            "local_ts": _fmt_ts(ts_local),
            "remote_ts": _fmt_ts(ts_remote),
        })
    return out


def read_last_output():
    """Read latest run outputs from temp files (if any)."""
    outputs = {
        "plugins": "",
        "site": "",
        "git": "",
    }
    for key in outputs.keys():
        f = STATUS_DIR / f"last_{key}_run.log"
        if f.exists():
            outputs[key] = f.read_text()[-8000:]  # tail-ish
    return outputs


def write_last_output(kind: str, stdout: str, stderr: str, code: int):
    f = STATUS_DIR / f"last_{kind}_run.log"
    header = f"# {kind} run (exit={code})\n\n"
    body = ""
    if stdout:
        body += "STDOUT:\n" + stdout + "\n"
    if stderr:
        body += "\nSTDERR:\n" + stderr + "\n"
    f.write_text(header + body)


@app.route("/", methods=["GET"])
def index():
    conflicts_plugins = read_conflicts(STATUS_DIR / "conflicts_plugins.txt")
    conflicts_site = read_conflicts(STATUS_DIR / "conflicts_site.txt")
    last_output = read_last_output()

    flash_msg = None
    # We don't use Flask flash queue; we just show recent action via query param
    status = request.args.get("status")
    msg = request.args.get("msg")

    if status and msg:
        flash_msg = {
            "ok": status == "ok",
            "message": msg
        }

    return render_template_string(
        HTML,
        title=APP_TITLE,
        local_root=str(BASE_DIR.parent),
        remote_host=os.environ.get("VIREOKA_REMOTE_HOST", "45.137.159.84"),
        remote_user=os.environ.get("VIREOKA_REMOTE_USER", "u814009065"),
        remote_root="/home/u814009065/domains/vireoka.com/public_html",
        conflicts={"plugins": conflicts_plugins, "site": conflicts_site},
        last_output=last_output,
        flash=flash_msg,
    )


@app.route("/run/<cmd>", methods=["POST"])
def run_command(cmd):
    script_map = {
        "plugins": "vsync.sh",
        "site": "vsite-sync.sh",
        "git": "vgit-deploy.sh",
    }
    if cmd not in script_map:
        return redirect(url_for("index", status="err", msg="Unknown command."))

    script_path = BASE_DIR / script_map[cmd]
    if not script_path.exists():
        return redirect(url_for("index", status="err", msg=f"{script_map[cmd]} not found."))

    try:
        proc = subprocess.run(
            ["bash", str(script_path)],
            capture_output=True,
            text=True,
            cwd=str(BASE_DIR),
        )
        write_last_output(cmd, proc.stdout, proc.stderr, proc.returncode)

        if proc.returncode == 0:
            return redirect(url_for("index", status="ok", msg=f"{script_map[cmd]} finished successfully."))
        else:
            return redirect(url_for("index", status="err", msg=f"{script_map[cmd]} exited with code {proc.returncode}."))
    except Exception as e:
        return redirect(url_for("index", status="err", msg=f"Exception: {e}"))


if __name__ == "__main__":
    # Run on localhost:5000
    app.run(host="127.0.0.1", port=5000, debug=False)
