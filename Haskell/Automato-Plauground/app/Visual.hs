module Visual (abrirVisualizacao) where

import Raylib.Core
import Raylib.Util.Colors
import Raylib.Core.Shapes
import Raylib.Core.Text
import Raylib.Types

import Automato
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Data.Graph.Inductive.Graph (labNodes, labEdges, Node)
import Data.Maybe (fromMaybe)
import Control.Monad (forM_)

-- | Estado da interface: o automato, posicoes dos nos e o passo da simulacao
data ContextoVisual = ContextoVisual
  { auto       :: Automato
  , posicoes   :: Map.Map Node (Float, Float)
  , passoAtual :: Int
  , historico  :: [[String]]
  }

-- | Inicializa a janela e os recursos da Raylib
abrirVisualizacao :: Automato -> Maybe ResultadoTeste -> IO ()
abrirVisualizacao automato maybeRes = do
    let nos = labNodes (grafo automato)
    let coords = gerarLayoutCircular nos (400, 300) 220
    let hist = maybe [] estadosPercorridos maybeRes
    
    janela <- initWindow 800 600 "Simulador de Automatos"
    setTargetFPS 60
    
    visualLoop (ContextoVisual automato coords 0 hist)
    
    closeWindow (Just janela)

-- | Loop principal
visualLoop :: ContextoVisual -> IO ()
visualLoop ctx = do
    close <- windowShouldClose
    if close then return ()
    else do
        -- Captura tecla fora do IF pois isKeyPressed e uma acao de IO
        espacoPressionado <- isKeyPressed KeySpace
        
        let novoPasso = if espacoPressionado && (passoAtual ctx + 1 < length (historico ctx))
                        then passoAtual ctx + 1
                        else passoAtual ctx
        
        beginDrawing
        clearBackground rayWhite
        
        desenharInterface (ctx { passoAtual = novoPasso })
        
        endDrawing
        visualLoop (ctx { passoAtual = novoPasso })

-- | Desenha os circulos, linhas e textos
desenharInterface :: ContextoVisual -> IO ()
desenharInterface ctx = do
    let a = auto ctx
    let ativos = if null (historico ctx) 
                 then Set.singleton (estadoInicial a) 
                 else Set.fromList (historico ctx !! passoAtual ctx)

    -- Desenha as arestas (transicoes)
    forM_ (labEdges (grafo a)) $ \(u, v, simb) -> do
        let v1 = getPos u (posicoes ctx)
        let v2 = getPos v (posicoes ctx)
        drawLineEx v1 v2 2 darkGray
        
        -- Calcula meio da linha para o texto do simbolo
        let midX = (vector2'x v1 + vector2'x v2) / 2
        let midY = (vector2'y v1 + vector2'y v2) / 2
        drawText (fromMaybe "ε" simb) (round midX + 5) (round midY - 10) 18 maroon

    -- Desenha os nos (estados)
    forM_ (labNodes (grafo a)) $ \(n, nome) -> do
        let vPos = getPos n (posicoes ctx)
        let (x, y) = (vector2'x vPos, vector2'y vPos)
        let estaAtivo = Set.member nome ativos
        
        -- Laranja se o estado estiver ativo na simulacao
        let corCorpo = if estaAtivo then orange else lightGray
        
        drawCircle (round x) (round y) 30 corCorpo
        drawCircleLines (round x) (round y) 30 black
        
        -- Destaque para estado Final
        if Set.member nome (estadosFinais a) 
           then drawCircleLines (round x) (round y) 35 black 
           else return ()
            
        drawText nome (round x - 12) (round y - 10) 20 black

-- | Converte as coordenadas do Map para o tipo Vector2 da Raylib
getPos :: Node -> Map.Map Node (Float, Float) -> Vector2
getPos n m = 
    let (px, py) = fromMaybe (400, 300) (Map.lookup n m) 
    in Vector2 px py

-- | Distribui os estados em circulo para o grafo nao ficar baguncado
gerarLayoutCircular :: [(Node, String)] -> (Float, Float) -> Float -> Map.Map Node (Float, Float)
gerarLayoutCircular nos (cx, cy) raio = 
    Map.fromList [ (fst n, (cx + raio * cos (2*pi*i/len), cy + raio * sin (2*pi*i/len))) 
                 | (i, n) <- zip [0..] nos ]
  where 
    len = fromIntegral (length nos)