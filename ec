#!/usr/bin/env python3
"""Electroclaw CLI: a tiny Ollama-backed helper for Raspberry Pi OS Lite."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path


DEFAULT_HOST = "http://localhost:11434"
DEFAULT_MODEL = "llama3.2:3b"
DRONE_SCRIPT = Path("/home/makelab3/dev/audio/scripts/make_drone.sh")
LOG_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
LOG_FILE = LOG_DIR / "electroclaw-agent" / "ec.log"
FIELDNOTES_FILE = LOG_DIR / "electroclaw-agent" / "fieldnotes.md"
SESSION_FILE = LOG_DIR / "electroclaw-agent" / "session.md"
MODE_FILE = LOG_DIR / "electroclaw-agent" / "mode.txt"
MEMORY_FILE = LOG_DIR / "electroclaw-agent" / "memory.md"
STATE_FILES = (LOG_FILE, FIELDNOTES_FILE, SESSION_FILE, MODE_FILE)
MODES = ("field", "audio", "system", "thinking", "archive")
DEFAULT_MODE = "field"
MODE_INSTRUCTIONS = {
    "audio": "You are assisting with audio, sound design, sonic practice, music, drones as sustained tones/textures, and field recording. Interpret 'drone' as an audio drone unless clearly stated otherwise.",
    "system": "You are assisting with Raspberry Pi, Linux, shell work, lightweight diagnostics, repair, and system checks.",
    "field": "You are assisting with field notes, observations, portability, local context, and practical making outside the studio.",
    "thinking": "You are assisting with reflection, concise reasoning, careful distinctions, and clear next steps.",
    "archive": "You are assisting with memory, traces, logs, fragments, durable notes, and useful retrieval.",
}
ASK_GROUNDING = "Always prioritize Electroclaw as a Raspberry Pi field-dev node for local AI, sound practice, maker experimentation, repairability, and low-power workflows. Avoid pop culture references unless explicitly requested, superhero or villain analogies, generic productivity advice, corporate language, and startup or product marketing tone."


class OllamaError(RuntimeError):
    """Raised when Ollama cannot be reached or returns an error."""


class CommandError(RuntimeError):
    """Raised when a local command cannot be run."""


def ollama_url(path: str) -> str:
    host = os.environ.get("OLLAMA_HOST", DEFAULT_HOST).rstrip("/")
    return f"{host}{path}"


def request_json(path: str, payload: dict | None = None, timeout: int = 120) -> dict:
    data = None
    headers = {"Accept": "application/json"}

    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = urllib.request.Request(ollama_url(path), data=data, headers=headers)

    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            body = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise OllamaError(f"Ollama returned HTTP {exc.code}: {detail}") from exc
    except urllib.error.URLError as exc:
        raise OllamaError(f"Could not reach Ollama at {ollama_url('')}: {exc.reason}") from exc
    except TimeoutError as exc:
        raise OllamaError("Ollama request timed out") from exc

    try:
        return json.loads(body)
    except json.JSONDecodeError as exc:
        raise OllamaError(f"Ollama returned invalid JSON: {body[:200]}") from exc


def print_check(ok: bool, label: str, detail: str = "") -> None:
    status = "ok" if ok else "warn"
    suffix = f" - {detail}" if detail else ""
    print(f"[{status}] {label}{suffix}")


def ensure_state_files() -> None:
    for path in STATE_FILES:
        path.parent.mkdir(parents=True, exist_ok=True)
        if not path.exists():
            path.touch()


def append_log(role: str, text: str) -> None:
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().isoformat(timespec="seconds")
    with LOG_FILE.open("a", encoding="utf-8") as handle:
        handle.write(f"[{timestamp}] {role}: {text.strip()}\n")


def cmd_status(_args: argparse.Namespace) -> int:
    data = request_json("/api/tags", timeout=10)
    models = data.get("models", [])

    print("Ollama: ok")
    print(f"Host: {os.environ.get('OLLAMA_HOST', DEFAULT_HOST)}")

    if not models:
        print("Models: none found")
        return 0

    print("Models:")
    for model in models:
        name = model.get("name", "unknown")
        size = model.get("size")
        if isinstance(size, int):
            print(f"  - {name} ({size / 1024 / 1024 / 1024:.1f} GB)")
        else:
            print(f"  - {name}")

    return 0


def cmd_ask(args: argparse.Namespace) -> int:
    prompt = " ".join(args.prompt).strip()
    if not prompt:
        print("Nothing to ask. Pass a prompt after `ec ask`.", file=sys.stderr)
        return 2

    mode = current_mode()
    instruction = MODE_INSTRUCTIONS.get(mode, MODE_INSTRUCTIONS[DEFAULT_MODE])
    if args.short:
        instruction = f"{instruction} Answer briefly in 1-3 sentences."
    memory_text = ask_memory_context()
    ollama_prompt = "\n\n".join(
        [
            instruction,
            ASK_GROUNDING,
            f"Current mode: {mode}",
            f"Existing memory:\n{memory_text}",
            f"User: {prompt}",
        ]
    )
    payload = {
        "model": args.model or os.environ.get("EC_MODEL", DEFAULT_MODEL),
        "prompt": ollama_prompt,
        "stream": False,
    }
    data = request_json("/api/generate", payload=payload, timeout=args.timeout)
    answer = data.get("response", "").strip()

    if not answer:
        raise OllamaError("Ollama returned an empty response")

    print(answer)
    append_log("user", prompt)
    append_log(payload["model"], answer)
    return 0


def cmd_log(args: argparse.Namespace) -> int:
    if not LOG_FILE.exists():
        print(f"No log yet: {LOG_FILE}")
        return 0

    lines = LOG_FILE.read_text(encoding="utf-8").splitlines()
    for line in lines[-args.lines :]:
        print(line)
    return 0


def current_mode() -> str:
    if not MODE_FILE.exists():
        MODE_FILE.parent.mkdir(parents=True, exist_ok=True)
        MODE_FILE.write_text(f"{DEFAULT_MODE}\n", encoding="utf-8")
        return DEFAULT_MODE

    mode = MODE_FILE.read_text(encoding="utf-8").strip()
    if mode in MODES:
        return mode
    MODE_FILE.write_text(f"{DEFAULT_MODE}\n", encoding="utf-8")
    return DEFAULT_MODE


def cmd_mode(args: argparse.Namespace) -> int:
    if args.mode is None:
        print(current_mode())
        return 0

    MODE_FILE.parent.mkdir(parents=True, exist_ok=True)
    MODE_FILE.write_text(f"{args.mode}\n", encoding="utf-8")
    print(args.mode)
    return 0


def cmd_init(_args: argparse.Namespace) -> int:
    print("Electroclaw readiness")
    ensure_state_files()

    try:
        data = request_json("/api/tags", timeout=10)
    except OllamaError as exc:
        print_check(False, "Ollama", str(exc))
    else:
        models = data.get("models", [])
        print_check(True, "Ollama", os.environ.get("OLLAMA_HOST", DEFAULT_HOST))
        if models:
            names = ", ".join(model.get("name", "unknown") for model in models)
            print_check(True, "Models", names)
        else:
            print_check(False, "Models", "none found")

    temp_code, temp = capture_vcgencmd("measure_temp")
    throttled_code, throttled = capture_vcgencmd("get_throttled")
    print_check(temp_code == 0, "Temperature", temp)
    print_check(throttled_code == 0, "Throttled", throttled)

    repo_dir = Path(__file__).resolve().parent
    git_dir = repo_dir / ".git"
    if git_dir.exists():
        result = subprocess.run(
            ["git", "-C", str(repo_dir), "status", "--short"],
            check=False,
            text=True,
            capture_output=True,
        )
        if result.returncode == 0:
            clean = not result.stdout.strip()
            detail = "clean" if clean else "changes present"
            print_check(clean, "Git status", detail)
        else:
            detail = result.stderr.strip() or "git status failed"
            print_check(False, "Git status", detail)
    else:
        print_check(False, "Git status", "not inside a git repo")

    for path in STATE_FILES:
        print_check(path.exists(), path.name, str(path))

    executable = os.access(DRONE_SCRIPT, os.X_OK)
    print_check(executable, "Audio drone script", str(DRONE_SCRIPT))
    return 0


def cmd_note(args: argparse.Namespace) -> int:
    note = " ".join(args.text).strip()
    if not note:
        print("Nothing to note. Pass text after `ec note`.", file=sys.stderr)
        return 2

    FIELDNOTES_FILE.parent.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().isoformat(timespec="seconds")
    mode = current_mode()
    with FIELDNOTES_FILE.open("a", encoding="utf-8") as handle:
        handle.write(f"- {timestamp} [{mode}] {note}\n")

    print(f"Added note: {FIELDNOTES_FILE}")
    return 0


def cmd_notes(args: argparse.Namespace) -> int:
    if not FIELDNOTES_FILE.exists():
        print(f"No notes yet: {FIELDNOTES_FILE}")
        return 0

    notes = [
        line
        for line in FIELDNOTES_FILE.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]
    for note in notes[-args.number :]:
        print(note)
    return 0


def recent_file_lines(path: Path, count: int) -> list[str]:
    if not path.exists():
        return []

    lines = [line for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    return lines[-count:]


def ask_memory_context() -> str:
    if not MEMORY_FILE.exists():
        return "No durable memory yet."

    lines = MEMORY_FILE.read_text(encoding="utf-8").splitlines()
    start = 0
    for index, line in enumerate(lines):
        if line.startswith("## "):
            start = index

    section = [line for line in lines[start:] if line.strip()]
    bullets = [
        line
        for line in section
        if line.lstrip().startswith(("- ", "* "))
    ]
    if bullets:
        return "\n".join(bullets[-3:])
    if section:
        return "\n".join(section)
    return "No durable memory yet."


def parse_vcgencmd_value(line: str, key: str) -> str:
    prefix = f"{key}="
    if line.startswith(prefix):
        return line.split("=", 1)[1].strip()
    return ""


def remember_thermal_lines(temp: str, throttled: str) -> tuple[str, str]:
    temp_value = parse_vcgencmd_value(temp, "temp")
    throttled_value = parse_vcgencmd_value(throttled, "throttled")

    temp_line = f"Temperature: {temp_value}" if temp_value else f"Temperature: {temp}"
    if throttled_value == "0x0":
        throttled_line = "Throttling: no throttling"
    elif throttled_value:
        throttled_line = f"Throttling: {throttled_value}"
    else:
        throttled_line = f"Throttling: {throttled}"

    return temp_line, throttled_line


def cmd_summary(_args: argparse.Namespace) -> int:
    fieldnotes = recent_file_lines(FIELDNOTES_FILE, 12)
    session = recent_file_lines(SESSION_FILE, 20)
    _temp_code, temp = capture_vcgencmd("measure_temp")
    _throttled_code, throttled = capture_vcgencmd("get_throttled")

    prompt = "\n".join(
        [
            "Write a short plain-English summary of the current Electroclaw session.",
            "Keep it practical, concise, and under 120 words.",
            "",
            "Recent field notes:",
            "\n".join(fieldnotes) if fieldnotes else "No field notes yet.",
            "",
            "Session log:",
            "\n".join(session) if session else "No session entries yet.",
            "",
            "Current thermals:",
            temp,
            throttled,
        ]
    )
    payload = {
        "model": os.environ.get("EC_MODEL", DEFAULT_MODEL),
        "prompt": prompt,
        "stream": False,
    }
    data = request_json("/api/generate", payload=payload)
    summary = data.get("response", "").strip()

    if not summary:
        raise OllamaError("Ollama returned an empty summary")

    print(summary)
    return 0


def cmd_remember(_args: argparse.Namespace) -> int:
    fieldnotes = recent_file_lines(FIELDNOTES_FILE, 20)
    session = recent_file_lines(SESSION_FILE, 30)
    mode = current_mode()
    _temp_code, temp = capture_vcgencmd("measure_temp")
    _throttled_code, throttled = capture_vcgencmd("get_throttled")
    temp_line, throttled_line = remember_thermal_lines(temp, throttled)

    prompt = "\n".join(
        [
            "Distil durable memory fragments for the Electroclaw agent.",
            "Write 3 to 6 short Markdown bullets.",
            "Keep only useful facts, preferences, open threads, and operating context.",
            "Do not include filler or a title.",
            "",
            f"Current mode: {mode}",
            "",
            "Recent field notes:",
            "\n".join(fieldnotes) if fieldnotes else "No field notes yet.",
            "",
            "Session log:",
            "\n".join(session) if session else "No session entries yet.",
            "",
            "Current thermals:",
            temp_line,
            throttled_line,
        ]
    )
    payload = {
        "model": os.environ.get("EC_MODEL", DEFAULT_MODEL),
        "prompt": prompt,
        "stream": False,
    }
    data = request_json("/api/generate", payload=payload)
    fragments = data.get("response", "").strip()

    if not fragments:
        raise OllamaError("Ollama returned empty memory fragments")

    MEMORY_FILE.parent.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().isoformat(timespec="seconds")
    with MEMORY_FILE.open("a", encoding="utf-8") as handle:
        handle.write(f"\n## {timestamp} [{mode}]\n\n{fragments}\n")

    print(f"Remembered: {MEMORY_FILE}")
    return 0


def cmd_identity(_args: argparse.Namespace) -> int:
    memory = recent_file_lines(MEMORY_FILE, 40)
    mode = current_mode()
    _temp_code, temp = capture_vcgencmd("measure_temp")
    _throttled_code, throttled = capture_vcgencmd("get_throttled")
    temp_line, throttled_line = remember_thermal_lines(temp, throttled)

    prompt = "\n".join(
        [
            "Write a short evolving identity statement for Electroclaw.",
            "Use 3 to 5 concise plain-English sentences.",
            "Electroclaw should describe itself as a portable Shedtronic field-dev and sonic practice node.",
            "Emphasize local AI through Ollama, terminal-based making, sound experiments, audio drones, field notes, thermal awareness, repairability, low-power local-first backpackable computing, and being an artist tool rather than a corporate product.",
            "Do not use these words or frames: cutting-edge, high-performance computing, industries, autonomous systems, industrial monitoring, innovation, innovative, startup, product launch, scalable, enterprise, disruptive, or market.",
            "Tone: plain, slightly strange, practical, sonic, and maker-oriented.",
            "Do not include a title or bullet list.",
            "",
            f"Current mode: {mode}",
            "",
            "Durable memory:",
            "\n".join(memory) if memory else "No durable memory yet.",
            "",
            "Current thermals:",
            temp_line,
            throttled_line,
        ]
    )
    payload = {
        "model": os.environ.get("EC_MODEL", DEFAULT_MODEL),
        "prompt": prompt,
        "stream": False,
    }
    data = request_json("/api/generate", payload=payload)
    identity = data.get("response", "").strip()

    if not identity:
        raise OllamaError("Ollama returned an empty identity statement")

    print(identity)
    return 0


def append_session_line(line: str) -> None:
    SESSION_FILE.parent.mkdir(parents=True, exist_ok=True)
    with SESSION_FILE.open("a", encoding="utf-8") as handle:
        handle.write(f"{line}\n")


def cmd_session_start(_args: argparse.Namespace) -> int:
    timestamp = datetime.now().isoformat(timespec="seconds")
    append_session_line(f"- start: {timestamp}")
    print(f"Session started: {SESSION_FILE}")
    return 0


def capture_vcgencmd(*args: str) -> tuple[int, str]:
    command = ["vcgencmd", *args]
    try:
        result = subprocess.run(command, check=False, text=True, capture_output=True)
    except FileNotFoundError:
        return 1, "vcgencmd not found"

    output = result.stdout.strip() or result.stderr.strip()
    return result.returncode, output


def cmd_session_end(_args: argparse.Namespace) -> int:
    timestamp = datetime.now().isoformat(timespec="seconds")
    temp_code, temp = capture_vcgencmd("measure_temp")
    throttled_code, throttled = capture_vcgencmd("get_throttled")

    append_session_line(f"- end: {timestamp}")
    append_session_line(f"  - temp: {temp}")
    append_session_line(f"  - throttled: {throttled}")

    print(f"Session ended: {SESSION_FILE}")
    print(temp)
    print(throttled)
    return temp_code or throttled_code


def run_vcgencmd(*args: str) -> int:
    command = ["vcgencmd", *args]
    try:
        result = subprocess.run(command, check=False, text=True, capture_output=True)
    except FileNotFoundError:
        print("ec: vcgencmd not found", file=sys.stderr)
        return 1

    if result.stdout.strip():
        print(result.stdout.strip())
    if result.stderr.strip():
        print(result.stderr.strip(), file=sys.stderr)

    return result.returncode


def cmd_thermals(_args: argparse.Namespace) -> int:
    temp_code = run_vcgencmd("measure_temp")
    throttled_code = run_vcgencmd("get_throttled")
    return temp_code or throttled_code


def numeric_value(value: str) -> str:
    try:
        float(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"{value!r} is not a number") from exc
    return value


def cmd_audio_drone(args: argparse.Namespace) -> int:
    command = [str(DRONE_SCRIPT), args.freq, args.dur]
    try:
        result = subprocess.run(command, check=False, text=True, capture_output=True)
    except FileNotFoundError as exc:
        raise CommandError(f"drone script not found: {DRONE_SCRIPT}") from exc

    if result.stdout.strip():
        print(result.stdout.strip())
    if result.stderr.strip():
        print(result.stderr.strip(), file=sys.stderr)

    return result.returncode


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="ec",
        description="Small Ollama CLI for the Electroclaw agent.",
    )
    subcommands = parser.add_subparsers(dest="command", required=True)

    status = subcommands.add_parser("status", help="check Ollama and list local models")
    status.set_defaults(func=cmd_status)

    ask = subcommands.add_parser("ask", help="send a prompt to Ollama")
    ask.add_argument("prompt", nargs="*", help="prompt text")
    ask.add_argument("-m", "--model", help=f"model to use (default: {DEFAULT_MODEL})")
    ask.add_argument("--short", action="store_true", help="answer briefly in 1-3 sentences")
    ask.add_argument("--timeout", type=float, default=60, help="request timeout in seconds")
    ask.set_defaults(func=cmd_ask)

    init = subcommands.add_parser("init", help="run lightweight readiness checks")
    init.set_defaults(func=cmd_init)

    identity = subcommands.add_parser(
        "identity", help="generate a short evolving identity statement"
    )
    identity.set_defaults(func=cmd_identity)

    log = subcommands.add_parser("log", help="show recent ec conversation log")
    log.add_argument("-n", "--lines", type=int, default=20, help="lines to show")
    log.set_defaults(func=cmd_log)

    mode = subcommands.add_parser("mode", help="show or set the current note mode")
    mode.add_argument("mode", nargs="?", choices=MODES, help="mode to set")
    mode.set_defaults(func=cmd_mode)

    note = subcommands.add_parser("note", help="append a timestamped field note")
    note.add_argument("text", nargs="*", help="note text")
    note.set_defaults(func=cmd_note)

    notes = subcommands.add_parser("notes", help="show recent field notes")
    notes.add_argument("-n", "--number", type=int, default=10, help="notes to show")
    notes.set_defaults(func=cmd_notes)

    summary = subcommands.add_parser(
        "summary", help="summarize recent notes, session entries, and thermals"
    )
    summary.set_defaults(func=cmd_summary)

    remember = subcommands.add_parser(
        "remember", help="distil recent notes and session context into memory"
    )
    remember.set_defaults(func=cmd_remember)

    session = subcommands.add_parser("session", help="session helper commands")
    session_subcommands = session.add_subparsers(
        dest="session_command", required=True
    )

    session_start = session_subcommands.add_parser(
        "start", help="append a session start timestamp"
    )
    session_start.set_defaults(func=cmd_session_start)

    session_end = session_subcommands.add_parser(
        "end", help="append a session end timestamp and thermals"
    )
    session_end.set_defaults(func=cmd_session_end)

    thermals = subcommands.add_parser(
        "thermals", help="show Raspberry Pi temperature and throttling state"
    )
    thermals.set_defaults(func=cmd_thermals)

    audio = subcommands.add_parser("audio", help="audio helper commands")
    audio_subcommands = audio.add_subparsers(dest="audio_command", required=True)

    drone = audio_subcommands.add_parser("drone", help="generate a drone tone")
    drone.add_argument("freq", type=numeric_value, help="frequency in Hz")
    drone.add_argument("dur", type=numeric_value, help="duration in seconds")
    drone.set_defaults(func=cmd_audio_drone)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        return args.func(args)
    except (OllamaError, CommandError) as exc:
        print(f"ec: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
