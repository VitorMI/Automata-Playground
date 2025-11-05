-- Define o módulo Menu e exporta apenas a função 'iniciarMenu'
module Menu (iniciarMenu) where

-- Importações do núcleo do Automato
import Automato
  ( Automato,
    ResultadoTeste (..),
    criarAutomato,
    imprimirAutomato,
    salvarResultados,
    testePalavra,
  )

-- Importações padrão do Haskell
import Control.Monad (forM, forM_)
import System.IO (hFlush, stdout)
import System.Directory (doesDirectoryExist, listDirectory)
import System.FilePath ((</>), takeExtension)
import Data.List (sort, intercalate)
import Text.Read (readMaybe)

-- --- Caminhos Padrão ---
-- Diretórios para busca de arquivos
defaultJsonDir :: FilePath
defaultJsonDir = "exemplos"

defaultPalavrasDir :: FilePath
defaultPalavrasDir = "exemplos"

-- | Função principal do menu, a ser chamada pelo Main.hs
iniciarMenu :: IO ()
iniciarMenu = do
  putStrLn "==============================="
  putStrLn "   Simulador de Autômatos"
  putStrLn "==============================="
  putStrLn "Bem-vindo!"
  putStrLn "Nenhum autômato carregado."
  -- Inicia o loop com o estado inicial (nenhum autômato carregado)
  mainLoop Nothing

-- | Loop principal do menu, agora privado a este módulo.
-- Ele gerencia o estado do autômato (Maybe Automato).
mainLoop :: Maybe Automato -> IO ()
mainLoop mAutomato = do
  printHeader "MENU PRINCIPAL"
  putStrLn "1. Carregar autômato (.json)"
  putStrLn "2. Visualizar informações do autômato"
  putStrLn "3. Testar palavra(s)"
  putStrLn "4. Salvar resultados dos testes em JSON"
  putStrLn "5. Sair"
  putStr "Escolha uma opção: "
  hFlush stdout
  opcao <- getLine
  case opcao of
    "1" -> carregarJSON mAutomato >>= mainLoop
    "2" -> visualizarInfo mAutomato >>= mainLoop
    "3" -> testarPalavras mAutomato >>= mainLoop
    "4" -> salvarTestes mAutomato >>= mainLoop
    "5" -> putStrLn "\nSaindo... Até logo!"
    _   -> do
      printError "Opção inválida. Tente novamente."
      mainLoop mAutomato

-- | Carrega um autômato via seletor de menu
carregarJSON :: Maybe Automato -> IO (Maybe Automato)
carregarJSON automatoAntigo = do
  printHeader "1. CARREGAR AUTÔMATO (.json)"
  putStrLn $ "Procurando arquivos .json em '" ++ defaultJsonDir ++ "'..."
  
  maybeCaminho <- selecionarArquivo defaultJsonDir ".json"
  
  case maybeCaminho of
    Nothing -> do
      putStrLn "Seleção cancelada. Mantendo autômato anterior (se houver)."
      return automatoAntigo
      
    Just caminho -> do
      putStrLn $ "\nCarregando autômato de: " ++ caminho
      -- TODO: Adicionar tratamento de exceção para 'criarAutomato'
      novoAutomato <- criarAutomato caminho
      printSuccess "Autômato carregado com sucesso!"
      return (Just novoAutomato)

-- | Visualiza informações do autômato
visualizarInfo :: Maybe Automato -> IO (Maybe Automato)
visualizarInfo Nothing = do
  printHeader "2. VISUALIZAR AUTÔMATO"
  printError "Nenhum autômato carregado."
  putStrLn "Por favor, carregue um autômato primeiro (Opção 1)."
  return Nothing
visualizarInfo (Just automato) = do
  -- A própria função 'imprimirAutomato' já tem a formatação
  putStrLn $ imprimirAutomato automato
  return (Just automato)

-- | Testa palavras individualmente ou em lote
testarPalavras :: Maybe Automato -> IO (Maybe Automato)
testarPalavras Nothing = do
  printHeader "3. TESTAR PALAVRAS"
  printError "Nenhum autômato carregado."
  putStrLn "Por favor, carregue um autômato primeiro (Opção 1)."
  return Nothing
testarPalavras (Just automato) = do
  printHeader "3. TESTAR PALAVRAS"
  putStrLn "1. Palavra individual"
  putStrLn "2. Arquivo de palavras (.txt)"
  putStr "Escolha uma opção: "
  hFlush stdout
  opcao <- getLine
  case opcao of
    "1" -> do
      putStr "Digite a palavra a ser testada: "
      hFlush stdout
      palavraTestada <- getLine
      resultado <- testePalavra automato palavraTestada
      -- Imprime o resultado formatado
      putStrLn $ formatarResultado resultado
      return (Just automato)
      
    "2" -> do
      putStrLn $ "\nProcurando arquivos .txt em '" ++ defaultPalavrasDir ++ "'..."
      maybeCaminho <- selecionarArquivo defaultPalavrasDir ".txt"
      
      case maybeCaminho of
        Nothing -> do
          putStrLn "Seleção de arquivo cancelada."
          return (Just automato)
          
        Just caminhoTxt -> do
          putStrLn $ "\nCarregando palavras do arquivo: " ++ caminhoTxt
          conteudo <- readFile caminhoTxt
          let palavras = lines conteudo
          
          resultados <- forM palavras (testePalavra automato)
          
          printSeparator
          putStrLn $ "Resultados do teste para '" ++ caminhoTxt ++ "':"
          -- Imprime todos os resultados formatados
          forM_ resultados (putStrLn . formatarResultado)
          printSeparator
          return (Just automato)
          
    _ -> do
      printError "Opção inválida."
      return (Just automato)

