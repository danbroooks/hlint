{-
    Suggest using better export declarations

<TEST>
main = 1
module Foo where foo = 1 -- module Foo(module Foo) where @NoRefactor
module Foo(foo) where foo = 1
module Foo(module Foo) where foo = 1 -- @Ignore module Foo(...) where @NoRefactor
module Foo(module Foo, foo) where foo = 1 -- module Foo(..., foo) where @NoRefactor
</TEST>
-}
{-# LANGUAGE TypeFamilies #-}

module Hint.Export(exportHint) where

import Hint.Type(ModuHint, ModuleEx(..),ideaNote,ignore',Note(..))

import HsSyn
import Module
import SrcLoc
import OccName
import RdrName

exportHint :: ModuHint
exportHint _ (ModuleEx _ _ (LL s m@HsModule {hsmodName = Just name, hsmodExports = exports}) _)
  | Nothing <- exports =
      let r = o{ hsmodExports = Just (noLoc [noLoc (IEModuleContents noExt name)] )} in
      [(ignore' "Use module export list" (L s o) (noLoc r) []){ideaNote = [Note "an explicit list is usually better"]}]
  | Just (L _ xs) <- exports
  , mods <- [x | x <- xs, isMod x]
  , modName <- moduleNameString (unLoc name)
  , names <- [ moduleNameString (unLoc n) | (LL _ (IEModuleContents _ n)) <- mods]
  , exports' <- [x | x <- xs, not (matchesModName modName x)]
  , modName `elem` names =
      let dots = mkRdrUnqual (mkVarOcc " ... ")
          r = o{ hsmodExports = Just (noLoc (noLoc (IEVar noExt (noLoc (IEName (noLoc dots)))) : exports') )}
      in
        [ignore' "Use explicit module export list" (L s o) (noLoc r) []]
      where
          o = m{hsmodImports=[], hsmodDecls=[], hsmodDeprecMessage=Nothing, hsmodHaddockModHeader=Nothing }
          isMod (LL _ (IEModuleContents _ _)) = True
          isMod _ = False

          matchesModName m (LL _ (IEModuleContents _ (L _ n))) = moduleNameString n == m
          matchesModName _ _ = False

exportHint _ _ = []
