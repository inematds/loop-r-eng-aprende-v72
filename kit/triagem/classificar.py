#!/usr/bin/env python3
"""classificar.py — o "sistema" que o loop melhora: triagem de mensagens de suporte por palavras de regras.txt.

  python3 classificar.py "esqueci minha senha"   → acesso
A primeira categoria cuja palavra aparece no texto vence; sem nenhuma, "outros". Dados de treino sintéticos.
"""
import sys
from pathlib import Path


def regras(pasta="."):
    out = []
    for linha in (Path(pasta) / "regras.txt").read_text(encoding="utf-8").splitlines():
        if ":" in linha and not linha.lstrip().startswith("#"):
            cat, palavras = linha.split(":", 1)
            out.append((cat.strip(), [p.strip().lower() for p in palavras.split(",") if p.strip()]))
    return out


def classificar(texto, rs):
    t = texto.lower()
    for cat, palavras in rs:
        if any(p in t for p in palavras):
            return cat
    return "outros"


if __name__ == "__main__":
    print(classificar(" ".join(sys.argv[1:]), regras()))
