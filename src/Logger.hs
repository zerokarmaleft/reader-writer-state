module Logger where

import Control.Monad.Trans.Reader
import Control.Monad.Trans.Writer
import Control.Monad.Trans.State
import Data.Char (toUpper)

type PureLogger a = Writer String a

logMessage1 :: String -> PureLogger ()
logMessage1 message =
  do tell $ message ++ "\n"
     return ()

sumOfSquares :: Int -> Int -> Int
sumOfSquares x y = (x * x) + (y * y)

sumOfSquares1 :: Int -> Int -> PureLogger Int
sumOfSquares1 x y =
  do logMessage1 $ "Input parameters: " ++ show x ++ " and " ++ show y
     let xSquared = x * x
         ySquared = y * y
     logMessage1 $ "Squaring first parameter: " ++ show xSquared
     logMessage1 $ "Squaring second parameter: " ++ show ySquared
     return $ xSquared + ySquared

type PrefixedLogger a = Reader String a

logMessage2 :: String -> PrefixedLogger String
logMessage2 message =
  do prefix <- ask
     return $ prefix ++ ":" ++ message
     
sumOfSquares2 :: Int -> Int -> PrefixedLogger (Int,String)
sumOfSquares2 x y =
  do logState1 <- logMessage2 $ "Input parameters: " ++ show x ++ " and " ++ show y
     let xSquared = x * x
         ySquared = y * y
     logState2 <- logMessage2 $ "Squaring first parameter: " ++ show xSquared
     logState3 <- logMessage2 $ "Squaring second parameter: " ++ show ySquared
     let logState = logState1 ++ "\n" ++ logState2 ++ "\n" ++ logState3 ++ "\n"
     return $ (xSquared + ySquared, logState)

type IndexedLogger a = State Int a

logMessage3 :: String -> IndexedLogger String
logMessage3 message =
  do idx <- get
     put (idx + 1)
     return $ show idx ++ ":" ++ message ++ "\n"

sumOfSquares3 :: Int -> Int -> IndexedLogger (Int,String)
sumOfSquares3 x y =
  do logState1 <- logMessage3 $ "Input parameters: " ++ show x ++ " and " ++ show y
     let xSquared = x * x
         ySquared = y * y
     logState2 <- logMessage3 $ "Squaring first parameter: " ++ show xSquared
     logState3 <- logMessage3 $ "Squaring second parameter: " ++ show ySquared
     let logState = logState1 ++ "\n" ++ logState2 ++ "\n" ++ logState3 ++ "\n"
     return $ (xSquared + ySquared, logState)
