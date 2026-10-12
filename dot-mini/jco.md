function jco () {

# opencode run --auto -m "VAI 2/DeepSeek-V4.1-Flash" -- \
# opencode run --auto -m "opencode-go/deepseek-v4.1-flash" -- \
opencode run --auto -m "VAI 2/glm-5.3" -- \
"$(cat /home/lamnt45/git/humanlayer2/dot-claude/commands/commit.md)
---
merge all into 1 commit
dont need to ask, just commit
"
}
