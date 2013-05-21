{-# OPTIONS --without-K #-}

module WithoutK11 where

data _≡_ {A : Set} (x : A) : A → Set where
  refl : x ≡ x

pattern r = refl

-- The --without-K option works with pattern synonyms.
K : (A : Set)(x : A)(P : x ≡ x → Set) → P refl → (p : x ≡ x ) →  P p
K A x P pr r = pr
