#!/usr/bin/env python3
"""loopr.py — veredito A/B, cartão de decisão, promoção e rollback, no desenho do LOOP-R (loop-r/.claude/skills/loop-r).

  python3 loopr.py iniciar  <loop> --v1 <prompt.md> --candidata <prompt.md>   pasta versoes/{v1,candidata-vB}, atual → v1, ledger, git
  python3 loopr.py veredito <loop> --csv <execucoes.csv> --de AAAA-MM-DD --ate AAAA-MM-DD --metrica <coluna>
                            --minimo N [--vigiar coluna:tolerancia ...]               grava <loop>/veredito.md
  python3 loopr.py cartao   <loop> --hipotese "<título>" [--tokens N]           o cartão de 5 linhas
  python3 loopr.py decidir  <loop> aprovado|rejeitado|esperar --por "<nome>"   grava <loop>/decisao.md
  python3 loopr.py promover <loop>                                            exige B_GANHOU + aprovado
  python3 loopr.py reverter <loop> --motivo "<motivo>"                        atual volta; a pasta fica
Saída 0 = feito/B_GANHOU; 1 = recusado ou A_SEGUE/AMOSTRA_INSUFICIENTE; 2 = erro de uso.
Teste z para duas proporções (variância agrupada), bicaudal, 95%. Valores "sim" contam como 1.
"""
import csv
import datetime
import math
import os
import subprocess
import sys
from pathlib import Path


def arg(a, nome, padrao=None):
    return a[a.index(nome) + 1] if nome in a else padrao


def git(loop, *cmd):
    subprocess.run(["git", "-C", str(loop), "-c", "user.name=loop-r", "-c", "user.email=loop-r@exemplo.invalid", *cmd],
                   check=True, capture_output=True, text=True)


def ledger(loop, linha):
    with open(loop / "memoria/ledger.md", "a", encoding="utf-8") as f:
        f.write(f"| {datetime.date.today()} | {linha} |\n")


def atual(loop):
    return os.readlink(loop / "versoes/atual")


def iniciar(loop, a):
    (loop / "versoes/v1").mkdir(parents=True, exist_ok=True)
    (loop / "versoes/candidata-vB").mkdir(parents=True, exist_ok=True)
    (loop / "memoria").mkdir(exist_ok=True)
    (loop / "versoes/v1/executor.prompt.md").write_text(Path(arg(a, "--v1")).read_text(encoding="utf-8"), encoding="utf-8")
    (loop / "versoes/candidata-vB/executor.prompt.md").write_text(Path(arg(a, "--candidata")).read_text(encoding="utf-8"), encoding="utf-8")
    os.symlink("v1", loop / "versoes/atual")
    (loop / "memoria/ledger.md").write_text("# Ledger\n\n| data | evento |\n|---|---|\n", encoding="utf-8")
    ledger(loop, "PROMOVIDA v1 — versão de base")
    subprocess.run(["git", "init", "-q", "-b", "main", str(loop)], check=True)
    git(loop, "add", "-A")
    git(loop, "commit", "-q", "-m", "loop-r: iniciar")
    print(f"loop iniciado: versoes/atual → {atual(loop)}")
    return 0


def taxa(linhas, col):
    s = sum(1 for x in linhas if x[col].strip().lower() == "sim")
    return s, len(linhas)


def veredito(loop, a):
    de, ate, met, minimo = arg(a, "--de"), arg(a, "--ate"), arg(a, "--metrica"), int(arg(a, "--minimo"))
    vig = [a[i + 1] for i, x in enumerate(a) if x == "--vigiar"]
    rows = [x for x in csv.DictReader(open(arg(a, "--csv"), encoding="utf-8")) if de <= x["data"] <= ate]
    A = [x for x in rows if x["variante"] == "A"]
    B = [x for x in rows if x["variante"] == "B"]
    (sa, na), (sb, nb) = taxa(A, met), taxa(B, met)
    pa, pb = sa / na if na else 0, sb / nb if nb else 0
    p = (sa + sb) / (na + nb) if na + nb else 0
    se = math.sqrt(p * (1 - p) * (1 / na + 1 / nb)) if na and nb else 0
    z = (pb - pa) / se if se else 0
    pv = math.erfc(abs(z) / math.sqrt(2))
    out = [f"Métrica do teste: {met}  A={pa:.4f} ({sa}/{na})  B={pb:.4f} ({sb}/{nb})  z={z:.4f} p={pv:.4f}"]
    caiu = []
    for v in vig:
        col, tol = v.split(":")
        (xa, _), (xb, _) = taxa(A, col), taxa(B, col)
        d = xb / nb - xa / na
        ok = d <= float(tol)   # colunas vigiadas aqui são eventos ruins (reclamação, opt-out): subir é piorar
        out.append(f"Vigiada {col}: A {xa}/{na} vs B {xb}/{nb}, Δ={d:+.4f} tol {float(tol):g} → {'DENTRO' if ok else 'FALHA'}")
        if not ok:
            caiu.append(col)
    if min(na, nb) < minimo:
        v = "AMOSTRA_INSUFICIENTE"
    elif z > 1.959964 and not caiu:
        v = "B_GANHOU"
    else:
        v = "A_SEGUE"
    (loop / "veredito.md").write_text(f"VEREDITO: {v}\n" + "\n".join(out) + "\n", encoding="utf-8")
    print(f"VEREDITO: {v}")
    print("\n".join(out))
    return 0 if v == "B_GANHOU" else 1


