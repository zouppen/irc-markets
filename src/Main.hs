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

-- Delay in seconds
delay = 60
chan = "#kokeilu"

main = do
  [host,port,pass] <- getArgs
  h <- connectIrssiProxy host (PortNumber $ fromInteger $ read port) pass
  var <- topicGuard h
  threadDelay 10000000 -- Sleep 10 seconds before first. Just quick hack.
  getMicroSeconds >>= loop (updateTopic (getTopic var chan) (setTopic h chan))
    
getMicroSeconds = do 
  now <- getPOSIXTime
  return $ floor $ 1e6*now

-- | Loop an action periodically
loop act last = do
  act
  now <- getMicroSeconds
  when (target > now) $ threadDelay $ target-now
  loop act target
  where target = last + (delay*1000000)
