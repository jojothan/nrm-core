{-# OPTIONS_GHC -fno-warn-partial-fields #-}
{-|
Module      : NRM.Types.Messaging.DownstreamEvent.JSON
Copyright   : (c) UChicago Argonne, 2019
License     : BSD3
Maintainer  : fre@freux.fr
-}
module NRM.Types.Messaging.DownstreamEvent.JSON
  ( Event (..)
  )
where

import Codegen.CHeader
import Protolude
import Record

data Event
  = CmdPerformance
      { cmdID :: Text
      , perf :: Int
      }
  | ThreadProgress
      { cmdID :: Text
      , processID :: Text
      , taskID :: Text
      , threadID :: Text
      , payload :: Int
      }
  | ThreadPhaseContext
      { cmdID :: Text
      , processID :: Text
      , taskID :: Text
      , threadID :: Text
      , cpu :: Int
      , startcompute :: Int
      , endcompute :: Int
      , startbarrier :: Int
      , endbarrier :: Int
      }
  deriving (Generic, CHeaderGen)

newtype T = T 
  [r| {host :: Text,
       port :: Int} |]
 deriving (Show, Generic)

t :: T 
t = T [r| { host = "o", port = 2} |]
