#!/usr/bin/env python3
"""
Schema validator for automotive-claude-code-agents skills and agents.

Validates YAML files have required fields and optionally fixes missing metadata.
"""

import argparse
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Set

# Try importing yaml, fall back to basic parsing if unavailable
try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False
    print("Warning: PyYAML not available, using basic text parsing", file=sys.stderr)


class ValidationResult:
    """Container for validation results."""

    def __init__(self):
        self.total_files = 0
        self.valid_files = 0
        self.invalid_files = 0
        self.errors: List[Tuple[Path, List[str]]] = []
        self.fixed_files: List[Path] = []

    def add_error(self, file_path: Path, missing_fields: List[str]):
        """Record validation error."""
        self.total_files += 1
        self.invalid_files += 1
        self.errors.append((file_path, missing_fields))

    def add_valid(self):
        """Record valid file."""
        self.total_files += 1
        self.valid_files += 1

    def add_fixed(self, file_path: Path):
        """Record fixed file."""
        self.fixed_files.append(file_path)

    def print_report(self):
        """Print validation report."""
        print("\n" + "=" * 80)
        print("VALIDATION REPORT")
        print("=" * 80)
        print(f"Total files checked: {self.total_files}")
        print(f"Valid files:         {self.valid_files}")
        print(f"Invalid files:       {self.invalid_files}")

        if self.fixed_files:
            print(f"Fixed files:         {len(self.fixed_files)}")

        if self.errors:
            print("\n" + "-" * 80)
            print("VALIDATION ERRORS:")
            print("-" * 80)
            for file_path, missing_fields in self.errors:
                print(f"\n{file_path}")
                for field in missing_fields:
                    print(f"  - Missing field: {field}")

        if self.fixed_files:
            print("\n" + "-" * 80)
            print("FIXED FILES:")
            print("-" * 80)
            for file_path in self.fixed_files:
                print(f"  - {file_path}")

        print("\n" + "=" * 80)


def validate_with_yaml(file_path: Path, required_fields: Set[str]) -> List[str]:
    """Validate YAML file using PyYAML parser."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)

        if not isinstance(data, dict):
            return ["Root element must be a dictionary"]

        missing_fields = []
        for field in required_fields:
            if field not in data or data[field] is None or data[field] == '':
                missing_fields.append(field)

        return missing_fields

    except yaml.YAMLError as e:
        return [f"YAML parsing error: {e}"]
    except Exception as e:
        return [f"Error reading file: {e}"]


def validate_with_text(file_path: Path, required_fields: Set[str]) -> List[str]:
    """Validate YAML file using basic text parsing (fallback)."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        missing_fields = []
        for field in required_fields:
            # Look for field at start of line followed by colon
            if f"\n{field}:" not in f"\n{content}" and not content.startswith(f"{field}:"):
                missing_fields.append(field)

        return missing_fields

    except Exception as e:
        return [f"Error reading file: {e}"]


