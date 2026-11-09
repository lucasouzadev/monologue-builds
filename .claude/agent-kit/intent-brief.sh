#!/usr/bin/env bash
# agent-kit UserPromptSubmit hook: asks the agent to silently compile the owner's message into a
# brief (skill intent-compiler) before acting. Adds ~2 lines of context; skips approvals, tiny
# acknowledgements and slash commands. Never prints the owner's text back. Read-only, offline.
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib.sh"
ak_require_py
input="$(cat)"
printf '%s' "$input" | HERE="$here" "$PY" -c '
import subprocess,os
import json,sys,re
try: d=json.load(sys.stdin) or {}
except Exception: sys.exit()
p=d.get("prompt","") or ""; sid=d.get("session_id","")
import unicodedata
t="".join(c for c in unicodedata.normalize("NFD",p.strip().lower()) if unicodedata.category(c)!="Mn")
if not t or t.startswith("/"): sys.exit()
acks={"ok","okay","sim","pode","pode sim","manda","manda ver","segue","yes","yep","go","go ahead","sure","beleza","fechado","isso","valeu","obrigado","obrigada","thanks","thank you","no","nao","si","vale","dale","claro","adelante","perfecto","perfeito","gracias","de acuerdo","combinado","ok pode","pode ir","hazlo","hagale"}
if t.strip(".!?, ") in acks or len(t)<4: sys.exit()
# Languages: en / pt / es (accents stripped). Order matters: first match wins.
MODES=[
 ("Fixer",    r"\b(bug|erro|error|quebr|crash|falha|falh|nao funciona|no funciona|doesn.?t work|not working|broke|broken|fix|regress|estranh|esquisit|rar[oa]\b|rompi|roto|travou|trav[ao]|congel|freez|stuck|fail)"),
 ("Status",   r"\b(como (ta|esta|vai|anda|va|estamos)|status|andamento|onde paramos|donde quedamos|where (are|were) we|how.s it going|progress|resumo|resumen|summary of)"),
 ("Continue", r"\b(continua|continue|segue|siga|sigue|seguimos|proximo passo|siguiente paso|next step|carry on|go on|retoma|resume)\b"),
 ("Auditor",  r"\b(audit|auditoria|auditar|e seguro|es seguro|is it safe|race condition|idempot|webhook|pagamento|pago|payment|cobranca|cobro|billing|vazamento|fuga|leak)"),
 ("Lens",     r"\b(mapeia|mapea|map out|analis|analyz|analyse|entender|entiende|understand|where is|onde fica|donde esta|divida tecnica|deuda tecnica|tech debt|explica|explain|investiga|investigate)"),
 ("Architect",r"\b(arquitetura|arquitectura|architecture|schema|migra|deploy|rollback|performance|rendimiento|desempenho|lent[oa]|slow|escala|scal|infra)"),
 ("Builder",  r"\b(adiciona|adicionar|agrega|agregar|anade|add\b|cria\b|criar|crea\b|crear|create|implementa|implement|constroi|construye|build\b|faz\b|fazer|haz\b|hacer|make\b|integra|integrate)"),
 ("Product",  r"\b(ideia|idea|queria|quero|quiero|quisiera|gostaria|seria bom|seria bueno|would like|i want|we need|precisamos|necesitamos|feature|funcionalidade|funcionalidad|tela|pantalla|screen|fluxo|flujo|flow)"),
]
mode="unknown"
for name,rx in MODES:
    if re.search(rx,t): mode=name; break
subprocess.Popen([sys.executable,os.environ["HERE"]+"/metrics.py","log","prompt","mode="+mode,"len=%d"%len(p),"session="+sid],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
extra=""
nmedia=len(re.findall(r"\[image( #?\d+)?\]",p,re.I))+len(re.findall(r"\S+\.(png|jpe?g|gif|webp|heic|mp4|mov|webm|mkv|m4v)\b",p,re.I))
if nmedia: extra+=f" Media attached ({nmedia}): use skill media-investigation; analyze every attachment, including any the owner did not mention, and cite those explicitly."
items=len(re.findall(r"(?m)^\s*(?:[-*\u2022]|\d+[.)])\s+\S",p))
if items>=3: extra+=f" The message lists {items} items: use skill triage (split, size, order; quick wins batched, large items get spec/plan options)."
print(f"[agent-kit] Before acting, silently compile the owner message into a brief (skill intent-compiler: goal, context from repo/handoff, acceptance, constraints, mode, skills, one blocking question at most). Likely mode: {mode}{" (no clear signal: infer it from the message and the repo)" if mode=="unknown" else ""}. Do not show the brief unless asked; restate only goal + acceptance in one line when non-trivial.{extra}")
'
exit 0
