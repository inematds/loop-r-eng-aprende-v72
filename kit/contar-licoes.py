#!/usr/bin/env python3
"""contar-licoes.py — mede o loop de lições "em prosa" de um projeto: LESSONS.md, FALHAS.md, LIMITES.md e a seção Lessons do CLAUDE.md/AGENTS.md.

  python3 contar-licoes.py <pasta>
Só conta (linhas, marcas, colunas); não imprime nenhuma linha dos arquivos. Saída 0 sempre que leu a pasta.
"""
import re
import sys
from pathlib import Path


def ler(p):
    return p.read_text(encoding="utf-8", errors="replace").splitlines() if p.exists() else None


def main(a):
    if not a or not Path(a[0]).is_dir():
        print("uso: contar-licoes.py <pasta>")
        return 2
    d = Path(a[0])
    achou = False
    for nome in ("CLAUDE.md", "AGENTS.md"):
        ls = ler(d / nome)
        if ls is None:
            continue
        achou = True
        dentro, n = False, 0
        for l in ls:
            if l.startswith("## "):
                dentro = l.strip().lower() in ("## lessons", "## lições", "## licoes")
            elif dentro and l.startswith("- "):
                n += 1
        print(f"{nome}: {len(ls)} linhas, {n} lições na seção Lessons")
    ls = ler(d / "LESSONS.md")
    if ls is not None:
        achou = True
        itens = [l for l in ls if l.startswith("- ")]
        rep = sum(1 for l in itens if re.search(r"REPETID|de novo|outra vez", l, re.I))
        ids = sum(1 for l in itens if re.match(r"- \[?L\d+", l))
        print(f"LESSONS.md: {len(itens)} lições · {rep} marcadas como repetidas · {ids} com ID")
    ls = ler(d / "FALHAS.md")
    if ls is not None:
        achou = True
        rows = [l for l in ls if re.match(r"\|\s*\d{4}-\d{2}-\d{2}", l)]
        tipo = [l.rstrip().rstrip("|").split("|")[-1].lower() for l in rows]
        pr = sum(1 for t in tipo if "prompt" in t)
        inf = sum(1 for t in tipo if "infra" in t)
        print(f"FALHAS.md: {len(rows)} falhas · {pr} prompt · {inf} infra (as duas contam quando a linha diz as duas)")
    ls = ler(d / "LIMITES.md")
    if ls is not None:
        achou = True
        rows = [l for l in ls if re.match(r"\|\s*\d{4}-\d{2}-\d{2}", l)]
        ab = sum(1 for l in rows if re.search(r"\|\s*aberto\s*\|?\s*$", l, re.I))
        print(f"LIMITES.md: {len(rows)} limites · {ab} ainda 'aberto'")
    sil = (d / ".sil").exists()
    print(f"SIL Loop R: {'iniciado' if sil else 'não iniciado'} nesta pasta")
    if not achou:
        print("nenhum arquivo de lições aqui")
    elif not sil:
        print("degrau: prosa — sem decisão registrada, sem data de revisão, sem citação")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
