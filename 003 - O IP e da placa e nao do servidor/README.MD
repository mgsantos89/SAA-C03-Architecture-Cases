# Case 03 — O IP é da placa e não do servidor

Nível: Médio
Módulo: EC2 Networking — Elastic Network Interfaces (ENI)

## Situação-problema

A **Cedro Seguros** (empresa fictícia) tem um **motor de cotação** legado rodando em EC2. Ele não é exposto à internet: é consumido por outros servidores internos (ERP, jobs batch e um sistema de relatórios), que chamam o serviço por um **IP privado fixo** gravado em arquivos de configuração espalhados por **12 servidores**. Mudar esse IP significa editar e reiniciar tudo à mão.

No mês passado, a instância do motor de cotação apresentou falha e precisou ser substituída. A nova instância subiu com **outro IP privado**, e começaram os problemas:

1. **Duas horas de indisponibilidade.** O servidor novo ficou pronto em 10 minutos, mas o time levou quase 2 horas para atualizar o IP nos 12 clientes. A diretoria exigiu que o próximo failover aconteça **sem tocar em nenhum cliente**.
2. **"É só usar um Elastic IP."** Essa foi a primeira sugestão na reunião de pós-incidente, mas os clientes estão todos **dentro da VPC** e falam com o motor pelo **IP privado**, e ninguém quer expor o serviço à internet.
3. **"Então deixa o reserva em outra AZ, que é mais seguro."** O time de infraestrutura quer manter um servidor reserva já ligado, mas propôs colocá-lo em outra Availability Zone, sem saber se o IP conseguiria "acompanhar" a troca. Um analista chegou a tentar anexar uma placa de rede a um servidor de outra AZ e abriu um chamado dizendo que "a instância não aparece na lista".
4. **"Placas de rede órfãs na conta."** Depois do incidente, o time de operações estranhou que, ao encerrar instâncias, **algumas interfaces de rede sumiram e outras ficaram para trás** com status **Available**, ocupando IPs da sub-rede e impedindo a exclusão de Security Groups. Descobriu-se que, na tentativa de "não perder o IP", alguém havia **desligado o Delete on termination** da placa principal de alguns servidores, e ninguém sabia dizer de antemão o que seria apagado.

Por trás das quatro reclamações está a mesma premissa errada: a de que o IP pertence ao servidor. Na AWS, o IP privado pertence à **placa de rede (ENI)**, uma placa pode ser tirada de um servidor e colocada em outro (desde que na mesma AZ), e ela tem um **ciclo de vida próprio**, como um volume EBS, que pode ou não acabar junto com a instância.

O orçamento não comporta um Load Balancer agora, e o protocolo legado dos clientes não permite trocar o IP por um nome DNS no curto prazo. Você foi chamado para **provar que é possível trocar o servidor que atende sem mudar o IP que os clientes enxergam**, usando uma **ENI dedicada** que carrega o IP do serviço. Você também precisa **medir quanto tempo o serviço fica fora durante a troca**, **mostrar os limites da solução**, **prever com exatidão quais ENIs sobrevivem ao encerramento das instâncias** e, por fim, **deixar a conta limpa**.

## Objetivo

Ao final do case você deve conseguir provar, com evidências (prints ou saída de terminal), que:

- o IP privado do serviço "mora" na **ENI**, e não na instância: ao mover a ENI de `case003-app-a` para `case003-app-b`, o **mesmo IP** passa a responder pelo servidor B;
- o **MAC address** da ENI é o mesmo antes e depois da migração, porque a placa de rede é a mesma e só mudou de servidor;
- o cliente percebe a troca **apenas pelo conteúdo da resposta HTTP**, sem nenhuma alteração do lado dele;
- o failover tem um **tempo de indisponibilidade mensurável**, e você sabe estimá-lo;
- a ENI é **presa à AZ** (na verdade, à sub-rede): ela não pode ser anexada a uma instância de outra Availability Zone (reclamação 3);
- **ENI resolve failover de IP privado** e **Elastic IP resolve failover de IP público**. Não são intercambiáveis (reclamação 2);
- você consegue **prever, antes do terminate**, quais ENIs serão apagadas e quais ficarão órfãs, com base em **como foram criadas** (automática × manual) e no atributo **Delete on termination** (reclamação 4).

