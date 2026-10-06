"""Check the stdio protocol without a real key, upload, or Gemini request."""
import asyncio
import os
from pathlib import Path
import sys
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


async def main():
    params = StdioServerParameters(
        command=sys.executable,
        args=['-X', 'utf8', str(Path(__file__).with_name('server.py'))],
        env={**os.environ, 'GEMINI_API_KEY': 'local-protocol-test-placeholder'},
    )
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            discovered = await session.list_tools()
            by_name = {tool.name: tool for tool in discovered.tools}
            assert set(by_name) == {'connection_status', 'start_video_analysis', 'analysis_result'}
            assert 'processing' in by_name['start_video_analysis'].inputSchema['properties']
            status = await session.call_tool('connection_status', {})
            assert not status.isError
            invalid = await session.call_tool('start_video_analysis', {
                'source': 'https://example.com/video.mp4', 'prompt': 'test'})
            assert invalid.isError
    print('MCP startup, tool discovery and invalid URL check: PASS')


if __name__ == '__main__':
    asyncio.run(main())
