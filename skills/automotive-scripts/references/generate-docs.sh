#!/usr/bin/env bash
# Auto-generate comprehensive documentation
# Supports multiple formats: MkDocs, Sphinx, Doxygen

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly DOCS_DIR="${PROJECT_ROOT}/docs"
readonly OUTPUT_DIR="${PROJECT_ROOT}/site"

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Default values
FORMAT="mkdocs"
SERVE=false
CLEAN=false

# Usage
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Generate comprehensive documentation for Automotive Claude Code.

OPTIONS:
    -f, --format FORMAT     Documentation format: mkdocs, sphinx, doxygen, all (default: mkdocs)
    -s, --serve             Start local documentation server after build
    -c, --clean             Clean build directories before generating
    -h, --help              Show this help message

FORMATS:
    mkdocs      Material-themed documentation (primary)
    sphinx      Sphinx with RTD theme (Python API)
    doxygen     C/C++ API documentation
    all         Generate all formats

EXAMPLES:
    # Generate and serve MkDocs
    $(basename "$0") -f mkdocs -s

    # Clean build and regenerate all
    $(basename "$0") -f all -c

    # Generate Sphinx docs only
    $(basename "$0") -f sphinx

EOF
    exit 0
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--format)
                FORMAT="$2"
                shift 2
                ;;
            -s|--serve)
                SERVE=true
                shift
                ;;
            -c|--clean)
                CLEAN=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# Clean build directories
clean_builds() {
    log_info "Cleaning documentation build directories..."

    rm -rf "${OUTPUT_DIR}"
    rm -rf "${DOCS_DIR}/_build"
    rm -rf "${DOCS_DIR}/doxygen"
    rm -rf "${PROJECT_ROOT}/.cache"

    log_success "Build directories cleaned"
}

# Generate MkDocs documentation
generate_mkdocs() {
    log_info "Generating MkDocs documentation..."

    cd "$PROJECT_ROOT" || exit 1

    # Check if mkdocs is installed
    if ! command -v mkdocs >/dev/null 2>&1; then
        log_warning "mkdocs not found, installing..."
        pip install mkdocs mkdocs-material mkdocstrings mkdocs-mermaid2-plugin
    fi

    # Check config
    if [[ ! -f mkdocs.yml ]]; then
        log_error "mkdocs.yml not found"
        return 1
    fi

    # Build
    mkdocs build --clean

    log_success "MkDocs documentation generated in ${OUTPUT_DIR}"

    # Serve if requested
    if [[ "$SERVE" == true ]]; then
        log_info "Starting MkDocs server at http://127.0.0.1:8000"
        mkdocs serve
    fi
}

# Generate Sphinx documentation
generate_sphinx() {
    log_info "Generating Sphinx documentation..."

    cd "$PROJECT_ROOT" || exit 1

    # Check if sphinx is installed
    if ! command -v sphinx-build >/dev/null 2>&1; then
        log_warning "sphinx not found, installing..."
        pip install sphinx sphinx-rtd-theme
    fi

    # Check if conf.py exists
    local sphinx_dir="${DOCS_DIR}/sphinx"
    if [[ ! -f "${sphinx_dir}/conf.py" ]]; then
        log_info "Initializing Sphinx..."
        mkdir -p "$sphinx_dir"
        sphinx-quickstart -q \
            -p "Automotive Claude Code" \
            -a "Automotive Claude Code Contributors" \
            -v "0.1.0" \
            --ext-autodoc \
            --ext-viewcode \
            --makefile \
            --no-batchfile \
            "$sphinx_dir"
    fi

    # Build
    sphinx-build -b html "$sphinx_dir" "${OUTPUT_DIR}/sphinx"

    log_success "Sphinx documentation generated in ${OUTPUT_DIR}/sphinx"

    # Serve if requested
    if [[ "$SERVE" == true ]]; then
        log_info "Starting Sphinx server at http://127.0.0.1:8001"
        cd "${OUTPUT_DIR}/sphinx" && python3 -m http.server 8001
    fi
}

# Generate Doxygen documentation
generate_doxygen() {
    log_info "Generating Doxygen documentation..."

    cd "$PROJECT_ROOT" || exit 1

    # Check if doxygen is installed
    if ! command -v doxygen >/dev/null 2>&1; then
        log_warning "doxygen not found, skipping C/C++ documentation"
        return 0
    fi

    # Check for Doxyfile
    local doxyfile="${DOCS_DIR}/Doxyfile"
    if [[ ! -f "$doxyfile" ]]; then
        log_info "Generating Doxyfile..."
        doxygen -g "$doxyfile"

        # Configure Doxyfile
        sed -i 's/PROJECT_NAME           = .*/PROJECT_NAME           = "Automotive Claude Code"/' "$doxyfile"
        sed -i 's/OUTPUT_DIRECTORY       = .*/OUTPUT_DIRECTORY       = docs\/doxygen/' "$doxyfile"
        sed -i 's/INPUT                  = .*/INPUT                  = tools/' "$doxyfile"
        sed -i 's/RECURSIVE              = NO/RECURSIVE              = YES/' "$doxyfile"
        sed -i 's/EXTRACT_ALL            = NO/EXTRACT_ALL            = YES/' "$doxyfile"
        sed -i 's/GENERATE_LATEX         = YES/GENERATE_LATEX         = NO/' "$doxyfile"
    fi

    # Build
    doxygen "$doxyfile"

    log_success "Doxygen documentation generated in ${DOCS_DIR}/doxygen/html"

    # Serve if requested
    if [[ "$SERVE" == true ]]; then
        log_info "Starting Doxygen server at http://127.0.0.1:8002"
        cd "${DOCS_DIR}/doxygen/html" && python3 -m http.server 8002
    fi
}

