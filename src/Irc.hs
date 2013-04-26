module Irc where

import System.IO
import Control.Monad
import Control.Concurrent
import Control.Concurrent.STM
import Control.Concurrent.STM.TVar
import Data.ByteString.Char8 (ByteString,empty,pack,unpack)
import Network
import Network.IRC
import Data.Map (Map)
import qualified Data.Map as M

type TopicVar = TVar (Map String ByteString)

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
topicGuard :: Handle -> IO TopicVar
topicGuard h = do
  var <- newTVarIO M.empty
  forkIO $ forever $ do
    s <- hGetLine h
    case decode (s++"\n") >>= topicChange of
      Just (k,a) -> atomically $ readTVar var >>= writeTVar var . M.insert k a
      Nothing -> return ()
  return var

-- | Parse if given message has topic change
topicChange :: Message -> Maybe (String,ByteString)
topicChange (Message _ "TOPIC" [chan,msg]) = Just (chan,pack msg)
topicChange (Message _ "332" [_,chan,msg]) = Just (chan,pack msg)
topicChange _ = Nothing

-- | Debug view of topic table. Doesn't handle character sets.
showTopics :: TopicVar -> IO ()
showTopics var = readTVarIO var >>= putStr . unlines . map pair . M.toList
  where pair (a,b) = a++": "++unpack b

-- | Sets channel topic
setTopic :: Handle -> String -> ByteString -> IO ()
setTopic h chan s = hPutStrLn h $ encode $ Message Nothing "TOPIC"
                    [chan,unpack s]

-- | Gets topic contents of given channel. Returns empty string if
-- channel is not known (yet).
getTopic :: TopicVar -> String -> IO ByteString
getTopic var chan = do
  m <- atomically $ readTVar var
  return $ M.findWithDefault empty chan m
    
