#!/usr/bin/env python3
"""
Process JSON trace submissions from chat and create standardized files.

Usage:
  python3 tools/process_trace_submission.py --input <json_file_or_string> --dest contributions/autosave-traces/
  
  Or copy-paste JSON from chat and pass as string.
"""

import argparse
import json
import os
import sys
import re
import time
from datetime import datetime
from pathlib import Path

def parse_input(input_arg):
    """Parse input: could be a JSON string or file path."""
    # Try as file
    if os.path.exists(input_arg):
        with open(input_arg, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    # Try as JSON string
    try:
        return json.loads(input_arg)
    except json.JSONDecodeError:
        # Try to extract JSON from text with code fences
        json_match = re.search(r'```(?:json)?\s*(\[\s*\{.*\}\s*\])', input_arg, re.DOTALL)
        if json_match:
            return json.loads(json_match.group(1))
        raise ValueError("Could not parse JSON from input")

def generate_filename(entry, index, total):
    """Generate standardized filename based on entry metadata."""
    # Extract metadata
    agent = entry.get('agent') or entry.get('contributor') or 'unknown'
    build = entry.get('build', 'unknown')
    event = entry.get('event') or entry.get('tag', f'trace_{index}')
    date = datetime.now().strftime('%Y-%m-%d')
    
    # Clean strings for filename
    def clean(s):
        return re.sub(r'[^\w\-]', '_', str(s).lower())
    
    agent_clean = clean(agent.replace(' ', '-'))
    build_clean = clean(build)
    event_clean = clean(event)
    
    return f"{date}_{agent_clean}_{build_clean}_{event_clean}.json"

def process_entry(entry, output_dir, index, total):
    """Process a single trace entry and save to file."""
    filename = generate_filename(entry, index, total)
    output_path = os.path.join(output_dir, filename)
    
    # Ensure directory exists
    os.makedirs(output_dir, exist_ok=True)

    if os.path.exists(output_path):
        print(f"Warning: {filename} already exists, skipping.")
        return output_path, filename, False
    
    # Write JSON with indentation
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(entry, f, indent=2)
    
    return output_path, filename, True


def acquire_lock(lock_path: Path, timeout: int = 10) -> bool:
    print("Acquiring lock...")
    start = time.time()
    while True:
        try:
            fd = os.open(lock_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            with os.fdopen(fd, 'w') as f:
                f.write(f"PID: {os.getpid()}\nTimestamp: {datetime.now().isoformat()}\n")
            print(f"Lock acquired (PID {os.getpid()})")
            return True
        except FileExistsError:
            if time.time() - start >= timeout:
                return False
            time.sleep(1)


def release_lock(lock_path: Path):
    print("Releasing lock...")
    try:
        os.remove(lock_path)
    except FileNotFoundError:
        pass

def main():
    parser = argparse.ArgumentParser(description='Process JSON trace submissions')
    parser.add_argument('--input', required=True, help='JSON string or file path')
    parser.add_argument('--dest', default='contributions/autosave-traces/', 
                       help='Output directory')
    parser.add_argument('--dry-run', action='store_true', 
                       help='Show what would be created without writing')
    parser.add_argument('--skip-lock', action='store_true',
                       help='Skip the lock file (emergency use only)')
    args = parser.parse_args()
    
    lock_path = Path(__file__).parent / '.trace_processing_lock'
    lock_acquired = False
    
    try:
        if not args.dry_run and not args.skip_lock:
            lock_acquired = acquire_lock(lock_path)
            if not lock_acquired:
                print("Failed to acquire lock within 10 seconds.", file=sys.stderr)
                return 1
        
        try:
            data = parse_input(args.input)
        except Exception as e:
            print(f"Error parsing input: {e}")
            return 1
        
        # Ensure data is a list
        if not isinstance(data, list):
            data = [data]
        
        print(f"Processing {len(data)} trace entries...")
        
        results = []
        skipped_duplicates = 0
        for i, entry in enumerate(data, 1):
            if args.dry_run:
                filename = generate_filename(entry, i, len(data))
                print(f"[{i}/{len(data)}] Would create: {filename}")
                print(f"  Agent: {entry.get('agent') or entry.get('contributor')}")
                print(f"  Build: {entry.get('build')}")
                print(f"  Event: {entry.get('event') or entry.get('tag')}")
                print()
            else:
                output_path, filename, created = process_entry(entry, args.dest, i, len(data))
                if created:
                    results.append((filename, output_path))
                else:
                    skipped_duplicates += 1
        
        if not args.dry_run and results:
            print(f"\nCreated {len(results)} files in {args.dest}:")
            for filename, path in results:
                print(f"  • {filename}")
            
            # Update README with new files
            readme_path = os.path.join(args.dest, 'README.md')
            if os.path.exists(readme_path):
                print(f"\nNote: Update {readme_path} manually with new file entries.")
        
        if skipped_duplicates:
            print(f"Skipped {skipped_duplicates} duplicate file(s).")
    finally:
        if lock_acquired:
            release_lock(lock_path)
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
