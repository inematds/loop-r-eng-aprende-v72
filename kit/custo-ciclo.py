#!/usr/bin/env python3
"""custo-ciclo.py — lê o rastro do loop (uma linha JSON por ciclo) e mostra custo por ciclo, custo por keep e os alertas.

  python3 custo-ciclo.py <rastros.jsonl> [--teto TOKENS_POR_CICLO] [--sem-keep N] [--erros-iguais N]
Alertas no espírito do meta-agente do LOOP-R (.claude/agents/meta-agente.md): ciclo acima de 80% do teto,
N ciclos seguidos sem keep, N erros seguidos com o mesmo motivo (laço de erro). Só relata; não age.
Saída 0 = sem alerta; 1 = há alerta; 2 = erro de uso.
"""
import json
import sys
from pathlib import Path


def arg(a, nome, padrao):
    return type(padrao)(a[a.index(nome) + 1]) if nome in a else padrao


def main(a):
    if not a or not Path(a[0]).exists():
        print("uso: custo-ciclo.py <rastros.jsonl> [--teto N] [--sem-keep N] [--erros-iguais N]")
        return 2
    teto, semkeep, iguais = arg(a, "--teto", 0), arg(a, "--sem-keep", 5), arg(a, "--erros-iguais", 3)
    cs = [json.loads(l) for l in Path(a[0]).read_text(encoding="utf-8").splitlines() if l.strip()]
    print("ciclo  status   segundos  tokens(ent+saída)  motivo")
    total, alertas = 0, []
    for c in cs:
        t = (c.get("tokens_entrada") or 0) + (c.get("tokens_saida") or 0)
        total += t
        tt = f"{t}" if c.get("tokens_entrada") is not None else "não informado"
        print(f"{c['ciclo']:>5}  {c['status']:<7}  {c['segundos']:>8}  {tt:>17}  {c['motivo'][:48]}")
        if teto and t > 0.8 * teto:
            alertas.append(f"ciclo {c['ciclo']} usou {100 * t // teto}% do teto de {teto} tokens")
    keeps = sum(1 for c in cs if c["status"] == "keep")
    print(f"total: {len(cs)} ciclos · {keeps} keep · {total} tokens")
    print(f"custo por keep: {total // keeps} tokens" if keeps else "custo por keep: sem keep ainda")
    seguidos = 0
    for c in reversed(cs):
        if c["status"] == "keep":
            break
        seguidos += 1
    if seguidos >= semkeep:
        alertas.append(f"{seguidos} ciclos seguidos sem keep")
    run = 1
    for x, y in zip(cs, cs[1:]):
        run = run + 1 if (y["status"] == "erro" and x["status"] == "erro" and x["motivo"] == y["motivo"]) else 1
        if run == iguais:
            alertas.append(f"{iguais} erros seguidos iguais: {y['motivo'][:60]}")
    for al in alertas:
        print("ALERTA: " + al)
    if not alertas:
        print("sem alerta")
    return 1 if alertas else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
