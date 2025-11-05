# **Simulador de Autômatos em Haskell**

O projeto `Simulador de Autômatos` é uma implementação robusta em Haskell para a manipulação e simulação de **Autômatos Finitos Não-Determinísticos (AFND)**, com suporte completo a **transições-épsilon ($\epsilon$)**.

Utilizando a biblioteca **`fgl` (Functional Graph Library)** como seu núcleo, o simulador é capaz de modelar e executar autômatos complexos. Ele combina o módulo `Automato`, que fornece a lógica de simulação, com o módulo `Menu`, que oferece uma interface de console interativa.

O simulador permite carregar dinamicamente autômatos de arquivos `.json`, testar palavras de arquivos `.txt` e salvar os resultados da simulação.

## **Visão Geral**

Este projeto implementa um simulador interativo para Autômatos Finitos Não-Determinísticos (AFND) em Haskell. O núcleo do simulador é construído sobre um grafo (`fgl`), permitindo-lhe modelar e executar a lógica complexa de AFNDs, incluindo:

  - Simulação de múltiplos caminhos de execução simultaneamente.
  - Processamento de transições-épsilon ($\epsilon$) para calcular o "fecho-épsilon" antes de consumir cada símbolo da palavra.

A interface do usuário, contida no módulo `Menu`, permite a **seleção dinâmica de arquivos** de um diretório, tornando o uso flexível e prático.

-----

## **Funcionalidades Principais**

### **1. Carregamento Dinâmico de Arquivos**

O menu interativo permite ao usuário navegar e selecionar arquivos dinamicamente:

  - **Opção 1 (Carregar Autômato):** Lista e carrega arquivos `.json` de um diretório de autômatos (ex: `exemplos/`).
  - **Opção 3.2 (Testar em Lote):** Lista e carrega arquivos `.txt` contendo listas de palavras para teste.

### **2. Teste de Palavras**

  - Permite testar palavras individualmente ou em lote (via seleção de arquivo `.txt`).
  - Os resultados da simulação são detalhados, mostrando o **conjunto de estados ativos** em cada etapa do processo.

### **3. Visualizar e Salvar Resultados**

  - **Visualizar Informações:** Exibe no console os detalhes do AFND carregado (alfabeto, estados, finais e todas as transições, incluindo $\epsilon$).
  - **Salvar Resultados:** Exporta os resultados dos testes (palavra, status de aceitação e histórico de estados) para um arquivo JSON especificado pelo usuário.

-----

## **Formato do JSON de Entrada**

Para suportar a natureza flexível dos AFNDs, o formato de entrada é uma lista plana de transições.

**Importante:** Transições-épsilon ($\epsilon$) são definidas usando `"simbolo": null` no arquivo JSON.

### Exemplo de JSON (para `afnd_comeca_0_termina_1.json`)

```json
{
  "alfabeto": ["0", "1"],
  "estadoInicial": "q0",
  "estadosFinais": ["q_final"],
  "transicoes": [
    
    { "origem": "q0", "simbolo": null, "destino": "q_start" },

    { "origem": "q_start", "simbolo": "0", "destino": "q_loop" },
    
    { "origem": "q_loop", "simbolo": "0", "destino": "q_loop" },
    
    { "origem": "q_loop", "simbolo": "1", "destino": "q_loop" },
    
    { "origem": "q_loop", "simbolo": "1", "destino": "q_final" }
  ]
}
```

### Exemplo de JSON (para `afd_zeros_pares.json`)

```json
{
  "alfabeto": ["0", "1"],
  "estadoInicial": "par",
  "estadosFinais": ["par"],
  "transicoes": [
    { "origem": "par", "simbolo": "0", "destino": "impar" },
    { "origem": "par", "simbolo": "1", "destino": "par" },
    { "origem": "impar", "simbolo": "0", "destino": "par" },
    { "origem": "impar", "simbolo": "1", "destino": "impar" }
  ]
}
```

-----

## **Estrutura do Projeto**

O projeto é dividido em três módulos principais:

### **1. Módulo `Main` (`Main.hs`)**

  - Ponto de entrada (entrypoint) do programa.
  - Sua única responsabilidade é importar e chamar a função `iniciarMenu` do módulo `Menu`.

### **2. Módulo `Menu` (`Menu.hs`)**

  - Implementa toda a interface de usuário interativa via console.
  - Gerencia o estado da aplicação (o `Maybe Automato` carregado).
  - Funções principais:
      - `iniciarMenu :: IO ()`: Inicia o programa e o loop principal.
      - `mainLoop :: Maybe Automato -> IO ()`: Controla o loop do menu.
      - `selecionarArquivo :: FilePath -> String -> IO (Maybe FilePath)`: Função genérica para listar e selecionar arquivos (`.json` ou `.txt`).

### **3. Módulo `Automato` (`Automato.hs`)**

  - O "cérebro" do simulador. Define as estruturas de dados e a lógica de simulação do AFND.
  - **Tipos**:
      - `Automato`: Representa o autômato.
          - `grafo :: Gr String (Maybe String)`: O grafo `fgl` onde os nós são `String` (nomes dos estados) e as arestas são `Maybe String` (símbolos ou `Nothing` para $\epsilon$).
          - `mapaDeNos :: Map String Node`: Mapeamento de nomes de estado para IDs de nó do `fgl`.
      - `ResultadoTeste`:
          - `estadosPercorridos :: [[String]]`: O histórico de conjuntos de estados ativos (uma lista de listas de strings).
      - `JsonAutomato`: Tipo auxiliar usado para decodificar a estrutura de JSON.
  - **Funções principais**:
      - `criarAutomato :: FilePath -> IO Automato`: Lê o JSON, constrói o grafo `fgl` e retorna um `Automato`.
      - `testePalavra :: Automato -> String -> IO ResultadoTeste`: Executa a simulação completa do AFND, gerenciando conjuntos de estados e fechos-épsilon.
      - `fechoEpsilon :: ... -> Set Node`: Lógica interna para calcular o fecho-épsilon.

-----

## **Dependências**

O projeto requer as seguintes bibliotecas Haskell:

  - **`fgl`**: A Functional Graph Library, núcleo da implementação do grafo.
  - **`aeson`**: Para manipulação (parse e encode) de JSON.
  - **`aeson-pretty`**: Para salvar os resultados em JSON formatado.
  - **`bytestring`**: Para ler e escrever arquivos.
  - **`containers`**: Para uso de `Data.Set` e `Data.Map`.
  - **`directory`**: Para listar o conteúdo de diretórios (usado no `Menu`).
  - **`filepath`**: Para manipular caminhos de arquivo e extensões (usado no `Menu`).
  - `base`: Biblioteca padrão.
