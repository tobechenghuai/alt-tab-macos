#!/usr/bin/env python3
"""Static contracts for the real app sources; runtime behavior is covered by Swift tests."""
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]


class CustomFeatureSourceTests(unittest.TestCase):
    def test_runtime_sources_keep_local_features_independent_of_commercial_state(self):
        gates = r'\b(?:LicenseManager|LicenseStatus|ProFeature|isProLocked|trialExpired|requiresPro|canUseProFeatures)\b'
        for path in (ROOT / 'src').rglob('*.swift'):
            if path.name.endswith('Tests.swift') or '_test-support' in path.parts:
                continue
            code = re.sub(r'/\*.*?\*/|//[^\n]*', '', path.read_text(), flags=re.S)
            self.assertNotRegex(code, gates, str(path))

    def test_production_preferences_and_controls_expose_every_style_and_size(self):
        macros = (ROOT / 'src/preferences/MacroPreferences.swift').read_text()
        for name, expected in [('AppearanceStylePreference', ['thumbnails', 'appIcons', 'titles']),
                               ('AppearanceSizePreference', ['small', 'medium', 'large', 'auto'])]:
            body = macros.split('enum ' + name + ':', 1)[1].split('var localizedString:', 1)[0]
            self.assertEqual(re.findall(r'^\s+case (\w+)', body, re.M), expected)
        controls = (ROOT / 'src/preferences/settings-window/tabs/appearance/AppearanceTab.swift').read_text()
        self.assertIn('AppearanceStylePreference.allCases', controls)
        self.assertIn('AppearanceSizePreference.allCases', controls)
        preferences = (ROOT / 'src/preferences/Preferences.swift').read_text()
        self.assertRegex(preferences, r'static let maxShortcutCount\s*=\s*9\b')
        for name in ['Style', 'Size', 'Theme']:
            self.assertIn('effectiveAppearance' + name, preferences)

    def test_custom_schema_marker_is_newer_than_all_legacy_migrations(self):
        source = (ROOT / 'src/preferences/PreferencesMigrations.swift').read_text()
        marker = re.search(r'#if CUSTOM_BUILD[\s\S]*?return "([0-9.]+)"', source).group(1)
        thresholds = re.findall(r'\("([0-9]+\.[0-9]+\.[0-9]+)",', source)
        version = lambda text: tuple(map(int, text.split('.')))
        self.assertGreater(version(marker), max(map(version, thresholds)))
        self.assertIn('Self.defaults.set(currentVersion, forKey: preferencesKey)', source)


if __name__ == '__main__':
    unittest.main()
