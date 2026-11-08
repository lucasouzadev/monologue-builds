#!/usr/bin/env bash
# agent-kit UserPromptSubmit hook: asks the agent to silently compile the owner's message into a
# brief (skill intent-compiler) before acting. Adds ~2 lines of context; skips approvals, tiny
# acknowledgements and slash commands. Never prints the owner's text back. Read-only, offline.
input="$(cat)"
printf '%s' "$input" | python3 -c '
import json,sys,re
try: p=(json.load(sys.stdin) or {}).get("prompt","") or ""
except Exception: sys.exit()
t=p.strip().lower()
if not t or t.startswith("/"): sys.exit()
acks={"ok","sim","pode","pode sim","manda","manda ver","segue","yes","go","ok pode","beleza","fechado","isso","valeu","obrigado","thanks","no","não","nao"}
if t.rstrip(".!") in acks or len(t)<4: sys.exit()
mode="Builder"
if re.search(r"\b(bug|erro|error|quebr|crash|não funciona|nao funciona|estranh|falh|broke|fix|regress)",t): mode="Fixer"
elif re.search(r"\b(como (tá|ta|está|esta)|status|andamento|onde paramos|what.s the status)",t): mode="Status"
elif re.search(r"\b(continua|continue|segue o plano|próximo passo|next step)",t): mode="Continue"
elif re.search(r"\b(audit|auditoria|é seguro|is it safe|race|idempot|webhook|pagamento|payment)",t): mode="Auditor"
elif re.search(r"\b(mapeia|analisa|analyze|entender|onde fica|where is|dívida|debt)",t): mode="Lens"
elif re.search(r"\b(arquitetura|schema|migration|deploy|rollback|performance|lento|slow)",t): mode="Architect"
elif re.search(r"\b(ideia|queria|quero|seria bom|would like|feature|tela|screen|fluxo|flow)",t): mode="Product"
print(f"[agent-kit] Before acting, silently compile the owner message into a brief (skill intent-compiler: goal, context from repo/handoff, acceptance, constraints, mode, skills, one blocking question at most). Likely mode: {mode}. Do not show the brief unless asked; restate only goal + acceptance in one line when non-trivial.")
'
exit 0
