"""
Knowledge Base Automation Tools
Automated KB generation, documentation scraping, and knowledge extraction
"""

import os
import re
import json
from pathlib import Path
from typing import List, Dict, Optional
from dataclasses import dataclass
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class KnowledgeSource:
    """Source for knowledge extraction"""
    url: Optional[str] = None
    file_path: Optional[str] = None
    source_type: str = "web"  # web, pdf, code, api
    category: str = "general"
    metadata: Dict = None


class KnowledgeBaseBuilder:
    """
    Automated knowledge base construction from multiple sources.

    Features:
    - Web scraping (documentation, specs)
    - PDF extraction (standards, manuals)
    - Code documentation generation
    - API reference extraction
    - Markdown generation (5-level hierarchy)
    """

    def __init__(self, output_dir: str = "knowledge-base"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def scrape_documentation(self, url: str, category: str) -> Dict:
        """
        Scrape online documentation and extract structured knowledge.

        Args:
            url: Documentation URL
            category: Knowledge category (standards/technologies/tools/processes)

        Returns:
            Structured knowledge dictionary
        """
        try:
            import requests
            from bs4 import BeautifulSoup

            response = requests.get(url, timeout=30)
            response.raise_for_status()

            soup = BeautifulSoup(response.content, 'html.parser')

            # Extract title
            title = soup.find('h1').text if soup.find('h1') else "Untitled"

            # Extract sections
            sections = []
            for heading in soup.find_all(['h2', 'h3', 'h4']):
                section = {
                    'level': int(heading.name[1]),
                    'title': heading.text.strip(),
                    'content': self._extract_section_content(heading)
                }
                sections.append(section)

            # Extract code blocks
            code_blocks = []
            for code in soup.find_all('code'):
                code_blocks.append({
                    'language': code.get('class', ['text'])[0],
                    'code': code.text.strip()
                })

            return {
                'title': title,
                'url': url,
                'category': category,
                'sections': sections,
                'code_examples': code_blocks,
                'timestamp': str(Path.ctime(Path.cwd()))
            }

        except Exception as e:
            logger.error(f"Failed to scrape {url}: {e}")
            return {}

    def _extract_section_content(self, heading) -> str:
        """Extract content following a heading until next heading"""
        content = []
        for sibling in heading.find_next_siblings():
            if sibling.name in ['h2', 'h3', 'h4']:
                break
            content.append(sibling.text.strip())
        return '\n\n'.join(content)

    def extract_pdf_knowledge(self, pdf_path: str) -> Dict:
        """
        Extract knowledge from PDF documents (standards, manuals).

        Args:
            pdf_path: Path to PDF file

        Returns:
            Structured knowledge dictionary
        """
        try:
            import PyPDF2

            with open(pdf_path, 'rb') as file:
                pdf_reader = PyPDF2.PdfReader(file)

                text_content = []
                for page in pdf_reader.pages:
                    text_content.append(page.extract_text())

                full_text = '\n\n'.join(text_content)

                # Extract structure
                sections = self._parse_pdf_structure(full_text)

                return {
                    'title': Path(pdf_path).stem,
                    'source': pdf_path,
                    'pages': len(pdf_reader.pages),
                    'sections': sections,
                    'full_text': full_text
                }

        except Exception as e:
            logger.error(f"Failed to extract PDF {pdf_path}: {e}")
            return {}

    def _parse_pdf_structure(self, text: str) -> List[Dict]:
        """Parse PDF text into structured sections"""
        sections = []

        # Simple pattern matching for numbered sections
        pattern = r'(\d+\.?\d*)\s+([A-Z][^\n]+)'
        matches = re.finditer(pattern, text)

        for match in matches:
            sections.append({
                'number': match.group(1),
                'title': match.group(2).strip()
            })

        return sections

    def generate_code_documentation(self, code_path: str, language: str) -> Dict:
        """
        Generate documentation from source code.

        Args:
            code_path: Path to source code file/directory
            language: Programming language (python/c++/java/etc)

        Returns:
            Structured API documentation
        """
        if language == 'python':
            return self._generate_python_docs(code_path)
        elif language in ['c++', 'cpp']:
            return self._generate_cpp_docs(code_path)
        else:
            logger.warning(f"Language {language} not yet supported")
            return {}

    def _generate_python_docs(self, code_path: str) -> Dict:
        """Generate documentation from Python code"""
        import ast
        import inspect

        with open(code_path, 'r') as f:
            source_code = f.read()

        tree = ast.parse(source_code)

        functions = []
        classes = []

        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef):
                functions.append({
                    'name': node.name,
                    'docstring': ast.get_docstring(node),
                    'args': [arg.arg for arg in node.args.args],
                    'line_number': node.lineno
                })
            elif isinstance(node, ast.ClassDef):
                methods = []
                for item in node.body:
                    if isinstance(item, ast.FunctionDef):
                        methods.append({
                            'name': item.name,
                            'docstring': ast.get_docstring(item)
                        })

                classes.append({
                    'name': node.name,
                    'docstring': ast.get_docstring(node),
                    'methods': methods,
                    'line_number': node.lineno
                })

        return {
            'file': code_path,
            'language': 'python',
            'functions': functions,
            'classes': classes
        }

    def _generate_cpp_docs(self, code_path: str) -> Dict:
        """Generate documentation from C++ code (basic parsing)"""
        with open(code_path, 'r') as f:
            source_code = f.read()

        # Simple regex-based extraction (for production, use clang AST)
        class_pattern = r'class\s+(\w+)\s*(?::\s*public\s+\w+)?\s*\{'
        function_pattern = r'(\w+)\s+(\w+)\s*\([^)]*\)\s*[{;]'

        classes = re.findall(class_pattern, source_code)
        functions = re.findall(function_pattern, source_code)

        return {
            'file': code_path,
            'language': 'c++',
            'classes': classes,
            'functions': [{'return_type': f[0], 'name': f[1]} for f in functions]
        }

    def extract_api_reference(self, openapi_spec: str) -> Dict:
        """
        Extract API reference from OpenAPI/Swagger spec.

        Args:
            openapi_spec: Path to OpenAPI YAML/JSON

        Returns:
            Structured API documentation
        """
        try:
            import yaml

            with open(openapi_spec, 'r') as f:
                if openapi_spec.endswith('.json'):
                    spec = json.load(f)
                else:
                    spec = yaml.safe_load(f)

            endpoints = []

            for path, methods in spec.get('paths', {}).items():
                for method, details in methods.items():
                    endpoints.append({
                        'path': path,
                        'method': method.upper(),
                        'summary': details.get('summary', ''),
                        'description': details.get('description', ''),
                        'parameters': details.get('parameters', []),
                        'responses': details.get('responses', {})
                    })

            return {
                'title': spec.get('info', {}).get('title', 'API'),
                'version': spec.get('info', {}).get('version', '1.0'),
                'endpoints': endpoints
            }

        except Exception as e:
            logger.error(f"Failed to extract API spec {openapi_spec}: {e}")
            return {}

    def generate_markdown_hierarchy(self, knowledge: Dict, category: str) -> None:
        """
        Generate 5-level markdown hierarchy from knowledge.

        Levels:
        1. Overview (1-2 pages)
        2. Conceptual (5-10 pages)
        3. Detailed (20-50 pages)
        4. Reference (10-100 pages)
        5. Advanced (30-100 pages)

        Args:
            knowledge: Structured knowledge dictionary
            category: Category path (e.g., 'standards/autosar')
        """
        category_path = self.output_dir / category
        category_path.mkdir(parents=True, exist_ok=True)

        title = knowledge.get('title', 'Untitled')

        # Level 1: Overview
        overview = self._generate_overview(knowledge, title)
        (category_path / '1-overview.md').write_text(overview)

        # Level 2: Conceptual
        conceptual = self._generate_conceptual(knowledge, title)
        (category_path / '2-conceptual.md').write_text(conceptual)

        # Level 3: Detailed
        detailed = self._generate_detailed(knowledge, title)
        (category_path / '3-detailed.md').write_text(detailed)

        # Level 4: Reference
        reference = self._generate_reference(knowledge, title)
        (category_path / '4-reference.md').write_text(reference)

        # Level 5: Advanced
        advanced = self._generate_advanced(knowledge, title)
        (category_path / '5-advanced.md').write_text(advanced)

        logger.info(f"Generated 5-level docs for {title} in {category_path}")

    def _generate_overview(self, knowledge: Dict, title: str) -> str:
        """Generate Level 1: Overview"""
        md = f"# {title} - Overview\n\n"
        md += "**Level**: 1 - Overview\n"
        md += "**Audience**: Beginners, Decision Makers\n"
        md += "**Reading Time**: 5 minutes\n\n"
        md += "---\n\n"
        md += "## What Is It?\n\n"
        md += knowledge.get('sections', [{}])[0].get('content', 'Description...') + "\n\n"
        md += "## Key Features\n\n"
        md += "- Feature 1\n- Feature 2\n- Feature 3\n\n"
        md += "## When to Use\n\n"
        md += "Use this when...\n\n"
        md += "## Next Steps\n\n"
        md += "- Read [Conceptual Guide](./2-conceptual.md) for deeper understanding\n"
        return md

    def _generate_conceptual(self, knowledge: Dict, title: str) -> str:
        """Generate Level 2: Conceptual"""
        md = f"# {title} - Conceptual Guide\n\n"
        md += "**Level**: 2 - Conceptual\n"
        md += "**Audience**: Engineers, Architects\n"
        md += "**Reading Time**: 30 minutes\n\n"
        md += "---\n\n"
        md += "## Architecture\n\n"
        md += "```\n[ASCII diagram here]\n```\n\n"
        md += "## Core Concepts\n\n"

        for section in knowledge.get('sections', [])[:5]:
            md += f"### {section.get('title', 'Section')}\n\n"
            md += section.get('content', 'Content...') + "\n\n"

        return md

    def _generate_detailed(self, knowledge: Dict, title: str) -> str:
        """Generate Level 3: Detailed"""
        md = f"# {title} - Detailed Implementation Guide\n\n"
        md += "**Level**: 3 - Detailed\n"
        md += "**Audience**: Developers\n"
        md += "**Reading Time**: 2 hours\n\n"
        md += "---\n\n"

        for section in knowledge.get('sections', []):
            md += f"## {section.get('title', 'Section')}\n\n"
            md += section.get('content', 'Content...') + "\n\n"

        # Add code examples
        for i, code in enumerate(knowledge.get('code_examples', [])[:10]):
            md += f"### Example {i+1}\n\n"
            md += f"```{code.get('language', 'text')}\n"
            md += code.get('code', '') + "\n"
            md += "```\n\n"

        return md

    def _generate_reference(self, knowledge: Dict, title: str) -> str:
        """Generate Level 4: Reference"""
        md = f"# {title} - API Reference\n\n"
        md += "**Level**: 4 - Reference\n"
        md += "**Audience**: Developers\n"
        md += "**Purpose**: Quick lookup\n\n"
        md += "---\n\n"
        md += "## Quick Reference\n\n"
        md += "| Item | Description |\n"
        md += "|------|-------------|\n"
        md += "| Item 1 | Description |\n\n"
        return md

    def _generate_advanced(self, knowledge: Dict, title: str) -> str:
        """Generate Level 5: Advanced"""
        md = f"# {title} - Advanced Topics\n\n"
        md += "**Level**: 5 - Advanced\n"
        md += "**Audience**: Experts, Architects\n"
        md += "**Reading Time**: 4 hours\n\n"
        md += "---\n\n"
        md += "## Advanced Patterns\n\n"
        md += "## Performance Optimization\n\n"
        md += "## Production Deployment\n\n"
        md += "## Troubleshooting\n\n"
        return md

    def build_from_sources(self, sources: List[KnowledgeSource]) -> None:
        """
        Build complete knowledge base from multiple sources.

        Args:
            sources: List of knowledge sources to process
        """
        for source in sources:
            logger.info(f"Processing source: {source.source_type} - {source.category}")

            if source.source_type == "web" and source.url:
                knowledge = self.scrape_documentation(source.url, source.category)
                if knowledge:
                    self.generate_markdown_hierarchy(knowledge, source.category)

            elif source.source_type == "pdf" and source.file_path:
                knowledge = self.extract_pdf_knowledge(source.file_path)
                if knowledge:
                    self.generate_markdown_hierarchy(knowledge, source.category)

            elif source.source_type == "code" and source.file_path:
                language = source.metadata.get('language', 'python')
                knowledge = self.generate_code_documentation(source.file_path, language)
                if knowledge:
                    self.generate_markdown_hierarchy(knowledge, source.category)

        logger.info(f"Knowledge base built in {self.output_dir}")


# Example usage
if __name__ == "__main__":
    builder = KnowledgeBaseBuilder(output_dir="knowledge-base")

    # Define knowledge sources
    sources = [
        KnowledgeSource(
            url="https://www.autosar.org/standards/",
            source_type="web",
            category="standards/autosar",
            metadata={'standard': 'AUTOSAR'}
        ),
        KnowledgeSource(
            url="https://www.iso.org/standard/43464.html",
            source_type="web",
            category="standards/iso26262",
            metadata={'standard': 'ISO 26262'}
        ),
        # Add more sources...
    ]

    # Build knowledge base
    builder.build_from_sources(sources)
