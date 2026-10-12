# Use a VLM as your eyes

If you can't read an image (your current model lacks vision), delegate to a vision-capable model:

```bash
opencode run -m "<model_id>" "<your_prompt>" -f <image_file_path> --thinking [--variant <variand_id>]
```

Ask the user which model and which reasoning level to use first. Options include:
- `VAI 1/Qwen3-VL-32B-Instruct-FP8` (vision)
- `opencode-go/muse-spark-1.3-contributor` (vision + reasoning; supports `--variant minimal|low|medium|high|xhigh`)
- ...

## Multiple images

Pass multiple `-f` flags. The CLI concatenates parts as `[file1, file2, ..., text]` — all images first, then the prompt text. So refer to images by their delivery order: `[Image 1]` = first `-f`, `[Image 2]` = second `-f`, etc.

```bash
opencode run -m "<model_id>" "Compare [Image 1] and [Image 2]. Which is darker?" -f img1.png -f img2.png --thinking [--variant <variant_id>]
```

The `[Image N]` tokens are plain text — opencode does not parse them. The model correlates them with the preceding image blocks by position. For true inline placement (e.g. "Look at [Image 1] then [Image 2] then [Image 1] again"), use the TUI composer (`opencode -i`) and `@mention` images at the desired cursor positions; the SDK preserves part order exactly as authored.

## Multi-turn conversations

For back-and-forth, pin a session ID rather than relying on `--continue` (which silently picks the most recent session and drifts if you interleave topics).

```bash
# 1. Start a session, capture the ID from the first JSON event
SID=$(opencode run -m "<model_id>" "<prompt>" --thinking [--variant <variant_id>] --format json 2>&1 | head -1 | jq -r .sessionID)

# 2. Fetch the first response (text + reasoning, since --format json drops the body)
opencode export "$SID" 2>/dev/null | jq '{text: ([.messages[-1].parts[] | select(.type=="text") | .text] | join("\n")), reasoning: ([.messages[-1].parts[] | select(.type=="reasoning") | .text] | join("\n"))}'

# 3. Continue with follow-ups (always pin the session ID)
opencode run -s "$SID" "<follow-up>" --thinking [--variant <variant_id>]
opencode run -s "$SID" "<another follow-up>" --thinking [--variant <variant_id>]
```

- `--format json` emits `{"sessionID": "ses_..."}` on the first line (and structured events after) — useful for the LLM to capture the ID, but not the human-readable body. Use `opencode export` to retrieve the last assistant message with text and reasoning.
- `-s` targets a specific session deterministically.
- Avoid `--continue` unless you're sure no other sessions will be created in between.
