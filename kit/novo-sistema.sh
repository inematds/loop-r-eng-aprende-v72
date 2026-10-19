#!/usr/bin/env bash
# novo-sistema.sh — cria o repo de ensaio: o classificador de triagem (v1), os casos visíveis e um commit de base.
# Uso: bash novo-sistema.sh <pasta>     (apaga e recria a pasta; use só pasta de ensaio)
set -euo pipefail
K=$(cd "$(dirname "$0")" && pwd); R=${1:?uso: novo-sistema.sh <pasta>}
rm -rf "$R"; mkdir -p "$R"
cp "$K/triagem/classificar.py" "$K/triagem/regras.txt" "$K/triagem/casos.jsonl" "$R/"
printf 'results.tsv\nrastros.jsonl\n__pycache__/\n.sil/\n' > "$R/.gitignore"
printf 'ciclo\tcommit\tbase\tnovo\tstatus\tdescricao\n' > "$R/results.tsv"
cd "$R"
git init -q -b main
git -c user.name=ensaio -c user.email=ensaio@exemplo.invalid add -A
git -c user.name=ensaio -c user.email=ensaio@exemplo.invalid commit -q -m "v1: regras de base"
echo "sistema criado em $R ($(python3 "$K/medir.py" .))"
