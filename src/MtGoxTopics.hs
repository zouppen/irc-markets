{-# LANGUAGE OverloadedStrings #-}
module MtGoxTopics where

import Control.Applicative
import Control.Monad
import Data.Aeson
import Data.Aeson.Types
import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as B
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import Network.Curl.Aeson
import Text.Regex.PCRE.Light
import qualified Data.ByteString.Char8 as B

panicThreshold = 0.1 -- Ten percent change triggers panic

ircTopic :: (Integer -> Integer -> IO Integer) -> IO ByteString
ircTopic m = do
  (low,high,last,now) <- curlAesonGetWith p
                         "http://data.mtgox.com/api/1/BTCEUR/ticker"
  old <- m now last
  return $ encodeUtf8 $ T.concat ["BTC: ", low,"–",high,"€", mayPanic old last]
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

-- | Splits topic to pieces in which you may put the BTC course inside.
splitOldTopic :: ByteString -> Maybe (ByteString, ByteString)
splitOldTopic s = case matches of
  Just [_,start,end] -> Just (start,end)
  _ -> Nothing
  where
    matches = match re s []
    re = compile "(.*)BTC: .*?[\\.!](.*)" [anchored]

-- | Updates topic with MtGox data by fetching old topic with @get@
-- and writing new topic with @set@. If topic has no slot for data, do
-- not run any HTTP action.
updateTopic :: (Integer -> Integer -> IO Integer)
               -> IO ByteString 
               -> (ByteString -> IO ())
               -> IO ()
updateTopic m get set = do
  oldTopic <- get
  case splitOldTopic oldTopic of
    Nothing -> B.putStrLn "channel is missing BTC tag"
    Just (a,c) -> do
      b <- ircTopic m
      let new = B.concat [a,b,c]
      if oldTopic==new
        then B.putStrLn "topic is not changed"
        else do set new
                B.putStrLn "changed topic to: "
                B.putStrLn new
