#!/usr/bin/env python3
"""Include GPL/source notices and verify the downloadable Custom ZIP."""
from pathlib import Path
import sys
import zipfile


def prepare_archive(path, root):
    required = {'AltTab Custom.app/Contents/Info.plist',
                'AltTab Custom.app/Contents/MacOS/AltTab Custom',
                'AltTab Custom.app/Contents/_CodeSignature/CodeResources'}
    with zipfile.ZipFile(path, 'a', compression=zipfile.ZIP_DEFLATED) as archive:
        if not required.issubset(archive.namelist()):
            raise ValueError('Custom archive is missing required app files')
        for name in ['LICENCE.md', 'CUSTOM_BUILD.md']:
            archive.write(root / name, name)
        damaged = archive.testzip()
        if damaged:
            raise ValueError(f'Damaged ZIP entry: {damaged}')
    if path.stat().st_size == 0:
        raise ValueError('Custom ZIP is empty')


if __name__ == '__main__':
    prepare_archive(Path(sys.argv[1]), Path(__file__).resolve().parents[2])
    print('Custom app ZIP and GPL/source notices verified')
