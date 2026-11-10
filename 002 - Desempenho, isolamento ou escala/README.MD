# Case 02 — Desempenho, isolamento ou escala?

Nível: Fácil
Módulo: EC2 Placement Groups

## Situação-problema

A **Órbita Analytics** (empresa fictícia) roda quase tudo em EC2. Até hoje, nenhum time se preocupou com **onde** as instâncias ficam fisicamente dentro da AWS: tudo é lançado com as configurações padrão. Neste mês, três times abriram chamados para a equipe de plataforma, e cada um, sem saber, está pedindo uma coisa diferente: **desempenho**, **isolamento** ou **escala**.

1. **Time de Pagamentos "caiu todo de uma vez".** *(isolamento)* O sistema de conciliação roda em **3 instâncias** justamente para não ter ponto único de falha. Na semana passada, uma falha de hardware na AWS derrubou **as três ao mesmo tempo**, e o sistema ficou fora por 40 minutos. O time quer saber como isso foi possível "se eram três máquinas".
2. **Time de Pesquisa — "o job ficou lento".** *(desempenho)* Uma simulação de **HPC** que troca muitas mensagens entre os nós passou a levar quase o dobro do tempo depois de uma recriação do ambiente. As instâncias continuam iguais, mas a latência de rede entre elas aumentou.
3. **Time de Dados — "vamos crescer para centenas de nós".** *(escala)* O cluster **Kafka** tem hoje 6 brokers e deve chegar a algumas centenas no próximo ano. O time precisa que uma falha de rack afete só uma fração dos brokers, e não o cluster inteiro.

Na reunião de alinhamento surgiram duas sugestões:

- um analista propôs colocar **tudo num único placement group Cluster**, "porque é o mais rápido";
- outro propôs usar **Spread para todo mundo**, "porque é o mais seguro".

As duas sugestões partem da mesma premissa errada: a de que existe um placement group "melhor". Na prática, cada estratégia otimiza **uma** dessas três dimensões e abre mão das outras.

Você foi chamado para **explicar o que aconteceu com cada time, criar o placement group certo para cada caso, provar como uma instância é vinculada a um grupo** e, por fim, **deixar a conta limpa**, registrando uma tabela de decisão que justifique cada escolha e mostre por que nenhuma das duas sugestões funciona.

## Objetivo

Ao final do case você deve conseguir provar, com evidências (prints ou saída de terminal), que:

- cada estratégia corresponde a uma dimensão: **Cluster = desempenho**, **Spread = isolamento**, **Partition = escala com isolamento**;
- existem **3 placement groups**, cada um com a estratégia adequada ao requisito do time (**Cluster**, **Spread/Rack** e **Partition/3**);
- você sabe **onde** o placement group é escolhido no lançamento da instância e **onde** confirmar o vínculo depois;
- o **Spread level = Host** não se aplica a este cenário (motivo: ele só existe para **AWS Outposts**);
- um placement group **só pode ser excluído quando está vazio**;
- nem "Cluster para tudo" nem "Spread para tudo" atende os três times. Cada estratégia tem um limite que inviabiliza pelo menos um dos casos.

## Conceitos e recursos envolvidos

- **Placement Groups**: como controlar o posicionamento físico das instâncias no hardware da AWS (recurso sem custo próprio)
- **Cluster**: instâncias próximas numa **única AZ**, baixa latência e alta banda (até ~10 Gbps por fluxo), mas **falha conjunta** se o hardware compartilhado falhar
- **Spread**: cada instância em **hardware distinto**, no máximo **7 instâncias em execução por AZ** por grupo; **Spread level** Rack × Host (Host = **AWS Outposts**)
- **Partition**: instâncias divididas em partições, cada uma com racks próprios, **até 7 partições por AZ**, escala para **centenas de instâncias** (Kafka, HDFS, Cassandra)
- **Failure domain** (domínio de falha) e a relação entre disponibilidade e desempenho
- Recursos: **EC2 → Network & Security → Placement Groups**, **EC2 → Launch instances → Advanced details → Placement group name**, aba **Details** da instância, **t3.micro** (Amazon Linux).

## Detalhes e critérios

Condições que precisam ser cumpridas e validadas, organizadas nas fases do atendimento.

### Fase 1 — Diagnóstico dos chamados

- [ ] Explicar em 1–2 linhas por que as **3 instâncias do time de Pagamentos** puderam cair juntas sem nenhum placement group configurado.
- [ ] Explicar em 1–2 linhas o que provavelmente mudou no ambiente do **time de Pesquisa** para a latência entre os nós aumentar.
- [ ] Para cada time, classificar a prioridade principal: **desempenho**, **isolamento** ou **escala** — e o que esse time pode sacrificar em troca.

