module TopicEngine where


-- | Splits topic to pieces in which you may put the stuff inside
splitOldTopic :: ByteString -> ByteString -> Maybe (ByteString, ByteString)
splitOldTopic tag s = case matches of
  Just [_,start,end] -> Just (start,end)
  _ -> Nothing
  where
    matches  = match compiled s []
    compiled = compile pattern [anchored]
    pattern  = B.concat ["(.*",tag,").*?($| \\|.*)"]

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
      b <- mtGoxTopic m
      let new = B.concat [a,b,c]
      if oldTopic==new
        then B.putStrLn "topic is not changed"
        else do set new
                B.putStr "changed topic to: "
                B.putStrLn new
