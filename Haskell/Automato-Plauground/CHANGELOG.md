# Revision history for Automato-Plauground

## 2.0 -- 2025-11-05

### Added
* **Suporte a AFND:** O simulador agora suporta Autômatos Finitos Não-Determinísticos (AFND).
* **Suporte a Transições-Épsilon ($\epsilon$):** O simulador processa transições-épsilon (definidas como `"simbolo": null` no JSON).
* **Menu Dinâmico de Arquivos:** O menu agora lista e permite a seleção de arquivos `.json` (autômatos) e `.txt` (palavras) de diretórios.
* **Melhoria na Formatação:** A saída de teste foi melhorada para mostrar o histórico de *conjuntos* de estados (ex: `{q0,q1} -> {q2}`).
* **Novas Dependências:** Adicionado `fgl`, `directory`, e `filepath`.

### Changed
* **QUEBRA DE COMPATIBILIDADE:** O núcleo do simulador foi refatorado de `Data.Map` para a biblioteca **`fgl` (Functional Graph Library)**.
* **QUEBRA DE COMPATIBILIDADE:** O formato do JSON foi alterado de um mapa aninhado para uma **lista plana de transições** para suportar AFNDs.
* O módulo `Menu.hs` foi introduzido para separar a lógica de UI do `Main.hs`.
* O `README.md` foi completamente atualizado para refletir as novas funcionalidades.

### Fixed
* Corrigido um crash (padrão não-exaustivo) que ocorria em `testePalavra` se o `estadoInicial` do JSON não fosse encontrado no grafo.
* Removidos todos os avisos do compilador (imports não utilizados, sombreamento de nomes).

### Removed
* Removida a implementação antiga (somente AFD) baseada em `Data.Map`.
* Removidos os caminhos de arquivo fixos (hardcoded) do menu.

## 1.0 -- 2024-12-12

### Added
* Primeira versão do simulador.
* Implementação de um simulador para **Autômatos Finitos Determinísticos (AFD)**.
* Lógica de transição baseada em `Data.Map` (mapas aninhados).
* Interface de menu interativo via console.
* Funcionalidade para carregar autômato de um arquivo JSON fixo (`automato.json`).
* Teste de palavras individuais inseridas pelo usuário.
* Teste de palavras em lote lidas de um arquivo de texto fixo (`palavras.txt`).
* Visualização formatada das informações do autômato (alfabeto, estados, transições).
* Funcionalidade para salvar resultados de testes em um arquivo JSON.