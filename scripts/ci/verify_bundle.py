#!/usr/bin/env python3
"""Validate the identity and runnable structure of a Custom application bundle."""
from pathlib import Path
import os
import plistlib
import sys


def verify_bundle(app):
    with (app / 'Contents/Info.plist').open('rb') as file:
        info = plistlib.load(file)
    expected = {'CFBundleIdentifier': 'com.tobechenghuai.alttab-custom',
                'CFBundleName': 'AltTab Custom', 'CFBundleExecutable': 'AltTab Custom',
                'CFBundlePackageType': 'APPL', 'AppCenterSecret': ''}
    for key, value in expected.items():
        if info.get(key) != value:
            raise ValueError(f'Unexpected {key} in Custom bundle')
    executable = app / 'Contents/MacOS' / info['CFBundleExecutable']
    if not executable.is_file() or not os.access(executable, os.X_OK):
        raise ValueError('Custom executable is missing or lacks execute permission')
    if not (app / 'Contents/_CodeSignature/CodeResources').is_file():
        raise ValueError('Bundle signature resources are missing')
    return info


if __name__ == '__main__':
    verify_bundle(Path(sys.argv[1]))
    print('Custom bundle identity, executable, and signature resources verified')
