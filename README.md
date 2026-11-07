# ☁️ SAA-C03 Architecture Cases

> Cases práticos de arquitetura AWS construídos durante minha preparação para a certificação **AWS Certified Solutions Architect – Associate (SAA-C03)**.

![AWS](https://img.shields.io/badge/AWS-SAA--C03-FF9900?logo=amazonaws&logoColor=white)
![Status](https://img.shields.io/badge/status-em%20andamento-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)

---

## 📖 Sobre o projeto

Ao longo da preparação para a SAA-C03, estudei, projetei, implementei, testei e documentei soluções para cenários inspirados em problemas que poderiam acontecer em empresas reais.

Este repositório reúne esse material. Cada case tem um **problema de negócio**, **requisitos técnicos** e um **desafio prático**, além de uma **implementação de referência** com diagramas, decisões de arquitetura e os **trade-offs** de cada escolha.

Os objetivos são:

- 🧠 Aprofundar conhecimento e desenvolver raciocínio arquitetural, indo além da memorização para a prova
- 🗂️ Montar um portfólio técnico que registre essa evolução
- 🤝 Ajudar outras pessoas que estudam AWS ou trabalham com Cloud, seja para certificação ou por desenvolvimento pessoal

Novos cases serão publicados diariamente.

---

## 🧭 Domínios abordados

| | Domínio | Exemplos de serviços |
|---|---|---|
| ☁️ | **Infraestrutura, EC2 e Networking** | EC2, VPC, Subnets, NAT Gateway, Route 53, Transit Gateway, VPC Endpoints |
| 🔐 | **Segurança, IAM e Governança** | IAM, Organizations, SCPs, KMS, Secrets Manager, WAF, GuardDuty, CloudTrail |
| 🏗️ | **Arquitetura e Alta Disponibilidade** | Multi-AZ, ELB, Auto Scaling, RDS Multi-AZ, Aurora, Route 53 failover |
| 📈 | **Escalabilidade e Performance** | CloudFront, ElastiCache, DynamoDB, SQS, Read Replicas, Global Accelerator |
| 💰 | **FinOps e Otimização de Custos** | Savings Plans, Spot, S3 Storage Classes, Cost Explorer, Budgets, Compute Optimizer |
| 🔄 | **Backup e Disaster Recovery** | AWS Backup, S3 Replication, Pilot Light, Warm Standby, Multi-Site, RPO/RTO |
| ⚙️ | **Serverless, Containers e Automação** | Lambda, API Gateway, Step Functions, EventBridge, ECS, EKS, Fargate |

---

## 🧩 Estrutura de cada case

Todo case segue o mesmo formato, para facilitar a leitura e a comparação entre soluções:

```
cases/
└── NN-nome-do-case/
    ├── README.md            # Cenário, problema, requisitos e desafio
    ├── solution/
    │   ├── SOLUTION.md      # Implementação de referência e passo a passo
    │   ├── DECISIONS.md     # Decisões arquiteturais (ADRs) e trade-offs
    │   └── iac/             # Código de infraestrutura (quando aplicável)
    └── diagrams/            # Diagramas da arquitetura
```

Cada `README.md` de case contém:

1. **📌 Cenário:** o contexto da empresa fictícia
2. **🚨 Problema de negócio:** a dor que precisa ser resolvida
3. **📋 Requisitos:** funcionais, não funcionais e restrições (custo, compliance, SLA, RPO/RTO)
4. **🎯 Desafio prático:** o que você precisa projetar ou implementar
5. **💡 Dicas:** serviços e conceitos para estudar antes de começar
6. **🔗 Referências:** documentação oficial e whitepapers relacionados

> 💭 **Sugestão:** tente resolver o desafio sozinho antes de abrir a pasta `solution/`. Comparar o seu raciocínio com a referência ensina mais do que só ler a resposta.

---

## 🗺️ Cases

| # | Case | Domínio | Status |
|---|---|---|---|
| 01 | [O servidor que "sumiu" toda manhã](001%20-%20%20O%20Servidor%20que%20sumia%20toda%20manha/README.MD) | ☁️ Infraestrutura & Networking | ✅ |
| 02 | _Em breve_ | 🔐 Segurança & IAM | 🔜 |
| 03 | _Em breve_ | 🏗️ Alta Disponibilidade | 🔜 |
| 04 | _Em breve_ | 📈 Escalabilidade & Performance | 🔜 |
| 05 | _Em breve_ | 💰 FinOps | 🔜 |
| 06 | _Em breve_ | 🔄 Backup & DR | 🔜 |
| 07 | _Em breve_ | ⚙️ Serverless & Containers | 🔜 |

**Legenda:** ✅ Publicado · 🚧 Em construção · 🔜 Em breve

---

## 🚀 Como usar este repositório

```bash
git clone https://github.com/<seu-usuario>/SAA-C03-Architecture-Cases.git
cd SAA-C03-Architecture-Cases/cases
```

1. Escolha um case e leia o `README.md` dele
2. Desenhe sua arquitetura (papel, draw.io, Excalidraw, o que preferir)
3. Implemente numa conta AWS **de estudo/sandbox**
4. Compare com a solução de referência e com os trade-offs documentados
5. Se encontrar uma abordagem diferente, abra um PR!

### ⚠️ Antes de implementar na sua conta

- **Custos:** alguns cases usam recursos que **não** entram no Free Tier (NAT Gateway, RDS Multi-AZ, EKS etc.). Configure um **AWS Budget** com alertas antes de começar.
- **Limpeza:** sempre destrua os recursos ao final. Cada solução traz instruções de *teardown*.
- **Conta isolada:** use uma conta dedicada a estudos, nunca uma conta de produção.
- **Credenciais:** nunca faça commit de access keys, secrets ou arquivos `.tfstate`. Prefira perfis do AWS CLI ou IAM Identity Center.
- **Versões fixadas:** as implementações em IaC usam versões fixas (pinned) de providers e módulos, para que o resultado seja reproduzível.

---

## 🤝 Como contribuir

Contribuições são muito bem-vindas! Você pode:

- 💡 Propor uma **solução alternativa** para um case, explicando os trade-offs
- 🐛 Corrigir erros técnicos, links quebrados ou trechos desatualizados
- 📝 Melhorar diagramas e documentação
- 🆕 Sugerir novos cenários via **Issue**

**Fluxo:**

1. Faça um fork do repositório
2. Crie uma branch: `git checkout -b feat/case-03-solucao-alternativa`
3. Faça commit das alterações: `git commit -m "feat(case-03): adiciona solução com Aurora Serverless"`
4. Envie para o seu fork: `git push origin feat/case-03-solucao-alternativa`
5. Abra um Pull Request descrevendo **o que** mudou e **por quê**

> Soluções alternativas devem ficar em `solution/alternatives/<seu-usuario>/`, com um `DECISIONS.md` explicando a abordagem.

---

## 📚 Recursos de estudo recomendados

- [AWS Certified Solutions Architect – Associate (página oficial)](https://aws.amazon.com/certification/certified-solutions-architect-associate/)
- [Exam Guide SAA-C03](https://d1.awsstatic.com/training-and-certification/docs-sa-assoc/AWS-Certified-Solutions-Architect-Associate_Exam-Guide.pdf)
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)
- [AWS Skill Builder](https://skillbuilder.aws/)

---

## ⚖️ Aviso

Os cenários são **fictícios** e servem apenas para fins educacionais. Todos os dados usados nos exemplos são **sintéticos**. Este projeto não tem afiliação nem endosso da Amazon Web Services. As implementações de referência são um ponto de partida para estudo e não devem ser usadas em produção sem revisão.

---

## 📄 Licença

Distribuído sob a licença **MIT**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👤 Autor

**Marco Gomes**

Se este conteúdo te ajudou, deixe uma ⭐ no repositório e compartilhe com quem também está estudando AWS!

`#AWS` `#AWSSolutionsArchitect` `#SAA_C03` `#CloudArchitecture` `#CloudComputing` `#DevOps`
