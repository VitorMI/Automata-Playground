-- Define o módulo Menu e exporta apenas a função 'iniciarMenu'
module Menu (iniciarMenu) where

import Automato
  ( Automato(..),
    ResultadoTeste (..),
    criarAutomato,
    imprimirAutomato,
    salvarResultados,
    testePalavra,
  )

-- Importação do módulo de Visualização Gráfica
import Visual (abrirVisualizacao)

import Control.Monad (forM, forM_)
import System.IO (hFlush, stdout)
import System.Directory (doesDirectoryExist, listDirectory)
import System.FilePath ((</>), takeExtension)
import Data.List (sort, intercalate)
import Text.Read (readMaybe)

defaultJsonDir :: FilePath
defaultJsonDir = "exemplos"

defaultPalavrasDir :: FilePath
defaultPalavrasDir = "exemplos"

-- | Função principal do menu
iniciarMenu :: IO ()
iniciarMenu = do
  putStrLn "==============================="
  putStrLn "   Simulador de Autômatos (GUI)"
  putStrLn "==============================="
  putStrLn "Bem-vindo!"
  -- Inicia o loop com o estado inicial (nenhum autômato carregado)
  mainLoop Nothing

-- | Loop principal do menu
mainLoop :: Maybe Automato -> IO ()
mainLoop mAutomato = do
  printHeader "MENU PRINCIPAL"
  putStrLn "1. Carregar autômato (.json)"
  putStrLn "2. Visualizar informações (Terminal)"
  putStrLn "3. Visualizar estrutura gráfica (Raylib)"
  putStrLn "4. Testar palavra(s)"
  putStrLn "5. Salvar resultados dos testes em JSON"
  putStrLn "6. Sair"
  putStr "Escolha uma opção: "
  hFlush stdout
  opcao <- getLine
  case opcao of
    "1" -> carregarJSON mAutomato >>= mainLoop
    "2" -> visualizarInfo mAutomato >>= mainLoop
    "3" -> visualizarGrafico mAutomato >>= mainLoop
    "4" -> testarPalavras mAutomato >>= mainLoop
    "5" -> salvarResultadosMenu mAutomato >>= mainLoop
    "6" -> putStrLn "\nSaindo... Até logo!"
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
      novoAutomato <- criarAutomato caminho
      printSuccess "Autômato carregado com sucesso!"
      return (Just novoAutomato)

-- | Visualiza informações no terminal
visualizarInfo :: Maybe Automato -> IO (Maybe Automato)
visualizarInfo Nothing = do
  printError "Nenhum autômato carregado."
  return Nothing
visualizarInfo (Just automato) = do
  putStrLn $ imprimirAutomato automato
  return (Just automato)

-- | Abre a janela da Raylib para ver apenas a estrutura
visualizarGrafico :: Maybe Automato -> IO (Maybe Automato)
visualizarGrafico Nothing = do
  printError "Nenhum autômato carregado."
  return Nothing
visualizarGrafico (Just automato) = do
  putStrLn "Abrindo visualização gráfica... Feche a janela para voltar ao menu."
  -- Passa 'Nothing' para o resultado para indicar que não há histórico de estados para animar
  abrirVisualizacao automato Nothing
  return (Just automato)

-- | Testa palavras individualmente ou em lote
testarPalavras :: Maybe Automato -> IO (Maybe Automato)
testarPalavras Nothing = do
  printError "Nenhum autômato carregado."
  return Nothing
