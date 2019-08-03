{-|
Module      : Nrm.Containers
Description : Containers interface and dispatch methods
Copyright   : (c) UChicago Argonne, 2019
License     : BSD3
Maintainer  : fre@freux.fr
-}
module Nrm.Containers
  ( ContainerRuntime (..)
  {-, getRuntime-}
  )
where

import Nrm.Containers.Class
import Nrm.Containers.Dummy
import Nrm.Containers.Nodeos
import Nrm.Containers.Singularity
import Protolude

data RuntimeName = NameDummy | NameOther

data Runtime = TagDummy DummyRuntime | TagOther DummyRuntime

{-instance -}

{-instance (MonadIO m) => ContainerRuntime m Runtime () where-}
{-getRuntime-}
  {-:: (MonadIO m, ContainerRuntime m DummyRuntime ())-}
  {-=> RuntimeName-}
  {--> m (Either Text Runtime)-}
{-getRuntime NameDummy = (TagDummy <$>) <$> doEnableRuntime-}
{-getRuntime NameOther = (TagOther <$>) <$> doEnableRuntime-}
