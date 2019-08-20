{-|
Module      : Nrm.Optparse.Client
Copyright   : (c) UChicago Argonne, 2019
License     : BSD3
Maintainer  : fre@freux.fr
-}
module Nrm.Optparse.Client
  ( opts
  , Opts (..)
  , CommonOpts (..)
  )
where

import qualified Data.ByteString as B
  ( getContents
  )
import Dhall
import Nrm.Types.Container
import Nrm.Types.Manifest
import qualified Nrm.Types.Manifest.Dhall as D
import qualified Nrm.Types.Manifest.Yaml as Y
import Nrm.Types.Messaging.UpstreamReq
import qualified Nrm.Types.Process as P
import qualified Nrm.Types.Units as U
import Nrm.Types.UpstreamClient
import Options.Applicative
import Protolude
import System.Directory
import System.Environment
import System.FilePath.Posix
import Text.Editor
import qualified Prelude
  ( print
  )

newtype CommonOpts
  = CommonOpts
      { verbose :: ClientVerbosity
      }

parserCommon :: Parser CommonOpts
parserCommon =
  CommonOpts <$>
    flag Normal
      Verbose
      (long "verbose" <> short 'v' <> help "Enable verbose mode.")

data RunCfg
  = RunCfg
      { stdinType :: SourceType
      , edit :: Bool
      , inputfile :: Maybe Text
      , containerName :: Maybe Text
      , cmd :: Text
      , runargs :: [Text]
      }

parserRun :: Parser RunCfg
parserRun =
  RunCfg <$>
    flag
      Dhall
      Yaml
      ( long "yaml" <> short 'y' <>
        help
          "Assume stdin to be yaml instead of dhall."
      ) <*>
    flag
      False
      True
      (long "edit" <> short 'e' <> help "Edit manifest yaml in $EDITOR before running the NRM client.") <*>
    optional
      ( strOption
        ( long "manifest" <>
          metavar "MANIFEST" <>
          help
            "Input manifest with .yml/.yaml/.dh/.dhall extension. Leave void for stdin (dhall) input."
        )
      ) <*>
    optional
      ( strOption
        ( long "container" <> short 'c' <>
          metavar "CONTAINER" <>
          help
            "Container name/UUID"
        )
      ) <*>
    strArgument
      ( metavar "CMD" <>
        help
          "Command name"
      ) <*>
    some
      ( strArgument
        ( metavar "ARG" <>
          help
            "Command arguments"
        )
      )

parserKill :: Parser ContainerID
parserKill =
  parseContainerID <$>
    strArgument
      ( metavar "CONTAINER" <>
        help
          "Name/UUID of the container to kill"
      )

parserSetpower :: Parser U.Power
parserSetpower =
  U.watts <$>
    argument Options.Applicative.auto
      ( metavar "POWERLIMIT" <>
        help
          "Power limit to set"
      )

data Opts = Opts {req :: Req, commonOpts :: CommonOpts}

opts :: Parser (IO Opts)
opts =
  hsubparser $
    command "run"
      ( info (run <$> parserRun <*> parserCommon) $
        progDesc "Run the application via NRM"
      ) <>
    command "kill"
      ( info (return <$> (Opts <$> (ReqKill . Kill <$> parserKill) <*> parserCommon)) $
        progDesc "Kill container"
      ) <>
    command
      "setpower"
      ( info
        ( return <$>
          ( Opts <$> (ReqSetPower . SetPower <$> parserSetpower) <*>
            parserCommon
          )
        ) $
        progDesc "Set power limit"
      ) <>
    command
      "list"
      ( info (return <$> (Opts (ReqContainerList ContainerList) <$> parserCommon)) $
        progDesc "List existing containers"
      ) <>
    command
      "state"
      ( info (return <$> (Opts (ReqGetState GetState) <$> parserCommon)) $
        progDesc "Show Nrm state"
      ) <>
    command
      "config"
      ( info (return <$> (Opts (ReqGetConfig GetConfig) <$> parserCommon)) $
        progDesc "Show Nrm configuration"
      ) <>
    help
      "Choice of operation."

data SourceType = Dhall | Yaml
  deriving (Eq)

data FinallySource = NoExt | FinallyFile SourceType Text | FinallyStdin SourceType

ext :: SourceType -> Maybe Text -> FinallySource
ext _ (Just fn)
  | xt `elem` [".dh", ".dhall"] = FinallyFile Dhall fn
  | xt `elem` [".yml", ".yaml"] = FinallyFile Yaml fn
  | otherwise = NoExt
  where
    xt = takeExtension $ toS fn
ext st Nothing = FinallyStdin st

load :: RunCfg -> IO Manifest
load RunCfg {..} =
  (if edit then editing else return) =<< case ext stdinType inputfile of
    (FinallyFile Dhall filename) ->
      detailed $
        D.inputManifest =<<
        toS <$>
        makeAbsolute (toS filename)
    (FinallyFile Yaml filename) ->
      Y.decodeManifestFile =<< toS <$> makeAbsolute (toS filename)
    (FinallyStdin Yaml) ->
      B.getContents <&> Y.decodeManifest >>= \case
        Left e -> Prelude.print e >> die "yaml parsing exception."
        Right manifest -> return manifest
    (FinallyStdin Dhall) -> B.getContents >>= D.inputManifest . toS
    NoExt ->
      die
        ( "couldn't figure out extension for input file. " <>
          "Please use something in {.yml,.yaml,.dh,.dhall} ."
        )

editing :: Manifest -> IO Manifest
editing c =
  runUserEditorDWIM yt (Y.encodeManifest c) <&> Y.decodeManifest >>= \case
    Left e -> Prelude.print e >> die "yaml parsing exception."
    Right manifest -> return manifest
  where
    yt = mkTemplate "yaml"

run :: RunCfg -> CommonOpts -> IO Opts
run rc common = do
  manifest <- load rc
  cn <-
    case containerName rc of
      Nothing -> fromMaybe (panic "Couldn't generate next container UUID") <$> nextContainerID
      Just n -> return $ Name n
  env <- fmap (\(x, y) -> (toS x, toS y)) <$> getEnvironment
  return $
    Opts
      ( ReqRun $ Run
        { manifest = manifest
        , path = P.Command $ cmd rc
        , args = P.Arguments $ P.Arg <$> runargs rc
        , runContainerID = cn
        , environ = P.Env env
        }
      )
      common

{-containerName :: Maybe Text-}
{-cmd :: Text-}
{-args :: [Text]-}

{-printY :: ManifestLocationCfg -> IO Manifest-}
{-printY c = do-}
{-manifest <- load c-}
{-putText . toS . Y.encodeManifest $ manifest-}
{-return manifest-}
