#!/usr/bin/env bash
# agente-claude.sh — o agente REAL do experimento: o Claude Code (sem ferramentas) propõe um regras.txt novo.
# Roda na pasta do repo, chamado pelo experimento.sh. Sai da cota da sua assinatura (uma chamada).
# Resposta vazia (limite da sessão, erro) = ERRO, saída 1: nunca vira "não mudou nada".
set -uo pipefail
K=$(cd "$(dirname "$0")" && pwd)
PEDIDO="Você melhora as regras de um classificador de mensagens de suporte. Formato de cada linha: 'categoria: palavra, palavra'; a primeira categoria cuja palavra aparece no texto vence; sem nenhuma, 'outros'.
Regras atuais:
$(cat regras.txt)

Casos que o classificador errou:
$(python3 "$K/medir.py" . --erros | tail -n +2)

Proponha UMA mudança que generalize (palavras que pessoas reais usariam), sem copiar frases inteiras dos casos.
Responda SÓ com o conteúdo completo do novo regras.txt, sem explicação e sem cercas de código."
J=$(mktemp)
echo "$PEDIDO" | claude -p --tools "" --output-format json > "$J" 2>/dev/null
python3 - "$J" <<'PY'
import json, os, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    print("ERRO: resposta do claude não é JSON"); sys.exit(1)
r = (d.get("result") or "").strip()
linhas = [l for l in r.splitlines() if not l.startswith("```")]
if d.get("is_error") or not any(":" in l for l in linhas):
    print("ERRO: sem regras na resposta (" + (r[:80] or "vazia") + ")"); sys.exit(1)
u = d.get("usage") or {}
ent = u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0) + u.get("cache_creation_input_tokens", 0)
if os.environ.get("TOKENS_ARQ"):
    open(os.environ["TOKENS_ARQ"], "w").write(f"{ent} {u.get('output_tokens', 0)}\n")
open("regras.txt", "w", encoding="utf-8").write("\n".join(linhas).strip() + "\n")
print(f"regras.txt reescrito ({len(linhas)} linhas)")
PY
rc=$?; rm -f "$J"; exit $rc
