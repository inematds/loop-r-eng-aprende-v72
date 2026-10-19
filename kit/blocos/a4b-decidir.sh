SIL=~/projetos/sil-loop-r/sil.py
E=${TMPDIR:-/tmp}/ensaio-aprende/a4; cd $E/p   # continua o bloco anterior
s() { python3 $SIL --project $E/p "$@"; }
j() { python3 -c 'import json,sys; d=json.load(sys.stdin); print(*[k+"="+json.dumps(d.get(k),ensure_ascii=False) for k in sys.argv[1:]])' "$@"; }
ATE=$(python3 -c 'import datetime; print(datetime.date.today() + datetime.timedelta(days=14))')
s decide L0001 adopt --approved-by "Seu Nome" --reason "falhou duas vezes; correção comprovada" | j status rule
s decide L0002 trial --until $ATE --criterion "nenhum push no remoto errado em 14 dias" \
  --approved-by "Seu Nome" --reason "uma ocorrência só" | j status
s check > /dev/null; echo "check: $?"
echo "## o arquivo vigiado mudou"; echo 'python3 -m http.server 8080' > serve.sh
s check | j reviews; s check > /dev/null; echo "check: $?"
s review R0001 keep --approved-by "Seu Nome" --reason "a porta mudou; a regra continua valendo" | j status
s check > /dev/null; echo "check: $?"