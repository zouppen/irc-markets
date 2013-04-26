module TemporalCache where

import qualified Data.Map as M
import Control.Concurrent.STM

-- | Map insertion which inserts value and drops previous values which
-- are older than given age. The key must be a timestamp or other kind
-- of increasing value.
ensureAgeInsert
  :: (Num k, Ord k) => k -> k -> a -> M.Map k a -> M.Map k a
ensureAgeInsert age k a m = M.insert k a $ M.filterWithKey cond m
  where cond this _ = this > k-age

-- | Return map which keeps only elements of given age. After
-- insertion it returns the oldest event in map.
newEmptyAgingMap :: (Num k, Ord k) => k -> IO (k -> a -> IO a)
newEmptyAgingMap age = do  
  var <- newTVarIO M.empty
  return $ f var
  where f var k a = atomically $ do
          oldMap <- readTVar var
          let newMap = ensureAgeInsert age k a oldMap
          writeTVar var newMap
          return $ snd $ M.findMin newMap
