SIL=~/projetos/sil-loop-r/sil.py
E=${TMPDIR:-/tmp}/ensaio-aprende/a4; cd $E/p   # continua o ensaio da aula 4 (R0001 ativa)
s() { python3 $SIL --project $E/p "$@"; }
j() { python3 -c 'import json,sys; d=json.load(sys.stdin); print(*[k+"="+json.dumps(d.get(k),ensure_ascii=False) for k in sys.argv[1:]])' "$@"; }
echo "# Instruções do projeto" > AGENTS.md
s enforce R0001 --binding yes --rung prose --leak "sessão que não lê o AGENTS.md" \
  --approved-by "Seu Nome" --reason "porta ocupada derruba o servidor de outra sessão" | j binding rung
s status | j promotion prose_binding; s check > /dev/null; echo "check: $?"
s promote | j written changed
s promote --write | j written; cat AGENTS.md
s check > /dev/null; echo "check: $?"
echo "## alguém editou o bloco à mão"; sed -i.bak 's/checar a porta/CHECAR A PORTA/' AGENTS.md
s check | j promotion; s check > /dev/null; echo "check: $?"
s promote --write | j written; s check > /dev/null; echo "check: $?"
echo "## o que um hook SessionStart injetaria"; s context --brief