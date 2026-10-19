K=~/projetos/loop-r-eng-aprende-v72/kit
E=${TMPDIR:-/tmp}/ensaio-aprende/a6; rm -rf $E; mkdir -p $E
echo "## sem guarda: a métrica sobe e o sistema não melhora"
for m in decora mexe-casos; do
  bash $K/novo-sistema.sh $E/sis > /dev/null
  AGENTE="bash $K/agente-falso.sh $m" bash $K/experimento.sh $E/sis "$m"
  echo "  nos casos escondidos: $(python3 $K/medir.py $E/sis --casos $K/triagem/escondidos.jsonl)"
done
echo "## com guarda: medidor congelado fora do repo + casos que o agente não vê"
bash $K/novo-sistema.sh $E/sis > /dev/null; bash $K/experimento.sh --congelar $E/sis $E/medidor.sha256
export GUARDA=$E/medidor.sha256 ESCONDIDOS=$K/triagem/escondidos.jsonl
for m in mexe-casos decora sinonimos; do
  AGENTE="bash $K/agente-falso.sh $m" bash $K/experimento.sh $E/sis "$m"; echo "saída: $?"
done