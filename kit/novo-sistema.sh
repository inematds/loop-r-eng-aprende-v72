#!/usr/bin/env bash
# novo-sistema.sh — cria o repo de ensaio: o classificador de triagem (v1), os casos visíveis e um commit de base.
# Uso: bash novo-sistema.sh <pasta>     (apaga e recria a pasta; use só pasta de ensaio)
# Só apaga pasta vazia ou que ele mesmo criou (marca .git/ensaio-aprende); qualquer outra, recusa com saída 2.
set -euo pipefail
K=$(cd "$(dirname "$0")" && pwd); R=${1:?uso: novo-sistema.sh <pasta>}
if [ -n "$(ls -A "$R" 2>/dev/null)" ] && [ ! -e "$R/.git/ensaio-aprende" ]; then
  echo "ERRO: $R já existe e não foi criada pelo novo-sistema.sh; não apago (use uma pasta de ensaio nova)"; exit 2
fi
rm -rf "$R"; mkdir -p "$R"
cp "$K/triagem/classificar.py" "$K/triagem/regras.txt" "$K/triagem/casos.jsonl" "$R/"
printf 'results.tsv\nrastros.jsonl\n__pycache__/\n.sil/\n' > "$R/.gitignore"
printf 'ciclo\tcommit\tbase\tnovo\tstatus\tdescricao\n' > "$R/results.tsv"
cd "$R"
git init -q -b main; touch .git/ensaio-aprende
git -c user.name=ensaio -c user.email=ensaio@exemplo.invalid add -A
git -c user.name=ensaio -c user.email=ensaio@exemplo.invalid commit -q -m "v1: regras de base"
echo "sistema criado em $R ($(python3 "$K/medir.py" .))"
