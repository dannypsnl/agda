{-# OPTIONS_GHC -Wunused-imports #-}

module Agda.Interaction.Options.Help
       (
         Help (..)
       , helpTopicUsage
       , string2HelpTopic
       , allHelpTopics
       ) where

import Control.DeepSeq

import GHC.Generics (Generic)

import Agda.Interaction.Options.Errors
import Agda.Interaction.Options.Warnings

import qualified Agda.Setup.EmacsMode as EmacsMode

-- | Interface to the @help@ function
data Help
  = GeneralHelp
  -- ^ General usage information
  | HelpFor HelpTopic
  -- ^ Specialised usage information about TOPIC
  deriving (Eq, Show, Generic)

instance NFData Help

-- | List of Help Topics
-- NOTA BENE:
-- You need to add each new topic together with its name to @allHelpTopics@

data HelpTopic
  = Warning
  | Error
  | EmacsMode
  deriving (Eq, Show, Generic)

instance NFData HelpTopic

allHelpTopics :: [(String, HelpTopic)]
allHelpTopics =
  [ ("warning"   , Warning  )
  , ("error"     , Error    )
  , ("emacs-mode", EmacsMode)
  ]

-- | Usage information generation

helpTopicUsage :: HelpTopic -> String
helpTopicUsage = \case
  Warning   -> usageWarning
  Error     -> helpErrors
  EmacsMode -> EmacsMode.help

-- | Conversion functions to strings

string2HelpTopic :: String -> Maybe HelpTopic
string2HelpTopic = flip lookup allHelpTopics

-- UNUSED Liang-Ting Chen 2019-07-15
--helpTopic2String :: HelpTopic -> String
--helpTopic2String w = fromMaybe __IMPOSSIBLE__ $ lookup w (map swap allHelpTopics)
--
