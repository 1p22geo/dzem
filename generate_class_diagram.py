#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from pathlib import Path


IDENTIFIER_RE = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*\b")


def find_gd_files(root: Path) -> list[Path]:
    return sorted(p for p in root.rglob("*.gd") if p.is_file())


def resolve_class_name(file_path: Path) -> str:
    for line in file_path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("class_name "):
            return stripped.split()[1]
    return file_path.stem


def top_level_lines(text: str) -> list[str]:
    lines: list[str] = []
    for line in text.splitlines():
        if line.startswith((" ", "\t")):
            continue
        lines.append(line.rstrip())
    return lines


def clean_type(type_text: str) -> str:
    return type_text.strip().rstrip(" ;:")


def parse_field(line: str) -> str | None:
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return None

    if " var " in stripped and not stripped.startswith(("var ", "static var ")):
        stripped = stripped[stripped.find("var ") :]

    var_match = re.match(
        r"^(static\s+)?var\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?::\s*([^=]+))?",
        stripped,
    )
    if var_match:
        is_static = bool(var_match.group(1))
        name = var_match.group(2)
        var_type = clean_type(var_match.group(3) or "")
        if var_type:
            return f"{'static ' if is_static else ''}{name}: {var_type}"
        return f"{'static ' if is_static else ''}{name}"

    const_match = re.match(
        r"^const\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?::\s*([^=]+))?",
        stripped,
    )
    if const_match:
        name = const_match.group(1)
        const_type = clean_type(const_match.group(2) or "")
        if const_type:
            return f"const {name}: {const_type}"
        return f"const {name}"

    return None


def split_params(params: str) -> list[str]:
    if not params.strip():
        return []
    parts: list[str] = []
    current = ""
    depth_square = depth_round = depth_curly = 0
    in_single = in_double = False

    i = 0
    while i < len(params):
        ch = params[i]
        if ch == '"' and not in_single:
            in_double = not in_double
        elif ch == "'" and not in_double:
            in_single = not in_single
        elif not in_single and not in_double:
            if ch == "[":
                depth_square += 1
            elif ch == "]":
                depth_square = max(0, depth_square - 1)
            elif ch == "(":
                depth_round += 1
            elif ch == ")":
                depth_round = max(0, depth_round - 1)
            elif ch == "{":
                depth_curly += 1
            elif ch == "}":
                depth_curly = max(0, depth_curly - 1)
            elif ch == "," and depth_square == depth_round == depth_curly == 0:
                parts.append(current.strip())
                current = ""
                i += 1
                continue
        current += ch
        i += 1

    if current.strip():
        parts.append(current.strip())
    return parts


def parse_method(line: str) -> str | None:
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return None

    method_match = re.match(
        r"^(static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)\((.*)\)\s*(?:->\s*([^:]+))?:",
        stripped,
    )
    if not method_match:
        return None

    is_static = bool(method_match.group(1))
    name = method_match.group(2)
    params = method_match.group(3).strip()
    return_type = clean_type(method_match.group(4) or "")

    formatted_params: list[str] = []
    for param in split_params(params):
        without_default = param.split("=")[0].strip()
        p_match = re.match(
            r"^([A-Za-z_][A-Za-z0-9_]*)\s*(?::\s*(.+))?$",
            without_default,
        )
        if not p_match:
            formatted_params.append(without_default)
            continue
        p_name = p_match.group(1)
        p_type = clean_type(p_match.group(2) or "")
        formatted_params.append(f"{p_name}: {p_type}" if p_type else p_name)

    signature = f"{'static ' if is_static else ''}{name}({', '.join(formatted_params)})"
    if return_type:
        signature += f": {return_type}"
    return signature


def class_refs(text: str, known_classes: set[str]) -> set[str]:
    without_double = re.sub(r'"(?:\\.|[^"\\])*"', " ", text)
    without_single = re.sub(r"'(?:\\.|[^'\\])*'", " ", without_double)
    return {
        token
        for token in IDENTIFIER_RE.findall(without_single)
        if token in known_classes
    }