-- | Salva os resultados dos testes em um arquivo JSON
salvarTestes :: Maybe Automato -> IO (Maybe Automato)
salvarTestes Nothing = do
  printHeader "4. SALVAR RESULTADOS"
  printError "Nenhum autômato carregado."
  return Nothing
salvarTestes (Just automato) = do
  printHeader "4. SALVAR RESULTADOS"
  putStrLn "Digite as palavras a serem testadas (separadas por espaço): "
  hFlush stdout
  entrada <- getLine
  let palavras = words entrada
  resultados <- forM palavras (testePalavra automato)
  putStr "Digite o nome do arquivo para salvar os resultados (ex: resultados.json): "
  hFlush stdout
  arquivo <- getLine
  salvarResultados arquivo resultados
  printSuccess $ "Resultados salvos com sucesso em " ++ arquivo
  return (Just automato)

-- --- Funções Auxiliares de Formatação ---
formatarResultado :: ResultadoTeste -> String
formatarResultado resultado =
  unlines [
    "---------------------------------------",
    "  Palavra: " ++ show (palavra resultado), -- 'show' para tratar bem a palavra vazia ""
    "  Aceita: " ++ show (aceita resultado),
    "  Histórico de Estados: " ++ formatarHistorico (estadosPercorridos resultado),
    "---------------------------------------"
  ]

--   Converte [["q0","q1"],["q2"]] em "{q0,q1} -> {q2}"
formatarHistorico :: [[String]] -> String
formatarHistorico historico =
  intercalate " -> " $ map formatarConjuntoEstados historico
  where
    formatarConjuntoEstados :: [String] -> String
    formatarConjuntoEstados [] = "{}" -- Caso de um caminho "morto"
    -- Ordena os estados para uma saída consistente (ex: {q0,q1} e não {q1,q0})
    formatarConjuntoEstados estados = "{" ++ intercalate "," (sort estados) ++ "}"

printHeader :: String -> IO ()
printHeader titulo = putStrLn $ "\n--- " ++ titulo ++ " ---"

printError :: String -> IO ()
printError msg = putStrLn $ "[ERRO] " ++ msg

printSuccess :: String -> IO ()
printSuccess msg = putStrLn $ "[SUCESSO] " ++ msg

printSeparator :: IO ()
printSeparator = putStrLn "---------------------------------------"

-- --- Funções do Seletor de Arquivos ---

-- | Função genérica para listar e selecionar um arquivo com uma extensão específica.
selecionarArquivo :: FilePath -> String -> IO (Maybe FilePath)
selecionarArquivo pasta extensao = do
    existe <- doesDirectoryExist pasta
    if not existe
    then do
        printError $ "O diretório '" ++ pasta ++ "' não foi encontrado."
        return Nothing
    else do
        nomesArquivos <- listDirectory pasta
        let arquivosFiltrados = sort $ filter (\nome -> takeExtension nome == extensao) nomesArquivos
        
        if null arquivosFiltrados
        then do
            printError $ "Nenhum arquivo '" ++ extensao ++ "' encontrado em '" ++ pasta ++ "'."
            return Nothing
        else do
            putStrLn $ "\nPor favor, selecione um arquivo '" ++ extensao ++ "':"
            let menu = zip [1..] arquivosFiltrados
            
            forM_ menu $ \(index, nome) -> do
                putStrLn $ "  " ++ show (index :: Int) ++ ". " ++ nome

            putStrLn "  0. Sair / Cancelar"
            
            obterSelecao pasta menu

-- | Função auxiliar para tratar a entrada numérica do usuário para o menu de arquivos.
obterSelecao :: FilePath -> [(Int, FilePath)] -> IO (Maybe FilePath)
obterSelecao pasta menu = do
    putStr "Digite o número (ou 0 para cancelar): "
    hFlush stdout
    input <- getLine
    
    case readMaybe input :: Maybe Int of
        Nothing -> do
            printError "Entrada inválida. Por favor, digite um número."
            obterSelecao pasta menu
        Just 0 -> do
            putStrLn "Seleção cancelada."
            return Nothing
        Just index ->
            case lookup index menu of
                Just arquivoSelecionado ->
                    return $ Just (pasta </> arquivoSelecionado)
                Nothing -> do
                    printError "Número inválido. Tente novamente."
                    obterSelecao pasta menu