## Conceitos e recursos envolvidos

- **ENI (Elastic Network Interface)**: placa de rede virtual com IP privado, MAC address, Security Groups e (opcionalmente) Elastic IP próprios
- **ENI primária (eth0) × ENI secundária**: a primária nasce com a instância e **não pode ser desanexada**; uma ENI criada manualmente pode ser movida entre instâncias
- **ENI presa à AZ / sub-rede**: só pode ser anexada a instâncias da **mesma AZ**
- **ENIs automáticas × manuais**: a eth0 criada no launch vem com **Delete on termination = true**; uma ENI criada manualmente e anexada depois vem com **Delete on termination = false**
- **Delete on termination** e **ciclo de vida independente** (ENI ≈ "EBS da rede"): o atributo pode ser alterado a qualquer momento (console: *Network interface → Actions → Change termination behavior*; CLI: `aws ec2 modify-network-interface-attribute`)
- **ENI órfã**: ENI em estado **Available** que sobrou após o terminate; ocupa IP da sub-rede, mantém Security Groups "em uso" e polui o inventário
- **Create / Attach / Detach / Force detachment**
- **Failover barato** com ENI × remapeamento de **Elastic IP** na rede pública
- **Security Group referenciando outro Security Group** (em vez de CIDR)
- Recursos: 3 instâncias **EC2** (t3.micro, Amazon Linux 2023), **User Data**, **Network Interfaces** (Network & Security), **Security Groups**, sub-redes em **2 AZs**.

## Detalhes e critérios

Condições que precisam ser cumpridas e validadas, organizadas nas fases do atendimento.

### Fase 1 — Montar o ambiente

- [ ] Lançar `case003-app-a` e `case003-app-b` na **mesma AZ e sub-rede** (AZ **a**), cada uma servindo, via **User Data**, uma página HTTP (porta 80) que identifique o servidor (`Servidor A` / `Servidor B`).
- [ ] Lançar `case003-cliente` na mesma VPC, mas em uma **sub-rede de outra AZ** (AZ **b**). Ela representa um dos 12 servidores clientes.
- [ ] Criar o Security Group `case003-cliente-sg` e associá-lo ao cliente.
- [ ] Criar o Security Group `case003-app-sg` liberando a porta **80** somente a partir de `case003-cliente-sg` (referência entre SGs, **nunca** `0.0.0.0/0` nem CIDR aberto) e associá-lo a A e B.
- [ ] Registrar o **ID**, o **IP privado primário** e o **Delete on termination** da eth0 de A, de B e do cliente.

### Fase 2 — Criar a ENI do serviço

- [ ] Criar a ENI `case003-eni-servico` na sub-rede de A/B, com **IPv4 privado Custom** (escolha um IP livre da sub-rede) e o SG `case003-app-sg`.
- [ ] Registrar o **ID**, o **IP privado**, o **MAC address** e a **AZ** da ENI recém-criada (status **Available**).
- [ ] Observar que a ENI já tem IP e MAC **antes de estar anexada a qualquer servidor**: o IP é da placa, não do servidor.
- [ ] Explicar em 1 linha por que esse IP será o "IP do serviço" que os clientes vão usar, e não o IP da eth0 de A.

### Fase 3 — Operação normal

- [ ] Anexar a ENI em `case003-app-a` e confirmar o status **In-use**.
- [ ] Verificar o **Delete on termination** da ENI do serviço agora que está anexada e comparar com o da eth0 de A (aba **Networking** da instância ou `aws ec2 describe-network-interfaces`).
- [ ] Do cliente, executar `curl http://<IP_DA_ENI>`. A resposta deve ser `Servidor A`.
- [ ] Deixar rodando no cliente um **loop de `curl` com timestamp** (1 requisição por segundo, com timeout curto) para registrar o failover.

> 💡 Dica: algo como `while true; do echo "$(date +%T) $(curl -s -m 1 http://<IP_DA_ENI> || echo FALHOU)"; sleep 1; done`

