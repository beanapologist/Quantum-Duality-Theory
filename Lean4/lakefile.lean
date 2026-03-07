import Lake
open Lake DSL

package «QDTBlackHole» where
  name := "QDTBlackHole"

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "v4.14.0"

@[default_target]
lean_lib «QDTBlackHole» where
  globs := #[.andSubmodules `QDTBlackHole]
