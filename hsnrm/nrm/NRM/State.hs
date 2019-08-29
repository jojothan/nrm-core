{-|
Module      : NRM.State
Copyright   : (c) 2019, UChicago Argonne, LL
License     : BSD3
Maintainer  : fre@freux.fr
-}
module NRM.State
  ( -- * Initial state
    initialState
  , -- * Creation/Registration
    createSlice
  , registerLibnrmDownstreamClient
  , registerAwaiting
  , registerFailed
  , registerLaunched
  , -- * Removal
    -- ** Slice removal
    removeSlice
  , -- ** Command removal
    CmdKey (..)
  , DeletionInfo (..)
  , removeCmd
  )
where

import qualified Data.Map as DM
import NRM.Slices.Dummy as CD
import NRM.Slices.Nodeos as CN
import NRM.Slices.Singularity as CS
import NRM.Node.Hwloc
import NRM.Node.Sysfs
import NRM.Node.Sysfs.Internal
import NRM.Types.Configuration
import NRM.Types.Slice
import NRM.Types.DownstreamClient
import NRM.Types.State
import NRM.Types.Process
import qualified NRM.Types.Sensor as Sensor
import NRM.Types.Topology
import NRM.Types.UpstreamClient
import Protolude

-- | Populate the initial NRMState.
initialState :: Cfg -> IO NRMState
initialState c = do
  hwl <- getHwlocData
  let packages' = DM.fromList $ (,Package {raplSensor = Nothing}) <$> selectPackageIDs hwl
  packages <-
    getDefaultRAPLDirs (toS $ raplPath $ raplCfg c) <&> \case
      Just (RAPLDirs rapldirs) -> Protolude.foldl goRAPL packages' rapldirs
      Nothing -> packages'
  return $ NRMState
    { slices = DM.fromList []
    , pus = DM.fromList $ (,PU) <$> selectPUIDs hwl
    , cores = DM.fromList $ (,Core) <$> selectCoreIDs hwl
    , dummyRuntime = if dummy c
    then Just CD.emptyRuntime
    else Nothing
    , singularityRuntime = if singularity c
    then Just SingularityRuntime
    else Nothing
    , nodeosRuntime = if nodeos c
    then Just NodeosRuntime
    else Nothing
    , ..
    }
  where
    goRAPL m RAPLDir {..} = DM.adjust (addRAPLSensor path maxEnergy) pkgid m
    addRAPLSensor path maxEnergy Package {..} = Package
      { raplSensor = Just
          ( Sensor.RaplSensor
            { raplPath = path
            , max = maxEnergy
            }
          )
      , ..
      }


-- | TODO
registerLibnrmDownstreamClient :: NRMState -> DownstreamThreadID -> NRMState
registerLibnrmDownstreamClient s _ = s

-- | Removes a slice from the state
removeSlice :: SliceID -> NRMState -> (Maybe Slice, NRMState)
removeSlice sliceID st =
  ( DM.lookup sliceID (slices st)
  , st {slices = DM.delete sliceID (slices st)}
  )

-- | Result annotation for command removal from the state.
data DeletionInfo
  = -- | If the slice was removed as a result of the command deletion
    SliceRemoved
  | -- | If the command was removed but the slice stayed.
    CmdRemoved

-- | Wrapper for the type of key to lookup commands on
data CmdKey = KCmdID CmdID | KProcessID ProcessID

-- | Removes a command from the state, and also removes the slice if it's
-- empty as a result.
removeCmd
  :: CmdKey
  -> NRMState
  -> Maybe (DeletionInfo, CmdID, Cmd, SliceID, NRMState)
removeCmd key st = case key of
  KCmdID cmdID ->
    DM.lookup cmdID (cmdIDMap st) <&> \(cmd, sliceID, slice) ->
      go cmdID cmd sliceID slice
  KProcessID pid ->
    DM.lookup pid (pidMap st) <&> \(cmdID, cmd, sliceID, slice) ->
      go cmdID cmd sliceID slice
  where
    go cmdID cmd sliceID slice =
      if length (cmds slice) == 1
      then (SliceRemoved, cmdID, cmd, sliceID, snd $ removeSlice sliceID st)
      else
        ( CmdRemoved
        , cmdID
        , cmd
        , sliceID
        , insertSlice sliceID
          (slice {cmds = DM.delete cmdID (cmds slice)})
          st
        )

-- | Registers a slice if not already tracked in the state, and returns the new state.
createSlice
  :: SliceID
  -> NRMState
  -> NRMState
createSlice sliceID st =
  case DM.lookup sliceID (slices st) of
    Nothing -> st {slices = slices'}
      where
        slices' = DM.insert sliceID emptySlice (slices st)
    Just _ -> st

-- | Registers an awaiting command in an existing slice
registerAwaiting
  :: CmdID
  -> CmdCore
  -> SliceID
  -> NRMState
  -> NRMState
registerAwaiting cmdID cmdValue sliceID st =
  st {slices = DM.update f sliceID (slices st)}
  where
    f c = Just $ c {awaiting = DM.insert cmdID cmdValue (awaiting c)}

{-{ awaiting = DM.delete cmdID (awaiting slice)-}
{-, cmds = DM.insert cmdID c (cmds slice)-}

-- | Turns an awaiting command to a launched one.
registerLaunched
  :: CmdID
  -> ProcessID
  -> NRMState
  -> Either Text (NRMState, SliceID, Maybe UpstreamClientID)
registerLaunched cmdID pid st =
  case DM.lookup cmdID (awaitingCmdIDMap st) of
    Nothing -> Left "No such awaiting command."
    Just (cmdCore, sliceID, slice) ->
      Right
        ( st
            { slices = DM.insert sliceID
                ( slice
                  { cmds = DM.insert cmdID (registerPID cmdCore pid) (cmds slice)
                  , awaiting = DM.delete cmdID (awaiting slice)
                  }
                )
                (slices st)
            }
        , sliceID
        , upstreamClientID cmdCore
        )

-- | Fails an awaiting command.
registerFailed
  :: CmdID
  -> NRMState
  -> Maybe (NRMState, SliceID, Slice, CmdCore)
registerFailed cmdID st =
  DM.lookup cmdID (awaitingCmdIDMap st) <&> \(cmdCore, sliceID, slice) ->
    (st {slices = DM.update f sliceID (slices st)}, sliceID, slice, cmdCore)
  where
    f c =
      if null (cmds c)
      then Nothing
      else Just $ c {awaiting = DM.delete cmdID (awaiting c)}
