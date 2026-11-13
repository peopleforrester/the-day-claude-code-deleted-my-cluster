#!/usr/bin/env python3
# ABOUTME: Extracts the message from a git commit invocation inside a shell command.
# ABOUTME: Reads the command as a shell would, so only the commit's own arguments are scanned.
#
# Synced from llm-coding-workflow scripts/git-hooks/lib/extract_commit_message.py
# at e400946 (llm-coding-workflow#516) on 2026-11-13; below this comment the
# file is the live one unchanged. Issue numbers in it are that repo's.
"""Pull the commit message out of a shell command string.

The hook that used this logic inline decided what to scan by pattern-matching
the raw command, which failed three ways, all reproduced on 2026-09-10 and
again on 2026-09-24:

1. It took the first heredoc delimiter found anywhere in the command, so an
   unrelated heredoc earlier in the line supplied the text that got scanned.
2. Because of (1) it **failed open**: attribution in the real message passed
   whenever a decoy came first.
3. It fired on commands running no git at all, because the literal string
   `git commit` appeared inside a heredoc body as documentation.

Tracking heredoc extent line by line fixed those (#154), but a line was still
"shell" whenever no heredoc was open, so two shapes kept firing (#360):

4. A quoted argument spanning lines, as in `gh issue create --body '...'`
   quoting a reproduction, put `git commit -m "<attribution>"` at the start of
   a line, where it read as an invocation.
5. Every `-m` from the commit line to the end of the command was collected,
   so `git commit -m x && gh issue comment 1 --body 'use -m "<attribution>"'`
   scanned the issue comment as part of the message.

So the command is now read the way a shell reads it: quotes, heredocs,
command substitution and separators all have their real extent, the command
is split into simple commands, and the message comes only from a `git commit`
command's own message arguments and its own stdin. Text another program is
handed (an issue body, a file being written) is never scanned.

A `-F <file>` (`--file`) message is read from disk when the file is there as
the hook runs, resolved as git would: against `--cwd` (the tool call's working
directory, else this process's) and any `git -C` before `commit`. Without
that, attribution in a message file passed this layer (#516). A file the
command itself writes first, or one behind an earlier `cd`, is not found yet
and is left to the native commit-msg hook, which sees the final message.

Exit status:
    0  a commit message was extracted and printed
    1  the command contains no git commit invocation
    2  a commit runs, but no message is present (interactive editor, or a
       -F file that cannot be read yet)
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from dataclasses import dataclass, field

_ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")

# Words that can stand before the program a simple command runs.
_RESERVED = {"if", "then", "else", "elif", "do", "while", "until", "!", "{", "}", "time"}
_WRAPPERS = {"sudo", "nohup", "env", "command", "exec", "timeout", "nice", "stdbuf"}
_WRAPPER_ARG = re.compile(r"^(-.*|\d+(\.\d+)?[smhd]?)$")

# Programs that run a string argument as shell, which is read through.
_SHELLS = {"sh", "bash", "dash", "zsh", "ksh"}
_MAX_DEPTH = 5

# git's own options before the subcommand that take a separate value.
_GIT_VALUE_OPTS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--config-env"}

# `git commit` options whose value becomes part of the message. A trailer is
# appended to it, so `--trailer` can carry attribution as surely as `-m`.
_MESSAGE_LONG = ("--message", "--trailer")
# The option whose value names a file holding the message (#516).
_FILE_LONG = "--file"

# Other `git commit` options that take a separate value, which must be skipped
# so the value is not read as an option.
_VALUE_LONG = {
    "--reuse-message",
    "--reedit-message",
    "--template",
    "--author",
    "--date",
    "--fixup",
    "--squash",
    "--cleanup",
    "--pathspec-from-file",
}
_VALUE_SHORT = set("mFCct")
# Short options whose optional value can only be attached (`-S<key>`, `-uno`).
_ATTACHED_SHORT = set("Su")


@dataclass
class _Command:
    """One simple command: its words and what it is fed on stdin."""

    words: list[str] = field(default_factory=list)
    stdin: list[str] = field(default_factory=list)

    def literal_text(self) -> str:
        """The text this command carries, standing in for its output."""
        return "\n".join(self.words[1:] + self.stdin)


class _Lexer:
    """A shell reader just deep enough to know which text belongs to which command.

    It handles single, double and ANSI-C quotes, backslash escapes, comments,
    heredocs (`<<`, `<<-`) and here-strings, `$(...)` and backticks (whose
    commands are collected too, since a shell runs them), redirections and the
    separators `; & && | || ( )` and newline. It does not expand anything.
    """

    def __init__(self, source: str) -> None:
        self.src = source
        self.commands: list[_Command] = []

    def run(self) -> list[_Command]:
        self._parse(0, None)
        return self.commands

    def _parse(self, i: int, close: str | None) -> tuple[int, list[_Command]]:
        """Read shell from `i` up to `close` (`)` or a backtick) or the end.

        Returns the index after the closing character and the commands read at
        this level.
        """
        src, n = self.src, len(self.src)
        level: list[_Command] = []
        cmd = _Command()
        buf: list[str] = []
        in_word = False
        expect = ""  # what the next word is: heredoc delimiter, here-string, redirect target
        pending: list[tuple[str, bool, _Command]] = []
        depth = 0

        def end_word() -> None:
            nonlocal in_word, expect
            if not in_word:
                return
            value = "".join(buf)
            buf.clear()
            in_word = False
            if expect in ("heredoc", "heredoc-strip"):
                pending.append((value, expect == "heredoc-strip", cmd))
            elif expect == "herestring":
                cmd.stdin.append(value)
            elif expect != "redirect":
                cmd.words.append(value)
            expect = ""

        def end_command() -> None:
            nonlocal cmd, expect
            end_word()
            expect = ""
            if cmd.words or cmd.stdin or any(owner is cmd for _, _, owner in pending):
                level.append(cmd)
                self.commands.append(cmd)
            cmd = _Command()

        while i < n:
            c = src[i]
            nxt = src[i + 1] if i + 1 < n else ""
            if close is not None and c == close and (close == "`" or depth == 0):
                end_command()
                return i + 1, level
            if c == "\\":
                if nxt != "\n":
                    buf.append(nxt)
                    in_word = True
                i += 2
            elif c == "'":
                end = src.find("'", i + 1)
                end = n if end < 0 else end
                buf.append(src[i + 1 : end])
                in_word = True
                i = end + 1
            elif c == '"':
                i = self._double_quoted(i + 1, buf)
                in_word = True
            elif c == "$" and nxt == "'":
                i = self._ansi_quoted(i + 2, buf)
                in_word = True
            elif c == "$" and nxt == "(":
                i, inner = self._parse(i + 2, ")")
                buf.append("\n".join(sub.literal_text() for sub in inner))
                in_word = True
            elif c == "`":
                i, inner = self._parse(i + 1, "`")
                buf.append("\n".join(sub.literal_text() for sub in inner))
                in_word = True
            elif c == "#" and not in_word:
                end = src.find("\n", i)
                i = n if end < 0 else end
            elif c in " \t\r":
                end_word()
                i += 1
            elif c == "\n":
                end_command()
                i = self._heredoc_bodies(i + 1, pending)
            elif c == "&" and nxt == ">":
                end_word()
                i += 3 if src.startswith("&>>", i) else 2
                expect = "redirect"
            elif c in ";&|":
                end_command()
                i += 1
                while i < n and src[i] in ";&|":
                    i += 1
            elif c in "<>":
                if in_word and "".join(buf).isdigit():
                    buf.clear()  # a file descriptor number, not a word
                    in_word = False
                end_word()
                if src.startswith("<<<", i):
                    expect, i = "herestring", i + 3
                elif src.startswith("<<-", i):
                    expect, i = "heredoc-strip", i + 3
                elif src.startswith("<<", i):
                    expect, i = "heredoc", i + 2
                else:
                    i += 1
                    while i < n and src[i] in "<>&|":
                        i += 1
                    expect = "redirect"
            elif c == "(":
                end_command()
                depth += 1
                i += 1
            elif c == ")":
                end_command()
                depth = max(depth - 1, 0)
                i += 1
            else:
                buf.append(c)
                in_word = True
                i += 1

        end_command()
        if pending:
            # The command ended right after the redirection, with no body.
            self._heredoc_bodies(n, pending)
        return n, level

    def _double_quoted(self, i: int, buf: list[str]) -> int:
        src, n = self.src, len(self.src)
        while i < n:
            c = src[i]
            nxt = src[i + 1] if i + 1 < n else ""
            if c == '"':
                return i + 1
            if c == "\\" and nxt in '$`"\\\n':
                if nxt != "\n":
                    buf.append(nxt)
                i += 2
            elif c == "$" and nxt == "(":
                i, inner = self._parse(i + 2, ")")
                buf.append("\n".join(sub.literal_text() for sub in inner))
            elif c == "`":
                i, inner = self._parse(i + 1, "`")
                buf.append("\n".join(sub.literal_text() for sub in inner))
            else:
                buf.append(c)
                i += 1
        return n

    def _ansi_quoted(self, i: int, buf: list[str]) -> int:
        src, n = self.src, len(self.src)
        escapes = {"n": "\n", "t": "\t", "r": "\r", "\\": "\\", "'": "'", '"': '"'}
        while i < n:
            c = src[i]
            if c == "'":
                return i + 1
            if c == "\\" and i + 1 < n:
                buf.append(escapes.get(src[i + 1], src[i : i + 2]))
                i += 2
            else:
                buf.append(c)
                i += 1
        return n

    def _heredoc_bodies(self, i: int, pending: list[tuple[str, bool, _Command]]) -> int:
        """Read the bodies of the heredocs opened on the line just ended.

        An unterminated body runs to the end of the command, as in bash.
        """
        src, n = self.src, len(self.src)
        for delimiter, strip_tabs, owner in pending:
            lines: list[str] = []
            while i < n:
                end = src.find("\n", i)
                line = src[i:] if end < 0 else src[i:end]
                i = n if end < 0 else end + 1
                if strip_tabs:
                    line = line.lstrip("\t")
                if line == delimiter:
                    break
                lines.append(line)
            owner.stdin.append("\n".join(lines))
        pending.clear()
        return i


def _program(words: list[str]) -> list[str]:
    """The words from the program a simple command runs, past prefixes."""
    i = 0
    while i < len(words):
        word = words[i]
        if _ASSIGNMENT.match(word) or word in _RESERVED:
            i += 1
        elif os.path.basename(word) in _WRAPPERS:
            i += 1
            while i < len(words) and (_WRAPPER_ARG.match(words[i]) or _ASSIGNMENT.match(words[i])):
                i += 1
        else:
            return words[i:]
    return []


def _commit_args(words: list[str]) -> tuple[list[str], list[str]] | None:
    """For `git commit`, its arguments and the `-C` directories before it, else None."""
    if not words or os.path.basename(words[0]) != "git":
        return None
    i = 1
    chdirs: list[str] = []
    while i < len(words) and words[i].startswith("-"):
        if words[i] == "-C" and i + 1 < len(words):
            chdirs.append(words[i + 1])
        i += 2 if words[i] in _GIT_VALUE_OPTS else 1
    if i < len(words) and words[i] == "commit":
        return words[i + 1 :], chdirs
    return None


def _long_name(option: str) -> str:
    """The long option an argument names, accepting git's unique abbreviations."""
    for name in (*_MESSAGE_LONG, _FILE_LONG):
        if len(option) >= 5 and name.startswith(option):
            return name
    return option


