# 📋 Documento de Requisitos – EcoLog Mobile

## 📱 Nome do Sistema
EcoLog Mobile – Aplicativo de Monitoramento Logístico Sustentável com Inteligência Artificial

---

# 1. 📌 Visão Geral do Sistema
O EcoLog Mobile é um aplicativo móvel que tem como objetivo monitorar operações logísticas e de pesagem rodoviária em tempo real, utilizando Inteligência Artificial para gerar análises sustentáveis, previsões de fluxo de veículos e recomendações que reduzam impactos ambientais, como emissão de CO₂ e desperdício de recursos.

O sistema será integrado a APIs externas (como sistemas de pesagem ou ERP), permitindo a transformação digital de processos logísticos locais.

---

# 2. 🎯 Problema que o Sistema Resolve
A falta de monitoramento inteligente nas operações logísticas gera:
- Filas de caminhões
- Desperdício de combustível
- Aumento da emissão de poluentes
- Ineficiência operacional
- Falta de dados para tomada de decisão sustentável

---

# 3. 👥 Atores do Sistema
- Administrador
- Operador de Pesagem
- Gestor Logístico
- Sistema de IA (API inteligente)

---

# 4. ⚙️ Requisitos Funcionais (RF)

### RF01 – Autenticação de Usuário
O sistema deve permitir que o usuário realize login com e-mail e senha.

Critério de Aceitação:
- O usuário deve conseguir acessar o sistema com credenciais válidas.
- O sistema deve exibir mensagem de erro para login inválido.

---

### RF02 – Visualizar Dashboard Logístico
O aplicativo deve exibir um dashboard com dados logísticos em tempo real.

Critério de Aceitação:
- Exibir número de veículos no pátio
- Exibir total de pesagens do dia
- Exibir peso total movimentado

---

### RF03 – Registrar Nova Pesagem
O sistema deve permitir o registro de novas pesagens de veículos.

Critério de Aceitação:
- Registrar placa do veículo
- Registrar peso de entrada/saída
- Armazenar data e hora automaticamente

---

### RF04 – Consultar Histórico de Pesagens
O usuário deve poder visualizar o histórico de pesagens registradas.

Critério de Aceitação:
- Filtrar por data
- Filtrar por placa
- Exibir lista organizada por ordem cronológica

---

### RF05 – Integração com API Externa
O sistema deve consumir dados de uma API externa (ERP ou sistema de pesagem).

Critério de Aceitação:
- Receber dados em tempo real
- Atualizar informações automaticamente no app

---

### RF06 – Geração de Insights com Inteligência Artificial
O aplicativo deve exibir análises geradas por IA com base nos dados logísticos.

Critério de Aceitação:
- Exibir previsões de fluxo de veículos
- Exibir recomendações sustentáveis
- Exibir alertas de gargalos operacionais

---

### RF07 – Relatórios Sustentáveis
O sistema deve gerar relatórios sobre impacto ambiental das operações.

Critério de Aceitação:
- Mostrar estimativa de emissão de CO₂
- Mostrar tempo médio de espera no pátio
- Exportar relatório em PDF (futuramente)

---

# 5. 🔒 Requisitos Não Funcionais (RNF)

### RNF01 – Usabilidade
O aplicativo deve possuir interface intuitiva e responsiva para dispositivos móveis.

### RNF02 – Desempenho
O sistema deve carregar as principais informações do dashboard em até 3 segundos.

### RNF03 – Segurança
Os dados dos usuários devem ser protegidos por autenticação e validação de acesso.

### RNF04 – Disponibilidade
O aplicativo deve estar disponível 24/7 para monitoramento logístico contínuo.

### RNF05 – Escalabilidade
O sistema deve suportar integração futura com novos módulos de IA e APIs externas.

### RNF06 – Compatibilidade
O aplicativo deve funcionar em dispositivos Android (principal foco do projeto).

---

# 6. 📜 Regras de Negócio (RN)

### RN01 – Registro Obrigatório de Dados
Toda pesagem deve conter placa, peso e data para ser validada no sistema.

### RN02 – Atualização em Tempo Real
Os dados logísticos devem ser atualizados automaticamente sempre que houver nova pesagem.

### RN03 – Análise Sustentável
A IA deve utilizar dados históricos para gerar recomendações relacionadas à eficiência e sustentabilidade.

### RN04 – Controle de Acesso
Apenas usuários autenticados podem acessar os dados do sistema.

---

# 7. 🤖 Requisitos Relacionados à Inteligência Artificial
- O sistema deve integrar uma IA para análise de dados logísticos
- A IA deve gerar insights sustentáveis
- A IA deve auxiliar na previsão de fluxo operacional
- A IA deve melhorar a tomada de decisão do gestor

---

# 8. 🌱 Requisitos de Sustentabilidade (Alinhamento ao Projeto Integrado)
O sistema deve:
- Reduzir desperdício operacional
- Contribuir para a diminuição da emissão de CO₂
- Promover a digitalização de processos logísticos
- Apoiar decisões baseadas em dados sustentáveis

ODS Relacionados:
- ODS 9: Indústria, Inovação e Infraestrutura
- ODS 12: Consumo e Produção Responsáveis
- ODS 13: Ação Contra a Mudança Climática
