# ec Commands

Quick reference for using `ec` over SSH on Electroclaw.

Run from the project folder:

```sh
cd /home/makelab3/dev/electroclaw-agent
```

## status

Check Ollama and list local models.

```sh
./ec status
```

## ask

Send a fast, minimal prompt to the local Ollama model.

```sh
./ec ask "Give me a one-line status check."
```

## reflect

Send a grounded, memory-aware prompt to the local Ollama model.

```sh
./ec reflect "What should I carry forward from this session?"
```

## init

Run lightweight Electroclaw readiness checks.

```sh
./ec init
```

## identity

Generate a short evolving identity statement from the latest memory section,
mode, and thermals.

```sh
./ec identity
./ec identity --timeout 120
```

## log

Show recent Ollama prompt/response log lines.

```sh
./ec log -n 20
```

## mode

Show or set the current note mode.

```sh
./ec mode bench
```

## note

Append a timestamped field note.

```sh
./ec note "Checked fan noise after drone render."
```

## notes

Show recent field notes.

```sh
./ec notes -n 5
```

## remember

Distil recent notes, session context, mode, and thermals into durable memory.

```sh
./ec remember
```

## summary

Summarize the last few field notes, latest session block, current mode, and
current thermals.

```sh
./ec summary
./ec summary --timeout 120
```

## session start

Append a session start timestamp.

```sh
./ec session start
```

## session end

Append a session end timestamp and current thermals.

```sh
./ec session end
```

## thermals

Print Raspberry Pi temperature and throttling state.

```sh
./ec thermals
```

## audio drone

Render a drone tone with frequency and duration.

```sh
./ec audio drone 110 5
```
