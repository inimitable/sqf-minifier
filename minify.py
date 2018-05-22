#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
"""Minifies an SQF file."""
from pathlib import Path
from re import sub, compile, DOTALL
import sre_constants

INLINE_COMMENT = compile('//+[^\n]+')
BLOCK_COMMENT = compile('/\*.*?\*/', DOTALL)
NOT_IN_QUOTES_REGEX = r"(?=([^\"\\]*(\\.|\"([^\"\\]*\\.)*[^\"\\]*\"))*[^\"]*$)"


def strip_comments(text: str) -> str:
    """Removes SQF-style comments and block comments."""
    text = sub(INLINE_COMMENT, '', text)
    text = sub(BLOCK_COMMENT, '', text)
    return text


def __safe_regexes() -> dict:
    """Generates some regex replacement rules automatically (based on character types)."""
    repdict = dict()
    needs_escaped = '[]{}()+'
    for char in ',=[];-/{}()<>+':
        escape = fr"\{char}" if char in needs_escaped else char
        repdict[rf' *{escape} *{NOT_IN_QUOTES_REGEX}'] = char

    return repdict


def __compile_regexes(repdict: dict) -> dict:
    """Compiles regex keys of a dictionary, and returns the dictionary with keys compiled."""
    regexes = dict()

    for k, v in repdict.items():
        try:
            regexes[compile(k)] = v
        except sre_constants.error:
            print(f"Fatal error compiling regex: {k}")
            raise

    return regexes


def get_regexes() -> dict:
    """Gets the list of replacement regexes for use in minifying SQF."""
    regexes = __safe_regexes()

    # special cases:
    # remove tabs
    regexes['\n?\t' + NOT_IN_QUOTES_REGEX] = ''
    # remove newlines
    regexes['\n' + NOT_IN_QUOTES_REGEX] = ''

    return __compile_regexes(regexes)


def safe_replacements(text: str) -> str:
    # Perform string-safe replacements.
    regexes = get_regexes()
    for regex, repl in regexes.items():
        try:
            text = sub(regex, repl, text)
        except sre_constants.error:
            print(f"Fatal error using regex {regex} -> {repl} on text")
            raise
    return text


def minify(file_in: (Path, str), file_out: (Path, str, bool, None) = None) -> str:
    """Minifies an SQF file, optionally outputting minified text to a file."""
    file_in = Path(file_in)

    if file_out is None:
        file_out = file_in.parent / f"{file_in.stem}-min{file_in.suffix}"

    with open(file_in) as f:
        text = f.read()

    text = strip_comments(text)
    text = safe_replacements(text)

    if file_out:
        with open(file_out, 'w') as f:
            f.write(text)

    return text


if __name__ == '__main__':
    from sys import argv


    def main(arguments: dict, do_print: bool = False):
        try:
            text = minify(**arguments)
            if do_print:
                # print(len(text))
                print(text)
        except FileNotFoundError:
            print(f"Cannot find file: \"{argv[1]}\"")


    if len(argv) == 3:
        args = {'file_in': argv[1], 'file_out': argv[2]}
        do_print = False
    elif len(argv) == 2:
        args = {'file_in': argv[1], 'file_out': False}
        do_print = True
    else:
        print('minify.py by inimitable\nMinifies an SQF source file.\n\nUsage:\n\tminify.py filename_in [filename_out]')
        quit()

    main(args, do_print)
