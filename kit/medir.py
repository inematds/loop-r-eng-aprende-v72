#!/usr/bin/env python3
"""medir.py — a métrica única do experimento: acerto do classificador do repo nos casos.

  python3 medir.py <repo>                       → acerto: 0.700 (28/40)
  python3 medir.py <repo> --valor               → 0.700
  python3 medir.py <repo> --casos <arquivo>     (padrão: <repo>/casos.jsonl)
  python3 medir.py <repo> --erros               lista os casos errados
Saída 0 = mediu; 2 = o sistema quebrou (sem casos, regras ilegíveis, erro do classificador).
"""
import importlib.util
import json
import sys
from pathlib import Path


def carregar(repo):
    spec = importlib.util.spec_from_file_location("classificar", Path(repo) / "classificar.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main(a):
    if not a:
        print("uso: medir.py <repo> [--casos arquivo] [--valor] [--erros]")
        return 2
    repo = Path(a[0])
    casos = Path(a[a.index("--casos") + 1]) if "--casos" in a else repo / "casos.jsonl"
    try:
        mod = carregar(repo)
        rs = mod.regras(repo)
        linhas = [json.loads(x) for x in casos.read_text(encoding="utf-8").splitlines() if x.strip()]
        ruins = [c for c in linhas if mod.classificar(c["texto"], rs) != c["esperado"]]
    except Exception as e:  # sistema quebrado não é nota zero: é erro
        print(f"ERRO na medida: {type(e).__name__}: {e}")
        return 2
    ok = len(linhas) - len(ruins)
    valor = ok / len(linhas) if linhas else 0.0
    if "--valor" in a:
        print(f"{valor:.3f} {ok} {len(linhas)}")
    else:
        print(f"acerto: {valor:.3f} ({ok}/{len(linhas)})")
    if "--erros" in a:
        for c in ruins:
            print(f"  errou: {c['texto']} → {mod.classificar(c['texto'], rs)} (esperado {c['esperado']})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
