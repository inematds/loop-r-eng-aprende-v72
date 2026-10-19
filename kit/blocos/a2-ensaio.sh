K=~/projetos/loop-r-eng-aprende-v72/kit
E=${TMPDIR:-/tmp}/ensaio-aprende/a2
bash $K/novo-sistema.sh $E/sis
for m in sinonimos estraga comenta; do
  AGENTE="bash $K/agente-falso.sh $m" bash $K/experimento.sh $E/sis "$m"; echo "saída: $?"
done
echo "## results.tsv"; cut -f1,3- $E/sis/results.tsv
echo "## git log"; git -C $E/sis log --format=%s