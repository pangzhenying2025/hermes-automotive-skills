"""
Tool Comparator for Commercial vs Opensource Automotive Tools.

Generates comprehensive feature comparison matrices for:
- CAN/Vehicle Network: CANoe vs cantools/python-can
- AUTOSAR: DaVinci/tresos vs Arctic Core
- Simulation: VEOS/TargetLink vs QEMU/Renode
- Calibration: INCA/CANape vs Panda/XCP-Lite
- Testing: VectorCAST vs GoogleTest/Catch2
- Static Analysis: Polyspace vs cppcheck/clang-tidy

Comparison dimensions:
- Features
- Performance
- Cost
- Learning curve
- Community support
- Industry adoption
- Standards compliance
"""

import json
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field, asdict
from enum import Enum
import logging

logger = logging.getLogger(__name__)


class FeatureSupport(Enum):
    """Feature support levels."""
    FULL = "full"
    PARTIAL = "partial"
    NONE = "none"
    PLANNED = "planned"


@dataclass
class Tool:
    """Tool information for comparison."""
    name: str
    category: str
    is_opensource: bool
    vendor: Optional[str]
    license: str
    cost_model: str  # "free", "commercial", "freemium"
    platforms: List[str]
    learning_curve: str  # "low", "medium", "high"
    community_size: str  # "small", "medium", "large"
    documentation_quality: str  # "poor", "good", "excellent"
    industry_adoption: str  # "niche", "moderate", "widespread"
    last_updated: str


@dataclass
class FeatureComparison:
    """Feature comparison between tools."""
    feature_name: str
    commercial_support: FeatureSupport
    opensource_support: FeatureSupport
    notes: str = ""


@dataclass
class ComparisonMatrix:
    """Comprehensive comparison between commercial and opensource tools."""
    category: str
    commercial_tool: Tool
    opensource_tools: List[Tool]
    feature_comparisons: List[FeatureComparison]
    use_cases: Dict[str, str]  # use_case -> recommended_tool
    migration_difficulty: str  # "easy", "moderate", "difficult"
    cost_savings_estimate: str
    recommendation: str


