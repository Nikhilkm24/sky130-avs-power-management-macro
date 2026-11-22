"""
Formatting Fixer Utility
Project: Closed-Loop AVS Power Management Macro on Sky130
Normalizes all source files to LF line endings and removes trailing whitespace.
"""

import os

EXTENSIONS_TO_FIX = {
    ".v", ".sv", ".vh",
    ".tcl", ".sdc",
    ".py",
    ".sp", ".cir",
    ".yml", ".yaml",
    ".md"
}

IGNORE_DIRS = {".git", ".venv", "build", "runs", "__pycache__"}

def fix_all_formatting():
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    fixed_count = 0

    for root, dirs, files in os.walk(project_root):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
        for f in files:
            ext = os.path.splitext(f)[1].lower()
            if ext in EXTENSIONS_TO_FIX:
                filepath = os.path.join(root, f)
                try:
                    with open(filepath, "rb") as fp:
                        raw = fp.read()
                except Exception:
                    continue

                try:
                    text = raw.decode("utf-8")
                except UnicodeDecodeError:
                    continue

                # Convert CRLF to LF
                text = text.replace("\r\n", "\n")

                # Remove trailing whitespace (except md where trailing spaces can be significant)
                if ext != ".md":
                    lines = [line.rstrip() for line in text.split("\n")]
                    text = "\n".join(lines)

                # Ensure final newline
                if not text.endswith("\n"):
                    text += "\n"

                new_raw = text.encode("utf-8")
                if new_raw != raw:
                    with open(filepath, "wb") as fp:
                        fp.write(new_raw)
                    fixed_count += 1

    print(f"[Format Fixer] Normalized {fixed_count} files to LF and trimmed trailing whitespace.")

if __name__ == "__main__":
    fix_all_formatting()
