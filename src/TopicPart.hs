module TopicPart where

import Data.Text (Text)

-- | Periodic update of topics
data TopicPart =
  TopicPart { tag      :: ByteString -- ^ Starting tag
            , update   :: IO Text    -- ^ Updating function
            , interval :: Integer    -- ^ Microseconds between updates
            }

-- | Seconds in a minute. Makes code more readable.
minute :: Integer
minute = 60000000