class ToolComparator:
    """Compares commercial and opensource automotive tools."""

    # Tool database with detailed information
    TOOL_DATABASE = {
        # CAN/Vehicle Network Tools
        "canoe": Tool(
            name="CANoe",
            category="vehicle_network",
            is_opensource=False,
            vendor="Vector",
            license="Commercial",
            cost_model="commercial",
            platforms=["Windows", "Linux"],
            learning_curve="high",
            community_size="large",
            documentation_quality="excellent",
            industry_adoption="widespread",
            last_updated="2024"
        ),
        "cantools": Tool(
            name="cantools",
            category="vehicle_network",
            is_opensource=True,
            vendor=None,
            license="MIT",
            cost_model="free",
            platforms=["Windows", "Linux", "macOS"],
            learning_curve="medium",
            community_size="medium",
            documentation_quality="good",
            industry_adoption="moderate",
            last_updated="2024"
        ),
        "python-can": Tool(
            name="python-can",
            category="vehicle_network",
            is_opensource=True,
            vendor=None,
            license="LGPL",
            cost_model="free",
            platforms=["Windows", "Linux", "macOS"],
            learning_curve="low",
            community_size="large",
            documentation_quality="excellent",
            industry_adoption="widespread",
            last_updated="2024"
        ),

        # AUTOSAR Tools
        "davinci": Tool(
            name="DaVinci",
            category="autosar",
            is_opensource=False,
            vendor="Vector",
            license="Commercial",
            cost_model="commercial",
            platforms=["Windows"],
            learning_curve="high",
            community_size="large",
            documentation_quality="excellent",
            industry_adoption="widespread",
            last_updated="2024"
        ),
        "tresos": Tool(
            name="EB tresos",
            category="autosar",
            is_opensource=False,
            vendor="Elektrobit",
            license="Commercial",
            cost_model="commercial",
            platforms=["Windows", "Linux"],
            learning_curve="high",
            community_size="large",
            documentation_quality="excellent",
            industry_adoption="widespread",
            last_updated="2024"
        ),
        "arctic-core": Tool(
            name="Arctic Core",
            category="autosar",
            is_opensource=True,
            vendor=None,
            license="GPL",
            cost_model="free",
            platforms=["Windows", "Linux"],
            learning_curve="high",
            community_size="small",
            documentation_quality="good",
            industry_adoption="niche",
            last_updated="2023"
        ),

        # Simulation Tools
        "veos": Tool(
            name="VEOS",
            category="simulation",
            is_opensource=False,
            vendor="dSPACE",
            license="Commercial",
            cost_model="commercial",
            platforms=["Windows", "Linux"],
            learning_curve="high",
            community_size="medium",
            documentation_quality="excellent",
            industry_adoption="moderate",
            last_updated="2024"
        ),
        "qemu": Tool(
            name="QEMU",
            category="simulation",
            is_opensource=True,
            vendor=None,
            license="GPL",
            cost_model="free",
            platforms=["Windows", "Linux", "macOS"],
            learning_curve="medium",
            community_size="large",
            documentation_quality="good",
            industry_adoption="widespread",
            last_updated="2024"
        ),
        "renode": Tool(
            name="Renode",
            category="simulation",
            is_opensource=True,
            vendor="Antmicro",
            license="MIT",
            cost_model="free",
            platforms=["Windows", "Linux", "macOS"],
            learning_curve="medium",
            community_size="medium",
            documentation_quality="excellent",
            industry_adoption="moderate",
            last_updated="2024"
        ),

        # Calibration Tools
        "inca": Tool(
            name="INCA",
            category="calibration",
            is_opensource=False,
            vendor="ETAS",
            license="Commercial",
            cost_model="commercial",
            platforms=["Windows"],
            learning_curve="high",
            community_size="large",
            documentation_quality="excellent",
            industry_adoption="widespread",
            last_updated="2024"
        ),
        "panda": Tool(
            name="Panda",
            category="calibration",
            is_opensource=True,
            vendor="comma.ai",
            license="MIT",
            cost_model="free",
            platforms=["Linux"],
            learning_curve="medium",
            community_size="medium",
            documentation_quality="good",
            industry_adoption="niche",
            last_updated="2024"
        ),

        # Testing Tools
        "vectorcast": Tool(
            name="VectorCAST",
            category="testing",
            is_opensource=False,
            vendor="Vector",
            license="Commercial",
            cost_model="commercial",
            platforms=["Windows", "Linux"],
            learning_curve="high",
            community_size="medium",
            documentation_quality="excellent",
            industry_adoption="moderate",
            last_updated="2024"
        ),
        "googletest": Tool(
            name="GoogleTest",
            category="testing",
            is_opensource=True,
            vendor="Google",
            license="BSD",
            cost_model="free",
            platforms=["Windows", "Linux", "macOS"],
            learning_curve="low",
            community_size="large",
            documentation_quality="excellent",
            industry_adoption="widespread",
            last_updated="2024"
        ),

        # Static Analysis
        "polyspace": Tool(
            name="Polyspace",
            category="static_analysis",
            is_opensource=False,
            vendor="MathWorks",
            license="Commercial",
            cost_model="commercial",
            platforms=["Windows", "Linux"],
            learning_curve="high",
            community_size="medium",
            documentation_quality="excellent",
            industry_adoption="moderate",
            last_updated="2024"
        ),
        "cppcheck": Tool(
            name="cppcheck",
            category="static_analysis",
            is_opensource=True,
            vendor=None,
            license="GPL",
            cost_model="free",
            platforms=["Windows", "Linux", "macOS"],
            learning_curve="low",
            community_size="large",
            documentation_quality="good",
            industry_adoption="widespread",
            last_updated="2024"
        ),
        "clang-tidy": Tool(
            name="clang-tidy",
            category="static_analysis",
            is_opensource=True,
            vendor="LLVM",
            license="Apache 2.0",
            cost_model="free",
            platforms=["Windows", "Linux", "macOS"],
            learning_curve="medium",
            community_size="large",
            documentation_quality="excellent",
            industry_adoption="widespread",
            last_updated="2024"
        )
    }

    # Feature comparison matrices
    FEATURE_MATRICES = {
        "vehicle_network": {
            "commercial": "canoe",
            "opensource": ["cantools", "python-can"],
            "features": [
                FeatureComparison(
                    "DBC parsing",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "Both support DBC files fully"
                ),
                FeatureComparison(
                    "CAN message simulation",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "python-can provides full simulation capabilities"
                ),
                FeatureComparison(
                    "LIN simulation",
                    FeatureSupport.FULL,
                    FeatureSupport.PARTIAL,
                    "Limited LIN support in opensource"
                ),
                FeatureComparison(
                    "FlexRay simulation",
                    FeatureSupport.FULL,
                    FeatureSupport.NONE,
                    "No opensource FlexRay support"
                ),
                FeatureComparison(
                    "Automotive Ethernet",
                    FeatureSupport.FULL,
                    FeatureSupport.PARTIAL,
                    "Basic Ethernet support in opensource tools"
                ),
                FeatureComparison(
                    "CAPL scripting",
                    FeatureSupport.FULL,
                    FeatureSupport.NONE,
                    "Use Python instead of CAPL"
                ),
                FeatureComparison(
                    "Python scripting",
                    FeatureSupport.PARTIAL,
                    FeatureSupport.FULL,
                    "Native Python support in opensource"
                ),
                FeatureComparison(
                    "Real-time analysis",
                    FeatureSupport.FULL,
                    FeatureSupport.PARTIAL,
                    "Depends on hardware interface"
                ),
                FeatureComparison(
                    "Trace recording",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "Both support logging"
                ),
                FeatureComparison(
                    "GUI interface",
                    FeatureSupport.FULL,
                    FeatureSupport.PARTIAL,
                    "CANoe has professional GUI, opensource tools mostly CLI"
                ),
                FeatureComparison(
                    "Hardware support",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "python-can supports multiple interfaces"
                ),
                FeatureComparison(
                    "Restbus simulation",
                    FeatureSupport.FULL,
                    FeatureSupport.PARTIAL,
                    "Requires custom scripting in opensource"
                )
            ],
            "use_cases": {
                "Simple CAN logging": "python-can",
                "DBC-based testing": "cantools",
                "Complex restbus simulation": "canoe",
                "Multi-protocol testing": "canoe",
                "Automated CI/CD testing": "python-can",
                "Quick prototyping": "python-can"
            },
            "migration_difficulty": "moderate",
            "cost_savings": "$10,000 - $30,000 per license",
            "recommendation": "Use python-can + cantools for 80% of use cases. CANoe only for complex multi-protocol simulations or regulatory requirements."
        },

        "autosar": {
            "commercial": "davinci",
            "opensource": ["arctic-core"],
            "features": [
                FeatureComparison(
                    "ARXML import/export",
                    FeatureSupport.FULL,
                    FeatureSupport.PARTIAL,
                    "Limited ARXML support in Arctic Core"
                ),
                FeatureComparison(
                    "RTE generation",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "Both generate RTE code"
                ),
                FeatureComparison(
                    "BSW configuration",
                    FeatureSupport.FULL,
                    FeatureSupport.PARTIAL,
                    "Arctic Core has basic BSW modules"
                ),
                FeatureComparison(
                    "GUI configuration",
                    FeatureSupport.FULL,
                    FeatureSupport.NONE,
                    "Arctic Core uses manual configuration"
                ),
                FeatureComparison(
                    "Multi-core support",
                    FeatureSupport.FULL,
                    FeatureSupport.PARTIAL,
                    "Limited multi-core in Arctic Core"
                ),
                FeatureComparison(
                    "Safety features (ASIL)",
                    FeatureSupport.FULL,
                    FeatureSupport.PARTIAL,
                    "Commercial tools have certified safety features"
                ),
                FeatureComparison(
                    "Code generation",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "Both generate C code"
                ),
                FeatureComparison(
                    "MCAL drivers",
                    FeatureSupport.FULL,
                    FeatureSupport.PARTIAL,
                    "Limited microcontroller support in Arctic Core"
                ),
                FeatureComparison(
                    "Diagnostic modules",
                    FeatureSupport.FULL,
                    FeatureSupport.PARTIAL,
                    "Basic diagnostics in Arctic Core"
                )
            ],
            "use_cases": {
                "Production ECU development": "davinci",
                "Learning AUTOSAR": "arctic-core",
                "Prototyping": "arctic-core",
                "Safety-critical systems": "davinci",
                "Academic projects": "arctic-core"
            },
            "migration_difficulty": "difficult",
            "cost_savings": "$50,000 - $150,000 per seat",
            "recommendation": "Arctic Core suitable for learning and non-safety-critical projects. Production systems require commercial tools for certification."
        },

        "simulation": {
            "commercial": "veos",
            "opensource": ["qemu", "renode"],
            "features": [
                FeatureComparison(
                    "ARM Cortex-M emulation",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "QEMU/Renode excellent for ARM"
                ),
                FeatureComparison(
                    "Peripheral simulation",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "Renode excels at peripheral modeling"
                ),
                FeatureComparison(
                    "Multi-core simulation",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "Both support multi-core"
                ),
                FeatureComparison(
                    "Real-time simulation",
                    FeatureSupport.FULL,
                    FeatureSupport.PARTIAL,
                    "VEOS optimized for real-time"
                ),
                FeatureComparison(
                    "Network simulation",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "Renode has excellent network support"
                ),
                FeatureComparison(
                    "GUI debugging",
                    FeatureSupport.FULL,
                    FeatureSupport.PARTIAL,
                    "VEOS has integrated GUI, Renode has basic GUI"
                ),
                FeatureComparison(
                    "GDB integration",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "All support GDB debugging"
                ),
                FeatureComparison(
                    "Platform support",
                    FeatureSupport.PARTIAL,
                    FeatureSupport.FULL,
                    "QEMU supports many architectures"
                ),
                FeatureComparison(
                    "Scripting/Automation",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "Renode has Python API, QEMU has QMP"
                )
            ],
            "use_cases": {
                "CI/CD testing": "renode",
                "Early software development": "qemu",
                "Complex ECU simulation": "veos",
                "Multi-node networks": "renode",
                "Architecture exploration": "qemu",
                "HIL testing": "veos"
            },
            "migration_difficulty": "easy",
            "cost_savings": "$20,000 - $50,000 per license",
            "recommendation": "QEMU/Renode excellent for most use cases. VEOS provides better integration with dSPACE ecosystem."
        },

        "testing": {
            "commercial": "vectorcast",
            "opensource": ["googletest"],
            "features": [
                FeatureComparison(
                    "Unit testing",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "Both fully support unit testing"
                ),
                FeatureComparison(
                    "Code coverage",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "gcov/lcov provide coverage for GoogleTest"
                ),
                FeatureComparison(
                    "Mocking framework",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "GoogleMock included with GoogleTest"
                ),
                FeatureComparison(
                    "Automotive standards compliance",
                    FeatureSupport.FULL,
                    FeatureSupport.PARTIAL,
                    "VectorCAST certified for ISO 26262"
                ),
                FeatureComparison(
                    "Regression testing",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "Both support regression testing"
                ),
                FeatureComparison(
                    "CI/CD integration",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "GoogleTest integrates easily with Jenkins/GitLab"
                ),
                FeatureComparison(
                    "Test report generation",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "Both generate XML reports"
                ),
                FeatureComparison(
                    "Learning curve",
                    FeatureSupport.PARTIAL,
                    FeatureSupport.FULL,
                    "GoogleTest easier to learn"
                )
            ],
            "use_cases": {
                "ISO 26262 projects": "vectorcast",
                "General unit testing": "googletest",
                "CI/CD pipelines": "googletest",
                "Certification required": "vectorcast",
                "Open-source projects": "googletest"
            },
            "migration_difficulty": "easy",
            "cost_savings": "$15,000 - $40,000 per license",
            "recommendation": "GoogleTest for most use cases. VectorCAST only when tool certification required for safety standards."
        },

        "static_analysis": {
            "commercial": "polyspace",
            "opensource": ["cppcheck", "clang-tidy"],
            "features": [
                FeatureComparison(
                    "Undefined behavior detection",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "All detect undefined behavior"
                ),
                FeatureComparison(
                    "MISRA C checking",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "clang-tidy has MISRA plugin"
                ),
                FeatureComparison(
                    "Formal verification",
                    FeatureSupport.FULL,
                    FeatureSupport.NONE,
                    "Polyspace uses formal methods"
                ),
                FeatureComparison(
                    "False positive rate",
                    FeatureSupport.FULL,
                    FeatureSupport.PARTIAL,
                    "Polyspace has lower false positives"
                ),
                FeatureComparison(
                    "Performance",
                    FeatureSupport.PARTIAL,
                    FeatureSupport.FULL,
                    "cppcheck/clang-tidy faster"
                ),
                FeatureComparison(
                    "CI/CD integration",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "All integrate with CI/CD"
                ),
                FeatureComparison(
                    "Custom rules",
                    FeatureSupport.FULL,
                    FeatureSupport.FULL,
                    "clang-tidy supports custom checks"
                ),
                FeatureComparison(
                    "Code modernization",
                    FeatureSupport.NONE,
                    FeatureSupport.FULL,
                    "clang-tidy can modernize code"
                )
            ],
            "use_cases": {
                "Safety-critical verification": "polyspace",
                "CI/CD quality gates": "clang-tidy",
                "Quick local checks": "cppcheck",
                "MISRA compliance": "clang-tidy",
                "Formal proof required": "polyspace"
            },
            "migration_difficulty": "easy",
            "cost_savings": "$30,000 - $80,000 per license",
            "recommendation": "Use cppcheck + clang-tidy for 90% of projects. Polyspace only for safety-critical systems requiring formal verification."
        }
    }

    def __init__(self):
        """Initialize the comparator."""
        self.tool_db = self.TOOL_DATABASE
        self.feature_matrices = self.FEATURE_MATRICES

    def compare_tools(
        self,
        commercial_tool: str,
        opensource_tool: str
    ) -> Optional[ComparisonMatrix]:
        """
        Compare a commercial tool with an opensource alternative.

        Args:
            commercial_tool: Commercial tool name
            opensource_tool: Opensource tool name

        Returns:
            ComparisonMatrix or None if tools not found
        """
        comm_tool = self.tool_db.get(commercial_tool)
        oss_tool = self.tool_db.get(opensource_tool)

        if not comm_tool or not oss_tool:
            logger.error(f"Tool(s) not found: {commercial_tool}, {opensource_tool}")
            return None

        if comm_tool.category != oss_tool.category:
            logger.error(f"Tools from different categories: {comm_tool.category} vs {oss_tool.category}")
            return None

        category = comm_tool.category
        matrix_spec = self.feature_matrices.get(category)

        if not matrix_spec:
            logger.error(f"No feature matrix for category: {category}")
            return None

        return ComparisonMatrix(
            category=category,
            commercial_tool=comm_tool,
            opensource_tools=[oss_tool],
            feature_comparisons=matrix_spec["features"],
            use_cases=matrix_spec["use_cases"],
            migration_difficulty=matrix_spec["migration_difficulty"],
            cost_savings_estimate=matrix_spec["cost_savings"],
            recommendation=matrix_spec["recommendation"]
        )

    def compare_category(self, category: str) -> Optional[ComparisonMatrix]:
        """
        Get complete comparison for a tool category.

        Args:
            category: Category name

        Returns:
            ComparisonMatrix or None
        """
        if category not in self.feature_matrices:
            logger.error(f"Category not found: {category}")
            return None

        matrix_spec = self.feature_matrices[category]

        comm_tool_name = matrix_spec["commercial"]
        oss_tool_names = matrix_spec["opensource"]

        comm_tool = self.tool_db[comm_tool_name]
        oss_tools = [self.tool_db[name] for name in oss_tool_names]

        return ComparisonMatrix(
            category=category,
            commercial_tool=comm_tool,
            opensource_tools=oss_tools,
            feature_comparisons=matrix_spec["features"],
            use_cases=matrix_spec["use_cases"],
            migration_difficulty=matrix_spec["migration_difficulty"],
            cost_savings_estimate=matrix_spec["cost_savings"],
            recommendation=matrix_spec["recommendation"]
        )

    def export_comparison_matrix(
        self,
        matrix: ComparisonMatrix,
        output_path: str,
        format: str = "markdown"
    ) -> None:
        """
        Export comparison matrix to file.

        Args:
            matrix: Comparison matrix
            output_path: Output file path
            format: Output format (markdown, json, html)
        """
        if format == "markdown":
            self._export_markdown(matrix, output_path)
        elif format == "json":
            self._export_json(matrix, output_path)
        elif format == "html":
            self._export_html(matrix, output_path)
        else:
            raise ValueError(f"Unsupported format: {format}")

    def _export_markdown(self, matrix: ComparisonMatrix, output_path: str) -> None:
        """Export comparison as Markdown table."""
        lines = [
            f"# {matrix.category.replace('_', ' ').title()} Tool Comparison",
            "",
            f"## {matrix.commercial_tool.name} vs {', '.join(t.name for t in matrix.opensource_tools)}",
            "",
            "### Overview",
            "",
            f"**Commercial**: {matrix.commercial_tool.name} ({matrix.commercial_tool.vendor})",
            f"**Opensource**: {', '.join(t.name for t in matrix.opensource_tools)}",
            "",
            "### Feature Comparison",
            "",
            "| Feature | Commercial | Opensource | Notes |",
            "|---------|------------|------------|-------|"
        ]

        for feat in matrix.feature_comparisons:
            comm_icon = self._support_to_icon(feat.commercial_support)
            oss_icon = self._support_to_icon(feat.opensource_support)
            lines.append(f"| {feat.feature_name} | {comm_icon} | {oss_icon} | {feat.notes} |")

        lines.extend([
            "",
            "### Use Case Recommendations",
            ""
        ])

        for use_case, tool in matrix.use_cases.items():
            lines.append(f"- **{use_case}**: {tool}")

        lines.extend([
            "",
            f"### Cost Savings: {matrix.cost_savings_estimate}",
            f"### Migration Difficulty: {matrix.migration_difficulty}",
            "",
            f"### Recommendation",
            "",
            matrix.recommendation
        ])

        with open(output_path, 'w') as f:
            f.write("\n".join(lines))

        logger.info(f"Markdown comparison exported to {output_path}")

    def _export_json(self, matrix: ComparisonMatrix, output_path: str) -> None:
        """Export comparison as JSON."""
        data = {
            "category": matrix.category,
            "commercial_tool": asdict(matrix.commercial_tool),
            "opensource_tools": [asdict(t) for t in matrix.opensource_tools],
            "feature_comparisons": [
                {
                    "feature": f.feature_name,
                    "commercial_support": f.commercial_support.value,
                    "opensource_support": f.opensource_support.value,
                    "notes": f.notes
                }
                for f in matrix.feature_comparisons
            ],
            "use_cases": matrix.use_cases,
            "migration_difficulty": matrix.migration_difficulty,
            "cost_savings": matrix.cost_savings_estimate,
            "recommendation": matrix.recommendation
        }

        with open(output_path, 'w') as f:
            json.dump(data, f, indent=2)

        logger.info(f"JSON comparison exported to {output_path}")

    def _export_html(self, matrix: ComparisonMatrix, output_path: str) -> None:
        """Export comparison as HTML."""
        html = f"""<!DOCTYPE html>
<html>
<head>
    <title>{matrix.category} Tool Comparison</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        table {{ border-collapse: collapse; width: 100%; margin: 20px 0; }}
        th, td {{ border: 1px solid #ddd; padding: 12px; text-align: left; }}
        th {{ background-color: #4CAF50; color: white; }}
        .full {{ color: green; }}
        .partial {{ color: orange; }}
        .none {{ color: red; }}
    </style>
</head>
<body>
    <h1>{matrix.category.replace('_', ' ').title()} Comparison</h1>
    <h2>{matrix.commercial_tool.name} vs {', '.join(t.name for t in matrix.opensource_tools)}</h2>

    <h3>Feature Comparison</h3>
    <table>
        <tr>
            <th>Feature</th>
            <th>Commercial</th>
            <th>Opensource</th>
            <th>Notes</th>
        </tr>
"""

        for feat in matrix.feature_comparisons:
            comm_support = feat.commercial_support.value
            oss_support = feat.opensource_support.value
            html += f"""        <tr>
            <td>{feat.feature_name}</td>
            <td class="{comm_support}">{comm_support}</td>
            <td class="{oss_support}">{oss_support}</td>
            <td>{feat.notes}</td>
        </tr>
"""

        html += """    </table>

    <h3>Cost Savings</h3>
    <p>{}</p>

    <h3>Recommendation</h3>
    <p>{}</p>
</body>
</html>""".format(matrix.cost_savings_estimate, matrix.recommendation)

        with open(output_path, 'w') as f:
            f.write(html)

        logger.info(f"HTML comparison exported to {output_path}")

    def _support_to_icon(self, support: FeatureSupport) -> str:
        """Convert feature support to icon."""
        icons = {
            FeatureSupport.FULL: "✓ Full",
            FeatureSupport.PARTIAL: "◐ Partial",
            FeatureSupport.NONE: "✗ None",
            FeatureSupport.PLANNED: "⏳ Planned"
        }
        return icons.get(support, "?")

    def get_all_categories(self) -> List[str]:
        """Get list of all comparison categories."""
        return list(self.feature_matrices.keys())

    def export_all_comparisons(self, output_dir: str, format: str = "markdown") -> None:
        """
        Export all comparison matrices.

        Args:
            output_dir: Output directory
            format: Output format
        """
        from pathlib import Path

        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)

        for category in self.get_all_categories():
            matrix = self.compare_category(category)
            if matrix:
                filename = f"{category}_comparison.{format if format != 'markdown' else 'md'}"
                self.export_comparison_matrix(
                    matrix,
                    str(output_path / filename),
                    format
                )

        logger.info(f"All comparisons exported to {output_dir}")


def main():
    """Main entry point."""
    logging.basicConfig(level=logging.INFO)

    comparator = ToolComparator()

    # Example: Compare vehicle network tools
    print("\n=== CAN/Vehicle Network Tool Comparison ===")
    matrix = comparator.compare_category("vehicle_network")

    if matrix:
        print(f"\nComparing: {matrix.commercial_tool.name} vs {', '.join(t.name for t in matrix.opensource_tools)}")
        print(f"\nFeatures:")
        for feat in matrix.feature_comparisons[:5]:  # Show first 5
            print(f"  {feat.feature_name}: Commercial={feat.commercial_support.value}, OSS={feat.opensource_support.value}")

        print(f"\nCost savings: {matrix.cost_savings_estimate}")
        print(f"Migration difficulty: {matrix.migration_difficulty}")

        # Export comparisons
        comparator.export_all_comparisons("/tmp/tool_comparisons", "markdown")


if __name__ == "__main__":
    main()
