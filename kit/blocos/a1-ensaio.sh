K=~/projetos/loop-r-eng-aprende-v72/kit   # git clone https://github.com/inematds/loop-r-eng-aprende-v72 ~/projetos/loop-r-eng-aprende-v72
for h in vaga triagem; do
  echo "## $h"; python3 $K/hipotese.py $K/hipoteses/$h.md; echo "saída: $?"
done
echo "## vendas: conversão 3% → 5%, 50 propostas por semana"
python3 $K/hipotese.py $K/hipoteses/vendas-conversao.md --por-semana 50; echo "saída: $?"
echo "## vendas: resposta em 48h 20% → 30% (métrica de sinal)"
python3 $K/hipotese.py $K/hipoteses/vendas-resposta.md --por-semana 50 | tail -2