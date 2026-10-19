#!/usr/bin/env bash
# experimento.sh — um ciclo no estilo autoresearch: o agente muda o sistema, UMA métrica decide,
# o git guarda (keep = commit) ou desfaz (discard = reset). Toda rodada vira uma linha em results.tsv.
#
# Uso:  AGENTE="<comando>" bash experimento.sh <repo> "<descrição>"
# Opcionais (aula 6 e 7):
#   GUARDA=<manifesto>      hash dos arquivos do medidor, gravado FORA do repo (crie com: bash experimento.sh --congelar <repo> <manifesto>)
#   ESCONDIDOS=<casos>      casos que o agente não vê; keep só se eles não caem e acompanham o ganho
#   RASTRO=<arquivo.jsonl>  uma linha por ciclo: segundos, tokens (se o agente informar), status e motivo
# No seu repo (aula 2, "Adaptar ao seu repo"):
#   MEDIR="<comando>"       roda na pasta do repo e imprime "<número> …" numa linha (padrão: python3 kit/medir.py .);
#                           recebe --valor e, com ESCONDIDOS, --casos <arquivo>
#   MEDIDOR="<arquivos>"    o que a medida lê e o --congelar congela (padrão: casos.jsonl; com MEDIR seu, inclua o script)
# O results.tsv nasce com cabeçalho se faltar e fica fora do git (.git/info/exclude): o repo não fica sujo.
# O agente recebe TOKENS_ARQ: se escrever "entrada saida" nele, os tokens entram no rastro.
# Saída: 0 keep · 1 discard · 2 erro (repo sujo, agente falhou, medida quebrou).
set -uo pipefail
K=$(cd "$(dirname "$0")" && pwd)
PADRAO="python3 $K/medir.py ."
MEDIR=${MEDIR:-$PADRAO}           # o comando que mede
MEDIDOR=${MEDIDOR:-casos.jsonl}   # o que o medidor lê de dentro do repo
export PYTHONDONTWRITEBYTECODE=1  # __pycache__ novo deixaria o repo sujo no ciclo seguinte

if [ "${1:-}" = "--congelar" ]; then
  extra=; [ "$MEDIR" = "$PADRAO" ] && extra="$K/medir.py"
  cd "${2:?repo}" && python3 "$K/hashes.py" congelar "${3:?manifesto}" $MEDIDOR $extra && echo "medidor congelado em $3"; exit 0
fi

R=${1:?uso: AGENTE=... experimento.sh <repo> "<descrição>"}; DESC=${2:-sem descrição}
cd "$R" || exit 2
[ -f results.tsv ] || printf 'ciclo\tcommit\tbase\tnovo\tstatus\tdescricao\n' > results.tsv
git check-ignore -q results.tsv || echo results.tsv >> "$(git rev-parse --git-path info/exclude)"
[ -z "$(git status --porcelain)" ] || { echo "ERRO: repo com mudança não commitada"; exit 2; }
CICLO=$(( $(wc -l < results.tsv) ))
INI=$(date +%s); TOKENS_ARQ=$(mktemp); export TOKENS_ARQ
read -r base _ _ < <($MEDIR --valor)
[ -n "${ESCONDIDOS:-}" ] && read -r hbase _ _ < <($MEDIR --casos "$ESCONDIDOS" --valor)

fim() {  # fim <status> <novo> <motivo>
  local st=$1 novo=$2 motivo=$3 c="-"
  if [ "$st" = keep ]; then
    git -c user.name=loop -c user.email=loop@exemplo.invalid commit -q -am "keep: $DESC ($base → $novo)"
    c=$(git rev-parse --short HEAD)
  else
    git reset -q --hard HEAD; git clean -q -fd
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$CICLO" "$c" "$base" "$novo" "$st" "$DESC" >> results.tsv
  if [ -n "${RASTRO:-}" ]; then
    read -r te ts < "$TOKENS_ARQ" 2>/dev/null || true
    printf '{"ciclo": %s, "descricao": "%s", "segundos": %s, "tokens_entrada": %s, "tokens_saida": %s, "status": "%s", "motivo": "%s"}\n' \
      "$CICLO" "$DESC" "$(( $(date +%s) - INI ))" "${te:-null}" "${ts:-null}" "$st" "$motivo" >> "$RASTRO"
  fi
  rm -f "$TOKENS_ARQ" "$TOKENS_ARQ.log"
  echo "ciclo $CICLO · $st · $base → $novo · $motivo"
  case $st in keep) exit 0;; discard) exit 1;; *) exit 2;; esac
}

bash -c "${AGENTE:?defina AGENTE}" > "$TOKENS_ARQ.log" 2>&1; rc=$?
[ $rc -eq 0 ] || fim erro - "agente falhou (saída $rc): $(tail -1 "$TOKENS_ARQ.log")"
[ -n "$(git status --porcelain)" ] || fim discard "$base" "o agente não mudou nada"
if [ -n "${GUARDA:-}" ] && ! python3 "$K/hashes.py" conferir "$GUARDA" > /dev/null 2>&1; then
  fim discard "$base" "DESCARTADO: mexeu no medidor ($MEDIDOR)"
fi
read -r novo _ _ < <($MEDIR --valor) || true
[ -n "${novo:-}" ] && [ "$novo" != "ERRO" ] || fim erro - "a medida quebrou"
if python3 -c "import sys; sys.exit(0 if float('$novo') > float('$base') else 1)"; then
  if [ -n "${ESCONDIDOS:-}" ]; then
    read -r hnovo _ _ < <($MEDIR --casos "$ESCONDIDOS" --valor)
    python3 -c "import sys; sys.exit(0 if float('$hnovo') >= float('$hbase') else 1)" || fim discard "$novo" "DESCARTADO: escondidos caíram ($hbase → $hnovo)"
    python3 -c "import sys; sys.exit(0 if float('$hnovo') > float('$hbase') else 1)" || fim discard "$novo" "DESCARTADO: ganho só no visível (escondidos $hbase → $hnovo)"
    fim keep "$novo" "melhorou (escondidos $hbase → $hnovo)"
  fi
  fim keep "$novo" "melhorou"
fi
fim discard "$novo" "não melhorou"