def fix_missing_fields(file_path: Path, missing_fields: List[str], file_type: str) -> bool:
    """Add missing version and category fields to YAML file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        # Prepare additions
        additions = []
        if 'version' in missing_fields:
            additions.append('version: "1.0.0"\n')
        if 'category' in missing_fields and file_type == 'skill':
            additions.append('category: automotive\n')

        if not additions:
            return False

        # Find insertion point (after first field or at beginning)
        insert_idx = 0
        for i, line in enumerate(lines):
            if line.strip() and not line.strip().startswith('#'):
                # Insert after first field
                if ':' in line:
                    insert_idx = i + 1
                    break

        # Insert additions
        for addition in reversed(additions):
            lines.insert(insert_idx, addition)

        # Write back
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)

        return True

    except Exception as e:
        print(f"Error fixing {file_path}: {e}", file=sys.stderr)
        return False


def validate_skills(skills_dir: Path, fix: bool = False) -> ValidationResult:
    """Validate all skill YAML files."""
    required_fields = {'name', 'description', 'instructions'}
    optional_fields = {'version', 'category'}
    result = ValidationResult()

    if not skills_dir.exists():
        print(f"Skills directory not found: {skills_dir}", file=sys.stderr)
        return result

    # Find all YAML files
    yaml_files = list(skills_dir.glob('**/*.yaml')) + list(skills_dir.glob('**/*.yml'))

    for yaml_file in yaml_files:
        if HAS_YAML:
            missing_fields = validate_with_yaml(yaml_file, required_fields)
        else:
            missing_fields = validate_with_text(yaml_file, required_fields)

        if missing_fields:
            # Filter out optional fields if fix mode is enabled
            critical_missing = [f for f in missing_fields if f not in optional_fields]

            if critical_missing:
                result.add_error(yaml_file, missing_fields)
            elif fix:
                # Only missing optional fields, can fix
                if fix_missing_fields(yaml_file, missing_fields, 'skill'):
                    result.add_valid()
                    result.add_fixed(yaml_file)
                else:
                    result.add_error(yaml_file, missing_fields)
            else:
                result.add_error(yaml_file, missing_fields)
        else:
            result.add_valid()

    return result


def validate_agents(agents_dir: Path, fix: bool = False) -> ValidationResult:
    """Validate all agent YAML files."""
    required_fields = {'name', 'description', 'role', 'capabilities'}
    optional_fields = {'version'}
    result = ValidationResult()

    if not agents_dir.exists():
        print(f"Agents directory not found: {agents_dir}", file=sys.stderr)
        return result

    # Find all YAML files
    yaml_files = list(agents_dir.glob('**/*.yaml')) + list(agents_dir.glob('**/*.yml'))

    for yaml_file in yaml_files:
        if HAS_YAML:
            missing_fields = validate_with_yaml(yaml_file, required_fields)
        else:
            missing_fields = validate_with_text(yaml_file, required_fields)

        if missing_fields:
            # Filter out optional fields if fix mode is enabled
            critical_missing = [f for f in missing_fields if f not in optional_fields]

            if critical_missing:
                result.add_error(yaml_file, missing_fields)
            elif fix:
                # Only missing optional fields, can fix
                if fix_missing_fields(yaml_file, missing_fields, 'agent'):
                    result.add_valid()
                    result.add_fixed(yaml_file)
                else:
                    result.add_error(yaml_file, missing_fields)
            else:
                result.add_error(yaml_file, missing_fields)
        else:
            result.add_valid()

    return result


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Validate YAML schema for skills and agents',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                    # Validate all files
  %(prog)s --fix              # Validate and fix missing version/category
  %(prog)s --skills-only      # Validate only skills
  %(prog)s --agents-only      # Validate only agents
        """
    )
    parser.add_argument(
        '--fix',
        action='store_true',
        help='Fix missing version and category fields'
    )
    parser.add_argument(
        '--skills-only',
        action='store_true',
        help='Validate only skills directory'
    )
    parser.add_argument(
        '--agents-only',
        action='store_true',
        help='Validate only agents directory'
    )
    parser.add_argument(
        '--root',
        type=Path,
        default=Path(__file__).parent.parent,
        help='Root directory of the repository (default: script parent directory)'
    )

    args = parser.parse_args()

    root_dir = args.root.resolve()
    skills_dir = root_dir / 'skills'
    agents_dir = root_dir / 'agents'

    print("=" * 80)
    print("AUTOMOTIVE CLAUDE CODE AGENTS - SCHEMA VALIDATOR")
    print("=" * 80)
    print(f"Root directory: {root_dir}")
    print(f"Fix mode:       {'ENABLED' if args.fix else 'DISABLED'}")
    print(f"YAML parser:    {'PyYAML' if HAS_YAML else 'Text-based (fallback)'}")
    print("=" * 80)

    all_valid = True

    # Validate skills
    if not args.agents_only:
        print("\nValidating SKILLS...")
        skills_result = validate_skills(skills_dir, args.fix)
        skills_result.print_report()
        if skills_result.invalid_files > 0:
            all_valid = False

    # Validate agents
    if not args.skills_only:
        print("\nValidating AGENTS...")
        agents_result = validate_agents(agents_dir, args.fix)
        agents_result.print_report()
        if agents_result.invalid_files > 0:
            all_valid = False

    # Exit with appropriate code
    if all_valid:
        print("\n✓ All validations passed!")
        return 0
    else:
        print("\n✗ Validation failed!")
        return 1


if __name__ == '__main__':
    sys.exit(main())