### Fase 2 — Criar os placement groups

- [ ] Criar `case002-hpc` com estratégia **Cluster** (time de Pesquisa).
- [ ] Criar `case002-critical` com estratégia **Spread** e **Spread level = Rack** (time de Pagamentos).
- [ ] Criar `case002-kafka` com estratégia **Partition** e **3 partições** (time de Dados).
- [ ] Na tela de criação do Spread, observar a opção **Host** e registrar por que ela **não** foi usada.
- [ ] Registrar na tabela de evidências o nome, a estratégia e o detalhe (spread level / nº de partições) de cada grupo.

### Fase 3 — Lançar uma instância no grupo certo

- [ ] Lançar 1 instância `case002-critico-01` (**t3.micro**, Amazon Linux) informando `case002-critical` em **Advanced details → Placement group name**.
- [ ] Na aba **Details** da instância, localizar o campo do placement group e confirmar o vínculo com `case002-critical`.
- [ ] Explicar em 1 linha por que o time de Pagamentos **não** poderia escalar para 10 instâncias numa única AZ usando este mesmo grupo.

### Fase 4 — Testar os limites

- [ ] Tentar **excluir** `case002-critical` com a instância ainda em execução e registrar o resultado (erro / bloqueio).
- [ ] Responder: o que aconteceria com a simulação do time de Pesquisa se o hardware compartilhado do grupo `case002-hpc` falhasse?
- [ ] Responder: por que a sugestão "**Spread para todo mundo**" quebra o plano do time de Dados?
- [ ] Responder: por que a sugestão "**Cluster para tudo**" repete o incidente do time de Pagamentos?

### Fase 5 — Desmontagem sem resíduo

- [ ] **Terminate** da instância `case002-critico-01` e aguardar o estado **Terminated**.
- [ ] Excluir os 3 placement groups (`case002-hpc`, `case002-critical`, `case002-kafka`).
- [ ] Confirmar que a tela de **Placement Groups** da região ficou vazia.

### Fase 6 — Tabela de decisão

- [ ] Preencher a tabela de decisão: **time × prioridade (desempenho / isolamento / escala) × estratégia × motivo × principal risco/limite**, que será entregue aos três times como justificativa.

## Critérios de aceite

- [ ] Os 3 placement groups aparecem na console com a estratégia correta: **Cluster**, **Spread / Rack** e **Partition / 3 partições**.
- [ ] A instância `case002-critico-01` exibe `case002-critical` como placement group na aba **Details**.
- [ ] Evidência de que o placement group **não pôde ser excluído** enquanto continha uma instância.
- [ ] Tabela de decisão relacionando cada time a uma prioridade (**desempenho**, **isolamento** ou **escala**) e citando, no mínimo:
  - **Cluster** = 1 AZ, ~10 Gbps, baixa latência, **falha conjunta**;
  - **Spread** = hardware distinto, **máx. 7 instâncias por AZ**;
  - **Partition** = partições em racks separados, **até 7 partições por AZ**, **centenas de instâncias**.
- [ ] Explicação correta de que o **Spread level Host** só se aplica ao **AWS Outposts**.
- [ ] Explicação de por que "Cluster para tudo" e "Spread para tudo" não atendem os três times.
- [ ] Conta limpa ao final: instância encerrada e tela de Placement Groups da região **vazia**.

---

## Registro de execução

### Tabela de evidências — placement groups

| Placement group     | Estratégia | Spread level / Partições | Estado | Observação |
| ------------------- | ---------- | ------------------------ | ------ | ---------- |
| `case002-hpc`       |            |                          |        |            |
| `case002-critical` |            |                          |        |            |
| `case002-kafka`     |            |                          |        |            |

### Instância de validação

- Instance ID:
- Tipo / AZ:
- Placement group exibido na aba Details:
- Resultado da tentativa de excluir o grupo com a instância ativa:

### Tabela de decisão

| Time       | Prioridade | Estratégia | Motivo da escolha | Principal risco / limite |
| ---------- | ---------- | ---------- | ----------------- | ------------------------ |
| Pesquisa   |            |            |                   |                          |
| Pagamentos |            |            |                   |                          |
| Dados      |            |            |                   |                          |

### Respostas

**Por que as 3 instâncias do time de Pagamentos caíram juntas?**


**O que mudou no ambiente do time de Pesquisa?**


**Por que o Spread level Host não foi usado?**


**Por que "Cluster para tudo" não serve?**


**Por que "Spread para todo mundo" não serve?**
