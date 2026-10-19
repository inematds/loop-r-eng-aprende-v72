K=~/projetos/loop-r-eng-aprende-v72/kit
E=${TMPDIR:-/tmp}/ensaio-aprende/a3; L=$E/loop   # continua o bloco anterior (veredito B_GANHOU gravado)
python3 $K/loopr.py promover $L; echo "saída: $?"
python3 $K/loopr.py cartao $L --hipotese "H3 — abrir citando a avaliação" --tokens 392000
python3 $K/loopr.py decidir $L aprovado --por "Seu Nome"
python3 $K/loopr.py promover $L; echo "atual → $(readlink $L/versoes/atual)"
python3 $K/loopr.py reverter $L --motivo "resposta caiu no 1º ciclo após a promoção"
echo "atual → $(readlink $L/versoes/atual) · pastas: $(ls $L/versoes | tr '\n' ' ')"
git -C $L log --format=%s