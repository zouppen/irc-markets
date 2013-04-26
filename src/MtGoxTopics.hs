{-# LANGUAGE OverloadedStrings #-}
module MtGoxTopics where

import Control.Applicative
import Control.Monad
import Data.Aeson
import Data.Aeson.Types
import Data.ByteString (ByteString)
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import Network.Curl.Aeson
import Text.Regex.PCRE.Light
import qualified Data.ByteString.Char8 as B

ircTopic :: IO ByteString
ircTopic = curlAesonGetWith p "http://data.mtgox.com/api/1/BTCEUR/ticker"
  where 
    p (Object o) = do
      low  <- pure o..."return"..."low"..."value_int"
      high <- pure o..."return"..."high"..."value_int"
      vol  <- pure o..."return"..."vol"..."value_int"
      return $ encodeUtf8 $
        T.concat ["BTC 24h: ", numBs low 1e5,"–",numBs high 1e5
                 ," € (volyymi "
                 ,numBs vol 1e11
                 ," kBTC)"
                 ]
    numBs :: String -> Double -> T.Text
    numBs s prec = T.pack $ show $ round $ read s / prec

-- | Splits topic to pieces in which you may put the BTC course inside.
splitOldTopic :: ByteString -> Maybe (ByteString, ByteString)
splitOldTopic s = case matches of
  Just [_,start,end] -> Just (start,end)
  _ -> Nothing
  where 
    matches = match re s []
    re = compile "(.*)BTC 24h: .*?\\)(.*)" [anchored]

-- | Updates topic with MtGox data by fetching old topic with @get@
-- and writing new topic with @set@. If topic has no slot for data, do
-- not run any HTTP action.
updateTopic :: IO ByteString -> (ByteString -> IO ()) -> IO ()
updateTopic get set = do
  oldTopic <- get
  case splitOldTopic oldTopic of
    Nothing -> return ()
    Just (a,c) -> do
      b <- ircTopic
      let new = B.concat [a,b,c]
      when (oldTopic/=new) (set new)
