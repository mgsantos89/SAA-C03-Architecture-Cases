# Case 01 — O servidor que "sumiu" toda manhã

Nível: Fácil
Módulo: EC2 Networking & IP Addressing

## Situação-problema

A **Acme Digital** (empresa fictícia) mantém um servidor de homologação em EC2 que recebe webhooks de um parceiro de pagamentos. No painel do parceiro, o endpoint de destino foi cadastrado usando **o IP público da instância**.

Para economizar, o servidor é **parado toda noite e ligado de manhã**. Desde então, chegam três reclamações:

1. **Toda manhã a integração quebra.** Os webhooks do parceiro dão timeout, e o time precisa abrir chamado para atualizar o IP cadastrado no painel.
2. **Um desenvolvedor não consegue acessar o servidor** via SSH de casa usando o IP `172.31.x.x` que aparece no console, mas consegue pelo outro IP.
3. **Alguém reiniciou o servidor durante o dia** e, para surpresa de todos, nada quebrou, o que confundiu ainda mais o time.

Você foi chamado para **reproduzir o problema, explicar a causa, aplicar uma correção imediata com Elastic IP** e, por fim, **deixar a conta limpa e sem custo residual**, recomendando a arquitetura definitiva.

## Objetivo

Ao final do case você deve conseguir provar, com evidências (prints ou saída de terminal), que:

- de fora da AWS, sem VPN, o SSH só funciona pelo **IP público**, o IP privado não é roteável pela internet;
- o **reboot** não altera nenhum IP, mas o **stop → start** troca o **IP público** e mantém o **IP privado** (a causa da reclamação 1);
- um **Elastic IP** mantém o IP público fixo mesmo após stop/start (correção imediata);
- **Disassociate não é Release**: só o Release devolve o IP à AWS e para a cobrança;
- existe uma alternativa arquitetural melhor que Elastic IP para este servidor.

## Conceitos e recursos envolvidos

- **IP público × IP privado** e faixas RFC 1918
- **Comportamento do IP no reboot e no stop/start**
- **Elastic IP**: IPv4 público fixo, associado a 1 recurso por vez, limite padrão de 5 por conta/região 
- **Custo do IPv4 público** (≈ US$ 0,005/h, em uso ou não; Free Tier 750 h/mês) e **Disassociate × Release**
- **Alternativas ao Elastic IP** (DNS com Route 53 / Load Balancer)
- Recursos: **EC2** (t2.micro / t3.micro, Amazon Linux), **Security Group**, **Key Pair**, **Elastic IPs** (Network & Security).

## Detalhes e critérios

Condições que precisam ser cumpridas e validadas, organizadas nas fases do atendimento.

### Fase 1 — Montar o ambiente

- [ ] Lançar 1 instância `case01-srv` em sub-rede pública, com **Auto-assign public IP = Enable**.
- [ ] Security Group `case01-sg` liberando **SSH (22)** apenas para `<SEU_IP>/32` (nunca `0.0.0.0/0`).
- [ ] Registrar na tabela de evidências: IP público, IP privado e **Private IPv4 DNS** logo após o lançamento.
- [ ] Identificar a qual faixa RFC 1918 pertence o IP privado (`10.0.0.0/8`, `172.16.0.0/12` ou `192.168.0.0/16`).

### Fase 2 — Reproduzir e diagnosticar (reclamações 2 e 3)

- [ ] Conectar por SSH usando o **IP público** e rodar `hostname` — relacionar o hostname exibido ao IP privado.
- [ ] Tentar SSH pelo **IP privado** a partir da sua máquina e registrar o resultado (timeout) — explica a reclamação 2.
- [ ] Executar **Reboot instance** e registrar os IPs novamente — explica a reclamação 3.

### Fase 3 — Reproduzir a causa raiz (reclamação 1)

- [ ] Executar **Stop instance** → aguardar **Stopped** → **Start instance** e registrar os IPs novamente.
- [ ] Tentar SSH com o IP público **antigo** e com o **novo**.
- [ ] Explicar em 1–2 linhas por que a integração do parceiro quebra toda manhã.

### Fase 4 — Correção imediata com Elastic IP

- [ ] Alocar 1 Elastic IP a partir do **Amazon's pool of IPv4 addresses** com a tag `Name = case01-eip`.
- [ ] Associar o Elastic IP à instância usando **Resource type = Instance**.
- [ ] Confirmar que o **Public IPv4 address** da instância passou a ser o Elastic IP e que o IP público anterior **deixou de responder** ao SSH.
- [ ] Fazer **Stop** e observar que, mesmo **Stopped**, a instância continua exibindo o Elastic IP.
- [ ] Fazer **Start** e conectar via SSH usando **exatamente o mesmo comando** de antes.

### Fase 5 — Desmontagem sem custo residual

- [ ] **Disassociate** o Elastic IP e verificar que a instância recebeu um **novo IP público aleatório**.
- [ ] Antes do Release, consultar a tela de Elastic IPs e registrar que o endereço ainda aparece **alocado** (e, portanto, cobrado).
- [ ] **Release** do Elastic IP, **Terminate** da instância e remoção do Security Group.

### Fase 6 — Recomendação de arquitetura

- [ ] Responder por escrito (2–3 linhas): por que o Elastic IP é considerado má prática como solução definitiva e qual alternativa você recomendaria à Acme Digital para este servidor.

## Critérios de aceite

- [ ] **Tabela de evidências** com 5 linhas (lançamento, pós-reboot, pós-stop/start, com EIP pós-stop/start, pós-disassociate) × colunas (IP público, IP privado) preenchida com os valores observados.
- [ ] Evidência de que o SSH pelo IP privado **falhou**, com a explicação do motivo (IP privado só é roteável dentro da VPC / via VPN).
- [ ] Evidência de que o IP público **não mudou** no reboot e **mudou** no stop/start sem EIP.
- [ ] Evidência de que o IP privado **permaneceu igual** em todas as etapas.
- [ ] Evidência de que, com o Elastic IP, o IP público ficou **idêntico** antes e depois do stop/start, inclusive com a instância **Stopped**.
- [ ] Explicação correta de que **Disassociate não para a cobrança**; só o **Release** devolve o IP à AWS.
- [ ] Recomendação citando **DNS (Route 53)** ou **Load Balancer** como alternativa.
- [ ] Conta limpa ao final: tela de Elastic IPs da região **vazia**, instância encerrada e SG removido.

---

## Registro de execução

### Tabela de evidências

| Etapa                         | IP público     | IP privado    | Observação |
| ----------------------------- | -------------- | ------------- | ---------- |
| Lançamento                    |                |               |            |
| Pós-reboot                    |                |               |            |
| Pós-stop/start (sem EIP)      |                |               |            |
| Com EIP, pós-stop/start       |                |               |            |
| Pós-disassociate              |                |               |            |

- Hostname: 
- Public IPv4 DNS (lançamento): 
- Private IPv4 DNS (lançamento):

### Respostas

**Por que a integração quebra toda manhã?**


**Elastic IP × alternativa recomendada:**