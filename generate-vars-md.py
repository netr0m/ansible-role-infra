#!/usr/bin/env python
import re

import typer


DEFAULT_INPUT_FILEPATH: str = "defaults/main.yml"
DEFAULT_OUTPUT_FILEPATH: str = "docs/default-variables.md"
DEFAULT_MARKDOWN_TITLE: str = "Default Variables"
DEFAULT_GROUP: str = "All"

DEBUG: bool = False
DRY_RUN: bool = False


IGNORE: list[str] = ["---", "..."]
GROUPS: dict[str, str] = {
    "start": r"^#{3}\s{1}.{1,}\s{1}#{3}$",
    "desc": r"^#\s{1}.{1,}$",
    "list_start": r".{1,}:$",
    "list_item": r"\s{1,}(-)?\s{1}.{1,}",
    "dict_item": r"\s{1,}.{1,}",
    "empty_list_or_dict": r".{1,}: (\[\]|\{\})$",
    "example": r"^\s{1,12}#\s{1}.{1,}$",
}


def debug(msg: str):
    if DEBUG:
        print(msg)


def read_file(filepath: str) -> list[str]:
    with open(filepath, "r") as f:
        defaults = f.readlines()
    
    return defaults


def has_start(lines: list[str]) -> bool:
    _lines = "".join(lines)
    return re.match(GROUPS["start"], _lines) != None


def is_start(line: str) -> bool:
    return re.match(GROUPS["start"], line) != None


def is_desc(line: str) -> bool:
    return re.match(GROUPS["desc"], line) != None


def is_list_start(line: str) -> bool:
    return re.match(GROUPS["list_start"], line) != None


def is_list_item(line: str) -> bool:
    if is_example(line):
        return False
    return re.match(GROUPS["list_item"], line) != None


def is_empty_list_or_dict(line: str) -> bool:
    if is_example(line):
        return False
    return re.match(GROUPS["empty_list_or_dict"], line) != None


def is_dict_item(line: str) -> bool:
    return re.match(GROUPS["dict_item"], line) != None


def is_example(line: str) -> bool:
    return re.match(GROUPS["example"], line) != None


def parse_defaults(defaults: list[str]) -> dict[str, list[dict[str, str]]]:
    parsed: dict[str, list] = {}
    _defaults: list[str] = [line.replace("\n", "") for line in defaults if line.replace("\n", "") not in IGNORE]
    _group: str | None = None
    _var: dict = {}

    if not has_start(_defaults):
        debug(f"No groups are defined. Using default group '{DEFAULT_GROUP}'")
        _group = DEFAULT_GROUP
        parsed[_group] = []

    for i, line in enumerate(_defaults):
        has_parsed_var: bool = False
        try:
            next_line = _defaults[i + 1]
        except IndexError:
            next_line = False

        if is_start(line):
            debug("="*32)
            _group = line.replace("###", "").strip()
            debug(f"Got group '{_group}'")
            if _group not in parsed:
                parsed[_group] = []
        elif is_desc(line):
            desc = line.replace("#", "").strip()
            debug(f"\tGot desc '{desc}'")
            if "desc" in _var:
                _var["desc"] += f"\n{desc}"
            else:
                _var["desc"] = desc
        else:
            if is_list_start(line):
                debug(f"\tGot var '{line}' (list def)'")
                if "var" in _var:
                    _var["var"] += f"\n{line}"
                else:
                    _var["var"] = line
            elif is_list_item(line):
                debug(f"\t\tGot var '{line}' (list item)")
                _var["var"] += f"\n{line}"
                if not next_line or is_desc(next_line):
                # if (next_line and not (is_list_item(next_line) or is_example(next_line))) or not next_line:
                    has_parsed_var = True
            elif is_empty_list_or_dict(line):
                debug(f"\tGot var '{line}' (empty list/dict)")
                _var["var"] = line
                if (next_line and not is_example(next_line)) or not next_line:
                    has_parsed_var = True
            elif is_example(line):
                debug(f"\t\tGot example '{line}'")
                _var["var"] += f"\n{line}"
                if not next_line or is_desc(next_line):
                    has_parsed_var = True
            elif line == "":
                continue
            else:
                _var["var"] = line
                has_parsed_var = True
                debug(f"\tGot var '{line}'")

            if has_parsed_var and _group != None:
                debug(f"\t{'*'*16}")
                parsed[_group].append(_var)
                _var = {}

    if DEBUG:
        for group, vars in parsed.items():
            print(f"{group}:")
            for var in vars:
                print(f"\t{var}")

    return parsed


def create_markdown(parsed: dict[str, list[dict[str, str]]], title: str, filepath: str):
    md_title: str = "#"
    md_group: str = "##"
    md_desc: str = "###"
    md_var_prefix: str = "```yaml"
    md_var_suffix: str = "```"

    md: list[str] = []

    md.append(f"{md_title} {title}")

    for group, variables in parsed.items():
        md.append(f"{md_group} {group}\n")

        for variable in variables:
            desc = variable.get("desc")
            var = variable.get("var")

            if var and desc:
                md.append(f"{md_desc} {desc}\n")
            if var:
                md.append(md_var_prefix)
                md.append(var)
                md.append(md_var_suffix)

    with open(filepath, "wt") as f:
        f.write("\n".join(md))
    print(f"Wrote default variables to markdown file '{filepath}'")


def main(
    in_file: str = typer.Option(
        DEFAULT_INPUT_FILEPATH,
        "--in-file", "-i",
        help="Path to the input-file. Should be a YAML file containing variables.",
    ),
    out_file: str = typer.Option(
        DEFAULT_OUTPUT_FILEPATH,
        "--out-file", "-o",
        help="Write the generated markdown to this filepath",
    ),
    title: str = typer.Option(
        DEFAULT_MARKDOWN_TITLE,
        "--title", "-t",
        help="A title for the generated markdown file",
    ),
    debug: bool = typer.Option(
        DEBUG,
        "--debug", "-v",
        help="Enable debugging",
    ),
    dry_run: bool = typer.Option(
        DRY_RUN,
        "--dry-run", "-d",
        help="Do not create any files. Prints the generating markdown contents to stdout.",
    ),
):
    global DEBUG, DRY_RUN
    DEBUG = debug
    DRY_RUN = dry_run

    defaults = read_file(in_file)
    parsed = parse_defaults(defaults)
    if not DRY_RUN:
        create_markdown(parsed, title, out_file)


if __name__ == "__main__":
    typer.run(main)
