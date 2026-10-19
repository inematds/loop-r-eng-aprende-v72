K=~/projetos/loop-r-eng-aprende-v72/kit
E=${TMPDIR:-/tmp}/ensaio-aprende/a2      # o repo do ensaio acima, já com o keep dos sinônimos
AGENTE="bash $K/agente-claude.sh" bash $K/experimento.sh $E/sis "claude: uma mudança"; echo "saída: $?"
echo "status da última linha: $(tail -1 $E/sis/results.tsv | cut -f5)"