def _message_values(args: list[str]) -> tuple[list[str], list[str]]:
    """Every `-m`, `--message` and `--trailer` value in order, and every `-F` file.

    Git joins repeated messages as paragraphs, so each is part of the message.
    Reading only the first let attribution through in a second `-m`, as did
    `-am`, `-m'x'` and `--message 'x'` (#342). `-F -` is stdin, which the
    caller reads already, so it is not listed as a file.
    """
    values: list[str] = []
    files: list[str] = []
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--":
            break
        if arg.startswith("--"):
            option, eq, value = arg.partition("=")
            option = _long_name(option)
            if option in _MESSAGE_LONG or option == _FILE_LONG:
                target = values if option in _MESSAGE_LONG else files
                if eq:
                    target.append(value)
                elif i + 1 < len(args):
                    target.append(args[i + 1])
                    i += 1
            elif option in _VALUE_LONG and not eq:
                i += 1
        elif arg.startswith("-") and len(arg) > 1:
            cluster = arg[1:]
            for j, letter in enumerate(cluster):
                if letter in _ATTACHED_SHORT:
                    break
                if letter in _VALUE_SHORT:
                    value = cluster[j + 1 :]
                    if not value and i + 1 < len(args):
                        value = args[i + 1]
                        i += 1
                    if letter == "m":
                        values.append(value)
                    elif letter == "F":
                        files.append(value)
                    break
        i += 1
    return values, [name for name in files if name and name != "-"]


