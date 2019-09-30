{-# LANGUAGE DerivingVia #-}

{-|
Module      : NRM.Types.DownstreamCmd
Copyright   : (c) UChicago Argonne, 2019
License     : BSD3
Maintainer  : fre@freux.fr
-}
module NRM.Types.DownstreamCmd
  ( DownstreamCmdID (..)
  , DownstreamCmd (..)
  , fromText
  , toText
  , toSensorID
  )
where

import Data.Aeson
import Data.Data
import Data.JSON.Schema
import Data.Map as DM
import Data.MessagePack
import Data.String (IsString (..))
import qualified Data.UUID as U
import LensMap.Core
import NRM.Classes.Messaging
import NRM.Classes.Sensors
import NRM.Types.Sensor
import NRM.Types.Units as Units
import Protolude
import Prelude (fail)

newtype DownstreamCmdID = DownstreamCmdID U.UUID
  deriving (Show, Eq, Ord, Generic, Data, Read, ToJSONKey, FromJSONKey)

toSensorID :: DownstreamCmdID -> SensorID
toSensorID (DownstreamCmdID uuid) = SensorID uuid

toText :: DownstreamCmdID -> Text
toText (DownstreamCmdID u) = U.toText u

fromText :: Text -> Maybe DownstreamCmdID
fromText = fmap DownstreamCmdID <$> U.fromText

data DownstreamCmd
  = DownstreamCmd
      { id :: SensorID
      , maxValue :: Units.Operations
      }
  deriving (Eq, Ord, Show, Generic, Data, MessagePack)
  deriving
    (JSONSchema, ToJSON, FromJSON)
    via GenericJSON DownstreamCmd

instance IsString DownstreamCmdID where

  fromString x =
    fromMaybe (panic "couldn't decode DownstreamCmdID")
      (Data.Aeson.decode $ toS x)

instance ToJSON DownstreamCmdID where

  toJSON (DownstreamCmdID x) = toJSON x

instance FromJSON DownstreamCmdID where

  parseJSON = fmap DownstreamCmdID <$> parseJSON

instance JSONSchema DownstreamCmdID where

  schema Proxy = schema (Proxy :: Proxy Text)

instance MessagePack DownstreamCmdID where

  toObject (DownstreamCmdID c) = toObject $ U.toText c

  fromObject x =
    fromObject x >>= \y ->
      case DownstreamCmdID <$> U.fromText y of
        Nothing -> fail "Couldn't parse DownstreamCmdID"
        Just t -> return t

instance HasLensMap (DownstreamCmdID, DownstreamCmd) ActiveSensorKey ActiveSensor where

  {-LM.map-}
  {-( \dc ->-}
  {-if DC.id dc == sensorID-}
  {-then dc & field @"maxValue" .~ (Operations $ floor b)-}
  {-else dc-}
  {-)-}
  lenses (downstreamCmdID, downstreamCmd) =
    DM.singleton
      ( SC.DownstreamCmd downstreamCmdID
      , ScopedLens (_2 . field @"rapl" . lens getter setter)
      )
    where
      getter (DownstreamCmd id maxValue) =
        Just $ ActiveSensor
          { activeTags = [Tag "perf"]
          , activeSource = Source $ show cmdID
          , activeRange = (0, 1)
          , maxFrequency = ratelimit $ monitoring $ app $ manifest cmdCore
          , process = identity
          }
        where
          textID = show packageID
      setter rapl (Just passiveSensor) =
        Just $ rapl & field @"max" .~ MaxEnergy (uJ (snd $ passiveRange passiveSensor))
      setter _rapl Nothing = Nothing
