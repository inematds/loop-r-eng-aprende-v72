SIL=~/projetos/sil-loop-r/sil.py   # git clone https://github.com/inematds/sil-loop-r ~/projetos/sil-loop-r
E=${TMPDIR:-/tmp}/ensaio-aprende/a4; rm -rf $E; mkdir -p $E/p; cd $E/p && git init -q
echo 'python3 -m http.server 8000' > serve.sh
s() { python3 $SIL --project $E/p "$@"; }
j() { python3 -c 'import json,sys; d=json.load(sys.stdin); print(*[k+"="+json.dumps(d.get(k),ensure_ascii=False) for k in sys.argv[1:]])' "$@"; }
s init | j version; s config --approval-batch 2 | j approval_batch
s occurrence --title "porta ocupada" --evidence "teste HTTP falhou: address already in use" \
  --cause "servidor de outra sessão na mesma porta" --correction "checar a porta antes" | j id
s lesson --occurrence O0001 --proposal "checar a porta antes de subir servidor" --scope "testes HTTP" --watch serve.sh | j id status
s occurrence --title "push no remoto errado" --evidence "git push foi para origin, não para o remoto da conta" | j id
s lesson --occurrence O0002 --proposal "conferir git remote -v antes do push" --scope "publicação" | j id status
echo "## fim da tarefa: chegou a hora do lote?"; s status | j approval_due approval_reasons
s request | j requested