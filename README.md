# O loop que aprende — Formação LOOP-R Engenharia (curso 5 de 6, o último)

Curso aberto e gratuito do INEMA.CLUB no formato INEMA Learning v7.2, em português, inglês e espanhol:
**https://inematds.github.io/loop-r-eng-aprende-v72/** · [EN](https://inematds.github.io/loop-r-eng-aprende-v72/en/) · [ES](https://inematds.github.io/loop-r-eng-aprende-v72/es/)

Oito aulas para quem já usa Claude Code ou Codex no terminal: hipótese com número, experimento keep/discard com git (desenho do autoresearch), veredito A/B com guarda-corpos, cartão de decisão, promoção e rollback (LOOP-R), lições com aprovação em lote e revisão (SIL Loop R), regra vinculante no AGENTS.md, o risco de otimizar contra o próprio medidor, rastro e custo por ciclo, e a montagem das oito peças no seu sistema.

## O kit (`kit/`)

Scripts pequenos (python3 + bash + git, sem pip). Os ensaios não chamam modelo; `agente-claude.sh` é o único que chama (`claude -p --tools "" --output-format json`, pela sua assinatura). O kit lê os repositórios públicos [loop-r](https://github.com/inematds/loop-r) e [sil-loop-r](https://github.com/inematds/sil-loop-r) em `~/projetos`, e nunca grava neles.

| arquivo | aula | o que faz |
|---|---|---|
| `hipotese.py`, `hipoteses/` | 1 | confere os sete campos da hipótese e calcula a amostra mínima de um A/B |
| `triagem/`, `novo-sistema.sh`, `medir.py` | 2, 6 | sistema de ensaio (classificador de triagem, 40 casos + 30 escondidos, sintéticos) e a métrica única |
| `experimento.sh`, `agente-falso.sh`, `agente-claude.sh` | 2, 6, 7 | um ciclo keep/discard com git; `GUARDA`, `ESCONDIDOS` e `RASTRO` opcionais |
| `loopr.py` | 3 | veredito (teste z), cartão, decidir, promover, reverter |
| `contar-licoes.py` | 4 | mede o loop de lições em prosa (LESSONS/FALHAS/LIMITES), só contagens |
| `hooks/settings-sessionstart.json` | 5 | hook que injeta `sil.py context --brief` em cada sessão |
| `hashes.py` | 6 | congela e confere o medidor (formato do sha256sum) |
| `custo-ciclo.py` | 7 | custo por ciclo, custo por keep e alertas a partir do rastro |
| `conferir-loop.py`, `montar.sh`, `loop.conf.exemplo` | 8 | confere as oito peças do loop |
| `blocos/`, `saidas/`, `capturar.sh` | — | cada bloco "Terminal" das aulas e a saída capturada em 19/10/2026 |

```bash
git clone https://github.com/inematds/loop-r-eng-aprende-v72 ~/projetos/loop-r-eng-aprende-v72
git clone https://github.com/inematds/loop-r ~/projetos/loop-r
git clone https://github.com/inematds/sil-loop-r ~/projetos/sil-loop-r
bash ~/projetos/loop-r-eng-aprende-v72/kit/blocos/a2-ensaio.sh
```

Os dados de vendas do exemplo do LOOP-R são sintéticos (gerador com seeds escolhidos); os dados de triagem do kit também.

## Gerar o site

Conteúdo em `conteudo/<idioma>/` (JSON). O HTML é gerado: `python3 gerar.py && python3 validar.py --links` (e `--lang en|es`). Não edite o HTML à mão. Depois de mexer num bloco de terminal: `TMPDIR=<pasta> bash kit/capturar.sh` e `python3 ~/.claude/skills/formato-curso-v72/scripts/resolver-kit.py . --conferir`.

---

**EN** — *The Loop That Learns*, course 5 of 6 of the LOOP-R Engineering Track: numeric hypotheses, keep/discard experiments with git, A/B verdicts with guardrails, promotion and rollback, lessons that become binding rules, Goodhart, cost per cycle. Open and free (INEMA.CLUB).

**ES** — *El loop que aprende*, curso 5 de 6 de la Formación LOOP-R Ingeniería: hipótesis con número, experimentos keep/discard con git, veredictos A/B con barandillas, promoción y rollback, lecciones que se vuelven reglas vinculantes, Goodhart y costo por ciclo. Abierto y gratuito (INEMA.CLUB).
