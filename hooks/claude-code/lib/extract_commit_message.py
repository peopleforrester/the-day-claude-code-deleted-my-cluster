#!/usr/bin/env python3
# ABOUTME: Extracts the message from a git commit invocation inside a shell command.
# ABOUTME: Heredoc-aware, so a decoy heredoc cannot mask the real message (#154).
"""Pull the commit message out of a shell command string.

Synced from the live working set (llm-coding-workflow
scripts/git-hooks/lib/extract_commit_message.py) on 2026-10-31, with the
fixes made here first that are marked below (#38).

The hook that used this logic inline decided what to scan by pattern-matching
the raw command, which failed three ways, all reproduced on 2026-09-10 and
again on 2026-09-24:

1. It took the first heredoc delimiter found anywhere in the command, so an
   unrelated heredoc earlier in the line supplied the text that got scanned.
2. Because of (1) it **failed open**: attribution in the real message passed
   whenever a decoy came first.
3. It fired on commands running no git at all, because the literal string
   `git commit` appeared inside a heredoc body as documentation.

The fix is to track heredoc extent while walking the command, so a line is
known to be either shell or body, and only shell lines can carry an
invocation. Reading `stdin` and printing the message keeps it callable from
bash and directly testable from Python.

It is still a parser of a command string, not a shell, so it is still a
guess. hooks/README.md lists what it does not see.

Exit status:
    0  a commit message was extracted and printed
    1  the command contains no git commit invocation
    2  a commit runs, but no message is present (interactive editor, -F file)
"""

from __future__ import annotations

import re
import sys

# `git commit` at a command position: start of line, or after a separator.
# Anchoring this is what stops a mention inside prose being read as a call.
#
# Fixed here first: a global option that takes a separate value
# (`git -C <path> commit`, `git -c <key>=<value> commit`) was not recognized,
# so the commit was read as no commit at all and allowed untouched.
_GIT_COMMIT = re.compile(
    r"(?:^|[;&|(`]|\&\&|\|\|)\s*git\s+"
    r"(?:(?:-C|-c|--git-dir|--work-tree|--namespace)\s+\S+\s+|-\S+\s+)*commit\b"
)

# A heredoc redirection, capturing the delimiter and whether it is quoted.
_HEREDOC = re.compile(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1")

# A message option and its value.
#
# Fixed here first: the live copy read only a separate `-m` and `--message=`.
# `git commit -am "..."`, one of the most common forms, was a commit with no
# message to scan, and so were `-m"..."`, `--message "..."` and an unquoted
# one-word value.
_MESSAGE_OPT = re.compile(
    r"(?<![\w-])(?:-[A-Za-z]*m[ \t]*|--message(?:=|[ \t]+))"
    r"(?:(?P<q>['\"])(?P<body>.*?)(?<!\\)(?P=q)|(?P<bare>[^\s'\";&|)]+))",
    re.S,
)

# `-m "$(cat <<'EOF'` names a heredoc whose body is read separately; the text
# between the quotes is only the substitution's shell, not message.
_HEREDOC_SUBSTITUTION = re.compile(r"^\$\(.*<<", re.S)


def _open_heredocs(line: str) -> list[tuple[int, str]]:
    """Heredocs opened by this shell line, in order, as (offset, delimiter)."""
    return [(m.start(), m.group(2)) for m in _HEREDOC.finditer(line)]


def extract(command: str) -> tuple[str | None, bool]:
    """Return (message, commit_seen).

    `commit_seen` is False when no git commit runs, which is a different
    outcome from a commit whose message could not be found: the first must be
    allowed through untouched, the second is worth reporting.
    """
    lines = command.split("\n")
    pending: list[str] = []  # delimiters whose bodies have not closed yet
    # Index, among the bodies still pending, of the commit's own heredoc.
    target: int | None = None
    body: list[str] = []
    commit_seen = False
    # Shell text from the commit invocation on, heredoc bodies left out.
    shell: list[str] = []

    for line in lines:
        if pending:
            # Inside a heredoc body. Never shell, so never an invocation.
            if line.strip() == pending[0]:
                pending.pop(0)
                if target is not None:
                    target -= 1
            elif target == 0:
                body.append(line)
            continue

        opened = _open_heredocs(line)
        if not commit_seen:
            commit = _GIT_COMMIT.search(line)
            if commit:
                commit_seen = True
                shell.append(line[commit.start():])
                # Fixed here first: only a heredoc opened after the invocation
                # can be its message. `cat > f <<'EOF' && git commit -m ...`
                # opens the file's heredoc on the commit line, and taking it
                # read the file body instead of the -m message.
                mine = [i for i, (offset, _) in enumerate(opened) if offset >= commit.start()]
                if mine:
                    target = mine[0]
        else:
            shell.append(line)
        pending.extend(delimiter for _, delimiter in opened)

    if not commit_seen:
        return None, False

    # Fixed here first: every -m, read from the invocation on. The live copy
    # searched from the start of the commit line, so `git stash push -m "wip"
    # && git commit -m ...` scanned "wip", and it kept only the first -m, while
    # git joins every -m into the message: `-m "subject" -m "Co-Authored-By:
    # ..."` put the trailer past the check. A heredoc after the invocation that
    # belongs to a later command on the line is scanned too, as a message would
    # be: on an ambiguous line this reads too much rather than too little.
    #
    # Scanning from the commit line to the end rather than that line alone: a
    # multi-line -m message continues on lines that carry no `git commit`
    # themselves, and collecting only matching lines silently dropped
    # everything after the subject, which is where attribution trailers live.
    joined = "\n".join(shell)
    parts = ["\n".join(body)] if body else []
    for m in _MESSAGE_OPT.finditer(joined):
        value = m.group("body") if m.group("q") else m.group("bare")
        if value and not _HEREDOC_SUBSTITUTION.match(value):
            parts.append(value)

    if not parts:
        return None, True
    return "\n\n".join(parts), True


def main() -> int:
    message, commit_seen = extract(sys.stdin.read())
    if not commit_seen:
        return 1
    if message is None:
        return 2
    sys.stdout.write(message)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
