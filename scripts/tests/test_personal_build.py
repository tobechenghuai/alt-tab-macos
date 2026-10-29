#!/usr/bin/env python3
"""Exercise the personal build with disposable files and fake macOS build tools."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile


ROOT = Path(__file__).resolve().parents[2]


class PersonalBuildTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='alttab-personal-test-')
        self.addCleanup(self.temporary.cleanup)
        self.project = Path(self.temporary.name) / 'project with spaces'
        (self.project / 'scripts/ci').mkdir(parents=True)
        (self.project / 'config').mkdir()
        shutil.copy(ROOT / 'scripts/ci/build.sh', self.project / 'scripts/ci/build.sh')
        shutil.copy(ROOT / 'config/personal.xcconfig', self.project / 'config/personal.xcconfig')
        (self.project / 'config/local.xcconfig').write_text('private-local-setting')
        self.bin = Path(self.temporary.name) / 'bin'
        self.bin.mkdir()
        self.log = self.project / 'commands.jsonl'
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ['PATH'],
                        MOCK_LOG=str(self.log), GITHUB_RUN_NUMBER='42')
        self.mock('xcodebuild', '''from pathlib import Path
app = Path('DerivedData/Build/Products/Release/AltTab.app/Contents/MacOS')
app.mkdir(parents=True)
(app / 'AltTab').write_text('arm64 executable')
''')
        self.mock('lipo', 'pass\n')
        self.mock('codesign', '''if '--display' in sys.argv:
    print('Signature=' + os.environ.get('MOCK_SIGNATURE', 'adhoc'), file=sys.stderr)
''')
        self.mock('ditto', '''from pathlib import Path
import zipfile
app, output = map(Path, sys.argv[-2:])
with zipfile.ZipFile(output, 'w') as archive:
    for path in app.rglob('*'):
        if path.is_file(): archive.write(path, path.relative_to(app.parent))
''')
        self.mock('shasum', '''import hashlib
from pathlib import Path
path = Path(sys.argv[-1])
print(hashlib.sha256(path.read_bytes()).hexdigest() + '  ' + path.name)
''')
        for name in ['security', 'curl', 'gh', 'npm', 'npx']:
            self.mock(name, 'sys.exit("Unexpected credential or publishing tool")\n')

    def mock(self, name, body):
        path = self.bin / name
        prelude = '''import json, os, sys
from pathlib import Path
name = Path(sys.argv[0]).name
with open(os.environ['MOCK_LOG'], 'a') as log:
    log.write(json.dumps([name, *sys.argv[1:]]) + '\\n')
if os.environ.get('FAIL_TOOL') == name: sys.exit(1)
if os.environ.get('FAIL_VERIFY') and '--verify' in sys.argv: sys.exit(1)
'''
        path.write_text('#!/usr/bin/env python3\n' + prelude + body)
        path.chmod(0o755)

    def run_build(self, success=True):
        result = subprocess.run(['bash', 'scripts/ci/build.sh'], cwd=self.project,
                                env=self.env, capture_output=True, text=True)
        self.assertNotIn('private-local-setting', result.stdout + result.stderr)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def commands(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def test_build_packages_only_arm64_app_with_checksum(self):
        self.run_build()
        commands = self.commands()
        build = commands[0]
        self.assertEqual(build[0], 'xcodebuild')
        self.assertEqual(build[build.index('-xcconfig') + 1], 'config/personal.xcconfig')
        self.assertIn('ARCHS=arm64', build)
        self.assertIn('CODE_SIGNING_ALLOWED=YES', build)
        self.assertIn('CURRENT_PROJECT_VERSION=0.0.42', build)
        self.assertEqual(commands[1][0:3], ['lipo', '-verify_arch', 'arm64'])
        self.assertEqual([c[0] for c in commands], ['xcodebuild', 'lipo', 'codesign', 'codesign', 'ditto', 'shasum'])
        artifact = self.project / 'artifacts/AltTab-personal-arm64.zip'
        with zipfile.ZipFile(artifact) as archive:
            self.assertEqual(archive.namelist(), ['AltTab.app/Contents/MacOS/AltTab'])
        digest = hashlib.sha256(artifact.read_bytes()).hexdigest()
        self.assertEqual(Path(str(artifact) + '.sha256').read_text(), digest + '  ' + artifact.name + '\n')

    def test_invalid_build_number_stops_before_build(self):
        self.env['GITHUB_RUN_NUMBER'] = '42/path'
        self.run_build(success=False)
        self.assertEqual(self.commands(), [])

    def test_build_failure_stops_before_packaging(self):
        self.env['FAIL_TOOL'] = 'xcodebuild'
        self.run_build(success=False)
        self.assertEqual([c[0] for c in self.commands()], ['xcodebuild'])
        self.assertFalse((self.project / 'artifacts').exists())

    def test_wrong_architecture_stops_before_signature_and_packaging(self):
        self.env['FAIL_TOOL'] = 'lipo'
        self.run_build(success=False)
        self.assertEqual([c[0] for c in self.commands()], ['xcodebuild', 'lipo'])
        self.assertFalse((self.project / 'artifacts').exists())

    def test_invalid_signature_stops_before_packaging(self):
        self.env['FAIL_VERIFY'] = '1'
        self.run_build(success=False)
        self.assertEqual([c[0] for c in self.commands()], ['xcodebuild', 'lipo', 'codesign'])
        self.assertFalse((self.project / 'artifacts').exists())

    def test_certificate_signature_is_rejected(self):
        self.env['MOCK_SIGNATURE'] = 'certificate'
        self.run_build(success=False)
        self.assertNotIn('ditto', [c[0] for c in self.commands()])

    def test_archive_failure_propagates(self):
        self.env['FAIL_TOOL'] = 'ditto'
        self.run_build(success=False)
        self.assertNotIn('shasum', [c[0] for c in self.commands()])

    def test_personal_signing_configuration_uses_adhoc_identity(self):
        config = (ROOT / 'config/personal.xcconfig').read_text()
        settings = dict(line.split('=', 1) for line in config.splitlines() if '=' in line)
        settings = {key.strip(): value.strip() for key, value in settings.items()}
        self.assertEqual(settings['CODE_SIGN_IDENTITY'], '-')
        self.assertEqual(settings['CODE_SIGN_STYLE'], 'Manual')
        self.assertEqual(settings['DEVELOPMENT_TEAM'], '')
        self.assertEqual(settings['APPCENTER_SECRET'], '')
        self.assertEqual(settings['OTHER_CODE_SIGN_FLAGS'], '--timestamp=none')

    def test_workflow_has_readonly_owner_only_artifact_flow(self):
        workflows = sorted([*(ROOT / '.github/workflows').glob('*.yml'), *(ROOT / '.github/workflows').glob('*.yaml')])
        self.assertEqual([p.name for p in workflows], ['personal-build.yml'])
        workflow = workflows[0].read_text()
        self.assertIn('contents: read', workflow)
        self.assertIn('github.actor == github.repository_owner', workflow)
        self.assertIn('github.triggering_actor == github.repository_owner', workflow)
        self.assertIn('persist-credentials: false', workflow)
        self.assertIn('CODE_SIGNING_ALLOWED=NO', workflow)
        self.assertNotRegex(workflow, r'secrets\.|contents:\s*write|pull_request|environment:|semantic-release|notariz|appcenter|WEBSITE_')
        uses = [line.split('uses:', 1)[1].split('#', 1)[0].strip() for line in workflow.splitlines() if 'uses:' in line]
        self.assertEqual(len(uses), 2)
        for action in uses:
            self.assertRegex(action, r'^actions/(checkout|upload-artifact)@[0-9a-f]{40}$')


if __name__ == '__main__':
    unittest.main()
