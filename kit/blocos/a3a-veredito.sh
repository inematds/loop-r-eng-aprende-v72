K=~/projetos/loop-r-eng-aprende-v72/kit
X=~/projetos/loop-r/exemplos/vendas-whatsapp   # git clone https://github.com/inematds/loop-r ~/projetos/loop-r (dados SINTÉTICOS)
E=${TMPDIR:-/tmp}/ensaio-aprende/a3; rm -rf $E; L=$E/loop   # uma CÓPIA: nada é gravado no repo loop-r
python3 $K/loopr.py iniciar $L --v1 $X/versoes/v1/executor.prompt.md --candidata $X/versoes/v2/executor.prompt.md
echo "## E0001 · H2 (até 80 palavras), tolerância 0 em reclamações"
python3 $K/loopr.py veredito $L --csv $X/dados/execucoes.csv --de 2026-02-02 --ate 2026-04-26 \
  --metrica resposta --minimo 166 --vigiar reclamou:0 --vigiar optout:0.005; echo "saída: $?"
echo "## E0002 · H3 (abrir citando um ponto da avaliação)"
python3 $K/loopr.py veredito $L --csv $X/dados/execucoes.csv --de 2026-05-04 --ate 2026-07-26 \
  --metrica resposta --minimo 212 --vigiar reclamou:0.01 --vigiar optout:0.005; echo "saída: $?"