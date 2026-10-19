#!/usr/bin/env python3
"""conferir-loop.py — confere as oito peças do loop que aprende numa pasta de projeto (uma por aula do curso).

  python3 conferir-loop.py <pasta> [--sil <caminho do sil.py>]
A pasta tem loop.conf (KEY=valor): SISTEMA (repo do experimento, padrão a pasta), LOOP (pasta com versoes/ e
memoria/, padrão a pasta), GUARDA, ESCONDIDOS, RASTRO, TETO_TOKENS, APROVADOR.
Saída 0 = 8/8; 1 = falta peça; 2 = erro de uso.
"""
import json
import os
import subprocess
import sys
from pathlib import Path

K = Path(__file__).resolve().parent


def conf(d):
    c = {}
    p = d / "loop.conf"
    if p.exists():
        for l in p.read_text(encoding="utf-8").splitlines():
            if "=" in l and not l.lstrip().startswith("#"):
                k, v = l.split("=", 1)
                v = v.split(" #", 1)[0]
                c[k.strip()] = os.path.expanduser(os.path.expandvars(v.strip().strip('"')))
    return c


def roda(*cmd, cwd=None):
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=cwd)
    return r.returncode, r.stdout


def main(a):
    if not a or not Path(a[0]).is_dir():
        print("uso: conferir-loop.py <pasta> [--sil caminho/sil.py]")
        return 2
    d = Path(a[0]).resolve()
    sil = a[a.index("--sil") + 1] if "--sil" in a else os.path.expanduser("~/projetos/sil-loop-r/sil.py")
    c = conf(d)
    pecas = []

    rc, _ = roda(sys.executable, str(K / "hipotese.py"), str(d / "hipotese.md")) if (d / "hipotese.md").exists() else (1, "")
    pecas.append(("1 hipótese com número", rc == 0, "hipotese.md passa no hipotese.py"))
    sis, lp = Path(c.get("SISTEMA") or d), Path(c.get("LOOP") or d)
    n = len((sis / "results.tsv").read_text(encoding="utf-8").splitlines()) - 1 if (sis / "results.tsv").exists() else 0
    pecas.append(("2 experimento keep/discard", n >= 1, f"results.tsv com {max(n, 0)} ciclo(s)"))
    led = lp / "memoria/ledger.md"
    ok = (lp / "versoes/atual").is_symlink() and led.exists() and "PROMOVIDA" in led.read_text(encoding="utf-8")
    pecas.append(("3 promoção e rollback", ok, "versoes/atual + ledger com PROMOVIDA"))
    regras, sinc = 0, False
    if (d / ".sil").exists() and Path(sil).exists():
        _, out = roda(sys.executable, sil, "--project", str(d), "export")
        try:
            regras = sum(1 for r in json.loads(out).get("rules", []) if r.get("status") == "active")
        except ValueError:
            regras = 0
        rc, out = roda(sys.executable, sil, "--project", str(d), "check")
        try:
            sinc = rc == 0 and json.loads(out)["promotion"]["in_sync"]
        except (ValueError, KeyError):
            sinc = False
    pecas.append(("4 lições com decisão (SIL)", regras >= 1, f"{regras} regra(s) ativa(s) no SIL"))
    bloco = any("sil-loop-r:begin" in (d / f).read_text(encoding="utf-8") for f in ("AGENTS.md", "CLAUDE.md") if (d / f).exists())
    pecas.append(("5 regra vinculante no AGENTS.md", bloco and sinc, "bloco promovido e check sem pendência"))
    g, e = c.get("GUARDA", ""), c.get("ESCONDIDOS", "")
    gok = bool(g) and Path(g).exists() and sis.resolve() not in Path(g).resolve().parents and roda(sys.executable, str(K / "hashes.py"), "conferir", g, cwd=sis)[0] == 0
    eok = bool(e) and Path(e).exists() and sis.resolve() not in Path(e).resolve().parents
    pecas.append(("6 medidor fora do alcance", gok and eok, "GUARDA confere e ESCONDIDOS fora da pasta"))
    r = c.get("RASTRO", "")
    rok = bool(r) and Path(r).exists() and Path(r).stat().st_size > 0
    pecas.append(("7 rastro por ciclo", rok, "RASTRO com pelo menos um ciclo"))
    pecas.append(("8 teto e aprovador", bool(c.get("TETO_TOKENS")) and bool(c.get("APROVADOR")), "TETO_TOKENS e APROVADOR no loop.conf"))

    feitas = sum(1 for _, ok, _ in pecas if ok)
    for nome, ok, como in pecas:
        print(f"{'OK   ' if ok else 'FALTA'}  {nome}  ({como})")
    print(f"LOOP: {feitas}/8 — " + ("PRONTO" if feitas == 8 else "FALTAM " + ", ".join(n.split(' ', 1)[0] for n, ok, _ in pecas if not ok)))
    return 0 if feitas == 8 else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
