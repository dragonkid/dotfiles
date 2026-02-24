#!/usr/bin/env python3
"""Analyze observations.jsonl and produce Phase 1 statistics.

Usage: python3 analyze-observations.py <observations.jsonl>

Output: human-readable tables of tool usage frequency, bigrams, trigrams,
per-session breakdown, and summary counts.

JSON schema (from observe.sh):
  - timestamp: ISO 8601
  - event: "tool_start" | "tool_complete" | "parse_error"
  - tool: tool name (absent for parse_error)
  - session: session UUID
  - input: JSON string (tool_start only, needs json.loads())
  - output: JSON string (tool_complete only)
"""

import json
import sys
from collections import Counter, defaultdict
from pathlib import Path


def parse_input_field(entry):
    """Parse the input field which is a JSON string, not a dict."""
    raw = entry.get("input")
    if raw is None:
        return {}
    if isinstance(raw, dict):
        return raw
    if isinstance(raw, str):
        try:
            return json.loads(raw)
        except (json.JSONDecodeError, ValueError):
            return {"raw": raw}
    return {}


def load_entries(path):
    entries = []
    parse_errors = 0
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entries.append(json.loads(line))
            except json.JSONDecodeError:
                parse_errors += 1
    return entries, parse_errors


def analyze(entries, parse_errors):
    total = len(entries) + parse_errors

    # Event type counts
    event_counts = Counter(e.get("event", "unknown") for e in entries)

    # Tool frequency (starts only)
    tool_starts = Counter()
    for e in entries:
        if e.get("event") == "tool_start" and e.get("tool"):
            tool_starts[e["tool"]] += 1

    # Group by session
    sessions = defaultdict(list)
    for e in entries:
        sessions[e.get("session", "unknown")].append(e)
    for sid in sessions:
        sessions[sid].sort(key=lambda x: x.get("timestamp", ""))

    # Bigrams and trigrams
    bigram_counts = Counter()
    trigram_counts = Counter()
    for evts in sessions.values():
        tools = [e["tool"] for e in evts if e.get("event") == "tool_start" and e.get("tool")]
        for i in range(len(tools) - 1):
            bigram_counts[(tools[i], tools[i + 1])] += 1
        for i in range(len(tools) - 2):
            trigram_counts[(tools[i], tools[i + 1], tools[i + 2])] += 1

    # Parallel tool groups (same timestamp, 2+ tools)
    parallel_groups = Counter()
    for evts in sessions.values():
        starts = [e for e in evts if e.get("event") == "tool_start"]
        ts_groups = defaultdict(list)
        for e in starts:
            ts_groups[e["timestamp"]].append(e)
        for group in ts_groups.values():
            if len(group) >= 2:
                tools = tuple(sorted(set(e["tool"] for e in group)))
                parallel_groups[tools] += 1

    # Per-session breakdown
    session_stats = []
    for sid, evts in sessions.items():
        tools = [e["tool"] for e in evts if e.get("event") == "tool_start" and e.get("tool")]
        session_stats.append((sid, len(tools), Counter(tools)))
    session_stats.sort(key=lambda x: x[1], reverse=True)

    # Date range
    timestamps = sorted(e.get("timestamp", "") for e in entries if e.get("timestamp"))

    # File types worked on
    ext_counter = Counter()
    for e in entries:
        if e.get("event") != "tool_start":
            continue
        inp = parse_input_field(e)
        fp = inp.get("file_path", "")
        if fp and "." in fp.split("/")[-1]:
            ext = fp.rsplit(".", 1)[-1].lower()
            ext_counter[ext] += 1

    return {
        "total": total,
        "parse_errors": parse_errors,
        "success": len(entries),
        "sessions": len(sessions),
        "date_range": (timestamps[0][:10], timestamps[-1][:10]) if timestamps else None,
        "event_counts": event_counts,
        "tool_starts": tool_starts,
        "bigrams": bigram_counts,
        "trigrams": trigram_counts,
        "parallel_groups": parallel_groups,
        "session_stats": session_stats[:5],
        "file_types": ext_counter,
    }


def format_table(headers, rows, col_widths=None):
    if not col_widths:
        col_widths = [
            max(len(str(h)), max((len(str(r[i])) for r in rows), default=0))
            for i, h in enumerate(headers)
        ]
    header_line = "  ".join(str(h).ljust(w) for h, w in zip(headers, col_widths))
    separator = "  ".join("-" * w for w in col_widths)
    lines = [header_line, separator]
    for row in rows:
        lines.append("  ".join(str(v).ljust(w) for v, w in zip(row, col_widths)))
    return "\n".join(lines)


def print_report(stats):
    print("=" * 60)
    print("OBSERVATION ANALYSIS")
    print("=" * 60)
    print(f"Total entries: {stats['total']}")
    print(f"Parse errors:  {stats['parse_errors']}")
    print(f"Success:       {stats['success']}")
    print(f"Sessions:      {stats['sessions']}")
    if stats["date_range"]:
        print(f"Date range:    {stats['date_range'][0]} to {stats['date_range'][1]}")

    # Sanity check: high parse error rate
    if stats["total"] > 0 and stats["parse_errors"] / stats["total"] > 0.1:
        pct = stats["parse_errors"] / stats["total"] * 100
        print(f"\n⚠ WARNING: {pct:.0f}% parse errors — observe.sh may have a bug")

    # Tool frequency
    print(f"\n--- Tool Usage (starts) ---")
    rows = [(tool, count) for tool, count in stats["tool_starts"].most_common(20)]
    if rows:
        print(format_table(["Tool", "Count"], rows, [30, 6]))

    # Bigrams
    bigrams = [(a, b, c) for (a, b), c in stats["bigrams"].most_common() if c >= 3]
    if bigrams:
        print(f"\n--- Bigrams (count >= 3) ---")
        print(format_table(["From", "To", "Count"], bigrams, [25, 25, 6]))

    # Trigrams
    trigrams = [(a, b, c, n) for (a, b, c), n in stats["trigrams"].most_common() if n >= 3]
    if trigrams:
        print(f"\n--- Trigrams (count >= 3) ---")
        print(format_table(["Tool 1", "Tool 2", "Tool 3", "Count"], trigrams, [18, 18, 18, 6]))

    # Parallel groups
    pgroups = [("+".join(tools), c) for tools, c in stats["parallel_groups"].most_common(10) if c >= 2]
    if pgroups:
        print(f"\n--- Parallel Tool Groups (count >= 2) ---")
        print(format_table(["Tools", "Count"], pgroups, [50, 6]))

    # Per-session
    print(f"\n--- Top Sessions by Tool Count ---")
    for sid, count, tcounts in stats["session_stats"]:
        top3 = ", ".join(f"{t}({c})" for t, c in tcounts.most_common(3))
        print(f"  {sid[:12]}  tools={count:3d}  top: {top3}")

    # File types
    if stats["file_types"]:
        print(f"\n--- File Types ---")
        rows = [(f".{ext}", c) for ext, c in stats["file_types"].most_common(10)]
        print(format_table(["Extension", "Count"], rows, [12, 6]))


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <observations.jsonl>", file=sys.stderr)
        sys.exit(1)

    path = Path(sys.argv[1])
    if not path.exists():
        print(f"File not found: {path}", file=sys.stderr)
        sys.exit(1)

    if path.stat().st_size == 0:
        print("Observations file is empty.")
        sys.exit(0)

    entries, parse_errors = load_entries(path)
    if not entries and parse_errors == 0:
        print("No entries found.")
        sys.exit(0)

    stats = analyze(entries, parse_errors)
    print_report(stats)


if __name__ == "__main__":
    main()
