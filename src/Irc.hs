module Main where

import System.IO
import Control.Monad
import Control.Concurrent
import Control.Concurrent.STM
import Control.Concurrent.STM.TVar
import Network
import Network.IRC
import Data.Map (Map)
import qualified Data.Map as M

-- | Connects to Irssi proxy with given hostname, port and password.
connectIrssiProxy :: HostName -> PortID -> String -> IO Handle
connectIrssiProxy host port pass = do
  h <- connectTo host port
  hSetBuffering h LineBuffering
  hPutStr h "NICK .\nPASS "
  hPutStr h pass
  hPutStr h "\nUSER . . :\n"
  return h

-- | Forks new thread which parses irc topics and keeps them in a map.
inputChan :: Handle -> IO (TVar (Map String String))
inputChan h = do
  var <- newTVarIO M.empty
  forkIO $ forever $ do
    s <- hGetLine h
    case decode (s++"\n") >>= topicChange of
      Just (k,a) -> atomically $ readTVar var >>= writeTVar var . M.insert k a
      Nothing -> return ()
  return var

-- | Parse if given message has topic change
topicChange :: Message -> Maybe (String,String)
topicChange (Message _ "TOPIC" [chan,msg]) = Just (chan,msg)
topicChange (Message _ "332" [_,chan,msg]) = Just (chan,msg)
topicChange _ = Nothing

-- | Debug view of topic table
showTopics :: TVar (Map String String) -> IO ()
showTopics var = readTVarIO var >>= putStr . unlines . map pair . M.toList
  where pair (a,b) = a++": "++b

-- | Sets channel topic
setTopic :: Handle -> String -> String -> IO ()
setTopic h chan s = hPutStrLn h $ encode $ Message Nothing "TOPIC" [chan,s]
