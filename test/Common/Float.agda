{-# OPTIONS --cubical-compatible --level-universe --safe #-}

module Common.Float where

open import Agda.Builtin.Float public
open import Common.String

floatToString : Float  -> String
floatToString = primShowFloat
