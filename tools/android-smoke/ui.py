"""Tiny uiautomator driver for the Android smoke run: `show`, `tap <needle>...`, `wait <needle>`.
Prints only UI text/labels (no screenshots) so a run can be read from the job log."""
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET


def dump():
    subprocess.run(['adb', 'shell', 'uiautomator', 'dump', '/sdcard/ui.xml'], capture_output=True)
    subprocess.run(['adb', 'pull', '/sdcard/ui.xml', '/tmp/ui.xml'], capture_output=True)
    try:
        return ET.parse('/tmp/ui.xml').getroot()
    except Exception:
        return None


def nodes(root):
    for node in root.iter('node'):
        text, desc = node.get('text') or '', node.get('content-desc') or ''
        numbers = list(map(int, re.findall(r'\d+', node.get('bounds') or '0,0,0,0')))
        if len(numbers) == 4:
            yield text, desc, node.get('class') or '', node.get('clickable') == 'true', numbers


def show():
    root = dump()
    if root is None:
        print('  (no UI hierarchy: app not showing / dump failed)')
        return
    count = 0
    for text, desc, cls, clickable, (l, t, r, b) in nodes(root):
        if text or desc:
            count += 1
            print(f'  [{l},{t},{r},{b}] {"*" if clickable else " "} text={text!r} desc={desc!r} {cls.split(".")[-1]}')
    if count == 0:
        print('  (hierarchy has no text/labels)')


def find(needles):
    root = dump()
    if root is None:
        return None
    for needle in needles:
        for text, desc, _cls, _clickable, (l, t, r, b) in nodes(root):
            if needle.lower() in text.lower() or needle.lower() in desc.lower():
                return needle, ((l + r) // 2, (t + b) // 2)
    return None


def main():
    command, args = sys.argv[1], sys.argv[2:]
    if command == 'show':
        show()
    elif command in ('tap', 'wait'):
        deadline = time.time() + 25
        while time.time() < deadline:
            hit = find(args)
            if hit:
                if command == 'tap':
                    subprocess.run(['adb', 'shell', 'input', 'tap', str(hit[1][0]), str(hit[1][1])])
                print(f'  {command} ok: {hit[0]!r} at {hit[1]}')
                return
            time.sleep(1.5)
        print(f'  {command} FAILED: none of {args} on screen')
        sys.exit(1)


main()
