#!/usr/bin/env python3
"""
Task Delegation CLI
Usage:
  python3 delegation_cli.py list                    # List my tasks
  python3 delegation_cli.py claim <task_id>           # Claim a task
  python3 delegation_cli.py complete <task_id>       # Mark complete
  python3 delegation_cli.py delegate <task_id> <nuc> # Delegate to NUC
"""

import sys
import json
import requests
import os

HUB_URL = os.environ.get('HUB_URL', 'http://100.80.211.39:8090')
NODE_NAME = os.environ.get('NODE_NAME', 'x2-nuc')

def get_tasks():
    r = requests.get(f'{HUB_URL}/api/tasks')
    return r.json().get('tasks', [])

def list_my_tasks():
    tasks = get_tasks()
    my_tasks = [t for t in tasks if t.get('assignee') == NODE_NAME]
    print(f"\n=== Tasks for {NODE_NAME} ===")
    for t in my_tasks:
        print(f"{t['id']}: {t['title']} [{t.get('status', 'pending')}]")
    if not my_tasks:
        print("No assigned tasks")
    print()

def list_unassigned():
    tasks = get_tasks()
    unassigned = [t for t in tasks if not t.get('assignee')]
    print(f"\n=== Unassigned Tasks ===")
    for t in unassigned:
        print(f"{t['id']}: {t['title']}")
    print()

def claim_task(task_id):
    r = requests.patch(f'{HUB_URL}/api/tasks/{task_id}', 
                      json={'assignee': NODE_NAME, 'status': 'in_progress'})
    if r.status_code == 200:
        print(f"✓ Claimed {task_id}")
    else:
        print(f"✗ Error: {r.text}")

def complete_task(task_id):
    r = requests.patch(f'{HUB_URL}/api/tasks/{task_id}', 
                      json={'status': 'completed'})
    if r.status_code == 200:
        print(f"✓ Completed {task_id}")
    else:
        print(f"✗ Error: {r.text}")

def delegate_task(task_id, nuc):
    r = requests.patch(f'{HUB_URL}/api/tasks/{task_id}',
                      json={'assignee': nuc, 'status': 'delegated'})
    if r.status_code == 200:
        print(f"✓ Delegated {task_id} to {nuc}")
    else:
        print(f"✗ Error: {r.text}")

def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    
    cmd = sys.argv[1]
    
    if cmd == 'list':
        list_my_tasks()
    elif cmd == 'unassigned':
        list_unassigned()
    elif cmd == 'claim':
        if len(sys.argv) < 3:
            print("Usage: claim <task_id>")
            return
        claim_task(sys.argv[2])
    elif cmd == 'complete':
        if len(sys.argv) < 3:
            print("Usage: complete <task_id>")
            return
        complete_task(sys.argv[2])
    elif cmd == 'delegate':
        if len(sys.argv) < 4:
            print("Usage: delegate <task_id> <nuc>")
            return
        delegate_task(sys.argv[2], sys.argv[3])
    else:
        print(f"Unknown command: {cmd}")

if __name__ == '__main__':
    main()
