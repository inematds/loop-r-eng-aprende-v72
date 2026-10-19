#!/usr/bin/env python3
"""hashes.py — congela e confere o medidor (mesmo formato do sha256sum, sem depender dele: roda em Linux e macOS).

  python3 hashes.py congelar <manifesto> <arquivo>...   grava "hash  caminho" (caminho como foi passado)
  python3 hashes.py conferir <manifesto>                saída 0 = igual; 1 = algum arquivo mudou ou sumiu
Caminhos relativos valem a partir da pasta atual.
"""
import hashlib
import sys
from pathlib import Path


def h(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def main(a):
    if len(a) >= 3 and a[0] == "congelar":
        Path(a[1]).write_text("".join(f"{h(p)}  {p}\n" for p in a[2:]), encoding="utf-8")
        return 0
    if len(a) == 2 and a[0] == "conferir":
        ruins = []
        for linha in Path(a[1]).read_text(encoding="utf-8").splitlines():
            dig, p = linha.split("  ", 1)
            if not Path(p).exists() or h(p) != dig:
                ruins.append(p)
        for p in ruins:
            print(f"MUDOU: {p}")
        return 1 if ruins else 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
