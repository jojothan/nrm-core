{-|
Module      : Nrm.Types.Messaging.DownstreamEvent.JSON
Copyright   : (c) UChicago Argonne, 2019
License     : BSD3
Maintainer  : fre@freux.fr
-}
module Nrm.Types.Messaging.DownstreamEvent.JSON
  ( Event (..)
  )
where

import Codegen.CHeader
import Protolude

data Event
  = Start
      { container_uuid :: Text
      , application_uuid :: Text
      }
  | Exit
      { application_uuid :: Text
      }
  | Performance
      { container_uuid :: Text
      , application_uuid :: Text
      , perf :: Int
      }
  | Progress
      { application_uuid :: Text
      , payload :: Int
      }
  | PhaseContext
      { cpu :: Int
      , startcompute :: Int
      , endcompute :: Int
      , startbarrier :: Int
      , endbarrier :: Int
      }
  deriving (Generic, CHeaderGen)
