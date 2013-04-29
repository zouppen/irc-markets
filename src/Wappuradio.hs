{-# LANGUAGE OverloadedStrings #-}
module Wappuradio where

import Data.Aeson
import Data.Aeson.Types
import Network.Curl.Aeson
import Data.Text (Text)

nytSoi :: IO Text
nytSoi = curlAesonGetWith p "http://www.wappuradio.fi/json/nytsoi.json"
  where p (Object o) = o .: "nytsoi"

