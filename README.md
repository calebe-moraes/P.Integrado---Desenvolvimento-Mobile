---

#  STOX

### Intelligent Inventory Management Platform

*Enterprise Mobile Solution Integrated with SAP Business One*

---

##  Executive Summary

**Stox** é uma plataforma móvel corporativa desenvolvida para modernizar e automatizar o processo de inventário do Grupo JCN, substituindo coletores físicos e processos manuais baseados em planilhas por uma solução integrada, inteligente e em tempo real.

O sistema conecta-se diretamente ao **SAP Business One (Service Layer API)** e utiliza **Visão Computacional com YOLO** para reconhecimento e contagem automática de peças.

O projeto foi desenvolvido como parte do **Projeto Integrado (PI)** do curso de Análise e Desenvolvimento de Sistemas da UNIFEOB.

---

##  Business Context

### Empresa Parceira

Grupo JCN
São João da Boa Vista – SP

### Cenário Atual

O processo atual de inventário envolve:

1. Uso de coletores físicos alugados
2. Exportação de dados
3. Tratamento manual em planilhas Excel
4. Importação posterior para o SAP B1

### Problemas Identificados

* Alto custo operacional com aluguel de equipamentos
* Retrabalho manual
* Risco elevado de erro humano
* Processo não integrado
* Baixa rastreabilidade em tempo real

---

##  Project Objectives

O Stox foi projetado para:

* Eliminar a dependência de coletores físicos
* Integrar inventários diretamente ao SAP Business One
* Permitir leitura de código de barras via câmera do smartphone
* Automatizar contagens utilizando Inteligência Artificial
* Gerar relatórios analíticos automáticos
* Reduzir custos operacionais
* Aumentar a confiabilidade dos dados

---

#  Enterprise Infrastructure & Development Environment

Um dos grandes diferenciais do projeto Stox é que todo o ambiente de desenvolvimento foi construído **on-premises**, configurado do zero, simulando um cenário corporativo real de produção.

##  Ambiente SAP

* Instalação completa do **SAP Business One**
* Configuração do **SAP Service Layer**
* Banco de dados **SBODemoBR (SQL Server)**
* Ambiente isolado para desenvolvimento
* Nenhuma informação crítica ou sensível da empresa foi utilizada

Todo o ambiente foi preparado exclusivamente para desenvolvimento e testes, garantindo segurança, controle e independência da infraestrutura oficial da empresa.

---

##  Infraestrutura de Rede

A infraestrutura foi planejada para oferecer:

* Abertura controlada e segura de portas
* Publicação segura da API
* Configuração de DNS próprio
* Roteador de borda dedicado
* Controle de firewall
* Comunicação via HTTPS

O objetivo foi disponibilizar uma **API estável, segura e performática** para integração com o aplicativo mobile.

---

##  Virtualização e Backup

A arquitetura inclui:

* **VMware** para virtualização do ambiente
* **Veeam Backup** para políticas de backup e recuperação
* Isolamento de máquinas virtuais
* Ambiente preparado para simular produção real

Essa estrutura garante:

* Alta disponibilidade para desenvolvimento
* Segurança de dados
* Recuperação em caso de falhas
* Ambiente escalável

---

##  Segurança

* Ambiente isolado (on-premises)
* Banco de dados de demonstração (SBODemoBR)
* Controle de portas e firewall
* Sem uso de dados reais da empresa
* Autenticação via Service Layer
* Comunicação criptografada (HTTPS)

O ambiente foi construído com foco em boas práticas de segurança da informação.

---

##  Artificial Intelligence Integration

### YOLO – You Only Look Once

O Stox integra um modelo de visão computacional baseado em YOLO para:

* Reconhecimento visual de peças
* Contagem automática de múltiplos itens
* Identificação de produtos
* Validação visual de inventário

### Capacidades Futuras de IA

* Detecção automática de divergências
* Geração inteligente de relatórios
* Sugestões preditivas de reposição
* Análise de padrões de inventário

---

##  System Architecture Overview

### Camadas do Sistema

**1️ Aplicativo Mobile (Flutter)**
Interface, leitura de código de barras, captura de imagens e comunicação com API.

**2️ Camada de Integração (Service Layer)**
Autenticação, controle de sessão e comunicação segura com SAP.

**3️ SAP Business One**
Registro oficial de inventário e atualização de estoque.

**4️ Motor de IA (YOLO)**
Processamento de imagem e contagem automática.

---

##  Core Features

*  Leitura de código de barras via câmera
*  Contagem automática com IA
*  Integração em tempo real com SAP B1
*  Relatórios inteligentes
*  Comunicação segura

---

##  Technology Stack

| Camada         | Tecnologia             |
| -------------- | ---------------------- |
| Mobile         | Flutter                |
| ERP            | SAP Business One       |
| API            | SAP Service Layer      |
| Banco de Dados | SQL Server (SBODemoBR) |
| IA             | YOLO                   |
| Linguagem IA   | Python                 |
| Virtualização  | VMware                 |
| Backup         | Veeam                  |
| Comunicação    | REST API (HTTPS)       |
| Versionamento  | Git                    |

---

##  Expected Business Impact

* Redução significativa de custos operacionais
* Eliminação de aluguel de coletores
* Automação completa do inventário
* Redução de erros humanos
* Modernização tecnológica do Grupo JCN

---

#  Development Team

| Name                            | RA       |
| ------------------------------- | -------- |
| Calebe Matheus Moreira Moraes   | 24000974 |
| Gustavo de Moraes Donadello     | 24000419 |
| Márcio Augusto Garcia Soares    | 24000138 |
| Lucas Vigo Calió                | 24000092 |
| Mateus Oliveira Milane          | 24000308 |
| Leandro José de Carvalho Coelho | 24001964 |

---

#  Academic Advisors

| Discipline                 | Professor                      |
| -------------------------- | ------------------------------ |
| Artificial Intelligence    | Rodrigo Marudi de Oliveira     |
| Software Quality & Testing | Marcelo Ciacco de Almeida      |
| Mobile Development         | Nivaldo de Andrade             |
| Software Engineering       | Max Streicher Vallim           |
| PI Coordinator             | Mariangela Martimbianco Santos |

---

##  Academic Context

Curso: Análise e Desenvolvimento de Sistemas
Instituição: UNIFEOB
Projeto: PI – Projeto Integrado

---

##  License

Projeto acadêmico desenvolvido para fins educacionais, utilizando ambiente controlado on-premises e banco de dados de demonstração.

---