{-# LANGUAGE OverloadedStrings #-}
module MtGoxTopics (mtGoxPart) where

import Control.Applicative
import Control.Monad
import Data.Aeson
import Data.Aeson.Types
import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as B
import Data.Text (Text)
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import Network.Curl.Aeson
import Text.Regex.PCRE.Light
import qualified Data.ByteString.Char8 as B
import TemporalCache
import TopicPart

panicThreshold  = 0.1 -- Ten percent change triggers panic
panicWindow     = 60  -- Compare panic condition to one hour old data
intervalMinutes = 3   -- Number of minutes between updates


mtGoxPart :: IO TopicPart
mtGoxPart = do
  m <- newEmptyAgingMap $ panicWindow * minute
  return $ TopicPart { tag = "BTC: "
                     , update = mtGoxTopic m
                     , interval = intervalMinutes * minute
                     }

mtGoxTopic :: (Integer -> Integer -> IO Integer) -> IO Text
mtGoxTopic m = do
  (low,high,last,now) <- curlAesonGetWith p
                         "http://data.mtgox.com/api/1/BTCEUR/ticker"
  old <- m now last
  return $ T.concat [low,"–",high,"€", mayPanic old last," "]
  where 
    p (Object o) = do
      low  <- pure o..."return"..."low"..."value_int"
      high <- pure o..."return"..."high"..."value_int"
      last <- pure o..."return"..."last_all"..."value_int"
      now  <- pure o..."return"..."now"
      return (numBs low 1e5,numBs high 1e5,read last,read now)
    numBs :: String -> Double -> T.Text
    numBs s prec = T.pack $ show $ round $ read s / prec
    numBsInt n prec = T.pack $ show $ round $ fromInteger n / prec
    mayPanic old last =
      case (abs (fromInteger old/fromInteger last-1)>panicThreshold,old<last) of
        (True,True)  -> T.concat [", raketoi, ",numBsInt last 1e5," € nyt!"]
        (True,False) -> T.concat [", syöksyy, ",numBsInt last 1e5," € nyt!"]
        _ -> ", vakaa."
