nice, write down (or update if this file existed) what we have done into docs/plans/{{date:yyyy/MM/dd}}/{{date:yyyy-MM-dd}}-<you-name-it>.md including trials, errors and lessons learnt.

Do this only for repos with actual changes this session. Check `git status` in the parent and each submodule first; a parent/harness-only change stays in the parent and must not be copied into clean submodules. If a change genuinely spans repos, put the full design log in the repo that owns the code and only cross-link from the others.

Then update docs/important/ and README.md in those same repos.
