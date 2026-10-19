K=~/projetos/loop-r-eng-aprende-v72/kit
E=${TMPDIR:-/tmp}/ensaio-aprende/a7; rm -rf $E; mkdir -p $E
bash $K/novo-sistema.sh $E/sis > /dev/null; export RASTRO=$E/rastros.jsonl
c() { TOKENS_FALSOS="$2" AGENTE="bash $K/agente-falso.sh $1" bash $K/experimento.sh $E/sis "$1" > /dev/null; }
c comenta "8000 500"; c sinonimos "9000 700"; c estraga "41000 3000"   # tokens inventados para o ensaio
c falha "0 0"; c falha "0 0"; c falha "0 0"
echo "## uma linha do rastro"; sed -n 2p $RASTRO
echo "## custo por ciclo"; python3 $K/custo-ciclo.py $RASTRO --teto 50000; echo "saída: $?"