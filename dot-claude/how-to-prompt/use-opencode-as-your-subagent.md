# Use OpenCode as your subagent

If your harness has no subagent/Task tool — or you want a different model, a clean
context, or several workers at once — shell out to OpenCode. Each `opencode run` is a
full agent session with its own context, tools, and permission system. The run is
one-shot for you; the session is not. It stays addressable, so the user can reopen it
and keep chatting with the same worker.

Treat the session ID as part of the result. Do not hand back only the answer. Think of
each delegation as a turn with a persistent teammate, not as a subprocess you discard.

## Pick exactly one model first

Use exactly one model, chosen by the user — never pick silently. Invoked from
SnippetSurfer, this guide asks once with a **Model** dropdown (first option
preselected) and expands to the chosen ID; every exact repeat of the same choice token
reuses that one answer:

```text
model: {{choice:Model=VAI 2/glm-5.3|opencode-go/deepseek-v4.1-flash}}
```

If no model has been chosen yet, ask the same multiple-choice question with your
harness's question tool. Run `opencode models` when you need the configured IDs. Put
the choice in `MODEL` once per shell:

```bash
MODEL="{{choice:Model=VAI 2/glm-5.3|opencode-go/deepseek-v4.1-flash}}"
```

Reasoning variants are part of the model string, and support varies by model; ask for
one only when the chosen model lists variants:

```bash
opencode run -m "$MODEL#high" "..."   # e.g. #high; check the model's variants
```

## Basic call

```bash
opencode run -m "$MODEL" --title "<short label>" "<prompt>"
```

Useful flags:

| Flag | What it does |
| --- | --- |
| `--agent build` | Default. Can edit files and run commands. |
| `--agent plan` | Analysis and planning; edit/write tools are denied. |
| `--agent explore` | Fast read-only search and mapping. |
| `--thinking` | Include reasoning blocks. |
| `-f, --file` | Attach a file; repeatable. |
| `--format json` | Emit newline-delimited events instead of prose. |
| `--auto` | Approve permissions that are not explicitly denied. |
| `-w=<name>` | Run in a fresh git worktree (note the `=`). |
| `--title` | Label the session so the user can find it later. |
| `--archived` | Hide a throwaway run from the session picker. |
| `-s`, `--fork` | Continue a pinned session, or branch it first. |

List the configured agents with `opencode debug agents`.

Run from the target directory. `opencode run` uses the current working directory;
`opencode <directory>` opens the TUI instead of running a prompt.

