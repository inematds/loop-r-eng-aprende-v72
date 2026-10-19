K=~/projetos/loop-r-eng-aprende-v72/kit
E=${TMPDIR:-/tmp}/ensaio-aprende/a8; rm -rf $E; mkdir -p $E/vazio
echo "## uma pasta sem nada"; python3 $K/conferir-loop.py $E/vazio > $E/vazio.txt; echo "saída: $?"; tail -1 $E/vazio.txt
echo "## as oito peças montadas pelo kit (o que as aulas 1 a 7 fizeram)"
bash $K/montar.sh $E/meu-loop > /dev/null
python3 $K/conferir-loop.py $E/meu-loop; echo "saída: $?"
echo "## o loop.conf que o conferir lê"; cat $E/meu-loop/loop.conf