# Generate API reference
generate_api_reference() {
    log_info "Generating API reference..."

    cd "$PROJECT_ROOT" || exit 1

    local api_dir="${DOCS_DIR}/api"
    mkdir -p "$api_dir"

    # Generate Python API docs
    if command -v sphinx-apidoc >/dev/null 2>&1; then
        sphinx-apidoc -f -o "$api_dir" tools/
        log_success "Python API reference generated"
    fi
}

# Generate skill catalog
generate_skill_catalog() {
    log_info "Generating skill catalog..."

    cd "$PROJECT_ROOT" || exit 1

    local catalog_file="${DOCS_DIR}/skills-catalog.md"

    cat > "$catalog_file" <<'EOF'
# Skills Catalog

Auto-generated catalog of all available skills in Automotive Claude Code.

## Skills by Category

EOF

    # Iterate through skill categories
    for category in skills/*/; do
        if [[ -d "$category" ]]; then
            local category_name
            category_name=$(basename "$category")

            echo "### ${category_name^}" >> "$catalog_file"
            echo "" >> "$catalog_file"

            # List skills in category
            for skill_dir in "$category"*/; do
                if [[ -d "$skill_dir" ]]; then
                    local skill_name
                    skill_name=$(basename "$skill_dir")

                    local skill_file="${skill_dir}/${skill_name}.yaml"
                    if [[ -f "$skill_file" ]]; then
                        # Extract description from YAML
                        local description
                        description=$(grep "^description:" "$skill_file" | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "No description")

                        echo "- **${skill_name}**: ${description}" >> "$catalog_file"
                    fi
                fi
            done

            echo "" >> "$catalog_file"
        fi
    done

    log_success "Skill catalog generated at ${catalog_file}"
}

# Generate command reference
generate_command_reference() {
    log_info "Generating command reference..."

    cd "$PROJECT_ROOT" || exit 1

    local cmd_file="${DOCS_DIR}/commands-reference.md"

    cat > "$cmd_file" <<'EOF'
# Commands Reference

Auto-generated reference of all available commands.

## Available Commands

EOF

    # Iterate through commands
    for cmd_category in commands/*/; do
        if [[ -d "$cmd_category" ]]; then
            local category_name
            category_name=$(basename "$cmd_category")

            echo "### ${category_name^}" >> "$cmd_file"
            echo "" >> "$cmd_file"

            for cmd_file_path in "$cmd_category"*.sh; do
                if [[ -f "$cmd_file_path" ]]; then
                    local cmd_name
                    cmd_name=$(basename "$cmd_file_path" .sh)

                    echo "#### ${cmd_name}" >> "$cmd_file"
                    echo "" >> "$cmd_file"
                    echo '```bash' >> "$cmd_file"
                    echo "./${cmd_file_path}" >> "$cmd_file"
                    echo '```' >> "$cmd_file"
                    echo "" >> "$cmd_file"

                    # Extract usage from script
                    if grep -q "^usage()" "$cmd_file_path"; then
                        echo "See script for detailed usage." >> "$cmd_file"
                    fi

                    echo "" >> "$cmd_file"
                fi
            done
        fi
    done

    log_success "Command reference generated at ${cmd_file}"
}

# Generate statistics
generate_statistics() {
    log_info "Generating project statistics..."

    cd "$PROJECT_ROOT" || exit 1

    local stats_file="${DOCS_DIR}/statistics.md"

    cat > "$stats_file" <<EOF
# Project Statistics

Generated: $(date)

## Code Metrics

- **Total Skills**: $(find skills/ -name "*.yaml" | wc -l)
- **Total Agents**: $(find agents/ -name "*.yaml" | wc -l)
- **Total Commands**: $(find commands/ -name "*.sh" | wc -l)
- **Total Workflows**: $(find workflows/ -name "*.yaml" | wc -l)
- **Python Files**: $(find tools/ -name "*.py" | wc -l)
- **Documentation Files**: $(find docs/ -name "*.md" | wc -l)

## Categories

### Skills by Category
$(for dir in skills/*/; do echo "- $(basename "$dir"): $(find "$dir" -name "*.yaml" | wc -l)"; done)

### Agents by Type
$(for dir in agents/*/; do echo "- $(basename "$dir"): $(find "$dir" -name "*.yaml" | wc -l)"; done)

## Lines of Code

\`\`\`
$(find tools/ -name "*.py" -exec wc -l {} + | tail -1)
\`\`\`

EOF

    log_success "Statistics generated at ${stats_file}"
}

# Main
main() {
    parse_args "$@"

    if [[ "$CLEAN" == true ]]; then
        clean_builds
    fi

    case "$FORMAT" in
        mkdocs)
            generate_skill_catalog
            generate_command_reference
            generate_statistics
            generate_mkdocs
            ;;
        sphinx)
            generate_api_reference
            generate_sphinx
            ;;
        doxygen)
            generate_doxygen
            ;;
        all)
            generate_skill_catalog
            generate_command_reference
            generate_statistics
            generate_api_reference
            generate_mkdocs
            generate_sphinx
            generate_doxygen
            ;;
        *)
            log_error "Invalid format: $FORMAT"
            usage
            ;;
    esac

    echo ""
    log_success "Documentation generation complete!"
    echo ""
}

main "$@"
