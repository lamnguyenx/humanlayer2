document this bug into docs/issues/bugs/{{date:yyyy/MM/dd}}/{{date:yyyy-MM-dd}}-<you-name-it>.md
include the solution, trials and errors when finding the solution if needed

Do this only for repos with actual changes in the fix. Check `git status` in the parent and each submodule first; a parent/harness-only bug stays in the parent and must not be copied into clean submodules. If the fix genuinely spans repos, put the full write-up in the repo that owns the code and only cross-link from the others.
