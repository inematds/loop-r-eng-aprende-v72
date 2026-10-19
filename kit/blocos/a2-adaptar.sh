K=~/projetos/loop-r-eng-aprende-v72/kit
E=${TMPDIR:-/tmp}/ensaio-aprende/a2-adaptar; rm -rf $E; mkdir -p $E/repo; cd $E/repo
# um repo "seu": sem results.tsv, sem .gitignore, com o próprio medidor
printf 'def dobro(x):\n    return x + 2\n' > calc.py
printf '1 2\n2 4\n5 10\n0 0\n' > casos.txt                      # entrada e esperado
cat > medir.sh <<'FIM'
# imprime "<acerto> <ok> <total>" (o experimento.sh lê o 1º número)
python3 -c "
import calc
c = [l.split() for l in open('casos.txt') if l.strip()]
ok = sum(calc.dobro(int(a)) == int(b) for a, b in c)
print(f'{ok / len(c):.3f} {ok} {len(c)}')"
FIM
git init -q -b main; git add -A; git -c user.name=treino -c user.email=treino@exemplo.invalid commit -qm "v1"
export MEDIR="bash medir.sh" MEDIDOR="casos.txt medir.sh"      # as duas variáveis da adaptação
bash $K/experimento.sh --congelar . $E/medidor.sha256; export GUARDA=$E/medidor.sha256
AGENTE="echo '# revisado' >> calc.py" bash $K/experimento.sh . "comenta"; echo "saída: $?"
AGENTE="printf 'def dobro(x):\n    return x * 2\n' > calc.py" bash $K/experimento.sh . "corrige"; echo "saída: $?"
AGENTE="echo '3 7' >> casos.txt" bash $K/experimento.sh . "mexe nos casos"; echo "saída: $?"
echo "## results.tsv (criado pelo experimento.sh)"; cut -f1,3- results.tsv
echo "## git status (vazio = limpo)"; git status --short
