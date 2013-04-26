module Main where

import Irc
import MtGoxTopics
import TemporalCache
import Control.Monad
import Control.Concurrent
import Control.Concurrent.STM
import Data.Time.Clock.POSIX
import Network
import System.Environment
import Data.Map ((!))

interval       = 1   -- Check ticker every minute
panicWindow    = 60  -- Compare panic condition to one hour old data

main = do
  [host,port,pass,chan] <- getArgs
  h <- connectIrssiProxy host (PortNumber $ fromInteger $ read port) pass
  var <- topicGuard h
  m <- newEmptyAgingMap $ panicWindow * minute
  putStrLn "connected"
  threadDelay 10000000 -- Sleep 10 seconds before first. Just quick hack.
  startTime <- getMicroSeconds
  loop (updateTopic m (getTopic var chan) (setTopic h chan)) startTime

getMicroSeconds :: IO Integer
getMicroSeconds = do 
  now <- getPOSIXTime
  return $ floor $ 1e6*now

minute = 60000000

-- | Loop an action periodically
loop act last = do
  act
  now <- getMicroSeconds
  -- Sleep at least 10 seconds even if we are late
  threadDelay $ max 10000000 $ fromInteger $ target-now
  loop act target
  where target = last + (interval*minute)