testarPalavras (Just automato) = do
  printHeader "4. TESTAR PALAVRAS"
  putStrLn "1. Palavra individual"
  putStrLn "2. Arquivo de palavras (.txt)"
  putStr "Escolha uma opção: "
  hFlush stdout
  opcao <- getLine
  case opcao of
    "1" -> do
      putStr "Digite a palavra: "
      hFlush stdout
      palavraTestada <- getLine
      resultado <- testePalavra automato palavraTestada
      putStrLn $ formatarResultado resultado
      
      -- TEMPORARIO
      putStr "Deseja ver a simulação passo a passo na GUI? (s/n): "
      hFlush stdout
      confirm <- getLine
      if confirm == "s" || confirm == "S"
        then abrirVisualizacao automato (Just resultado)
        else return ()
      
      return (Just automato)
      
    "2" -> do
      maybeCaminho <- selecionarArquivo defaultPalavrasDir ".txt"
      case maybeCaminho of
        Nothing -> return (Just automato)
        Just caminhoTxt -> do
          conteudo <- readFile caminhoTxt
          let palavras = lines conteudo
          resultados <- forM palavras (testePalavra automato)
          printSeparator
          forM_ resultados (putStrLn . formatarResultado)
          printSeparator
          return (Just automato)
    _ -> do
      printError "Opção inválida."
      return (Just automato)

-- | Salva os resultados (Opção 5)
salvarResultadosMenu :: Maybe Automato -> IO (Maybe Automato)
salvarResultadosMenu Nothing = printError "Nenhum autômato carregado." >> return Nothing
salvarResultadosMenu (Just automato) = do
  printHeader "5. SALVAR RESULTADOS"
  putStr "Palavras para testar (separadas por espaço): "
  hFlush stdout
  entrada <- getLine
  let palavras = words entrada
  resultados <- forM palavras (testePalavra automato)
  putStr "Nome do arquivo (ex: resultados.json): "
  hFlush stdout
  arquivo <- getLine
  salvarResultados arquivo resultados
  printSuccess "Resultados salvos!"
  return (Just automato)

formatarResultado :: ResultadoTeste -> String
formatarResultado resultado =
  unlines [
    "---------------------------------------",
    "  Palavra: " ++ show (palavra resultado),
    "  Aceita: " ++ (if aceita resultado then "SIM" else "NÃO"),
    "  Histórico: " ++ formatarHistorico (estadosPercorridos resultado),
    "---------------------------------------"
  ]

formatarHistorico :: [[String]] -> String
formatarHistorico historico =
  intercalate " -> " $ map formatarConjuntoEstados historico
  where
    formatarConjuntoEstados estados = "{" ++ intercalate "," (sort estados) ++ "}"

printHeader :: String -> IO ()
printHeader titulo = putStrLn $ "\n=== " ++ titulo ++ " ==="

printError :: String -> IO ()
printError msg = putStrLn $ "[ERRO] " ++ msg

printSuccess :: String -> IO ()
printSuccess msg = putStrLn $ "[OK] " ++ msg

printSeparator :: IO ()
printSeparator = putStrLn "---------------------------------------"

selecionarArquivo :: FilePath -> String -> IO (Maybe FilePath)
selecionarArquivo pasta extensao = do
    existe <- doesDirectoryExist pasta
    if not existe
    then do
        printError $ "O diretório '" ++ pasta ++ "' não foi encontrado."
        return Nothing
    else do
        nomesArquivos <- listDirectory pasta
        let filtrados = sort $ filter (\nome -> takeExtension nome == extensao) nomesArquivos
        if null filtrados
        then do
            printError $ "Nenhum arquivo '" ++ extensao ++ "' encontrado em '" ++ pasta ++ "'."
            return Nothing
        else do
            putStrLn $ "\nArquivos disponíveis em '" ++ pasta ++ "':"
            let menu = zip [1..] filtrados
            forM_ menu $ \(index, nome) -> putStrLn $ "  " ++ show (index :: Int) ++ ". " ++ nome
            putStrLn "  0. Sair / Cancelar"
            obterSelecao pasta menu

obterSelecao :: FilePath -> [(Int, FilePath)] -> IO (Maybe FilePath)
obterSelecao pasta menu = do
    putStr "Escolha o número: "
    hFlush stdout
    input <- getLine
    case readMaybe input :: Maybe Int of
        Nothing -> printError "Digite um número válido." >> obterSelecao pasta menu
        Just 0 -> return Nothing
        Just index ->
            case lookup index menu of
                Just arquivo -> return $ Just (pasta </> arquivo)
                Nothing -> printError "Opção inválida." >> obterSelecao pasta menu