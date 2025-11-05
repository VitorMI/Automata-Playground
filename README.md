# Automata-Playground

O objetivo do simulador é permitir que o usuário defina um **AFND (Autômato Finito Não-Determinístico)**, incluindo suporte a **transições-épsilon ($\epsilon$)**, insira sequências de entrada e veja se elas são aceitas ou rejeitadas. O simulador também exibe o histórico de *conjuntos* de estados percorridos durante a simulação.

O projeto possui duas versões em linguagens distintas: Haskell e Prolog.

## Funcionalidades (Versão Haskell)

| ID | Funcionalidade | Descrição |
|----|--------------|-------------|
| 1 | Definir Autômato por arquivo JSON | Permite ao usuário definir a estrutura de AFDs, AFNDs e transições-épsilon, utilizando um arquivo JSON. |
| 2 | Testar sequência | Permite ao usuário testar uma sequência de entrada no autômato definido, retornando se a sequência foi aceita ou rejeitada. |
| 3 | Visualizar caminho percorrido | Mostra o histórico de *conjuntos* de estados visitados (ex: `{q0,q1} -> {q2}`), essencial para a simulação de AFNDs. |
| 4 | Exportar resultados para arquivo JSON | Exporta os resultados da simulação (aceitação e histórico de estados) para um arquivo no formato JSON. |
| 5 | Interface de linha de comando | Fornece um menu interativo para carregar autômatos (`.json`) e listas de palavras (`.txt`) dinamicamente de diretórios. |

-----

## Como Rodar o Projeto

### Pré-requisitos

Antes de executar o projeto, certifique-se de que as seguintes ferramentas estão instaladas no seu sistema:

  - **Haskell**: Instalar GHC e Cabal (ou Stack).
  - **Prolog**: Instalar SWI-Prolog.
  - **Git**: Instalar Git.

### Passos para Executar

#### 1\. Clonar o Repositório

Abra o terminal e clone o repositório usando o comando:

```sh
git clone https://github.com/seu-usuario/Automata-Playground.git
cd Automata-Playground
```

#### 2\. Versão em Haskell

A versão em Haskell é um simulador de AFND completo com interface de menu.

##### Dependências Principais

O projeto requer as seguintes bibliotecas (que serão gerenciadas pelo Cabal ou Stack):

  - `fgl`: A Functional Graph Library, núcleo da simulação.
  - `aeson`: Para manipulação de JSON.
  - `directory`: Para listar arquivos no menu.
  - `filepath`: Para manipular caminhos e extensões de arquivos.
  - `containers`, `bytestring`, `aeson-pretty`

##### Instalar Dependências

Usando Cabal, na pasta do projeto:

```sh
cabal update
cabal install --dependencies-only
```

##### Compilar o Projeto

```sh
cabal build
```

##### Executar o Simulador

Execute o simulador com o seguinte comando (o nome pode variar dependendo do seu arquivo `.cabal`):

```sh
cabal run Automato-Playground
```

#### 3\. Versão em Prolog

Para rodar a versão em Prolog, siga os passos abaixo:

##### Instalar Dependências

Certifique-se de que o SWI-Prolog está instalado.

##### Executar o Simulador

Abra o SWI-Prolog no terminal e carregue o arquivo principal do projeto:

```sh
[main].
```

Depois, inicie a simulação executando o seguinte comando dentro do SWI-Prolog:

```prolog
main.
```

-----

#### 4\. Arquivo JSON de Entrada (Haskell)

A versão em Haskell usa um formato JSON flexível que suporta AFNDs. O campo `transicoes` é uma **lista plana** de objetos. Transições-épsilon ($\epsilon$) são definidas usando `"simbolo": null`.

##### Exemplo 1: AFD

```json
{
  "alfabeto": ["0", "1"],
  "estadoInicial": "q0",
  "estadosFinais": ["q2"],
  "transicoes": [
    { "origem": "q0", "simbolo": "0", "destino": "q1" },
    { "origem": "q0", "simbolo": "1", "destino": "q0" },
    { "origem": "q1", "simbolo": "0", "destino": "q1" },
    { "origem": "q1", "simbolo": "1", "destino": "q2" },
    { "origem": "q2", "simbolo": "0", "destino": "q1" },
    { "origem": "q2", "simbolo": "1", "destino": "q0" }
  ]
}
```

##### Exemplo 2: AFND

```json
{
  "alfabeto": ["0", "1"],
  "estadoInicial": "q0",
  "estadosFinais": ["q3"],
  "transicoes": [
    { "origem": "q0", "simbolo": null, "destino": "q1" },
    { "origem": "q0", "simbolo": null, "destino": "q2" },
    { "origem": "q1", "simbolo": "0", "destino": "q1" },
    { "origem": "q1", "simbolo": "0", "destino": "q3" },
    { "origem": "q2", "simbolo": "1", "destino": "q2" },
    { "origem": "q2", "simbolo": "1", "destino": "q3" },
    { "origem": "q3", "simbolo": "0", "destino": "q3" },
    { "origem": "q3", "simbolo": "1", "destino": "q3" }
  ]
}
```

## Observações

  - Certifique-se de que os diretórios (ex: `exemplos/`) contenham seus arquivos `.json` e `.txt` para que o menu da versão Haskell possa encontrá-los.