def generate_diagram(root: Path) -> str:
    gd_files = find_gd_files(root)
    class_by_file = {file_path: resolve_class_name(file_path) for file_path in gd_files}
    known_classes = set(class_by_file.values())
    path_to_class = {
        f"res://{file_path.relative_to(root).as_posix()}": class_name
        for file_path, class_name in class_by_file.items()
    }

    classes: list[tuple[str, list[str], list[str]]] = []
    base_types: set[str] = set()
    inheritance: set[tuple[str, str]] = set()
    associations: set[tuple[str, str]] = set()

    for file_path in gd_files:
        class_name = class_by_file[file_path]
        text = file_path.read_text(encoding="utf-8")
        top = top_level_lines(text)

        extends_value: str | None = None
        for line in top:
            stripped = line.strip()
            if stripped.startswith("extends "):
                extends_value = stripped[len("extends ") :].strip()
                break

        if extends_value:
            if (
                extends_value.startswith('"')
                and extends_value.endswith('"')
                or extends_value.startswith("'")
                and extends_value.endswith("'")
            ):
                base = path_to_class.get(extends_value[1:-1], extends_value[1:-1])
            elif extends_value.startswith("res://"):
                base = path_to_class.get(extends_value, extends_value)
            else:
                base = extends_value
            inheritance.add((base, class_name))
            if base not in known_classes and not str(base).startswith("res://"):
                base_types.add(base)

        fields: list[str] = []
        methods: list[str] = []
        for line in top:
            field = parse_field(line)
            if field:
                fields.append(field)
                continue
            method = parse_method(line)
            if method:
                methods.append(method)
        classes.append((class_name, fields, methods))

        for declaration in fields + methods:
            for target in class_refs(declaration, known_classes):
                if target != class_name:
                    associations.add((class_name, target))

        for preload_or_load in re.finditer(
            r'(?:preload|load)\(("([^"]+\.gd)"|\'([^\']+\.gd)\')\)',
            text,
        ):
            ref_path = preload_or_load.group(2) or preload_or_load.group(3)
            target = path_to_class.get(ref_path)
            if target and target != class_name:
                associations.add((class_name, target))

        for constructor in re.finditer(r"\b([A-Za-z_][A-Za-z0-9_]*)\.new\(", text):
            target = constructor.group(1)
            if target in known_classes and target != class_name:
                associations.add((class_name, target))

    lines: list[str] = []
    lines.append("classDiagram")
    lines.append("    direction TB")
    lines.append("")

    for base in sorted(base_types):
        lines.append(f"    class {base}")
    if base_types:
        lines.append("")

    for class_name, fields, methods in classes:
        lines.append(f"    class {class_name} {{")
        for field in fields:
            lines.append(f"        +{field}")
        for method in methods:
            lines.append(f"        +{method}")
        lines.append("    }")
        lines.append("")

    for base, child in sorted(inheritance):
        if not str(base).startswith("res://"):
            lines.append(f"    {base} <|-- {child}")

    for source, target in sorted(associations):
        lines.append(f"    {source} --> {target}")

    return "\n".join(lines).rstrip() + "\n"


def render_html(diagram_text: str) -> str:
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Class Diagram</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    <script>
        mermaid.initialize({{ startOnLoad: true, theme: 'dark', securityLevel: 'loose' }});
    </script>
    <style>
        body {{
            margin: 0;
            padding: 16px;
            background: #111;
            color: #eee;
            font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
        }}
        h1 {{ margin: 0 0 12px 0; font-size: 20px; }}
        .wrap {{
            overflow: auto;
            border: 1px solid #333;
            border-radius: 8px;
            padding: 12px;
            background: #181818;
        }}
        .mermaid {{ min-width: 1200px; }}
    </style>
</head>
<body>
    <h1>Class Diagram</h1>
    <div class="wrap">
        <div class="mermaid">
{diagram_text}
        </div>
    </div>
</body>
</html>
"""


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate Mermaid class diagram from all .gd files."
    )
    parser.add_argument(
        "--root",
        default=".",
        help="Project root to scan for .gd files (default: current directory).",
    )
    parser.add_argument(
        "--mmd-out",
        default="class_diagram.mmd",
        help="Output Mermaid file path (default: class_diagram.mmd).",
    )
    parser.add_argument(
        "--html-out",
        default="class_diagram.html",
        help="Output HTML viewer path (default: class_diagram.html).",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    mmd_out = Path(args.mmd_out)
    if not mmd_out.is_absolute():
        mmd_out = root / mmd_out
    html_out = Path(args.html_out)
    if not html_out.is_absolute():
        html_out = root / html_out

    diagram_text = generate_diagram(root)
    mmd_out.write_text(diagram_text, encoding="utf-8")
    html_out.write_text(render_html(diagram_text), encoding="utf-8")

    print(f"Wrote {mmd_out}")
    print(f"Wrote {html_out}")


if __name__ == "__main__":
    main()