For a resumable session, add `--format json` so you can capture the session ID
(see [Get a parseable result](#get-a-parseable-result)).

## Write a brief it can act on

The subagent starts with no access to your conversation, plan, or reasoning. It also
cannot ask you questions: a non-interactive approval request is rejected, not queued.
Give it everything it needs in the prompt:

```text
You are a subagent. The caller will not answer questions, so do not ask any.
Working directory: /abs/path/to/repo
Goal: <one sentence>
Context: <what the caller already knows; skip rediscovery>
Constraints:
- <files/areas to avoid>
- <style, library, or version constraints>
Definition of done:
- <observable behavior>
- `<test command>` passes
Final answer:
- <exact format: findings as path:line, changed files, test output, or a patch summary>
- State every assumption you made.
```

Prefer `--agent plan` or `--agent explore` for investigation and review. Use
`--agent build` when you actually want files changed.

## Get a parseable result

In the default format, assistant text goes to stdout and banners, status, and tool UI
go to stderr:

```bash
answer=$(opencode run -m "$MODEL" "..." 2>/dev/null)
```

For anything agentic, use JSONL:

```bash
opencode run -m "$MODEL" --title "<label>" --format json "..." > run.jsonl 2> run.err

SID=$(head -1 run.jsonl | jq -r .sessionID)
jq -r 'select(.type == "text") | .part.text' run.jsonl
```

The default format above does not expose the session ID. Use JSONL whenever you plan
to hand the session back.

Every line is an event. `text` is the answer; `--thinking` adds `reasoning` events;
`step_start` and `step_finish` frame each step, and `step_finish` reports token usage
and cost. Always filter to `text` when you want only the deliverable.

A task can fail and still exit 0 — a rejected permission, for example. Check the
transcript, `git status`, and `git diff`; don't trust the exit code alone.

## Hand the session back

`opencode run` ends your turn, not the conversation. When you report the result to the
user, include the session ID and a resume command:

```bash
# Interactive TUI, run from the project directory
opencode -s "$SID"

# Minimal interface
opencode mini -s "$SID"

# Another one-shot turn, from you or the user
opencode run -s "$SID" -m "$MODEL" "<follow-up>"
```

Use a meaningful `--title`, and omit `--archived` when the user may want to continue
the conversation: archived sessions stay addressable by ID but disappear from the
session picker. If you forgot to capture the ID, find it with `opencode session list`
or `opencode session list --format json`.

Reuse the same session for related follow-ups instead of starting a new worker; it
already has the repo context and prior decisions. Start a new session only when you
want a clean slate or a parallel branch.

End your report to the user with something like:

```text
OpenCode session: ses_...
Continue it with: opencode -s ses_...
```

## Continue the same conversation

Both you and the user can send more turns to the same session. Pin the session ID
instead of using `--continue`, which silently picks the newest session and drifts if
anything else runs in between:

```bash
opencode run -s "$SID" -m "$MODEL" "Now handle the empty case."
opencode run -s "$SID" --fork -m "$MODEL" "Try the alternative approach instead."
```

`--fork` branches the conversation while leaving the original intact for the user.

Read the last assistant reply from the stored transcript:

```bash
opencode session export "$SID" | jq -r '
  .messages
  | map(select(.type == "assistant"))
  | last
  | .content
  | map(select(.type == "text") | .text)
  | join("\n")'
```

## Parallel workers

Read-only fan-out — one process per area, all sharing the OpenCode server but with
separate contexts:

```bash
MODEL="{{choice:Model=VAI 2/glm-5.3|opencode-go/deepseek-v4.1-flash}}"
mkdir -p /tmp/oc

for area in api web db; do
  opencode run -m "$MODEL" --agent explore --format json \
    --title "explore:$area" \
    "In this repo, map how $area works. Return file:line references and a short summary." \
    > "/tmp/oc/$area.jsonl" 2> "/tmp/oc/$area.err" &
done
wait

for area in api web db; do
  echo "== $area =="
  jq -r 'select(.type == "text") | .part.text' "/tmp/oc/$area.jsonl"
  SID=$(head -1 "/tmp/oc/$area.jsonl" | jq -r .sessionID)
  echo "resume: opencode -s $SID"
done
```

Every worker stays resumable. Report the IDs the user may want to open. Add
`--archived` only for jobs you never intend to revisit.

For write tasks, give each worker its own worktree so edits cannot collide:

```bash
opencode run -m "$MODEL" --agent build --worktree=fix-auth \
  --title "fix-auth" --format json "Fix the auth timeout..." \
  > /tmp/oc/fix-auth.jsonl 2> /tmp/oc/fix-auth.err

git worktree list
# .../opencode/worktree/<project>/fix-auth  <sha>  (detached HEAD)
git -C "<that path>" diff

SID=$(head -1 /tmp/oc/fix-auth.jsonl | jq -r .sessionID)
echo "resume: opencode -s $SID"
```

Worktrees live under OpenCode's data directory (by default
`~/.local/share/opencode/worktree/...`) and start on a detached HEAD. Create a branch
there if you need commits. Sessions remember their working directory, so resuming one
keeps its tools in the same worktree. Never run two writing agents in the same
checkout.

## Permissions and safety

- `--auto` approves anything not explicitly denied, including edits and shell
  commands. Use it only when the user has authorized autonomous changes.
- Without `--auto`, an approval-requiring action is rejected and the agent reports it;
  the run does not hang. Prefer `plan`/`explore` when you only need analysis.
- The subagent inherits the user's OpenCode config, permissions, MCP servers, and
  skills. It can read the repo and, unless denied, use the network.
- In CI, add `--standalone` and pass provider keys through the environment so the
  private server receives them.

## Gotchas

- Model syntax is `provider/model`; attach reasoning with `#variant`. `--variant` is
  not a V2 flag.
- Use `--worktree=<name>` with `=`. `-w fix-auth` treats `fix-auth` as part of the
  prompt and generates a random worktree name.
- Put flags before the prompt. The message is variadic and will absorb stray tokens.
- `-f` attachments are placed before the prompt text; refer to them by order
  (`[Image 1]`, `[File 1]`). For image reading, see
  [use-vlm-as-your-eye.md](./use-vlm-as-your-eye.md).
- `--archived` keeps a run out of the session picker. Never archive a session the user
  may want to continue.
- Default output with `--thinking` includes `Thinking:` lines on stdout, so parse
  `--format json` instead.
- Long prompts: pass `"$(cat /tmp/brief.md)"` rather than fighting shell quoting.
- If `opencode` is not on `PATH`, use `~/.opencode/bin/opencode`.