> 💡 Dica: `aws ec2 describe-network-interfaces --filters Name=tag:Name,Values=case003-* --query "NetworkInterfaces[].{Id:NetworkInterfaceId,Ip:PrivateIpAddress,Status:Status,Instancia:Attachment.InstanceId,Device:Attachment.DeviceIndex,DoT:Attachment.DeleteOnTermination}" --output table`
> (ENIs automáticas não recebem a tag `Name` da instância; filtre também por `Name=subnet-id` ou `Name=attachment.instance-id`.)

### Fase 4 — Simular a falha e executar o failover (reclamação 1)

- [ ] Simular a falha: **Detach** da ENI em `case003-app-a` (usar **Force detachment** se travar).
- [ ] Anexar a **mesma ENI** em `case003-app-b`.
- [ ] Observar no loop do cliente o momento em que as respostas passam de `Servidor A` para `FALHOU` e depois para `Servidor B`, **no mesmo IP**.
- [ ] Registrar o **MAC address** da ENI depois da migração.
- [ ] Calcular o **tempo de indisponibilidade**: do último `Servidor A` até o primeiro `Servidor B`.
- [ ] Confirmar que **nenhum comando ou configuração** foi alterado no cliente durante o processo.

### Fase 5 — Testar os limites de AZ e da eth0 (reclamações 2 e 3)

- [ ] Tentar anexar a ENI do serviço à instância `case003-cliente` (outra AZ) e registrar o que acontece: a instância aparece na lista do **Attach**? (Opcional: tentar via CLI com `aws ec2 attach-network-interface` e registrar a mensagem de erro.)
- [ ] Tentar desanexar a **ENI primária (eth0)** de `case003-app-a` e registrar o resultado.
- [ ] Responder: por que um **Elastic IP** não resolveria o problema da Cedro Seguros?
- [ ] Responder: o que aconteceria com o plano de failover se o servidor reserva estivesse em **outra AZ**?

### Fase 6 — Reproduzir as ENIs órfãs (reclamação 4)

- [ ] Reproduzir o erro do analista: **desligar o Delete on termination da eth0 de `case003-app-b`** (console: *Network interface → Actions → Change termination behavior*; ou CLI `aws ec2 modify-network-interface-attribute --network-interface-id <eni-eth0-b> --attachment AttachmentId=<attach-id>,DeleteOnTermination=false`).
- [ ] Montar o **inventário completo** de ENIs do case: as 3 eth0 + a ENI do serviço, com **criada como** (automática/manual), **anexada em** e **Delete on termination** atual.
- [ ] **Antes** de encerrar qualquer instância, preencher a coluna **Previsão** da tabela de ciclo de vida: quais ENIs vão sumir e quais vão ficar **Available**, com a justificativa.

### Fase 7 — Desmontagem e conferência da previsão

- [ ] Encerrar (**Terminate**) as 3 instâncias.
- [ ] Conferir a lista de **Network Interfaces** e preencher a coluna **Resultado** da tabela de ciclo de vida.
- [ ] Comparar previsão × resultado e explicar qualquer divergência.
- [ ] Tentar excluir o Security Group `case003-app-sg` **antes** de remover as ENIs remanescentes e registrar o erro (dependência com as ENIs órfãs).
- [ ] Excluir manualmente todas as ENIs remanescentes do case (status **Available**).
- [ ] Excluir os Security Groups `case003-app-sg` e `case003-cliente-sg`.
- [ ] Confirmar que a tela de **Network Interfaces** não tem nenhuma ENI remanescente do case.

### Fase 8 — Recomendação de arquitetura

- [ ] Responder por escrito (2–3 linhas): quando usar **ENI** e quando usar **Elastic IP** para failover (IP privado × IP público).
- [ ] Responder por escrito (2–3 linhas): quais são as limitações deste failover (manual, preso a uma AZ) e qual arquitetura você recomendaria à Cedro Seguros quando houver orçamento e o protocolo legado puder ser alterado.
- [ ] Responder por escrito (2–3 linhas): qual **regra operacional** a Cedro deve adotar sobre o Delete on termination para não acumular ENIs órfãs (quando faz sentido desligá-lo e como o time deve inventariar/limpar ENIs **Available**).

## Critérios de aceite

