#!/usr/bin/env python3
"""Regression checks for hosted UI coverage and cached Flutter slice preparation."""
import collections
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class CIContracts(unittest.TestCase):
    def test_shards_cover_ui_once(self):
        expected = []
        for source in (ROOT / 'superDemoAppUITests').glob('*.swift'):
            text = source.read_text()
            if not re.search(r'func test\w+\(', text):
                continue
            cls = re.search(r'class (\w+)\s*:', text).group(1)
            expected += [f'superDemoAppUITests/{cls}/{name}'
                         for name in re.findall(r'func (test\w+)\(', text)
                         if name != 'testLaunchPerformance']
        command = ('source tool/ci_iphone_test_shards.sh; '
                   'for shard in ui-1 ui-2 ui-3 ui-4; do '
                   'ci_iphone_shard_only_testing_args "$shard" || exit; done')
        actual = subprocess.check_output(['bash', '-c', command], cwd=ROOT, text=True)
        actual = [line.removeprefix('-only-testing:') for line in actual.splitlines()]
        self.assertTrue(expected)
        self.assertEqual(collections.Counter(expected), collections.Counter(actual))
        self.assertTrue(all(count == 1 for count in collections.Counter(actual).values()))

    def test_prepared_slices_reuse_and_repair(self):
        # Exercise the actual script with tiny frameworks, no Flutter SDK or build.
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'tool').mkdir()
            (root / 'Config').mkdir()
            (root / 'flutter_module').mkdir()
            script = root / 'tool/prepare_flutter_embed.sh'
            shutil.copy2(ROOT / 'tool/prepare_flutter_embed.sh', script)
            mock_bin = root / 'mock-bin'
            mock_bin.mkdir()
            (mock_bin / 'uname').write_text('#!/bin/sh\necho Darwin\n')
            (mock_bin / 'uname').chmod(0o755)
            env = dict(os.environ, PATH=f'{mock_bin}:{os.environ["PATH"]}')
            for config in ['Debug', 'Release']:
                for name in ['Flutter', 'App', 'FlutterPluginRegistrant']:
                    for sdk in ['ios-arm64', 'ios-arm64_x86_64-simulator']:
                        framework = root / f'Flutter/{config}/{name}.xcframework/{sdk}/{name}.framework'
                        framework.mkdir(parents=True)
                        (framework / name).write_text('fixture binary')

            def run():
                return subprocess.check_output(['bash', str(script), '--skip-build'], env=env, text=True)

            self.assertIn('flatten XCFramework', run())
            binary = root / 'Flutter/Debug/iphonesimulator/App.framework/App'
            timestamp = binary.stat().st_mtime_ns
            self.assertIn('skip binary copies', run())
            self.assertEqual(timestamp, binary.stat().st_mtime_ns)
            # Generated xcconfig must be recreated even when copies are skipped.
            (root / 'Config/FlutterEmbed.local.xcconfig').unlink()
            run()
            self.assertTrue((root / 'Config/FlutterEmbed.local.xcconfig').is_file())
            # Incomplete flattened output and changed preparation logic invalidate reuse.
            shutil.rmtree(binary.parent)
            self.assertIn('flatten XCFramework', run())
            script.write_text(script.read_text() + '\n# preparation version change\n')
            self.assertIn('flatten XCFramework', run())
            # Missing required source fails without leaving a reusable marker.
            shutil.rmtree(root / 'Flutter/Debug/App.xcframework')
            result = subprocess.run(['bash', str(script), '--skip-build'], env=env,
                                    text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            self.assertNotEqual(0, result.returncode)
            self.assertFalse((root / 'Flutter/.prepared-slices').exists())


if __name__ == '__main__':
    unittest.main()
