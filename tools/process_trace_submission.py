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
    
    # Write JSON with indentation
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(entry, f, indent=2)
    
    return output_path, filename

def main():
    parser = argparse.ArgumentParser(description='Process JSON trace submissions')
    parser.add_argument('--input', required=True, help='JSON string or file path')
    parser.add_argument('--dest', default='contributions/autosave-traces/', 
                       help='Output directory')
    parser.add_argument('--dry-run', action='store_true', 
                       help='Show what would be created without writing')
    args = parser.parse_args()
    
    try:
        data = parse_input(args.input)
    except Exception as e:
        print(f"Error parsing input: {e}")
        sys.exit(1)
    
    # Ensure data is a list
    if not isinstance(data, list):
        data = [data]
    
    print(f"Processing {len(data)} trace entries...")
    
    results = []
    for i, entry in enumerate(data, 1):
        if args.dry_run:
            filename = generate_filename(entry, i, len(data))
            print(f"[{i}/{len(data)}] Would create: {filename}")
            print(f"  Agent: {entry.get('agent') or entry.get('contributor')}")
            print(f"  Build: {entry.get('build')}")
            print(f"  Event: {entry.get('event') or entry.get('tag')}")
            print()
        else:
            output_path, filename = process_entry(entry, args.dest, i, len(data))
            results.append((filename, output_path))
    
    if not args.dry_run and results:
        print(f"\nCreated {len(results)} files in {args.dest}:")
        for filename, path in results:
            print(f"  • {filename}")
        
        # Update README with new files
        readme_path = os.path.join(args.dest, 'README.md')
        if os.path.exists(readme_path):
            print(f"\nNote: Update {readme_path} manually with new file entries.")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