def _read_message_file(name: str, cwd: str, chdirs: list[str]) -> str | None:
    """The text of a `-F` file, resolved as git resolves it, or None if unreadable.

    The lexer expands nothing, so `$VAR` and `~` are expanded here from this
    process's environment, which is the shell's the command will run in.
    """
    base = cwd
    for directory in chdirs:
        base = os.path.join(base, os.path.expanduser(os.path.expandvars(directory)))
    path = os.path.join(base, os.path.expanduser(os.path.expandvars(name)))
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            return handle.read()
    except OSError:
        return None


def _commands(source: str, depth: int = 0) -> list[_Command]:
    """Every simple command in `source`, including script text a shell is handed."""
    found: list[_Command] = []
    for command in _Lexer(source).run():
        words = _program(command.words)
        if depth < _MAX_DEPTH and words:
            if os.path.basename(words[0]) in _SHELLS and "-c" in words[1:-1]:
                found.extend(_commands(words[words.index("-c", 1) + 1], depth + 1))
            elif words[0] == "eval":
                found.extend(_commands(" ".join(words[1:]), depth + 1))
        found.append(_Command(words=words, stdin=command.stdin))
    return found


def extract(command: str, cwd: str | None = None) -> tuple[str | None, bool]:
    """Return (message, commit_seen).

    `commit_seen` is False when no git commit runs, which is a different
    outcome from a commit whose message could not be found: the first must be
    allowed through untouched, the second is worth reporting.
    """
    base = cwd or os.getcwd()
    commit_seen = False
    parts: list[str] = []
    for cmd in _commands(command):
        found = _commit_args(cmd.words)
        if found is None:
            continue
        args, chdirs = found
        commit_seen = True
        values, files = _message_values(args)
        # stdin is the message under `-F -`; read it whatever the flags say,
        # since failing closed costs nothing when it is not.
        parts.extend(values + cmd.stdin)
        for name in files:
            text = _read_message_file(name, base, chdirs)
            if text is not None:
                parts.append(text)

    if not commit_seen:
        return None, False
    parts = [part for part in parts if part]
    if parts:
        return "\n\n".join(parts), True
    return None, True


def main() -> int:
    parser = argparse.ArgumentParser(description="Print the message a git commit command carries.")
    parser.add_argument("--cwd", default="", help="directory the command runs in")
    options = parser.parse_args()
    message, commit_seen = extract(sys.stdin.read(), options.cwd or None)
    if not commit_seen:
        return 1
    if message is None:
        return 2
    sys.stdout.write(message)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
