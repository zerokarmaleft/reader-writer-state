{-# LANGUAGE Rank2Types #-}

module RWSLogger where

import Control.Monad.IO.Class
import Control.Monad.Trans.RWS.Lazy

type Logger a = RWST String String Int IO a

newtype DBConnection = DBConnection String
                     deriving (Show)

logMessage :: String -> Logger ()
logMessage message =
  do count <- get
     prefix <- ask
     let indexedMessage = show count ++ ":" ++ prefix ++ ":" ++ message ++ "\n"
     tell indexedMessage
     modify (+1)
     
connect :: String -> IO DBConnection
connect uri =
  do putStrLn "[Fake IO] Instead of printing to console, actually connect to a database over a network"
     return $ DBConnection uri
     
close :: DBConnection -> IO ()
close connection =
  putStrLn "[Fake IO] Instead of printing to console, actually clean up resources (memory, file handles) allocated to connect to a database"

query :: DBConnection -> String -> IO String
query connection q = 
  do putStrLn "[Fake IO] Instead of printing to console, actually send a query string to a database and return the results"
     return $ "Query results from sending '" ++ q ++ "' to " ++ show connection

connectToDatabase :: String -> Logger ()
connectToDatabase uri =
  do connection <- liftIO $ connect uri
     logMessage $ "Connection established to: " ++ show connection
     results    <- liftIO $ query connection "SELECT * FROM all_the_things"
     logMessage $ "Query succeeded and returned: " ++ results

     logMessage $ "Shutting down connection..."
     liftIO $ close connection
     logMessage $ "Connection closed."
