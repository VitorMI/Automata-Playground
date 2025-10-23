{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

-- Módulo Automato: Define as funções e tipos relacionados ao autômato.
module Automato
  ( Automato, -- Exporta o tipo Automato
    criarAutomato, -- Função para criar um autômato a partir de um arquivo JSON
    imprimirAutomato, -- Função para exibir informações do autômato
    testePalavra, -- Função para testar uma palavra no autômato
    salvarResultados, -- Função para salvar os resultados dos testes em JSON
    ResultadoTeste (..) -- Exporta o construtor e os campos de ResultadoTeste
  )
where

-- Importações necessárias
import Data.Aeson (FromJSON, ToJSON, decode, object, (.=)) -- Para trabalhar com JSON
import Data.Aeson.Encode.Pretty (encodePretty) -- Para gerar JSON formatado ("pretty")
import qualified Data.ByteString.Lazy as B -- Para manipular arquivos binários (JSON)
import GHC.Generics (Generic) -- Para derivar instâncias de FromJSON e ToJSON automaticamente
import Data.Set (Set, member) -- Para representar conjuntos (alfabeto e estados finais)
import qualified Data.Map.Strict as Map -- Para representar transições como um mapa
import qualified Data.Map as Map
import qualified Data.Set as Set
import Data.List (intercalate) -- Import para juntar strings com um separador

-- Definição do tipo Automato
data Automato = Automato
  { alfabeto       :: Set String -- Conjunto de símbolos do alfabeto
  , estadoInicial  :: String -- Estado inicial do autômato
  , estadosFinais  :: Set String -- Conjunto de estados finais
  , transicoes     :: Map.Map String (Map.Map String String) -- Transições do autômato
  } deriving (Show, Generic)

-- Instância para permitir que o tipo Automato seja decodificado de JSON
instance FromJSON Automato

-- Definição do tipo ResultadoTeste
data ResultadoTeste = ResultadoTeste
  { palavra          :: String -- A palavra testada
  , aceita           :: Bool -- Indica se a palavra foi aceita ou rejeitada
  , estadosPercorridos :: [String] -- Lista dos estados percorridos durante o teste
  } deriving (Show, Generic)

-- Instância para permitir que o tipo ResultadoTeste seja codificado em JSON
instance ToJSON ResultadoTeste

-- Função para ler o arquivo JSON contendo a definição do autômato
lerJson :: FilePath -> IO (Maybe Automato)
lerJson arquivo = do
  conteudo <- B.readFile arquivo -- Lê o conteúdo do arquivo JSON
  return (decode conteudo) -- Decodifica o JSON para o tipo Automato

-- Função para criar o autômato a partir do arquivo JSON
criarAutomato :: FilePath -> IO Automato
criarAutomato arquivo = do
  maybeAutomato <- lerJson arquivo -- Tenta carregar o autômato do JSON
  case maybeAutomato of
    Just automato -> return automato -- Retorna o autômato se o JSON for válido
    Nothing       -> error "Erro ao carregar o autômato do JSON" -- Exibe erro se falhar

-- Função para imprimir informações detalhadas sobre o autômato
imprimirAutomato :: Automato -> String
imprimirAutomato auto =
  let
    -- Função auxiliar para formatar um conjunto (Set) como { a, b, c }
    formatarConjunto :: Set.Set String -> String
    formatarConjunto s = "{ " ++ intercalate ", " (Set.toList s) ++ " }"

    -- Função auxiliar para formatar todas as transições
    -- A assinatura de tipo aqui foi corrigida para corresponder ao seu autômato
    formatarTransicoes :: Map.Map String (Map.Map String String) -> String -- <- MUDANÇA 1
    formatarTransicoes transMap =
      let
        todasAsTransicoes = concatMap formatarLinhaEstado (Map.toList transMap)
      in unlines todasAsTransicoes
      where
        -- A assinatura desta função auxiliar também foi corrigida
        formatarLinhaEstado :: (String, Map.Map String String) -> [String] -- <- MUDANÇA 2
        formatarLinhaEstado (origem, mapaDeTransicoes) =
          -- Agora, usamos Map.toList no mapa interno para obter a lista (símbolo, destino)
          map (\(simbolo, destino) ->
              "    δ(" ++ origem ++ ", " ++ simbolo ++ ") = " ++ destino
          ) (Map.toList mapaDeTransicoes) -- <- MUDANÇA 3

  in unlines [
    "---------------------------------------",
    "      INFORMAÇÕES DO AUTÔMATO          ",
    "---------------------------------------",
    "  - Alfabeto (Σ):      " ++ formatarConjunto (alfabeto auto),
    "  - Estado Inicial:    " ++ estadoInicial auto,
    "  - Estados Finais (F): " ++ formatarConjunto (estadosFinais auto),
    "  - Funções de Transição (δ):",
    formatarTransicoes (transicoes auto),
    "---------------------------------------"
  ]
-- Função para testar uma palavra no autômato
testePalavra :: Automato -> String -> IO ResultadoTeste
testePalavra automato palavraTestada =
  let simbolos = map (:[]) palavraTestada -- Converte cada caractere da palavra em uma string
      invalida = any (\s -> not (member s (alfabeto automato))) simbolos -- Verifica se a palavra está no alfabeto
  in if invalida
     then return $ ResultadoTeste palavraTestada False ["Fora do alfabeto"] -- Rejeita palavras fora do alfabeto
     else do
       -- Simula as transições do autômato
       let (estadoFinal, estadosSimulados) = foldl (\(estadoAtual, estados) letra ->
                                  case Map.lookup estadoAtual (transicoes automato) >>= Map.lookup letra of
                                    Just proximoEstado -> (proximoEstado, proximoEstado : estados) -- Avança para o próximo estado
                                    Nothing            -> ("", []) -- Trata transições inválidas
                               )
                               (estadoInicial automato, [estadoInicial automato]) -- Começa no estado inicial
                               simbolos

       -- Retorna o resultado do teste
       return $ ResultadoTeste palavraTestada (estadoFinal /= "" && member estadoFinal (estadosFinais automato)) (reverse estadosSimulados)

-- Função para salvar os resultados dos testes em um arquivo JSON
salvarResultados :: FilePath -> [ResultadoTeste] -> IO ()
salvarResultados arquivo resultados = do
  let json = encodePretty $ object ["resultados" .= resultados] -- Codifica os resultados em JSON formatado
  B.writeFile arquivo json -- Salva o JSON em um arquivo
  putStrLn $ "Resultados salvos em " ++ arquivo -- Informa ao usuário onde os resultados foram salvos