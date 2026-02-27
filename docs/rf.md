Requisitos Funcionais (RF)
STOX – Requisitos Funcionais
RF01 – Autenticação

O sistema deve permitir autenticação via SAP Business One Service Layer.

RF02 – Leitura de Código de Barras

O aplicativo deve permitir leitura de código de barras utilizando a câmera do dispositivo móvel.

RF03 – Consulta de Item

O sistema deve consultar informações do item no SAP B1 via endpoint:
/b1s/v2/Items

RF04 – Registro de Contagem

O sistema deve registrar contagens de inventário utilizando:
/b1s/v2/InventoryCounting

RF05 – Atualização de Inventário

O sistema deve permitir envio da contagem para atualização no SAP B1.

RF06 – Contagem via IA

O sistema deve permitir contagem automática de peças utilizando modelo YOLO.

RF07 – Relatórios

O sistema deve gerar relatórios de inventário com:

Itens contados

Divergências

Usuário responsável

Data e hora

RF08 – Histórico

O sistema deve manter histórico de inventários realizados.