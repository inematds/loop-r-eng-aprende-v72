#!/usr/bin/env bash
# capturar.sh — roda cada bloco "Terminal" do curso (kit/blocos/*.sh) e grava a saída em kit/saidas/.
# É daqui que saem as abas "Saída capturada" das aulas. Sem argumento: só os ensaios (sem modelo, sem placeholder).
# Uso: TMPDIR=<pasta> bash capturar.sh          # ensaios, na ordem (a5 depende de a4)
#      TMPDIR=<pasta> bash capturar.sh a2-real  # um bloco qualquer (os *-real chamam o modelo: saem da cota)
# A pasta temporária aparece como /tmp na saída gravada (o aluno roda sem TMPDIR).
set -uo pipefail
K=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$K/saidas"
alvos=("$@"); [ ${#alvos[@]} -eq 0 ] && alvos=($(cd "$K/blocos" && ls *.sh | grep -v -e '-real' -e 'a4-contar' | sed 's/\.sh$//'))
for b in "${alvos[@]}"; do
  ( cd /tmp && bash "$K/blocos/$b.sh" ) 2>&1 | sed "s#${TMPDIR:-/tmp}#/tmp#g" > "$K/saidas/$b.txt"
  echo "$b: $(wc -l < "$K/saidas/$b.txt") linhas"
done
