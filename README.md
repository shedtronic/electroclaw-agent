# Electroclaw Field Manual

Electroclaw is a portable Shedtronic field-dev and sonic practice node. It is a
terminal tool for local AI, field notes, audio drones, thermal awareness,
session memory, and small maker experiments that can be understood over SSH.

It runs on Raspberry Pi OS Lite using Python standard library code, direct
Ollama HTTP calls to `localhost:11434`, plain text state files, and local scripts.
No dashboard, no cloud dependency, no smooth talking control room. Just the box,
the shell, the hum, and a small set of habits.

## Philosophy

Electroclaw is:

- local-first: the useful work happens on the Pi
- low-power: prefer small tests over grand gestures
- repairable: state is plain text, scripts are visible
- terminal-based: SSH is a real workspace
- maker-oriented: try, listen, inspect, adjust
- sound focused: drones, textures, field notes, sonic practice
- co-evolving: a workshop companion, not a generic assistant

It should stay practical, slightly strange, and modest. It should not pretend to
be a corporate product or a giant lab. When in doubt, make a small observable
test with the tools already on the machine.

## Install

```sh
cd /home/makelab3/dev/electroclaw-agent
chmod +x ec
```

Optional shell shortcut:

```sh
sudo ln -s /home/makelab3/dev/electroclaw-agent/ec /usr/local/bin/ec
```

If you do not create the shortcut, run commands as `./ec` from the project
folder.

## First Check

Run readiness checks before a session:

```sh
./ec init
```

This checks Ollama, available models, thermals, git status, state files, and the
audio drone script. It may create missing state folders/files. It reports git as
`[ok]` only when the repo is clean, and `[warn]` when changes are present.

Check Ollama directly:

```sh
./ec status
```

Check heat and throttling:

```sh
./ec thermals
```

`throttled=0x0` means no throttling. Any other value is worth noting.

## Working Modes

Modes tag new field notes and influence `ec ask` and `ec reflect`. They are not
strict rules, just a small compass.

```sh
./ec mode
./ec mode bench
./ec mode field
./ec mode audio
./ec mode thinking
./ec mode archive
./ec mode system
```

- `bench`: SSH work, VS Code/Codex sessions, testing, maintenance, commits,
  script making, and Raspberry Pi workshop practice.
- `field`: observations, portability, outside context, and notes from the room.
- `audio`: sound design, sonic practice, music, field recording, and drones as
  sustained tones or textures.
- `thinking`: reflection, concise reasoning, distinctions, and next steps.
- `archive`: memory, traces, logs, fragments, and useful retrieval.
- `system`: Raspberry Pi, Linux, diagnostics, repair, and system checks.

## Session Ritual

Start a session:

```sh
./ec session start
```

Take notes as you work:

```sh
./ec note "Checked enclosure fan after thermal run"
./ec notes -n 5
```

Ask the local model small, useful questions:

```sh
./ec ask "Give me a quiet test plan for this audio patch."
./ec ask -m llama3.2:3b "Summarize these thermal notes in one paragraph."
./ec ask --short "What should I check next?"
```

`ec ask` is fast, practical, and lightweight. It includes the current mode, but
does not pull in memory. Use it when you want a quick nudge.

Use `ec reflect` when you want the slower, memory-aware, contextual version:

```sh
./ec reflect "What thread should I carry forward from this session?"
```

End the session:

```sh
./ec session end
```

Ending a session appends an end timestamp and current thermals to `session.md`.

## Memory Loop

Summarize the current session:

```sh
./ec summary
```

Distil recent field notes and session context into durable memory fragments:

```sh
./ec remember
```

Ask Electroclaw for its evolving identity:

```sh
./ec identity
```

The identity command reads memory, current mode, and thermals, then asks Ollama
for a short statement of what Electroclaw is, what it is good at, and what it
should avoid. It should sound plain, slightly strange, practical, sonic, and
maker-oriented.

## Bench Workflow

A typical bench session looks like this:

```sh
./ec init
./ec mode bench
./ec session start
./ec note "Testing a small change over SSH."
./ec ask --short "What is the safest next check?"
./ec reflect "What changed, and what should I carry forward?"
./ec remember
./ec session end
```

The pattern is simple: check the machine, set the mode, mark the session, make
one small change, ask for the next observable test, reflect when needed, save the
memory, close the loop.

## Sound Practice

Render an audio drone:

```sh
./ec audio drone 110 5
```

This calls:

```text
/home/makelab3/dev/audio/scripts/make_drone.sh FREQ DUR
```

`FREQ` and `DUR` must be numbers. The script output is printed directly. Use
notes to mark what the drone was for, what it sounded like, and whether the box
stayed cool.

## Logs And Files

Conversation log:

```text
~/.local/state/electroclaw-agent/ec.log
```

Field notes:

```text
~/.local/state/electroclaw-agent/fieldnotes.md
```

Session notes:

```text
~/.local/state/electroclaw-agent/session.md
```

Current mode:

```text
~/.local/state/electroclaw-agent/mode.txt
```

Durable memory:

```text
~/.local/state/electroclaw-agent/memory.md
```

These files are the machine's working memory. They are plain text on purpose.
Open them with `less`, `nano`, `sed`, or whatever is already in your hands.

## Configuration

Change the Ollama endpoint:

```sh
export OLLAMA_HOST=http://localhost:11434
```

Change the default model used by `ask`, `summary`, `remember`, and `identity`:

```sh
export EC_MODEL=llama3.2:3b
```

The default model is `llama3.2:3b`.

## Commands

### `ec init`

Runs lightweight readiness checks: Ollama, available models, thermals, git
status, state files, and the audio drone script.

```sh
./ec init
```

### `ec ask`

Fast, practical, lightweight local AI. Uses current mode briefly and keeps the
prompt small for Pi-friendly use.

```sh
./ec ask --short "What should I check next?"
```

### `ec reflect`

Slower, memory-aware, contextual local AI. Uses mode, recent durable memory, and
semantic grounding rules.

```sh
./ec reflect "What should I carry forward from this session?"
```

### `ec note` / `ec notes`

Append and read mode-tagged field notes.

```sh
./ec note "Rendered a low drone and checked thermals."
./ec notes -n 5
```

### `ec remember`

Distils recent field notes, session notes, current mode, and thermals into
durable memory fragments.

```sh
./ec remember
```

### `ec summary`

Summarizes recent field notes, session notes, and current thermals.

```sh
./ec summary
```

### `ec session start` / `ec session end`

Marks session boundaries. Ending a session records current thermals.

```sh
./ec session start
./ec session end
```

### `ec mode`

Shows or sets the current mode.

```sh
./ec mode
./ec mode audio
```

### `ec thermals`

Prints Raspberry Pi temperature and throttling state.

```sh
./ec thermals
```

### `ec identity`

Generates a short evolving identity statement from memory, mode, and thermals.

```sh
./ec identity
```

### `ec audio drone`

Renders an audio drone with frequency and duration.

```sh
./ec audio drone 110 5
```

## Quick Reference

```sh
./ec status
./ec init
./ec identity
./ec ask "Write a short haiku about relays"
./ec ask -m llama3.2:3b "What is Ohm's law?"
./ec reflect "What should I remember from this work?"
./ec log
./ec log -n 50
./ec mode
./ec mode audio
./ec mode bench
./ec note "Checked enclosure fan after thermal run"
./ec notes
./ec notes -n 5
./ec remember
./ec summary
./ec session start
./ec session end
./ec thermals
./ec audio drone 110 5
```

For a shorter SSH reference, see `COMMANDS.md`.
