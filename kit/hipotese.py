#!/usr/bin/env python3
"""hipotese.py — confere se uma hipótese tem número antes de virar experimento.

  python3 hipotese.py <hipotese.md>                     # confere os campos
  python3 hipotese.py <hipotese.md> --por-semana 50     # teste A/B em produção: amostra mínima e semanas

Campos (uma linha cada, "campo: valor"): hipótese, métrica, atual, alvo, direção, medida por, sem piorar.
"atual" e "alvo" são números (0.20 ou 20%). Saída 0 = OK; 1 = reprovada; 2 = erro de uso.
Amostra mínima: teste z para duas proporções, 95% de confiança e 80% de poder (loop-r/docs/05 §3).
"""
import math
import re
import sys
from pathlib import Path

CAMPOS = ["hipótese", "métrica", "atual", "alvo", "direção", "medida por", "sem piorar"]
VAGAS = ["melhorar", "otimizar", "mais rápido", "melhor", "aumentar"]


def numero(v):
    v = v.strip().replace(",", ".")
    m = re.fullmatch(r"(-?\d+(?:\.\d+)?)\s*(%?)", v)
    if not m:
        return None
    x = float(m.group(1))
    return x / 100 if m.group(2) else x


def amostra(p1, p2, za=1.959964, zb=0.841621):
    pm = (p1 + p2) / 2
    n = (za * math.sqrt(2 * pm * (1 - pm)) + zb * math.sqrt(p1 * (1 - p1) + p2 * (1 - p2))) ** 2 / (p1 - p2) ** 2
    return math.ceil(n)


def main(a):
    if not a or not Path(a[0]).exists():
        print("uso: hipotese.py <hipotese.md> [--por-semana N]")
        return 2
    texto = Path(a[0]).read_text(encoding="utf-8")
    h = {}
    for linha in texto.splitlines():
        if ":" in linha:
            k, v = linha.split(":", 1)
            h[k.strip().lower().lstrip("-# ").strip()] = v.strip()
    falta = [c for c in CAMPOS if not h.get(c)]
    problemas = []
    atual, alvo = numero(h.get("atual", "")), numero(h.get("alvo", ""))
    if h.get("atual") and atual is None:
        problemas.append("atual não é número")
    if h.get("alvo") and alvo is None:
        problemas.append("alvo não é número")
    if h.get("direção") and h["direção"] not in ("maximizar", "minimizar"):
        problemas.append("direção é maximizar ou minimizar")
    if atual is not None and alvo is not None and h.get("direção") in ("maximizar", "minimizar"):
        if (alvo > atual) != (h["direção"] == "maximizar"):
            problemas.append("alvo na direção errada")
    if h.get("hipótese") and not re.search(r"\d", h["hipótese"]) and any(w in h["hipótese"].lower() for w in VAGAS) and not h.get("alvo"):
        problemas.append("hipótese vaga sem número")
    if falta or problemas:
        print("HIPÓTESE: REPROVADA")
        if falta:
            print("  falta: " + ", ".join(falta))
        for p in problemas:
            print("  " + p)
        return 1
    print(f"HIPÓTESE: OK — {h['métrica']}: {atual:g} → {alvo:g} ({h['direção']})")
    print(f"  medida por: {h['medida por']}")
    print(f"  sem piorar: {h['sem piorar']}")
    if "--por-semana" in a:
        vol = float(a[a.index("--por-semana") + 1])
        if not (0 < atual < 1 and 0 < alvo < 1):
            print("  amostra: só para proporção (entre 0 e 1)")
            return 1
        n = amostra(atual, alvo)
        semanas = math.ceil(2 * n / vol)
        print(f"  amostra mínima: {n} por variante (95%, poder 80%) — {2 * n} no total")
        print(f"  com {vol:g} por semana: {semanas} semanas")
        if semanas > 12:
            print("  AVISO: mais de 12 semanas — teste uma métrica de sinal mais rápida e vigie esta")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
