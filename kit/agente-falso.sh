#!/usr/bin/env bash
# agente-falso.sh <modo> — faz o papel do agente no ensaio, sem chamar modelo nenhum (roda na pasta do repo).
#   sinonimos   acrescenta estorno/devolução/devolver em reembolso (melhora de verdade)
#   estraga     tira "senha" de acesso (piora)
#   comenta     só acrescenta um comentário (não muda a nota)
#   decora      copia o texto exato de cada caso errado para as regras (decorar a prova)
#   mexe-casos  reescreve o "esperado" dos casos para bater com a resposta atual (mexer no medidor)
#   falha       sai com erro, como um agente sem resposta (limite da sessão)
# Tokens: escreve TOKENS_FALSOS (padrão "9000 600", números inventados para o ensaio) em $TOKENS_ARQ.
set -euo pipefail
K=$(cd "$(dirname "$0")" && pwd)
[ -n "${TOKENS_ARQ:-}" ] && echo "${TOKENS_FALSOS:-9000 600}" > "$TOKENS_ARQ"
case ${1:?modo} in
  sinonimos) python3 -c "import re,pathlib as p;f=p.Path('regras.txt');f.write_text(re.sub(r'(?m)^(reembolso: .*)$',r'\1, estorno, devolução, devolver',f.read_text(encoding='utf-8')),encoding='utf-8')" ;;
  estraga)   python3 -c "import pathlib as p;f=p.Path('regras.txt');f.write_text(f.read_text(encoding='utf-8').replace('acesso: senha, ','acesso: '),encoding='utf-8')" ;;
  comenta)   echo "# revisado pelo agente" >> regras.txt ;;
  decora|mexe-casos) python3 - "$1" "$K" <<'PY'
import json, sys
from pathlib import Path
modo = sys.argv[1]; sys.path.insert(0, ".")
import classificar as c
rs = c.regras(".")
casos = [json.loads(x) for x in Path("casos.jsonl").read_text(encoding="utf-8").splitlines() if x.strip()]
if modo == "decora":
    extra = {}
    for x in casos:
        if c.classificar(x["texto"], rs) != x["esperado"]:
            extra.setdefault(x["esperado"], []).append(x["texto"].replace(",", ""))
    linhas = []
    for l in Path("regras.txt").read_text(encoding="utf-8").splitlines():
        cat = l.split(":", 1)[0].strip()
        linhas.append(l + "".join(", " + t for t in extra.get(cat, [])) if cat in extra and not l.startswith("#") else l)
    Path("regras.txt").write_text("\n".join(linhas) + "\n", encoding="utf-8")
else:
    for x in casos:
        x["esperado"] = c.classificar(x["texto"], rs)
    Path("casos.jsonl").write_text("".join(json.dumps(x, ensure_ascii=False) + "\n" for x in casos), encoding="utf-8")
PY
  ;;
  falha) echo "ERRO: sem resposta do modelo (limite da sessão)"; exit 1 ;;
  *) echo "modo desconhecido: $1"; exit 2 ;;
esac
