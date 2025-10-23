module Main where

-- Importa apenas a função 'iniciarMenu' do nosso novo módulo de Menu.
import Menu (iniciarMenu)

-- A função principal agora apenas delega a execução para o módulo de menu.
main :: IO ()
main = iniciarMenu