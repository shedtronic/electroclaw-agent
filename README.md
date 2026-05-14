# electroclaw-agent

`ec` is a small Python CLI that talks directly to Ollama on `localhost:11434`.
It uses only the Python standard library so it can run comfortably on Raspberry
Pi OS Lite.

## Install

```sh
cd /home/makelab3/dev/electroclaw-agent
chmod +x ec
```

Optional shell shortcut:

```sh
sudo ln -s /home/makelab3/dev/electroclaw-agent/ec /usr/local/bin/ec
```

## Commands

```sh
./ec status
./ec init
./ec ask "Write a short haiku about relays"
./ec ask -m llama3.2 "What is Ohm's law?"
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

## Configuration

- `OLLAMA_HOST` changes the Ollama endpoint. Default: `http://localhost:11434`
- `EC_MODEL` changes the default model for `ask`. Default: `llama3.2:3b`

Logs are written to:

```text
~/.local/state/electroclaw-agent/ec.log
```

Field notes are written to:

```text
~/.local/state/electroclaw-agent/fieldnotes.md
```

Session notes are written to:

```text
~/.local/state/electroclaw-agent/session.md
```

The current note mode is written to:

```text
~/.local/state/electroclaw-agent/mode.txt
```

Durable memory fragments are written to:

```text
~/.local/state/electroclaw-agent/memory.md
```
