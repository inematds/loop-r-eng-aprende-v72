#!/usr/bin/env bash
# montar.sh — monta no ensaio as oito peças do loop que aprende (o que as aulas 1 a 7 fizeram), sem chamar modelo.
# Uso: bash montar.sh <pasta>      (apaga e recria <pasta> e <pasta>-fora; use só pasta de ensaio)
# Precisa de: ~/projetos/sil-loop-r (SIL=…/sil.py para outro lugar) e ~/projetos/loop-r (LOOPR=… para outro lugar).
set -euo pipefail
K=$(cd "$(dirname "$0")" && pwd); D=${1:?uso: montar.sh <pasta>}
SIL=${SIL:-$HOME/projetos/sil-loop-r/sil.py}; X=${LOOPR:-$HOME/projetos/loop-r}/exemplos/vendas-whatsapp
FORA=$D-fora   # fora do repo do sistema: medidor congelado, casos escondidos, rastro, versões promovidas
s() { python3 "$SIL" --project "$D" "$@" > /dev/null; }
g() { git -C "$D" -c user.name=ensaio -c user.email=ensaio@exemplo.invalid "$@"; }

if [ -n "$(ls -A "$FORA" 2>/dev/null)" ] && [ ! -e "$FORA/.ensaio-aprende" ]; then   # só apaga o que ele criou
  echo "ERRO: $FORA já existe e não foi criada pelo montar.sh; não apago"; exit 2
fi
bash "$K/novo-sistema.sh" "$D" > /dev/null; rm -rf "$FORA"; mkdir -p "$FORA"; touch "$FORA/.ensaio-aprende"
cp "$K/hipoteses/triagem.md" "$D/hipotese.md"                                   # peça 1
cp "$K/triagem/escondidos.jsonl" "$FORA/"
cat > "$D/loop.conf" <<EOF
LOOP=$FORA/promocao
GUARDA=$FORA/medidor.sha256
ESCONDIDOS=$FORA/escondidos.jsonl
RASTRO=$FORA/rastros.jsonl
TETO_TOKENS=50000
APROVADOR=Seu Nome
EOF
echo "# Instruções do projeto" > "$D/AGENTS.md"
g add -A; g commit -q -m "loop: hipótese, loop.conf e AGENTS.md"
bash "$K/experimento.sh" --congelar "$D" "$FORA/medidor.sha256" > /dev/null    # peça 6
GUARDA=$FORA/medidor.sha256 ESCONDIDOS=$FORA/escondidos.jsonl RASTRO=$FORA/rastros.jsonl \
  AGENTE="bash $K/agente-falso.sh sinonimos" bash "$K/experimento.sh" "$D" "sinonimos" > /dev/null   # peças 2 e 7
L=$FORA/promocao                                                                 # peça 3
python3 "$K/loopr.py" iniciar "$L" --v1 "$X/versoes/v1/executor.prompt.md" --candidata "$X/versoes/v2/executor.prompt.md" > /dev/null
python3 "$K/loopr.py" veredito "$L" --csv "$X/dados/execucoes.csv" --de 2026-05-04 --ate 2026-07-26 \
  --metrica resposta --minimo 212 --vigiar reclamou:0.01 --vigiar optout:0.005 > /dev/null
python3 "$K/loopr.py" decidir "$L" aprovado --por "Seu Nome" > /dev/null
python3 "$K/loopr.py" promover "$L" > /dev/null
s init; s config --approval-batch 1                                              # peça 4
s occurrence --title "porta ocupada" --evidence "teste HTTP falhou: address already in use" --correction "checar a porta antes"
s lesson --occurrence O0001 --proposal "checar a porta antes de subir servidor" --scope "testes HTTP"
s request
s decide L0001 adopt --approved-by "Seu Nome" --reason "falhou duas vezes; correção comprovada"
s enforce R0001 --binding yes --rung prose --leak "sessão que não lê o AGENTS.md" \
  --approved-by "Seu Nome" --reason "porta ocupada derruba o servidor de outra sessão"   # peça 5
s promote --write
g commit -q -am "loop: regra vinculante promovida no AGENTS.md"
echo "loop montado em $D (fora do repo: $FORA)"