def cartao(loop, a):
    linhas = (loop / "veredito.md").read_text(encoding="utf-8").splitlines()
    met = linhas[1].split()
    vig = " · ".join(l.split(":")[0].replace("Vigiada ", "") + (" ok" if "DENTRO" in l else " caiu") for l in linhas[2:])
    tok = arg(a, "--tokens")
    print(f"CICLO — hipótese: \"{arg(a, '--hipotese')}\"")
    print(f"Resultado:   {met[3]} {met[4].split('=')[1]} → {met[6].split('=')[1]}  ({met[5]} vs {met[7]}, {met[8]}, {met[9]})  [{linhas[0]}]")
    print(f"Vigiado:     {vig or '—'}")
    print(f"Custo:       {int(tok):,} tokens neste ciclo (sai da cota)".replace(",", ".") if tok else "Custo:       não medido")
    print("Decisão:     aprovar / rejeitar / esperar mais dados")
    return 0


def decidir(loop, a):
    d = a[1]
    if d not in ("aprovado", "rejeitado", "esperar") or not arg(a, "--por"):
        print("uso: decidir <loop> aprovado|rejeitado|esperar --por <nome>")
        return 2
    (loop / "decisao.md").write_text(f"{d} — {datetime.date.today()} — {arg(a, '--por')}\n", encoding="utf-8")
    print(f"decisão gravada: {d}")
    return 0


def promover(loop, a):
    v = (loop / "veredito.md").read_text(encoding="utf-8").split()[1] if (loop / "veredito.md").exists() else "nenhum"
    d = (loop / "decisao.md").read_text(encoding="utf-8").split()[0] if (loop / "decisao.md").exists() else "nenhuma"
    if v != "B_GANHOU" or d != "aprovado":
        print(f"RECUSADO: promover exige veredito B_GANHOU e decisão aprovado (veredito: {v}; decisão: {d})")
        return 1
    n = 1 + max(int(p.name[1:]) for p in (loop / "versoes").glob("v[0-9]*"))
    (loop / "versoes/candidata-vB").rename(loop / f"versoes/v{n}")
    os.remove(loop / "versoes/atual")
    os.symlink(f"v{n}", loop / "versoes/atual")
    ledger(loop, f"PROMOVIDA v{n} — {v}, decisão {d}")
    (loop / "veredito.md").rename(loop / f"versoes/v{n}/veredito.md")
    (loop / "decisao.md").rename(loop / f"versoes/v{n}/decisao.md")
    git(loop, "add", "-A")
    git(loop, "commit", "-q", "-m", f"loop-r: promote v{n}")
    print(f"PROMOVIDA: versoes/atual → v{n}")
    return 0


def reverter(loop, a):
    motivo = arg(a, "--motivo")
    if not motivo:
        print("RECUSADO: rollback pede --motivo (vai para o ledger)")
        return 1
    agora = atual(loop)
    promovidas = [l.split("PROMOVIDA ")[1].split()[0] for l in (loop / "memoria/ledger.md").read_text(encoding="utf-8").splitlines() if "PROMOVIDA " in l]
    anteriores = promovidas[:promovidas.index(agora)] if agora in promovidas else []
    if not anteriores:
        print(f"RECUSADO: não há versão promovida antes de {agora}")
        return 1
    alvo = anteriores[-1]
    os.remove(loop / "versoes/atual")
    os.symlink(alvo, loop / "versoes/atual")
    ledger(loop, f"ROLLBACK {agora} → {alvo} — {motivo}")
    git(loop, "add", "-A")
    git(loop, "commit", "-q", "-m", f"loop-r: rollback {agora} → {alvo}")
    print(f"ROLLBACK: versoes/atual → {alvo} (a pasta {agora} continua lá)")
    return 0


def main(a):
    cmds = dict(iniciar=iniciar, veredito=veredito, cartao=cartao, decidir=decidir, promover=promover, reverter=reverter)
    if len(a) < 2 or a[0] not in cmds:
        print(__doc__)
        return 2
    return cmds[a[0]](Path(a[1]), a[1:])


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
