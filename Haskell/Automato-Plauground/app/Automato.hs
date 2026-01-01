{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

-- | Documento depois

module Automato
  ( Automato(..), 
    criarAutomato,
    imprimirAutomato,
    testePalavra,
    salvarResultados,
    ResultadoTeste(..)
  )
where

import Data.Aeson (FromJSON, ToJSON, decode, object, (.=))
import Data.Aeson.Encode.Pretty (encodePretty)
import qualified Data.ByteString.Lazy as B
import GHC.Generics (Generic)
import Data.Set (Set)
import qualified Data.Set as Set
import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import Data.List (intercalate, foldl')
import Data.Maybe (fromJust, mapMaybe)
import Data.Graph.Inductive.Graph (Node, mkGraph, labNodes, lsuc, lab)
import Data.Graph.Inductive.PatriciaTree (Gr)

data JsonTransicao = JsonTransicao
  { origem  :: String
  , simbolo :: Maybe String
  , destino :: String
  } deriving (Show, Generic, FromJSON)

data JsonAutomato = JsonAutomato
  { alfabeto       :: Set String
  , estadoInicial  :: String
  , estadosFinais  :: Set String
  , transicoes     :: [JsonTransicao]
  } deriving (Show, Generic, FromJSON)

data Automato = Automato
  { alfabeto       :: Set String
  , estadoInicial  :: String
  , estadosFinais  :: Set String
  , grafo          :: Gr String (Maybe String)
  , mapaDeNos      :: Map String Node
  , mapaDeRotulos  :: Map Node String
  } deriving (Show, Generic)

data ResultadoTeste = ResultadoTeste
  { palavra          :: String
  , aceita           :: Bool
  , estadosPercorridos :: [[String]]
  } deriving (Show, Generic, ToJSON)

converterParaGrafo :: JsonAutomato -> Automato
converterParaGrafo JsonAutomato{..} =
  let
    estadosDeTransicoes = Set.unions [Set.fromList [origem t, destino t] | t <- transicoes]
    todosEstados = Set.unions [estadosDeTransicoes, Set.singleton estadoInicial, estadosFinais]
    listaDeNos = Set.toList todosEstados
    mapaDeNos   = Map.fromList (zip listaDeNos [0..])
    mapaDeRotulos = Map.fromList (zip [0..] listaDeNos)
    nosFGL = [(fromJust (Map.lookup rotulo mapaDeNos), rotulo) | rotulo <- listaDeNos]
    arestasFGL = mapMaybe criarAresta transicoes
      where
        criarAresta t = do
          noOrigem  <- Map.lookup (origem t) mapaDeNos
          noDestino <- Map.lookup (destino t) mapaDeNos
          return (noOrigem, noDestino, simbolo t)
    grafoFinal = mkGraph nosFGL arestasFGL
  in
    Automato alfabeto estadoInicial estadosFinais grafoFinal mapaDeNos mapaDeRotulos

criarAutomato :: FilePath -> IO Automato
criarAutomato arquivo = do
  conteudo <- B.readFile arquivo
  case decode conteudo of
    Just jsonAuto -> return (converterParaGrafo jsonAuto)
    Nothing       -> error "Erro ao carregar o autômato do JSON"

imprimirAutomato :: Automato -> String
imprimirAutomato Automato{..} =
  let
    formatarConjunto s = "{ " ++ intercalate ", " (Set.toList s) ++ " }"
    formatarTransicoes g = unlines $ concatMap (\(no, rot) -> map (formatarLinha rot) (lsuc g no)) (labNodes g)
    formatarLinha orig (dest, simb) = "    δ(" ++ orig ++ ", " ++ fromMaybe "ε" simb ++ ") = " ++ fromJust (lab grafo dest)
  in unlines ["--- INFO ---", "Alfabeto: " ++ formatarConjunto alfabeto, "Inicial: " ++ estadoInicial, "Finais: " ++ formatarConjunto estadosFinais, "Transições:", formatarTransicoes grafo]

fechoEpsilon :: Gr String (Maybe String) -> Set Node -> Set Node
fechoEpsilon g initial = loop (Set.toList initial) initial
  where
    loop [] vis = vis
    loop (n:q) vis =
      let prox = [d | (d, Nothing) <- lsuc g n, Set.notMember d vis]
      in loop (q ++ prox) (Set.union vis (Set.fromList prox))

mover :: Gr String (Maybe String) -> Set Node -> String -> Set Node
mover g nos simb = Set.unions [Set.fromList [d | (d, Just s) <- lsuc g n, s == simb] | n <- Set.toList nos]

testePalavra :: Automato -> String -> IO ResultadoTeste
testePalavra Automato{..} pal = do
  let simbolos = map (:[]) pal
  case Map.lookup estadoInicial mapaDeNos of
    Nothing -> return $ ResultadoTeste pal False []
    Just noIni -> do
      let iniFecho = fechoEpsilon grafo (Set.singleton noIni)
      let (finaisSim, hist) = foldl' (\(atuais, h) s -> 
            let prox = fechoEpsilon grafo (mover grafo atuais s)
            in (prox, prox : h)) (iniFecho, [iniFecho]) simbolos
      let aceitou = not $ Set.null $ Set.intersection finaisSim (Set.fromList $ mapMaybe (`Map.lookup` mapaDeNos) (Set.toList estadosFinais))
      let histRotulos = map (Set.toList . Set.map (\n -> fromJust (Map.lookup n mapaDeRotulos))) (reverse hist)
      return $ ResultadoTeste pal aceitou histRotulos

salvarResultados :: FilePath -> [ResultadoTeste] -> IO ()
salvarResultados arquivo res = B.writeFile arquivo (encodePretty $ object ["resultados" .= res])

fromMaybe :: a -> Maybe a -> a
fromMaybe d Nothing = d
fromMaybe _ (Just x) = x