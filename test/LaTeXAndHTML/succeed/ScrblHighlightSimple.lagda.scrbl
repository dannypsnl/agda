@title{simple}

@p{This is test file}
@agda|{
module ScrblHighlightSimple where

  data Bool : Set where
            true : Bool
            false : Bool

  a : Bool
  a = true
}|
