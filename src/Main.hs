module Main where

import Irc
import MtGoxTopics
import Control.Monad
import Control.Concurrent
import Control.Concurrent.STM
import Data.Time.Clock.POSIX
import Network
import System.Environment
import Data.Map ((!))

main = do
  [host,port,pass,chan] <- getArgs
  h <- connectIrssiProxy host (PortNumber $ fromInteger $ read port) pass
  var <- topicGuard h
  putStrLn "connected"
  threadDelay 10000000 -- Sleep 10 seconds before first. Just quick hack.
  startTime <- getMicroSeconds
  loop (updateTopic m (getTopic var chan) (setTopic h chan)) startTime

getMicroSeconds :: IO Integer
getMicroSeconds = do 
  now <- getPOSIXTime
  return $ floor $ 1e6*now

-- | Loop an action periodically
loop act last = do
  act
  now <- getMicroSeconds
  -- Sleep at least 10 seconds even if we are late
  threadDelay $ max 10000000 $ fromInteger $ target-now
  loop act target
  where target = last + (interval*minute)
