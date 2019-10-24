{-# LANGUAGE DerivingVia #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

-- |
-- Module      : NRM.Types.Messaging.UpstreamRep
-- Copyright   : (c) UChicago Argonne, 2019
-- License     : BSD3
-- Maintainer  : fre@freux.fr
module NRM.Types.Messaging.UpstreamRep
  ( Rep (..),
    OutputType (..),
    EndStream (..),
    SliceList (..),
    CPD (..),
    Stdout (..),
    Stderr (..),
    Start (..),
    SliceKilled (..),
    CmdEnded (..),
    NoSuchCmd (..),
    StartFailure (..),
    NoSuchSlice (..),
    CmdKilled (..),
    ThisCmdKilled (..),
    GetPower (..),
    GetConfig (..),
    GetState (..),
  )
where

import qualified CPD.Core as CPD
import Data.Aeson
import Data.JSON.Schema
import Data.MessagePack
import NRM.Classes.Messaging
import NRM.Orphans.ExitCode ()
import NRM.Types.CmdID
import NRM.Types.Configuration as C
import NRM.Types.Slice as C
import NRM.Types.State as S
import NRM.Types.Units as U
import Protolude hiding (Rep)

data Rep
  = -- | Listing slices upon upstream request
    RepList SliceList
  | -- | Returning current CPD
    RepCPD CPD
  | -- | Command Started successfully
    RepStart Start
  | -- | Command Produced Stdout output
    RepStdout Stdout
  | -- | Command Produced Stderr output
    RepStderr Stderr
  | -- | Command out or err stream ended.
    RepEndStream EndStream
  | -- | Command failed to start
    RepStartFailure StartFailure
  | -- | Command ended with exit code
    RepCmdEnded CmdEnded
  | -- | No such slice was found in the state
    RepNoSuchSlice NoSuchSlice
  | -- | No such command was found in the state
    RepNoSuchCmd NoSuchCmd
  | -- | A slice was killed
    RepSliceKilled SliceKilled
  | -- | A command was killed
    RepCmdKilled CmdKilled
  | -- | The command for this upstream client was killed
    RepThisCmdKilled ThisCmdKilled
  | -- | Power query response
    RepGetPower GetPower
  | -- | State query response
    RepGetState GetState
  | -- | Configuration query response
    RepGetConfig GetConfig
  deriving (Show, Generic, MessagePack)

data OutputType = StdoutOutput | StderrOutput
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON OutputType

newtype EndStream
  = EndStream
      { streamType :: OutputType
      }
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON EndStream

data StartFailure
  = StartFailure
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON StartFailure

newtype CmdEnded
  = CmdEnded
      { exitCode :: ExitCode
      }
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON CmdEnded

data NoSuchCmd
  = NoSuchCmd
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON NoSuchCmd

data NoSuchSlice
  = NoSuchSlice
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON NoSuchSlice

newtype CPD
  = CPD
      { cpd :: CPD.Problem
      }
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON CPD

newtype SliceList
  = SliceList
      { slices :: [(C.SliceID, C.Slice)]
      }
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON SliceList

data Stdout
  = Stdout
      { stdoutCmdID :: CmdID,
        stdoutPayload :: Text
      }
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON Stdout

data Stderr
  = Stderr
      { stderrCmdID :: CmdID,
        stderrPayload :: Text
      }
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON Stderr

data Start
  = Start
      { startSliceID :: C.SliceID,
        startCmdID :: CmdID
      }
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON Start

data ThisCmdKilled
  = ThisCmdKilled
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON ThisCmdKilled

newtype CmdKilled
  = CmdKilled
      { killedCmdID :: CmdID
      }
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON CmdKilled

newtype SliceKilled
  = SliceKilled
      { killedSliceID :: C.SliceID
      }
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON SliceKilled

newtype GetPower
  = GetPower
      { limit :: U.Power
      }
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON GetPower

newtype GetState
  = GetState
      { state :: S.NRMState
      }
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON GetState

newtype GetConfig
  = GetConfig
      { config :: C.Cfg
      }
  deriving (Show, Generic, MessagePack)
  deriving (JSONSchema, ToJSON, FromJSON) via GenericJSON GetConfig

instance NRMMessage Rep Rep where

  fromJ = identity

  toJ = identity
