K=~/projetos/loop-r-eng-aprende-v72/kit
E=${TMPDIR:-/tmp}/ensaio-aprende/a7      # o ensaio acima
RASTRO=$E/rastros.jsonl AGENTE="bash $K/agente-claude.sh" bash $K/experimento.sh $E/sis "claude"; echo "saída: $?"
tail -1 $E/rastros.jsonl | python3 -c 'import json,sys; d=json.load(sys.stdin); print("tokens:", "sim" if (d["tokens_entrada"] or 0) > 0 else "não", "·", d["status"])'