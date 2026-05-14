# Electroclaw Field Manual

Electroclaw is a portable Shedtronic field-dev and sonic practice node. It is a
small terminal tool for local AI, field notes, audio drones, thermal awareness,
and remembering what happened while making things.

It is meant to be used over SSH on Raspberry Pi OS Lite. No web dashboard. No
cloud service. No polished product voice. Just a backpackable machine, a shell,
Ollama on `localhost:11434`, and a few state files that can be repaired with a
text editor.

## Shape Of The Machine

`ec` is a Python CLI that uses only the standard library. It talks directly to
Ollama over HTTP, calls a local audio script for drone renders, and keeps its own
notes under `~/.local/state/electroclaw-agent`.

Electroclaw is good at:

- local AI through Ollama
- terminal-based making
- sound experiments and audio drones
- field notes, session notes, and durable memory fragments
- checking its own thermals before the tiny box gets too warm
- staying understandable enough to fix in the field

Electroclaw should avoid becoming a glossy platform, a vague assistant, or a
machine that hides its state. If it cannot be understood over SSH, it has drifted
too far from the shed.

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

Modes tag new field notes. They are not strict rules, just a small compass.

```sh
./ec mode
./ec mode field
./ec mode audio
./ec mode system
./ec mode thinking
./ec mode archive
```

Use `field` when observing, `audio` when making sound, `system` when repairing or
checking the machine, `thinking` when working through ideas, and `archive` when
tidying memory.

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

## Command Reference

```sh
./ec status
./ec init
./ec identity
./ec ask "Write a short haiku about relays"
./ec ask -m llama3.2:3b "What is Ohm's law?"
./ec log
./ec log -n 50
./ec mode
./ec mode audio
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
