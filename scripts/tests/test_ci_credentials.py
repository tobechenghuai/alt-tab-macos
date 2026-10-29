#!/usr/bin/env python3
"""Exercise credential handling with fake signing tools and disposable workspaces."""
import base64
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


class CredentialHandlingTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='alttab-ci-test-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.project = self.root / 'project'
        self.project.mkdir()
        (self.project / 'scripts').mkdir()
        shutil.copytree(ROOT / 'scripts/codesign', self.project / 'scripts/codesign')
        for name in ['print_env.sh', 'replace_environment_variables_in_app.sh', 'package_and_notarize_release.sh', 'upload_symbols_to_appcenter.sh']:
            shutil.copy(ROOT / 'scripts' / name, self.project / 'scripts' / name)
        (self.project / 'config').mkdir()
        (self.project / 'VERSION.txt').write_text('1.2.3\n')
        (self.project / 'products').mkdir()
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.runner = self.root / 'runner temp'
        self.runner.mkdir()
        self.envfile = self.root / 'github-env'
        self.envfile.touch()
        self.log = self.root / 'commands.jsonl'
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ['PATH'],
                        RUNNER_TEMP=str(self.runner), GITHUB_ENV=str(self.envfile), MOCK_LOG=str(self.log),
                        APPLE_P12_CERTIFICATE=base64.b64encode(b'private-signing-material').decode(),
                        APPLE_PASSWORD='private-apple-password', APPLE_ID='ci@example.test', APPLE_TEAM_ID='TEAM123',
                        APPCENTER_SECRET='private-appcenter-value', APPCENTER_TOKEN='private-appcenter-token',
                        GITHUB_TOKEN='private-github-token', VERSION_FILE='VERSION.txt', APP_NAME='AltTab',
                        XCODE_BUILD_PATH='products')
        self.mock('security', '''import json, os, sys
from pathlib import Path
args = sys.argv[1:]
with open(os.environ['MOCK_LOG'], 'a') as log: log.write(json.dumps(args) + '\\n')
if os.environ.get('FAIL_SECURITY_ON') == args[0]: sys.exit(1)
if args[0] == 'create-keychain': Path(args[-1]).touch()
elif args[0] == 'delete-keychain': Path(args[-1]).unlink(missing_ok=True)
elif args[0] == 'list-keychains' and '-s' not in args: print('    "/Users/Test User/Library/Keychains/login.keychain-db"')
elif args[0] == 'default-keychain': sys.exit('Default keychain must stay unchanged')
''')
        self.mock('jq', '''import json, sys
if sys.argv[1:] == ['--version']: print('jq-test')
else: print(json.load(sys.stdin)[sys.argv[-1].lstrip('.')])
''')

    def mock(self, name, body):
        path = self.bin / name
        path.write_text('#!/usr/bin/env python3\n' + body)
        path.chmod(0o755)

    def run_script(self, name, *arguments, success=True):
        result = subprocess.run(['bash', '-x', 'scripts/' + name, *arguments], cwd=self.project,
                                env=self.env, capture_output=True, text=True)
        for name in ['APPLE_P12_CERTIFICATE', 'APPLE_PASSWORD', 'APPCENTER_SECRET', 'APPCENTER_TOKEN', 'GITHUB_TOKEN']:
            self.assertNotIn(self.env[name], result.stdout + result.stderr, 'Credential appeared in output: ' + name)
        self.assertNotIn('private-signing-material', result.stdout + result.stderr)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def signing_directory(self):
        entry = self.envfile.read_text().splitlines()[-1]
        key, value = entry.split('=', 1)
        self.assertEqual(key, 'ALT_TAB_SIGNING_DIR')
        self.env[key] = value
        return Path(value)

    def test_environment_report_uses_allowlist(self):
        result = self.run_script('print_env.sh')
        self.assertIn('APP_NAME=AltTab', result.stdout)
        self.assertNotRegex(result.stdout, r'(?m)^PATH=')

    def test_signing_uses_private_keychain_and_preserves_search_paths(self):
        result = self.run_script('codesign/setup_ci_master.sh')
        directory = self.signing_directory()
        self.assertEqual(directory.stat().st_mode & 0o777, 0o700)
        self.assertEqual(list(self.runner.glob('alttab-certificate.*')), [])
        commands = [json.loads(line) for line in self.log.read_text().splitlines()]
        create = next(c for c in commands if c[0] == 'create-keychain')
        self.assertRegex(create[2], r'^[a-f0-9]{64}$')
        self.assertNotIn(create[2], result.stdout + result.stderr)
        search = next(c for c in commands if c[:4] == ['list-keychains', '-d', 'user', '-s'])
        self.assertIn('/Users/Test User/Library/Keychains/login.keychain-db', search)
        imported = next(c for c in commands if c[0] == 'import')
        self.assertEqual(imported[imported.index('-k') + 1], str(directory / 'signing.keychain-db'))
        self.run_script('codesign/cleanup_ci.sh')
        self.assertFalse(directory.exists())
        self.run_script('codesign/cleanup_ci.sh')

    def test_import_failure_cleans_both_private_directories(self):
        self.env['FAIL_SECURITY_ON'] = 'import'
        self.run_script('codesign/setup_ci_master.sh', success=False)
        self.assertEqual(list(self.runner.iterdir()), [])

    def test_generated_config_is_restored_after_signing(self):
        original = 'CODE_SIGN_IDENTITY = Stable Developer ID\n'
        config = self.project / 'config/local.xcconfig'
        config.write_text(original)
        self.run_script('codesign/setup_ci_master.sh')
        self.signing_directory()
        self.run_script('replace_environment_variables_in_app.sh')
        self.assertIn('CURRENT_PROJECT_VERSION = 1.2.3', config.read_text())
        self.run_script('codesign/cleanup_ci.sh')
        self.assertEqual(config.read_text(), original)

    def test_cleanup_removes_new_config_and_refuses_foreign_directory(self):
        self.run_script('codesign/setup_ci_master.sh')
        self.signing_directory()
        self.run_script('replace_environment_variables_in_app.sh')
        self.run_script('codesign/cleanup_ci.sh')
        self.assertFalse((self.project / 'config/local.xcconfig').exists())
        self.run_script('codesign/cleanup_ci.sh', str(self.project), success=False)
        self.assertTrue(self.project.exists())

    def test_restore_failure_preserves_backup_and_cleans_keychain_before_retry(self):
        config = self.project / 'config/local.xcconfig'
        original = 'CODE_SIGN_IDENTITY = Stable Developer ID\n'
        config.write_text(original)
        self.run_script('codesign/setup_ci_master.sh')
        directory = self.signing_directory()
        self.run_script('replace_environment_variables_in_app.sh')
        self.mock('cp', 'import sys\nsys.exit(1)\n')
        result = self.run_script('codesign/cleanup_ci.sh', success=False)
        self.assertIn(str(directory), result.stderr)
        self.assertEqual((directory / 'local.xcconfig.original').read_text(), original)
        self.assertTrue((directory / 'local.xcconfig.generated').exists())
        self.assertFalse((directory / 'signing.keychain-db').exists())
        (self.bin / 'cp').unlink()
        self.run_script('codesign/cleanup_ci.sh')
        self.assertEqual(config.read_text(), original)
        self.assertFalse(directory.exists())

    def test_config_removal_failure_preserves_cleanup_state_for_retry(self):
        self.run_script('codesign/setup_ci_master.sh')
        directory = self.signing_directory()
        self.run_script('replace_environment_variables_in_app.sh')
        self.mock('rm', 'import sys\nsys.exit(1)\n')
        self.run_script('codesign/cleanup_ci.sh', success=False)
        self.assertTrue((self.project / 'config/local.xcconfig').exists())
        self.assertTrue((directory / 'local.xcconfig.generated').exists())
        self.assertFalse((directory / 'signing.keychain-db').exists())
        (self.bin / 'rm').unlink()
        self.run_script('codesign/cleanup_ci.sh')
        self.assertFalse((self.project / 'config/local.xcconfig').exists())
        self.assertFalse(directory.exists())

    def test_keychain_removal_failure_retains_keychain_and_allows_retry(self):
        config = self.project / 'config/local.xcconfig'
        config.write_text('original configuration\n')
        self.run_script('codesign/setup_ci_master.sh')
        directory = self.signing_directory()
        self.run_script('replace_environment_variables_in_app.sh')
        self.env['FAIL_SECURITY_ON'] = 'delete-keychain'
        self.run_script('codesign/cleanup_ci.sh', success=False)
        self.assertTrue((directory / 'signing.keychain-db').exists())
        commands = [json.loads(line) for line in self.log.read_text().splitlines()]
        self.assertIn(['lock-keychain', str(directory / 'signing.keychain-db')], commands)
        self.assertEqual(config.read_text(), 'original configuration\n')
        self.assertFalse((directory / 'local.xcconfig.generated').exists())
        config.write_text('subsequent local change\n')
        del self.env['FAIL_SECURITY_ON']
        self.run_script('codesign/cleanup_ci.sh')
        self.assertEqual(config.read_text(), 'subsequent local change\n')
        self.assertFalse(directory.exists())

    def test_directory_removal_failure_is_reported_and_can_be_retried(self):
        self.run_script('codesign/setup_ci_master.sh')
        directory = self.signing_directory()
        self.mock('rm', '''from pathlib import Path
import sys
(Path(sys.argv[-1]) / 'owned-by-alttab-ci').unlink()
sys.exit(1)
''')
        result = self.run_script('codesign/cleanup_ci.sh', success=False)
        self.assertIn(str(directory), result.stderr)
        self.assertTrue(directory.exists())
        self.assertTrue((directory / 'owned-by-alttab-ci').exists())
        self.assertFalse((directory / 'signing.keychain-db').exists())
        (self.bin / 'rm').unlink()
        self.run_script('codesign/cleanup_ci.sh')
        self.assertFalse(directory.exists())

    def test_notarization_credentials_stay_out_of_trace(self):
        self.mock('ditto', 'from pathlib import Path\nimport sys\nPath(sys.argv[-1]).touch()\n')
        self.mock('xcrun', 'pass\n')
        tool = self.project / 'scripts/notarytool'
        tool.write_text('#!/bin/sh\nprintf "  status: Accepted\\n"\n')
        tool.chmod(0o755)
        self.run_script('package_and_notarize_release.sh')
        self.assertTrue((self.project / 'products/AltTab-1.2.3.zip').exists())

    def test_cleanup_rejects_symlinks_and_parent_traversal(self):
        (self.project / 'owned-by-alttab-ci').touch()
        alias = self.runner / 'alttab-signing.link'
        alias.symlink_to(self.project, target_is_directory=True)
        self.run_script('codesign/cleanup_ci.sh', str(alias), success=False)
        directory = self.runner / 'alttab-signing.fake'
        directory.mkdir()
        traversal = str(directory) + '/../../project'
        self.run_script('codesign/cleanup_ci.sh', traversal, success=False)
        self.assertTrue((self.project / 'owned-by-alttab-ci').exists())

    def test_symbol_upload_tokens_and_signed_url_stay_out_of_trace(self):
        self.mock('ditto', 'pass\n')
        self.mock('curl', '''import json, sys
if 'POST' in sys.argv: print(json.dumps({'symbol_upload_id': 'test-id', 'upload_url': 'https://upload.example.test/private-signature'}))
''')
        result = self.run_script('upload_symbols_to_appcenter.sh')
        self.assertNotIn('private-signature', result.stdout + result.stderr)

    def test_workflow_limits_secret_environment_to_steps(self):
        workflow = (ROOT / '.github/workflows/ci_cd.yml').read_text()
        self.assertNotIn('secrets.', workflow.split('\njobs:', 1)[0])
        for line in workflow.splitlines():
            if 'secrets.' in line:
                self.assertGreaterEqual(len(line) - len(line.lstrip()), 10, line)
        self.assertIn('persist-credentials: false', workflow)
        self.assertRegex(workflow, r'if: \$\{\{ always\(\) \}\}\n\s+run: scripts/codesign/cleanup_ci.sh')


if __name__ == '__main__':
    unittest.main()
