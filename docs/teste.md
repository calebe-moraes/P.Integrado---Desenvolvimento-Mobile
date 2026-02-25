# 🧪 Plano de Testes – EcoLog Mobile

## 1. 📌 Objetivo

Este documento descreve a estratégia de validação e verificação do sistema EcoLog Mobile, garantindo que o aplicativo móvel e suas integrações com APIs e Inteligência Artificial funcionem corretamente, de forma segura e confiável.

O objetivo é assegurar qualidade, estabilidade e aderência aos requisitos definidos no projeto.

---

# 2. 🎯 Estratégia de Teste

Serão aplicados os seguintes tipos de teste:

- ✅ Testes de Unidade
- ✅ Testes de Interface (UI)
- ✅ Testes de Integração (API e IA)
- ✅ Testes Manuais Exploratórios

Ferramentas previstas:
- Jest (Backend)
- React Native Testing Library (Mobile)
- Testes via Postman (API)
- Testes de integração com módulo de IA

---

# 3. 🧪 Testes de Unidade

## 🔹 TU01 – Validação de Login

Requisito relacionado: RF01

Objetivo:
Garantir que o sistema valide corretamente credenciais do usuário.

Entrada válida:
email: usuario@email.com  
senha: 123456  

Resultado esperado:
Usuário autenticado com sucesso.

Entrada inválida:
email: incorreto@email.com  
senha: 123  

Resultado esperado:
Mensagem de erro exibida.

---

## 🔹 TU02 – Registro de Nova Pesagem

Requisito relacionado: RF03

Objetivo:
Verificar se o sistema registra corretamente os dados obrigatórios da pesagem.

Campos obrigatórios:
- Placa
- Peso
- Data

Resultado esperado:
Registro salvo no banco de dados.

---

# 4. 📱 Testes de Interface (UI)

## 🔹 TUI01 – Carregamento do Dashboard

Requisito relacionado: RF02

Objetivo:
Garantir que o dashboard carregue corretamente os indicadores logísticos.

Resultado esperado:
- Número de veículos exibido
- Total de pesagens exibido
- Peso total exibido
- Tempo de carregamento menor que 3 segundos (RNF02)

---

## 🔹 TUI02 – Navegação entre Telas

Objetivo:
Validar se o usuário consegue navegar entre:
- Dashboard
- Histórico
- Nova Pesagem
- Relatórios

Resultado esperado:
Transição sem travamentos ou erros.

---

# 5. 🔗 Testes de Integração

## 🔹 TI01 – Integração com API Externa

Requisito relacionado: RF05

Objetivo:
Verificar se o aplicativo consome corretamente os dados da API externa.

Resultado esperado:
Dados recebidos em formato JSON válido e exibidos corretamente no app.

---

## 🔹 TI02 – Integração com IA

Requisito relacionado: RF06

Objetivo:
Garantir que o sistema receba análises e previsões da IA.

Entrada:
Dados históricos de pesagens.

Resultado esperado:
Exibição de:
- Previsão de fluxo logístico
- Recomendações sustentáveis
- Alertas de gargalo

---

# 6. 🌱 Testes Relacionados à Sustentabilidade

## 🔹 TS01 – Cálculo de Emissão Estimada de CO₂

Requisito relacionado: RF07

Objetivo:
Validar se o sistema calcula corretamente estimativas ambientais.

Resultado esperado:
Exibição de indicador ambiental com base no tempo médio de espera.

---

# 7. 📊 Matriz de Rastreabilidade

| Requisito | Tipo de Teste | Código do Teste |
|-----------|--------------|----------------|
| RF01 | Unidade | TU01 |
| RF02 | Interface | TUI01 |
| RF03 | Unidade | TU02 |
| RF05 | Integração | TI01 |
| RF06 | Integração | TI02 |
| RF07 | Sustentabilidade | TS01 |

---

# 8. 📌 Critérios de Aceitação Geral

O sistema será considerado validado quando:

- Todos os testes críticos passarem com sucesso
- Não houver falhas de autenticação
- A IA retornar respostas válidas
- O tempo de resposta estiver dentro do limite definido
- O aplicativo não apresentar travamentos durante navegação

---

# 9. 🚀 Evolução Futura

Em versões futuras, poderão ser incluídos:
- Testes automatizados de ponta a ponta (E2E)
- Testes de carga
- Testes de segurança avançados
- Monitoramento contínuo de qualidade
