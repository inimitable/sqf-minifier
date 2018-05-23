#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
"""SQF Minifier tests."""
from pathlib import Path

from sqflinter.sqflint import Writer, analyze
from minify import minify_code
from unittest import TestCase

TEST_FILE = 'demo.sqf'

def test(code: (Path, str), status='success'):
    w = Writer()

    if len(code) < 255 and ('/' in code or '\\' in code):  # maybe a path?
        try:
            with open(code) as f:
                code = f.read()
        except FileNotFoundError:
            pass

    analyze(code, w)

    stat_out = 'success'
    for err in w.strings:
        if any([j in err for j in ['error']]):
            stat_out = 'fail'

    return status == stat_out


test_files = {'demos/demo.sqf': 'success'}

class TestMinifier(TestCase):

    def test_demo_files(self):
        for file, status in test_files.items():
            with open(file) as f:
                code = f.read()
                self.assertTrue(test(code, status))
                minified = minify_code(code)
                self.assertTrue(test(minified, status))
