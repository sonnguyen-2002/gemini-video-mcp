import json
from pathlib import Path
from tempfile import TemporaryDirectory
from types import SimpleNamespace
import unittest
from unittest.mock import MagicMock, patch

import server


class VideoTests(unittest.TestCase):
    def setUp(self):
        server.JOBS.clear()

    def test_only_supported_youtube_urls(self):
        self.assertIsNone(server.validate_source('https://youtu.be/example'))
        for url in ('http://youtube.com/watch?v=x', 'https://youtube.com.evil.test/x',
                    'https://user:pass@youtube.com/watch?v=x', 'https://example.com/x.mp4'):
            with self.assertRaises(ValueError):
                server.validate_source(url)

    def test_local_file_validation(self):
        with TemporaryDirectory() as directory:
            video = Path(directory) / 'clip.mp4'
            video.write_bytes(b'fake-video')
            self.assertEqual(server.validate_source(str(video)), video)
            video.write_bytes(b'')
            with self.assertRaises(ValueError):
                server.validate_source(str(video))

    def test_agentic_result_saved_and_upload_deleted(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            video = root / 'clip.mp4'
            video.write_bytes(b'fake-video')
            uploaded = SimpleNamespace(name='files/test', uri='test-uri', mime_type='video/mp4',
                                       state=SimpleNamespace(name='ACTIVE'))
            client = MagicMock()
            client.files.upload.return_value = uploaded
            client.interactions.create.return_value = SimpleNamespace(
                output_text='Phan tich thu nghiem', steps=[SimpleNamespace(type='processing_call'),
                    SimpleNamespace(type='processing_result')])
            server.JOBS['test'] = {'job_id': 'test', 'status': 'running'}
            with patch.object(server, 'ROOT', root), patch.object(server, 'load_key', return_value='fake-key'), \
                    patch.object(server.genai, 'Client', return_value=client):
                server.analyze('test', str(video), 'Phan tich', 'test-model')
            result = server.analysis_result('test')
            self.assertEqual(result['status'], 'completed')
            self.assertTrue(result['agentic_verified'])
            self.assertEqual((root / 'results/test.md').read_text(encoding='utf-8'), 'Phan tich thu nghiem')
            self.assertEqual(json.loads((root / 'results/test.json').read_text(encoding='utf-8'))['status'], 'completed')
            call = client.interactions.create.call_args.kwargs
            self.assertEqual(call['input'][0]['processing'], 'agentic')
            self.assertFalse(call['store'])
            client.files.delete.assert_called_once_with(name='files/test')
            client.close.assert_called_once()

    def test_failure_redacts_key_and_deletes_upload(self):
        with TemporaryDirectory() as directory:
            video = Path(directory) / 'clip.mp4'
            video.write_bytes(b'fake-video')
            client = MagicMock()
            client.files.upload.return_value = SimpleNamespace(name='files/test', uri='test-uri',
                mime_type='video/mp4', state=SimpleNamespace(name='ACTIVE'))
            client.interactions.create.side_effect = RuntimeError('failed fake-key')
            server.JOBS['test'] = {'job_id': 'test', 'status': 'running'}
            with patch.object(server, 'load_key', return_value='fake-key'), \
                    patch.object(server.genai, 'Client', return_value=client):
                server.analyze('test', str(video), 'test', 'test-model')
            result = server.analysis_result('test')
            self.assertEqual(result['status'], 'failed')
            self.assertNotIn('fake-key', result['error'])
            client.files.delete.assert_called_once()
            client.close.assert_called_once()


if __name__ == '__main__':
    unittest.main()
