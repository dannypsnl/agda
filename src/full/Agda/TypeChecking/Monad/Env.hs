{-# OPTIONS_GHC -Wunused-imports #-}

module Agda.TypeChecking.Monad.Env where

import qualified Data.List as List

import Data.Maybe (fromMaybe)

import Agda.Syntax.Common
import Agda.Syntax.Abstract.Name

import Agda.TypeChecking.Monad.Base

import qualified Agda.Utils.SmallSet as SmallSet

import Agda.Utils.Impossible

-- | Get the name of the current module, if any.
{-# SPECIALIZE currentModule :: TCM ModuleName #-}
{-# SPECIALIZE currentModule :: ReduceM ModuleName #-}
currentModule :: MonadTCEnv m => m ModuleName
currentModule = asksTC envCurrentModule

-- | Set the name of the current module.
withCurrentModule :: (MonadTCEnv m) => ModuleName -> m a -> m a
withCurrentModule m =
    localTC $ \ e -> e { envCurrentModule = m }

-- | Get the path of the currently checked file
getCurrentPath :: (MonadTCEnv m, MonadFileId m) => m AbsolutePath
getCurrentPath = do
  i <- fromMaybe __IMPOSSIBLE__ <$> asksTC envCurrentPath
  fileFromId i

-- | Get the number of variables bound by anonymous modules.
{-# SPECIALIZE getAnonymousVariables :: ModuleName -> TCM Nat #-}
{-# SPECIALIZE getAnonymousVariables :: ModuleName -> ReduceM Nat #-}
getAnonymousVariables :: MonadTCEnv m => ModuleName -> m Nat
getAnonymousVariables m = do
  ms <- asksTC envAnonymousModules
  return $ sum [ n | (m', n) <- ms, mnameToList m' `List.isPrefixOf` mnameToList m ]

-- | Add variables bound by an anonymous module.
withAnonymousModule :: ModuleName -> Nat -> TCM a -> TCM a
withAnonymousModule m n =
  localTC $ \ e -> e { envAnonymousModules = (m, n) : envAnonymousModules e }

-- | Set the current environment to the given
withEnv :: MonadTCEnv m => TCEnv -> m a -> m a
withEnv env = localTC $ \ env0 -> env
  -- Keep persistent settings
  { envPrintMetasBare         = envPrintMetasBare env0
  }

-- | Get the current environment
getEnv :: TCM TCEnv
getEnv = askTC

-- | Set highlighting level
withHighlightingLevel :: HighlightingLevel -> TCM a -> TCM a
withHighlightingLevel h = localTC $ \ e -> e { envHighlightingLevel = h }

-- | Restore setting for 'ExpandLast' to default.
doExpandLast :: TCM a -> TCM a
doExpandLast = localTC $ \ e -> e { envExpandLast = setExpand (envExpandLast e) }
  where
    setExpand ReallyDontExpandLast = ReallyDontExpandLast
    setExpand _                    = ExpandLast

dontExpandLast :: TCM a -> TCM a
dontExpandLast = localTC $ \ e -> e { envExpandLast = DontExpandLast }

reallyDontExpandLast :: TCM a -> TCM a
reallyDontExpandLast = localTC $ \ e -> e { envExpandLast = ReallyDontExpandLast }

-- | If the reduced did a proper match (constructor or literal pattern),
--   then record this as simplification step.
{-# SPECIALIZE performedSimplification :: TCM a -> TCM a #-}
performedSimplification :: MonadTCEnv m => m a -> m a
performedSimplification = localTC $ \ e -> e { envSimplification = YesSimplification }

{-# SPECIALIZE performedSimplification' :: Simplification -> TCM a -> TCM a #-}
performedSimplification' :: MonadTCEnv m => Simplification -> m a -> m a
performedSimplification' simpl = localTC $ \ e -> e { envSimplification = simpl `mappend` envSimplification e }

getSimplification :: MonadTCEnv m => m Simplification
getSimplification = asksTC envSimplification

-- * Controlling reduction.

-- | Lens for 'AllowedReductions'.
updateAllowedReductions :: (AllowedReductions -> AllowedReductions) -> TCEnv -> TCEnv
updateAllowedReductions f e = e { envAllowedReductions = f (envAllowedReductions e) }

modifyAllowedReductions :: MonadTCEnv m => (AllowedReductions -> AllowedReductions) -> m a -> m a
modifyAllowedReductions = localTC . updateAllowedReductions

putAllowedReductions :: MonadTCEnv m => AllowedReductions -> m a -> m a
putAllowedReductions = modifyAllowedReductions . const

-- | Reduce @Def f vs@ only if @f@ is a projection.
onlyReduceProjections :: MonadTCEnv m => m a -> m a
onlyReduceProjections = modifyAllowedReductions $ SmallSet.intersection $
  SmallSet.singleton ProjectionReductions

-- | Allow all reductions except for non-terminating functions (default).
allowAllReductions :: MonadTCEnv m => m a -> m a
allowAllReductions = putAllowedReductions allReductions

-- | Allow all reductions including non-terminating functions.
allowNonTerminatingReductions :: MonadTCEnv m => m a -> m a
allowNonTerminatingReductions = putAllowedReductions reallyAllReductions

-- | Allow all reductions when reducing types. Otherwise only allow
--   inlined functions to be unfolded.
onlyReduceTypes :: MonadTCEnv m => m a -> m a
onlyReduceTypes = modifyAllowedReductions $ SmallSet.intersection $
  SmallSet.fromList [TypeLevelReductions, InlineReductions]

-- | Update allowed reductions when working on types
typeLevelReductions :: MonadTCEnv m => m a -> m a
typeLevelReductions = modifyAllowedReductions $ \reds -> if
  | TypeLevelReductions `SmallSet.member` reds ->
      if NonTerminatingReductions `SmallSet.member` reds
       then reallyAllReductions
       else allReductions
  | otherwise -> reds

-- * Concerning 'envInsideDotPattern'

insideDotPattern :: TCM a -> TCM a
insideDotPattern = localTC $ \ e -> e { envInsideDotPattern = True }

isInsideDotPattern :: TCM Bool
isInsideDotPattern = asksTC envInsideDotPattern

-- | Don't use call-by-need evaluation for the given computation.
callByName :: TCM a -> TCM a
callByName = localTC $ \ e -> e { envCallByNeed = False }

-- | Don't fold let bindings when printing. This is a bit crude since it disables any folding of let
--   bindings at all. In many cases it's better to use `removeLetBinding` before printing to drop
--   the let bindings that should not be folded.
dontFoldLetBindings :: MonadTCEnv m => m a -> m a
dontFoldLetBindings = localTC $ \ e -> e { envFoldLetBindings = False }