- [ ] Saída do loop de `curl` mostrando o **mesmo IP** respondendo `Servidor A` antes e `Servidor B` depois do failover.
- [ ] **MAC address** da ENI **idêntico** antes e depois da migração.
- [ ] Evidência de que **nenhuma alteração** foi feita no cliente durante o failover.
- [ ] **Tempo de indisponibilidade** registrado, com os timestamps de início e fim.
- [ ] Evidência de que a ENI **não pode ser anexada** a uma instância de outra AZ e de que a **eth0 não pode ser desanexada**.
- [ ] `case003-app-sg` liberando a porta 80 apenas a partir de `case003-cliente-sg` (sem CIDR aberto).
- [ ] Tabela **ENI × criada como × Delete on termination × previsão × resultado** completa, com a previsão preenchida **antes** do terminate.
- [ ] A eth0 de `case003-app-a` e de `case003-cliente` foi apagada; a ENI do serviço e a eth0 de `case003-app-b` ficaram **Available** (ou divergências explicadas).
- [ ] Explicação correta de **ENI (IP privado) × Elastic IP (IP público)** para failover.
- [ ] Recomendação de arquitetura definitiva citando as limitações do failover com ENI, e regra operacional para Delete on termination.
- [ ] Conta limpa ao final: 3 instâncias encerradas, **nenhuma ENI do case** restante e Security Groups removidos.

---

## Registro de execução

### Ambiente

| Recurso            | AZ | Sub-rede | IP privado (eth0) | ENI ID (eth0) | Observação |
| ------------------ | -- | -------- | ----------------- | ------------- | ---------- |
| `case003-app-a`    |    |          |                   |               |            |
| `case003-app-b`    |    |          |                   |               |            |
| `case003-cliente`  |    |          |                   |               |            |

### Tabela de evidências — ENI do serviço

| Etapa                    | Anexada em | IP da ENI | MAC address | Delete on termination | Resposta do `curl` | Observação |
| ------------------------ | ---------- | --------- | ----------- | --------------------- | ------------------ | ---------- |
| Criada (Available)       | —          |           |             | —                     | —                  |            |
| Operação normal          |            |           |             |                       |                    |            |
| Pós-detach               | —          |           |             | —                     |                    |            |
| Pós-failover             |            |           |             |                       |                    |            |
| Pós-terminate instâncias | —          |           |             | —                     | —                  |            |

- ENI ID:
- AZ da ENI:

### Tempo de indisponibilidade

| Evento                         | Timestamp |
| ------------------------------ | --------- |
| Última resposta `Servidor A`   |           |
| Primeira falha                 |           |
| Primeira resposta `Servidor B` |           |
| **Indisponibilidade total**    |           |

### Testes de limite

- Attach da ENI no `case003-cliente` (outra AZ):
- Detach da eth0 de `case003-app-a`:

### Ciclo de vida das ENIs (preencher a Previsão ANTES do terminate)

| ENI                         | Criada como (auto/manual) | Anexada em (antes do terminate) | Delete on termination | Previsão | Resultado após terminate | Bateu? |
| --------------------------- | ------------------------- | ------------------------------- | --------------------- | -------- | ------------------------ | ------ |
| eth0 de `case003-app-a`     |                           |                                 |                       |          |                          |        |
| eth0 de `case003-app-b`     |                           |                                 |                       |          |                          |        |
| eth0 de `case003-cliente`   |                           |                                 |                       |          |                          |        |
| `case003-eni-servico`       |                           |                                 |                       |          |                          |        |

- Horário em que a previsão foi escrita:
- Horário do terminate:
- Divergências e explicação:
- Erro ao excluir `case003-app-sg` com ENIs órfãs presentes:

### Respostas

**Por que esse IP é o "IP do serviço", e não o da eth0?**


**Por que a ENI do serviço continuou existindo após o terminate das instâncias?**


**Por que a eth0 de `case003-app-b` não foi apagada, se ela foi criada automaticamente?**


**Por que um Elastic IP não resolveria o problema?**


**O que aconteceria com o reserva em outra AZ?**


**ENI × Elastic IP para failover:**


**Limitações e arquitetura recomendada:**


**Regra operacional para Delete on termination e ENIs órfãs:**
