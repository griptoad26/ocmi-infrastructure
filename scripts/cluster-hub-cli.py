#!/usr/bin/env python3
"""Cluster Hub CLI - Client for Cluster Hub Server"""

import os, sys, json, requests, argparse

HUB_URL = os.environ.get('CLUSTER_HUB_URL', 'http://100.80.211.39:8090')

def files_list():
    r = requests.get(f'{HUB_URL}/api/files/list')
    data = r.json()
    print(f"Files ({data['count']}):")
    for f in data['files']:
        print(f"  {f['name']}")

def file_push(filenames):
    for fname in filenames:
        if os.path.isfile(fname):
            with open(fname) as f:
                content = f.read()
            name = os.path.basename(fname)
            r = requests.put(f'{HUB_URL}/api/files/{name}', json={'content': content})
            print(f"  ✅ {name}")

def file_pull(filenames=None):
    r = requests.get(f'{HUB_URL}/api/files/list')
    hub_files = {f['name']: f for f in r.json()['files']}
    to_get = filenames or list(hub_files.keys())
    for name in to_get:
        if name in hub_files:
            r = requests.get(f'{HUB_URL}/api/files/{name}')
            with open(name, 'w') as f:
                f.write(r.text)
            print(f"  ✅ {name}")

def task_list():
    r = requests.get(f'{HUB_URL}/api/tasks')
    tasks = r.json().get('tasks', [])
    print(f"Tasks ({len(tasks)}):")
    for t in tasks:
        print(f"  {t['id']}: {t.get('title', 'Untitled')}")

def task_create(title, **kwargs):
    r = requests.post(f'{HUB_URL}/api/tasks', json={'title': title, **kwargs})
    print(f"✅ Created: {r.json()['id']}")

def task_update(task_id, **kwargs):
    r = requests.patch(f'{HUB_URL}/api/tasks/{task_id}', json=kwargs)
    print(f"✅ Updated: {task_id}")

def register():
    import platform, socket
    r = requests.post(f'{HUB_URL}/api/nodes/register', json={
        'hostname': socket.gethostname(),
        'os': platform.system() + ' ' + platform.release()
    })
    print(f"✅ Registered: {r.json()['node_id']}")

def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers()
    sub.add_parser('files', help='List files').set_defaults(cmd=files_list)
    push = sub.add_parser('push', help='Push files'); push.add_argument('files', nargs='+')
    push.set_defaults(cmd=lambda a: [file_push(a.files)])
    pull = sub.add_parser('pull', help='Pull files'); pull.add_argument('files', nargs='*')
    pull.set_defaults(cmd=lambda a: file_pull(a.files))
    sub.add_parser('task-list', help='List tasks').set_defaults(cmd=task_list)
    create = sub.add_parser('task-create', help='Create task'); create.add_argument('title')
    create.set_defaults(cmd=lambda a: task_create(a.title))
    sub.add_parser('register', help='Register node').set_defaults(cmd=register)
    
    args = p.parse_args()
    if hasattr(args, 'cmd'):
        args.cmd(args)
    else:
        p.print_help()

if __name__ == '__main__':
    main()
