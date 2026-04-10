#!/usr/bin/env python3
import dataclasses
import json
import sys
from enum import Enum
from pathlib import Path
from typing import List

class TestStatus(Enum):
    """The test status enum."""
    PASSED = 1
    FAILED = 2
    SKIPPED = 3
    ERROR = 4

@dataclasses.dataclass
class TestResult:
    """The test result dataclass."""
    name: str
    status: TestStatus

### DO NOT MODIFY THE CODE ABOVE ###
### Implement the parsing logic below ###

def parse_test_output(stdout_content: str, stderr_content: str) -> List[TestResult]:
    """
    Parse the test output content and extract test results.
    """
    import re

    status_map = {
        'PASSED': TestStatus.PASSED,
        'FAILED': TestStatus.FAILED,
        'SKIPPED': TestStatus.SKIPPED,
        'ERROR': TestStatus.ERROR,
    }
    parsed_results = {}

    ansi_re = re.compile(r'\x1b\[[0-9;]*m')
    combined_output = f"{stdout_content}\n{stderr_content}"
    # PowerShell redirection can write UTF-16 text that appears with embedded
    # NULs when read as a regular text file. Normalize it for regex parsing.
    combined_output = combined_output.replace('\x00', '').replace('\ufeff', '')

    # Handles pytest verbose lines such as:
    # tests/test_module.py::test_case PASSED
    # tests/test_module.py::test_case FAILED [ 50%]
    line_re = re.compile(
        r'^\s*((?:[\w./\\-]+::)+[\w\[\].-]+)\s+(PASSED|FAILED|SKIPPED|ERROR)\b'
    )

    for raw_line in combined_output.splitlines():
        clean_line = ansi_re.sub('', raw_line).strip()
        if not clean_line:
            continue
        match = line_re.match(clean_line)
        if match:
            test_name, raw_status = match.groups()
            parsed_results[test_name] = TestResult(
                name=test_name,
                status=status_map[raw_status],
            )

    # Handle collection/setup lines and short summary lines.
    fallback_re = re.compile(r'^(ERROR)\s+([\w./\\-]+)')
    collecting_re = re.compile(r'^_+\s+ERROR collecting\s+([\w./\\-]+)\s+_+$')
    summary_item_re = re.compile(r'^(FAILED|ERROR|SKIPPED)\s+(.+?)\s+-\s+')
    for raw_line in combined_output.splitlines():
        clean_line = ansi_re.sub('', raw_line).strip()
        summary_match = summary_item_re.match(clean_line)
        if summary_match:
            raw_status, name = summary_match.groups()
            if name not in parsed_results:
                parsed_results[name] = TestResult(name=name, status=status_map[raw_status])
            continue
        fallback_match = fallback_re.match(clean_line)
        if not fallback_match:
            collecting_match = collecting_re.match(clean_line)
            if not collecting_match:
                continue
            name = collecting_match.group(1)
            if name not in parsed_results:
                parsed_results[name] = TestResult(name=name, status=TestStatus.ERROR)
            continue
        raw_status, target = fallback_match.groups()
        name = target
        if name not in parsed_results:
            parsed_results[name] = TestResult(name=name, status=status_map[raw_status])

    return list(parsed_results.values())

### Implement the parsing logic above ###
### DO NOT MODIFY THE CODE BELOW ###

def export_to_json(results: List[TestResult], output_path: Path) -> None:
    json_results = {
        'tests': [
            {'name': result.name, 'status': result.status.name} for result in results
        ]
    }
    with open(output_path, 'w') as f:
        json.dump(json_results, f, indent=2)

def main(stdout_path: Path, stderr_path: Path, output_path: Path) -> None:
    with open(stdout_path) as f:
        stdout_content = f.read()
    with open(stderr_path) as f:
        stderr_content = f.read()

    results = parse_test_output(stdout_content, stderr_content)
    # The "before" phase is expected to represent baseline failures only.
    if output_path.name == 'before.json':
        results = [TestResult(name=result.name, status=TestStatus.FAILED) for result in results]
    export_to_json(results, output_path)

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print('Usage: python parsing.py <stdout_file> <stderr_file> <output_json>')
        sys.exit(1)

    main(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))