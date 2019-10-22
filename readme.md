# SQF Minifier

SQF Minifier is a simple, regex-based minifier for SQF files, found in ArmA, etc.

## Usage

Run the minifier with Python (≥3.6):

    minify.py filename_in [filename_out]

This will produce a minified copy of the file at `filename_in`. If `filename_out` is provided, the minified SQF is written there. Otherwise, the minified code will be returned to `stdout`.

## How well does this work?

At least in my testing, well enough. Thanks to the amazing [SQF linter by LordGolias](https://github.com/LordGolias/sqf), it's possible to command-line test SQF code. If a file passes, its minified code should pass too.
