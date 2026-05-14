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

Send a prompt to the local Ollama model.

```sh
./ec ask "Give me a one-line status check."
```

## init

Run lightweight Electroclaw readiness checks.

```sh
./ec init
```

## log

Show recent Ollama prompt/response log lines.

```sh
./ec log -n 20
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

## summary

Summarize recent field notes, session entries, and current thermals.

```sh
./ec summary
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
