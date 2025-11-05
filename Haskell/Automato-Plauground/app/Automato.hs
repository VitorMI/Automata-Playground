{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

-- Módulo Automato: Define as funções e tipos relacionados ao autômato (agora AFND).
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
import Data.Aeson (FromJSON, ToJSON, decode, object, (.=), Value(Null))
import Data.Aeson.Encode.Pretty (encodePretty) -- Para gerar JSON formatado ("pretty")
import qualified Data.ByteString.Lazy as B -- Para manipular arquivos binários (JSON)
import GHC.Generics (Generic) -- Para derivar instâncias de FromJSON e ToJSON automaticamente
import Data.Set (Set, member) -- Para representar conjuntos (alfabeto e estados finais)
import qualified Data.Set as Set
import Data.Map.Strict (Map) -- Para representar transições como um mapa
import qualified Data.Map.Strict as Map
import Data.List (intercalate, foldl') -- Import para juntar strings e usar foldl estrito
import Data.Maybe (fromJust, mapMaybe) -- Funções auxiliares
import Data.Graph.Inductive.Graph (Node, LEdge, mkGraph, labNodes, lsuc, lab) -- Funções principais
import Data.Graph.Inductive.PatriciaTree (Gr) -- Implementação concreta eficiente
import Data.Graph.Inductive.Query.DFS (dfs) -- Para o fecho-épsilon


-- Tipo auxiliar para uma única transição no JSON
data JsonTransicao = JsonTransicao
  { origem  :: String
  , simbolo :: Maybe String -- null no JSON será 'Nothing' (transição épsilon)
  , destino :: String
  } deriving (Show, Generic, FromJSON)

-- Tipo auxiliar que reflete a estrutura do JSON
data JsonAutomato = JsonAutomato
  { alfabeto       :: Set String
  , estadoInicial  :: String
  , estadosFinais  :: Set String
  , transicoes     :: [JsonTransicao] -- Lista de transições
  } deriving (Show, Generic, FromJSON)

data Automato = Automato
  { alfabeto       :: Set String
  , estadoInicial  :: String
  , estadosFinais  :: Set String
  , grafo          :: Gr String (Maybe String) -- O grafo de transições
  , mapaDeNos      :: Map String Node    -- Mapeia "q0" -> 1 (ID interno do FGL)
  , mapaDeRotulos  :: Map Node String    -- Mapeia 1 -> "q0"
  } deriving (Show, Generic)

data ResultadoTeste = ResultadoTeste
  { palavra          :: String
  , aceita           :: Bool
  , estadosPercorridos :: [[String]]
  } deriving (Show, Generic)

instance ToJSON ResultadoTeste -- Isso continua funcionando

-- Constrói o tipo 'Automato' (com grafo FGL) a partir do 'JsonAutomato'
converterParaGrafo :: JsonAutomato -> Automato
converterParaGrafo JsonAutomato{..} =
  let
    -- 1. Coletar todos os nomes de estados únicos
    --    'transicoes', 'estadoInicial', 'estadosFinais' são variáveis locais
    estadosDeTransicoes = Set.unions [Set.fromList [origem t, destino t] | t <- transicoes]
    todosEstados = Set.unions [estadosDeTransicoes, Set.singleton estadoInicial, estadosFinais]
    
    -- 2. Criar os mapeamentos (String <-> Node)
    --    (O FGL usa 'Int' como 'Node' internamente)
    listaDeNos = Set.toList todosEstados
    mapaDeNos   = Map.fromList (zip listaDeNos [0..])
    mapaDeRotulos = Map.fromList (zip [0..] listaDeNos)
    
    -- 3. Criar a lista de nós para o FGL: (Node, Label)
    nosFGL = [(fromJust (Map.lookup rotulo mapaDeNos), rotulo) | rotulo <- listaDeNos]
    
    -- 4. Criar a lista de arestas para o FGL: (NodeOrigem, NodeDestino, LabelAresta)
    arestasFGL :: [LEdge (Maybe String)]
    arestasFGL = mapMaybe criarAresta transicoes -- 'transicoes' é variável local
      where
        criarAresta :: JsonTransicao -> Maybe (LEdge (Maybe String))
        criarAresta t = do
          noOrigem  <- Map.lookup (origem t) mapaDeNos
          noDestino <- Map.lookup (destino t) mapaDeNos
          return (noOrigem, noDestino, simbolo t)
          
    -- 5. Construir o grafo
    grafoFinal = mkGraph nosFGL arestasFGL
    
  in
    Automato
      { alfabeto       = alfabeto -- 'alfabeto' é variável local
      , estadoInicial  = estadoInicial -- 'estadoInicial' é variável local
      , estadosFinais  = estadosFinais -- 'estadosFinais' é variável local
      , grafo          = grafoFinal
      , mapaDeNos      = mapaDeNos
      , mapaDeRotulos  = mapaDeRotulos
      }

-- Função para ler o arquivo JSON
lerJson :: FilePath -> IO (Maybe JsonAutomato) -- Lê o tipo JsonAutomato
lerJson arquivo = do
  conteudo <- B.readFile arquivo
  return (decode conteudo)

-- Função para criar o autômato a partir do arquivo JSON
criarAutomato :: FilePath -> IO Automato
criarAutomato arquivo = do
  maybeJsonAutomato <- lerJson arquivo -- Tenta carregar o JSON
  case maybeJsonAutomato of
    Just jsonAuto -> return (converterParaGrafo jsonAuto) -- Converte para o tipo Automato
    Nothing       -> error "Erro ao carregar o autômato do JSON"

imprimirAutomato :: Automato -> String
imprimirAutomato Automato{..} =
  let
    -- 'alfabeto', 'estadoInicial', 'estadosFinais', 'grafo' são variáveis locais
    formatarConjunto :: Set.Set String -> String
    formatarConjunto s = "{ " ++ intercalate ", " (Set.toList s) ++ " }"

    formatarTransicoes :: Gr String (Maybe String) -> String
    formatarTransicoes g =
      let
        todosOsNos = labNodes g
        linhasDeTransicao = concatMap (formatarLinhasDeNo g) todosOsNos
      in unlines linhasDeTransicao
      where
        formatarLinhasDeNo g (no, rotuloOrigem) =
          let sucessores = lsuc g no
          in map (formatarLinha rotuloOrigem) sucessores
        
        formatarLinha origem (destino, simbolo) =
          let 
            rotuloDestino = fromJust (lab g destino)
            strSimbolo = case simbolo of
                            Just s  -> s
                            Nothing -> "ε"
          in
            "    δ(" ++ origem ++ ", " ++ strSimbolo ++ ") = " ++ rotuloDestino

  in unlines [
    "---------------------------------------",
    "      INFORMAÇÕES DO AUTÔMATO          ",
    "---------------------------------------",
    "  - Alfabeto (Σ):      " ++ formatarConjunto alfabeto,
    "  - Estado Inicial:    " ++ estadoInicial,
    "  - Estados Finais (F): " ++ formatarConjunto estadosFinais,
    "  - Funções de Transição (δ):",
    formatarTransicoes grafo,
    "---------------------------------------"
  ]


-- Retorna os sucessores de um nó que são alcançáveis via épsilon
sucEpsilon :: Gr String (Maybe String) -> Node -> [Node]
sucEpsilon g n = [dest | (dest, Nothing) <- lsuc g n]

-- Calcula o fecho-épsilon para um conjunto de estados
-- (todos os estados alcançáveis a partir do conjunto inicial usando apenas transições épsilon)
fechoEpsilon :: Gr String (Maybe String) -> Set Node -> Set Node
fechoEpsilon g initialNodes =
  -- Usamos uma função auxiliar com:
  -- 1. Uma "fila" de trabalho (nodesToVisit)
  -- 2. Um conjunto de nós já "visitados" (que é nosso resultado)
  loop (Set.toList initialNodes) initialNodes
  where
    loop :: [Node] -> Set Node -> Set Node
    loop [] visited = visited -- Base case: Fila vazia, terminamos. Retorna os visitados.
    loop (n:queue) visited =
        -- 1. Pega os vizinhos-épsilon do nó 'n'
        let neighbors = sucEpsilon g n
        -- 2. Filtra apenas os que NUNCA vimos antes
            newNeighbors = [dest | dest <- neighbors, dest `Set.notMember` visited]
        -- 3. Adiciona esses novos vizinhos ao conjunto de visitados e ao FIM da fila
            newVisited = Set.union visited (Set.fromList newNeighbors)
            newQueue = queue ++ newNeighbors -- Adiciona ao fim (BFS)
        in
          loop newQueue newVisited

-- Calcula a transição para um conjunto de estados dado um símbolo
mover :: Gr String (Maybe String) -> Set Node -> String -> Set Node
mover g nos simbolo =
  Set.unions (Set.map moverNo nos)
  where
    moverNo n = Set.fromList [dest | (dest, Just s) <- lsuc g n, s == simbolo]

-- Função de simulação principal
testePalavra :: Automato -> String -> IO ResultadoTeste
testePalavra Automato{..} palavraTestada = -- MUDANÇA: Usando RecordWildCards
  let
    -- 'alfabeto', 'grafo', 'estadoInicial', 'mapaDeNos', 
    -- 'estadosFinais', 'mapaDeRotulos' são variáveis locais
    simbolos = map (:[]) palavraTestada
    invalida = any (\s -> not (member s alfabeto)) simbolos
    
  in if invalida
     then return $ ResultadoTeste palavraTestada False [["Palavra fora do alfabeto"]]
     else do
       -- 1. Encontrar o nó inicial e calcular seu fecho-épsilon
       let g = grafo
       let Just noInicial = Map.lookup estadoInicial mapaDeNos
       let estadosIniciais = fechoEpsilon g (Set.singleton noInicial)
       
       -- 2. Simular a palavra usando foldl'
       let (estadosFinaisSimulados, historico) =
             foldl' (passoSimulacao g)
                    (estadosIniciais, [estadosIniciais])
                    simbolos
       
       -- 3. Verificar se algum dos estados finais está no conjunto de estados de aceitação
       let nosFinais = Set.fromList $ mapMaybe (\s -> Map.lookup s mapaDeNos) (Set.toList estadosFinais)
       let aceitaPalavra = not $ Set.null $ Set.intersection estadosFinaisSimulados nosFinais
       
       -- 4. Formatar o histórico de 'Set Node' para '[[String]]'
       let historicoFormatado = map (Set.toList . Set.map (\n -> fromJust (Map.lookup n mapaDeRotulos))) (reverse historico)
       
       return $ ResultadoTeste palavraTestada aceitaPalavra historicoFormatado
  where
    -- Função auxiliar para o fold
    passoSimulacao g (estadosAtuais, historico) simbolo =
      let
        proximosEstados = mover g estadosAtuais simbolo
        proximosComEpsilon = fechoEpsilon g proximosEstados
      in
        (proximosComEpsilon, proximosComEpsilon : historico)

salvarResultados :: FilePath -> [ResultadoTeste] -> IO ()
salvarResultados arquivo resultados = do
  let json = encodePretty $ object ["resultados" .= resultados]
  B.writeFile arquivo json
  putStrLn $ "Resultados salvos em " ++ arquivo