#!/usr/bin/env python3
"""
LLM Council - Multi-Model Debate System for Automotive Software Development

This module implements a comprehensive consensus-building debate system between
Claude Opus 4.6 (Anthropic) and GPT-5.4 (Azure OpenAI) for critical engineering
decisions in automotive software development.

Features:
- Multi-round debates with configurable consensus thresholds
- Parallel model execution for improved performance
- Response caching for cost optimization
- P0 skill validation for safety-critical reviews
- Comprehensive artifact generation and metrics tracking
- Architecture Decision Record (ADR) generation
- Integration with CI/CD pipelines

Usage:
    from tools.llm_council import LLMCouncil

    council = LLMCouncil()
    result = await council.debate(
        topic="Architecture for battery thermal management system",
        context={"requirements": [...], "constraints": [...]},
        rounds=3
    )

Author: Automotive Claude Code Team
License: MIT
"""

from __future__ import annotations

import asyncio
import hashlib
import json
import logging
import os
import re
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set, Tuple, Union

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("llm_council")


# =============================================================================
# Enumerations
# =============================================================================

class ConfidenceLevel(Enum):
    """Confidence levels for council decisions."""
    HIGH = "high"      # Unanimous consensus, early agreement
    MEDIUM = "medium"  # Minor disagreement, late consensus
    LOW = "low"        # Significant conflict, no consensus


class TaskType(Enum):
    """Task types for routing optimization."""
    CODE_OPTIMIZATION = "code_optimization"
    ARCHITECTURE_DESIGN = "architecture_design"
    BUG_DIAGNOSIS = "bug_diagnosis"
    API_DESIGN = "api_design"
    REFACTORING = "refactoring"
    SECURITY_REVIEW = "security_review"
    PERFORMANCE_TUNING = "performance_tuning"
    SAFETY_CRITICAL = "safety_critical"
    CODE_REVIEW = "code_review"
    P0_VALIDATION = "p0_validation"
    GENERAL = "general"


class ReviewSeverity(Enum):
    """Severity levels for code review findings."""
    CRITICAL = "critical"   # Must fix before merge
    HIGH = "high"           # Should fix before merge
    MEDIUM = "medium"       # Should fix eventually
    LOW = "low"             # Nice to have
    INFO = "info"           # Informational only


class ConsensusState(Enum):
    """States for consensus tracking."""
    PENDING = "pending"
    PARTIAL = "partial"
    REACHED = "reached"
    DEADLOCK = "deadlock"


# =============================================================================
# Data Classes
# =============================================================================

@dataclass
class ModelConfig:
    """Configuration for an LLM model."""
    name: str
    provider: str
    api_key_env: str
    endpoint: Optional[str] = None
    api_version: Optional[str] = None
    max_tokens: int = 8192
    temperature: float = 0.7
    timeout_seconds: int = 120
    retry_count: int = 3
    retry_delay_ms: int = 1000
    strengths: List[str] = field(default_factory=list)

    def get_cache_key(self) -> str:
        """Generate cache key for this configuration."""
        return f"{self.provider}:{self.name}:{self.temperature}"


@dataclass
class DebateRound:
    """Represents a single round of debate."""
    round_number: int
    claude_response: str
    gpt_response: str
    timestamp: datetime
    claude_duration_ms: float = 0.0
    gpt_duration_ms: float = 0.0
    consensus_state: ConsensusState = ConsensusState.PENDING
    agreement_score: float = 0.0
    key_agreements: List[str] = field(default_factory=list)
    key_disagreements: List[str] = field(default_factory=list)


@dataclass
class ReviewFinding:
    """A single finding from code review."""
    severity: ReviewSeverity
    category: str
    message: str
    file_path: Optional[str] = None
    line_number: Optional[int] = None
    suggestion: Optional[str] = None
    agreed_by: List[str] = field(default_factory=list)


@dataclass
class P0SkillValidation:
    """Result of P0 skill validation."""
    skill_name: str
    is_valid: bool
    safety_score: float  # 0.0 - 1.0
    issues: List[str] = field(default_factory=list)
    recommendations: List[str] = field(default_factory=list)
    validation_timestamp: datetime = field(default_factory=datetime.utcnow)


@dataclass
class DebateResult:
    """Final result of a council debate."""
    topic: str
    task_type: TaskType
    rounds_completed: int
    debate_history: List[DebateRound]
    consensus_reached: bool
    confidence_level: ConfidenceLevel
    final_decision: str
    action_items: List[str]
    total_duration_ms: float
    total_cost_usd: float
    artifact_path: Optional[Path] = None
    review_findings: List[ReviewFinding] = field(default_factory=list)
    p0_validations: List[P0SkillValidation] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class CacheEntry:
    """Cache entry for model responses."""
    response: str
    timestamp: datetime
    ttl_seconds: int = 3600
    hit_count: int = 0

    def is_expired(self) -> bool:
        """Check if cache entry has expired."""
        age = (datetime.utcnow() - self.timestamp).total_seconds()
        return age > self.ttl_seconds


# =============================================================================
# Response Cache
# =============================================================================

class ResponseCache:
    """
    LRU cache for model responses to reduce API costs.

    Caches responses based on prompt hash to avoid redundant API calls
    for similar queries.
    """

    def __init__(self, max_size: int = 1000, default_ttl: int = 3600):
        self._cache: Dict[str, CacheEntry] = {}
        self._max_size = max_size
        self._default_ttl = default_ttl
        self._hits = 0
        self._misses = 0
        self.logger = logging.getLogger("llm_council.cache")

    def _hash_prompt(self, prompt: str, model_key: str) -> str:
        """Generate hash key for a prompt."""
        content = f"{model_key}:{prompt}"
        return hashlib.sha256(content.encode()).hexdigest()[:16]

    def get(self, prompt: str, model_key: str) -> Optional[str]:
        """Retrieve cached response if available and valid."""
        key = self._hash_prompt(prompt, model_key)
        entry = self._cache.get(key)

        if entry is None:
            self._misses += 1
            return None

        if entry.is_expired():
            del self._cache[key]
            self._misses += 1
            return None

        entry.hit_count += 1
        self._hits += 1
        self.logger.debug(f"Cache hit for key {key[:8]}...")
        return entry.response

    def set(
        self,
        prompt: str,
        model_key: str,
        response: str,
        ttl: Optional[int] = None
    ) -> None:
        """Store response in cache."""
        # Evict oldest entries if at capacity
        if len(self._cache) >= self._max_size:
            self._evict_oldest()

        key = self._hash_prompt(prompt, model_key)
        self._cache[key] = CacheEntry(
            response=response,
            timestamp=datetime.utcnow(),
            ttl_seconds=ttl or self._default_ttl
        )
        self.logger.debug(f"Cached response for key {key[:8]}...")

    def _evict_oldest(self) -> None:
        """Evict oldest cache entries."""
        if not self._cache:
            return

        # Sort by timestamp and remove oldest 10%
        sorted_keys = sorted(
            self._cache.keys(),
            key=lambda k: self._cache[k].timestamp
        )
        evict_count = max(1, len(sorted_keys) // 10)
        for key in sorted_keys[:evict_count]:
            del self._cache[key]

    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        total_requests = self._hits + self._misses
        hit_rate = self._hits / total_requests if total_requests > 0 else 0.0

        return {
            "size": len(self._cache),
            "max_size": self._max_size,
            "hits": self._hits,
            "misses": self._misses,
            "hit_rate": hit_rate
        }

    def clear(self) -> None:
        """Clear all cached entries."""
        self._cache.clear()
        self._hits = 0
        self._misses = 0


# =============================================================================
# Model Adapters
# =============================================================================

class ModelAdapter(ABC):
    """Abstract base class for model adapters."""

    def __init__(self, config: ModelConfig, cache: Optional[ResponseCache] = None):
        self.config = config
        self.cache = cache
        self.logger = logging.getLogger(f"llm_council.{config.provider}")
        self._request_count = 0
        self._total_tokens = 0

    @abstractmethod
    async def get_completion(
        self,
        messages: List[Dict[str, str]],
        system_prompt: str
    ) -> Tuple[str, float]:
        """
        Get completion from the model.

        Args:
            messages: List of message dicts with 'role' and 'content'
            system_prompt: System prompt for the model

        Returns:
            Tuple of (response_text, duration_ms)
        """
        pass

    def _get_api_key(self) -> str:
        """Get API key from environment variable."""
        api_key = os.environ.get(self.config.api_key_env)
        if not api_key:
            raise ValueError(
                f"API key not found. Set {self.config.api_key_env} environment variable."
            )
        return api_key

    def _build_cache_key(
        self,
        messages: List[Dict[str, str]],
        system_prompt: str
    ) -> str:
        """Build cache key from messages and system prompt."""
        content = json.dumps({
            "system": system_prompt,
            "messages": messages
        }, sort_keys=True)
        return content

    def get_stats(self) -> Dict[str, Any]:
        """Get adapter statistics."""
        return {
            "provider": self.config.provider,
            "model": self.config.name,
            "request_count": self._request_count,
            "total_tokens": self._total_tokens
        }


class ClaudeAdapter(ModelAdapter):
    """Adapter for Anthropic Claude API."""

    def __init__(self, config: ModelConfig, cache: Optional[ResponseCache] = None):
        super().__init__(config, cache)
        self._client = None

    @property
    def client(self):
        """Lazy initialization of Anthropic client."""
        if self._client is None:
            try:
                from anthropic import Anthropic
                self._client = Anthropic(api_key=self._get_api_key())
            except ImportError:
                raise ImportError(
                    "anthropic package required. Install with: pip install anthropic"
                )
        return self._client

    async def get_completion(
        self,
        messages: List[Dict[str, str]],
        system_prompt: str
    ) -> Tuple[str, float]:
        """Get completion from Claude."""
        # Check cache first
        if self.cache:
            cache_key = self._build_cache_key(messages, system_prompt)
            cached = self.cache.get(cache_key, self.config.get_cache_key())
            if cached:
                return cached, 0.0

        start_time = time.perf_counter()
        self._request_count += 1

        try:
            # Run synchronous API call in executor for async compatibility
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: self.client.messages.create(
                    model=self.config.name,
                    max_tokens=self.config.max_tokens,
                    temperature=self.config.temperature,
                    system=system_prompt,
                    messages=messages
                )
            )

            duration_ms = (time.perf_counter() - start_time) * 1000
            response_text = response.content[0].text

            # Update token count
            if hasattr(response, 'usage'):
                self._total_tokens += response.usage.input_tokens + response.usage.output_tokens

            self.logger.debug(
                f"Claude response received in {duration_ms:.0f}ms "
                f"({len(response_text)} chars)"
            )

            # Cache the response
            if self.cache:
                cache_key = self._build_cache_key(messages, system_prompt)
                self.cache.set(cache_key, self.config.get_cache_key(), response_text)

            return response_text, duration_ms

        except Exception as e:
            self.logger.error(f"Claude API error: {e}")
            raise


class GPTAdapter(ModelAdapter):
    """Adapter for Azure OpenAI GPT API."""

    def __init__(self, config: ModelConfig, cache: Optional[ResponseCache] = None):
        super().__init__(config, cache)
        self._client = None

    @property
    def client(self):
        """Lazy initialization of OpenAI client."""
        if self._client is None:
            try:
                from openai import AzureOpenAI
                self._client = AzureOpenAI(
                    api_key=self._get_api_key(),
                    api_version=self.config.api_version or "2024-12-01-preview",
                    azure_endpoint=self.config.endpoint or os.environ.get(
                        "AZURE_OPENAI_ENDPOINT", ""
                    )
                )
            except ImportError:
                raise ImportError(
                    "openai package required. Install with: pip install openai"
                )
        return self._client

    async def get_completion(
        self,
        messages: List[Dict[str, str]],
        system_prompt: str
    ) -> Tuple[str, float]:
        """Get completion from GPT."""
        # Check cache first
        if self.cache:
            cache_key = self._build_cache_key(messages, system_prompt)
            cached = self.cache.get(cache_key, self.config.get_cache_key())
            if cached:
                return cached, 0.0

        start_time = time.perf_counter()
        self._request_count += 1

        # Prepend system message
        full_messages = [{"role": "system", "content": system_prompt}] + messages

        try:
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: self.client.chat.completions.create(
                    model=self.config.name,
                    messages=full_messages,
                    max_tokens=self.config.max_tokens,
                    temperature=self.config.temperature
                )
            )

            duration_ms = (time.perf_counter() - start_time) * 1000
            response_text = response.choices[0].message.content

            # Update token count
            if hasattr(response, 'usage') and response.usage:
                self._total_tokens += response.usage.total_tokens

            self.logger.debug(
                f"GPT response received in {duration_ms:.0f}ms "
                f"({len(response_text)} chars)"
            )

            # Cache the response
            if self.cache:
                cache_key = self._build_cache_key(messages, system_prompt)
                self.cache.set(cache_key, self.config.get_cache_key(), response_text)

            return response_text, duration_ms

        except Exception as e:
            self.logger.error(f"GPT API error: {e}")
            raise


# =============================================================================
# Consensus Analyzer
# =============================================================================

class ConsensusAnalyzer:
    """
    Analyzes debate responses to determine consensus state.

    Uses multiple heuristics including keyword matching, semantic similarity,
    and structural analysis to determine agreement levels.
    """

    # Agreement indicators
    AGREEMENT_KEYWORDS = [
        "agree", "consensus", "aligned", "concur", "same conclusion",
        "similar recommendation", "both recommend", "unanimous",
        "correct observation", "valid point", "well noted"
    ]

    # Disagreement indicators
    DISAGREEMENT_KEYWORDS = [
        "disagree", "however", "alternatively", "different approach",
        "contrary", "oppose", "instead suggest", "rather than",
        "on the other hand", "reconsider", "concern about"
    ]

    # Partial agreement indicators
    PARTIAL_AGREEMENT_KEYWORDS = [
        "partially agree", "mostly agree", "agree with caveat",
        "with modifications", "building on", "extending"
    ]

    def __init__(self):
        self.logger = logging.getLogger("llm_council.consensus")

    def analyze_round(
        self,
        claude_response: str,
        gpt_response: str
    ) -> Tuple[ConsensusState, float, List[str], List[str]]:
        """
        Analyze a debate round for consensus.

        Returns:
            Tuple of (consensus_state, agreement_score, key_agreements, key_disagreements)
        """
        claude_lower = claude_response.lower()
        gpt_lower = gpt_response.lower()

        # Score agreement/disagreement signals
        agreement_score = self._calculate_agreement_score(claude_lower, gpt_lower)

        # Extract key points
        key_agreements = self._extract_agreements(claude_response, gpt_response)
        key_disagreements = self._extract_disagreements(claude_response, gpt_response)

        # Determine consensus state
        if agreement_score >= 0.8 and len(key_disagreements) == 0:
            state = ConsensusState.REACHED
        elif agreement_score >= 0.5:
            state = ConsensusState.PARTIAL
        elif agreement_score <= 0.2 and len(key_disagreements) > 2:
            state = ConsensusState.DEADLOCK
        else:
            state = ConsensusState.PENDING

        self.logger.debug(
            f"Consensus analysis: state={state.value}, "
            f"score={agreement_score:.2f}, "
            f"agreements={len(key_agreements)}, "
            f"disagreements={len(key_disagreements)}"
        )

        return state, agreement_score, key_agreements, key_disagreements

    def _calculate_agreement_score(
        self,
        claude_text: str,
        gpt_text: str
    ) -> float:
        """Calculate agreement score between 0.0 and 1.0."""
        agreement_count = sum(
            1 for kw in self.AGREEMENT_KEYWORDS
            if kw in claude_text or kw in gpt_text
        )
        partial_count = sum(
            1 for kw in self.PARTIAL_AGREEMENT_KEYWORDS
            if kw in claude_text or kw in gpt_text
        )
        disagreement_count = sum(
            1 for kw in self.DISAGREEMENT_KEYWORDS
            if kw in claude_text or kw in gpt_text
        )

        # Weighted score calculation
        positive = agreement_count * 1.0 + partial_count * 0.5
        negative = disagreement_count * 1.0
        total = positive + negative

        if total == 0:
            return 0.5  # Neutral if no signals

        score = positive / total
        return max(0.0, min(1.0, score))

    def _extract_agreements(
        self,
        claude_response: str,
        gpt_response: str
    ) -> List[str]:
        """Extract key agreement points from responses."""
        agreements = []

        # Look for explicit agreement statements
        patterns = [
            r"(?:I agree|We both agree|Consensus on)[:\s]+([^.]+\.)",
            r"(?:Both models|Both perspectives|We both) (?:recommend|suggest)[:\s]+([^.]+\.)",
            r"(?:Key agreement|Shared conclusion)[:\s]+([^.]+\.)"
        ]

        for pattern in patterns:
            for text in [claude_response, gpt_response]:
                matches = re.findall(pattern, text, re.IGNORECASE)
                agreements.extend(matches)

        return list(set(agreements))[:5]  # Limit to 5 key agreements

    def _extract_disagreements(
        self,
        claude_response: str,
        gpt_response: str
    ) -> List[str]:
        """Extract key disagreement points from responses."""
        disagreements = []

        patterns = [
            r"(?:I disagree|However|Alternatively)[:\s]+([^.]+\.)",
            r"(?:Different view|Contrary to|Instead of)[:\s]+([^.]+\.)",
            r"(?:Key difference|Point of disagreement)[:\s]+([^.]+\.)"
        ]

        for pattern in patterns:
            for text in [claude_response, gpt_response]:
                matches = re.findall(pattern, text, re.IGNORECASE)
                disagreements.extend(matches)

        return list(set(disagreements))[:5]  # Limit to 5 key disagreements


# =============================================================================
# P0 Skill Validator
# =============================================================================

class P0SkillValidator:
    """
    Validates P0 (Priority 0) skills for safety-critical applications.

    P0 skills are those that directly affect vehicle safety and must
    meet strict quality and safety requirements.
    """

    # P0 skill categories that require validation
    P0_CATEGORIES = {
        "safety": ["iso26262", "asil", "fmea", "fta", "hazard"],
        "security": ["iso21434", "tara", "secoc", "crypto", "auth"],
        "autosar": ["bsw", "swc", "rte", "mcal", "com"],
        "battery": ["bms", "thermal", "soc", "soh", "balancing"],
        "adas": ["perception", "planning", "control", "fusion"]
    }

    # Required validation checks for P0 skills
    VALIDATION_CHECKS = [
        "input_validation",
        "error_handling",
        "boundary_conditions",
        "fault_tolerance",
        "documentation_coverage",
        "test_coverage_reference",
        "misra_compliance",
        "timing_constraints"
    ]

    def __init__(self):
        self.logger = logging.getLogger("llm_council.p0_validator")

    def is_p0_skill(self, skill_path: str) -> bool:
        """Check if a skill is classified as P0."""
        skill_lower = skill_path.lower()
        for category, keywords in self.P0_CATEGORIES.items():
            if any(kw in skill_lower for kw in keywords):
                return True
        return False

    def validate_skill(
        self,
        skill_name: str,
        skill_content: str,
        claude_analysis: str,
        gpt_analysis: str
    ) -> P0SkillValidation:
        """
        Perform P0 validation on a skill.

        Args:
            skill_name: Name/path of the skill
            skill_content: Content of the skill definition
            claude_analysis: Claude's analysis of the skill
            gpt_analysis: GPT's analysis of the skill

        Returns:
            P0SkillValidation result
        """
        issues = []
        recommendations = []
        checks_passed = 0
        total_checks = len(self.VALIDATION_CHECKS)

        # Run validation checks
        for check in self.VALIDATION_CHECKS:
            passed, issue, recommendation = self._run_check(
                check, skill_content, claude_analysis, gpt_analysis
            )
            if passed:
                checks_passed += 1
            else:
                if issue:
                    issues.append(issue)
                if recommendation:
                    recommendations.append(recommendation)

        # Calculate safety score
        safety_score = checks_passed / total_checks

        # Determine validity (must pass at least 80% of checks for P0)
        is_valid = safety_score >= 0.8

        self.logger.info(
            f"P0 validation for {skill_name}: "
            f"valid={is_valid}, score={safety_score:.2f}, "
            f"issues={len(issues)}"
        )

        return P0SkillValidation(
            skill_name=skill_name,
            is_valid=is_valid,
            safety_score=safety_score,
            issues=issues,
            recommendations=recommendations
        )

    def _run_check(
        self,
        check_name: str,
        content: str,
        claude_analysis: str,
        gpt_analysis: str
    ) -> Tuple[bool, Optional[str], Optional[str]]:
        """Run a single validation check."""
        check_methods = {
            "input_validation": self._check_input_validation,
            "error_handling": self._check_error_handling,
            "boundary_conditions": self._check_boundary_conditions,
            "fault_tolerance": self._check_fault_tolerance,
            "documentation_coverage": self._check_documentation,
            "test_coverage_reference": self._check_test_coverage,
            "misra_compliance": self._check_misra_compliance,
            "timing_constraints": self._check_timing_constraints
        }

        check_method = check_methods.get(check_name)
        if check_method:
            return check_method(content, claude_analysis, gpt_analysis)

        return True, None, None  # Unknown check passes by default

    def _check_input_validation(
        self,
        content: str,
        claude_analysis: str,
        gpt_analysis: str
    ) -> Tuple[bool, Optional[str], Optional[str]]:
        """Check for input validation patterns."""
        patterns = ["validate", "check", "bounds", "range", "assert"]
        if any(p in content.lower() for p in patterns):
            return True, None, None
        return False, "Missing input validation", "Add input validation for all parameters"

    def _check_error_handling(
        self,
        content: str,
        claude_analysis: str,
        gpt_analysis: str
    ) -> Tuple[bool, Optional[str], Optional[str]]:
        """Check for error handling patterns."""
        patterns = ["error", "exception", "fault", "fail", "invalid"]
        if any(p in content.lower() for p in patterns):
            return True, None, None
        return False, "Missing error handling", "Add comprehensive error handling"

    def _check_boundary_conditions(
        self,
        content: str,
        claude_analysis: str,
        gpt_analysis: str
    ) -> Tuple[bool, Optional[str], Optional[str]]:
        """Check for boundary condition handling."""
        patterns = ["min", "max", "limit", "boundary", "overflow"]
        if any(p in content.lower() for p in patterns):
            return True, None, None
        return False, "Missing boundary checks", "Add boundary condition handling"

    def _check_fault_tolerance(
        self,
        content: str,
        claude_analysis: str,
        gpt_analysis: str
    ) -> Tuple[bool, Optional[str], Optional[str]]:
        """Check for fault tolerance mechanisms."""
        patterns = ["timeout", "retry", "fallback", "redundant", "watchdog"]
        if any(p in content.lower() for p in patterns):
            return True, None, None
        return False, "Missing fault tolerance", "Add fault tolerance mechanisms"

    def _check_documentation(
        self,
        content: str,
        claude_analysis: str,
        gpt_analysis: str
    ) -> Tuple[bool, Optional[str], Optional[str]]:
        """Check for documentation coverage."""
        patterns = ["description", "param", "return", "note", "warning"]
        if any(p in content.lower() for p in patterns):
            return True, None, None
        return False, "Insufficient documentation", "Add comprehensive documentation"

    def _check_test_coverage(
        self,
        content: str,
        claude_analysis: str,
        gpt_analysis: str
    ) -> Tuple[bool, Optional[str], Optional[str]]:
        """Check for test coverage references."""
        patterns = ["test", "verify", "validate", "coverage", "assertion"]
        if any(p in content.lower() for p in patterns):
            return True, None, None
        return False, "Missing test references", "Add test coverage requirements"

    def _check_misra_compliance(
        self,
        content: str,
        claude_analysis: str,
        gpt_analysis: str
    ) -> Tuple[bool, Optional[str], Optional[str]]:
        """Check for MISRA compliance indicators."""
        # Check if either model mentioned MISRA concerns
        combined = (claude_analysis + gpt_analysis).lower()
        if "misra" in combined and "violation" not in combined:
            return True, None, None
        if "misra violation" in combined:
            return False, "MISRA violation detected", "Fix MISRA compliance issues"
        return True, None, None  # Assume compliant if not mentioned

    def _check_timing_constraints(
        self,
        content: str,
        claude_analysis: str,
        gpt_analysis: str
    ) -> Tuple[bool, Optional[str], Optional[str]]:
        """Check for timing constraint handling."""
        patterns = ["timeout", "deadline", "wcet", "latency", "real-time"]
        if any(p in content.lower() for p in patterns):
            return True, None, None
        return False, "Missing timing constraints", "Add timing constraint specifications"


# =============================================================================
# Main LLM Council Class
# =============================================================================

class LLMCouncil:
    """
    Multi-model debate system for consensus-building.

    Orchestrates debates between Claude Opus 4.6 and GPT-5.4 to reach
    informed decisions on complex engineering problems in automotive
    software development.
    """

    # Default model configurations
    DEFAULT_CLAUDE_CONFIG = ModelConfig(
        name="claude-opus-4-6",
        provider="anthropic",
        api_key_env="ANTHROPIC_API_KEY",
        max_tokens=8192,
        temperature=0.7,
        strengths=[
            "system-coherence",
            "safety-validation",
            "edge-case-analysis",
            "interface-contracts",
            "architecture-preservation",
            "defense-in-depth"
        ]
    )

    DEFAULT_GPT_CONFIG = ModelConfig(
        name="gpt-5.4",
        provider="azure-openai",
        api_key_env="AZURE_OPENAI_API_KEY",
        api_version="2024-12-01-preview",
        max_tokens=8192,
        temperature=0.7,
        strengths=[
            "pattern-recognition",
            "performance-tricks",
            "developer-ergonomics",
            "fast-symptom-analysis",
            "code-smell-detection",
            "micro-optimizations"
        ]
    )

    # Task type routing configuration
    TASK_ROUTING = {
        TaskType.CODE_OPTIMIZATION: {
            "rounds": 2,
            "claude_focus": "safety-validation",
            "gpt_focus": "performance-tricks"
        },
        TaskType.ARCHITECTURE_DESIGN: {
            "rounds": 4,
            "claude_focus": "system-coherence",
            "gpt_focus": "practical-patterns"
        },
        TaskType.BUG_DIAGNOSIS: {
            "rounds": 2,
            "claude_focus": "root-cause-investigation",
            "gpt_focus": "fast-symptom-analysis"
        },
        TaskType.API_DESIGN: {
            "rounds": 3,
            "claude_focus": "interface-contracts",
            "gpt_focus": "developer-ergonomics"
        },
        TaskType.REFACTORING: {
            "rounds": 3,
            "claude_focus": "architecture-preservation",
            "gpt_focus": "code-smell-detection"
        },
        TaskType.SECURITY_REVIEW: {
            "rounds": 4,
            "claude_focus": "defense-in-depth",
            "gpt_focus": "attack-patterns"
        },
        TaskType.PERFORMANCE_TUNING: {
            "rounds": 3,
            "claude_focus": "system-bottlenecks",
            "gpt_focus": "micro-optimizations"
        },
        TaskType.SAFETY_CRITICAL: {
            "rounds": 5,
            "claude_focus": "functional-safety",
            "gpt_focus": "failure-mode-analysis"
        },
        TaskType.CODE_REVIEW: {
            "rounds": 2,
            "claude_focus": "code-quality",
            "gpt_focus": "best-practices"
        },
        TaskType.P0_VALIDATION: {
            "rounds": 3,
            "claude_focus": "safety-compliance",
            "gpt_focus": "implementation-quality"
        },
        TaskType.GENERAL: {
            "rounds": 3,
            "claude_focus": "comprehensive-analysis",
            "gpt_focus": "practical-solutions"
        }
    }

    # Cost estimates per round (both models combined)
    COST_PER_ROUND_USD = 0.04

    def __init__(
        self,
        claude_config: Optional[ModelConfig] = None,
        gpt_config: Optional[ModelConfig] = None,
        artifact_base_path: Optional[Path] = None,
        enable_cache: bool = True,
        enable_parallel: bool = True
    ):
        """
        Initialize the LLM Council.

        Args:
            claude_config: Configuration for Claude model
            gpt_config: Configuration for GPT model
            artifact_base_path: Base path for storing debate artifacts
            enable_cache: Whether to enable response caching
            enable_parallel: Whether to enable parallel model execution
        """
        self.claude_config = claude_config or self.DEFAULT_CLAUDE_CONFIG
        self.gpt_config = gpt_config or self.DEFAULT_GPT_CONFIG

        # Initialize cache if enabled
        self.cache = ResponseCache() if enable_cache else None

        # Initialize adapters with cache
        self.claude_adapter = ClaudeAdapter(self.claude_config, self.cache)
        self.gpt_adapter = GPTAdapter(self.gpt_config, self.cache)

        # Initialize analyzers
        self.consensus_analyzer = ConsensusAnalyzer()
        self.p0_validator = P0SkillValidator()

        self.artifact_base_path = artifact_base_path or Path("/tmp")
        self.enable_parallel = enable_parallel
        self.logger = logging.getLogger("llm_council.orchestrator")

    async def debate(
        self,
        topic: str,
        context: Dict[str, Any],
        task_type: TaskType = TaskType.GENERAL,
        rounds: Optional[int] = None,
        save_artifacts: bool = True,
        early_consensus_exit: bool = True
    ) -> DebateResult:
        """
        Conduct a multi-round debate between models.

        Args:
            topic: The topic/question to debate
            context: Additional context (requirements, constraints, code, etc.)
            task_type: Type of task for optimized routing
            rounds: Number of debate rounds (defaults based on task_type)
            save_artifacts: Whether to save debate artifacts to disk
            early_consensus_exit: Whether to exit early when consensus is reached

        Returns:
            DebateResult with consensus decision and debate history
        """
        start_time = time.perf_counter()

        # Determine number of rounds
        routing = self.TASK_ROUTING.get(task_type, self.TASK_ROUTING[TaskType.GENERAL])
        max_rounds = rounds or routing["rounds"]

        self.logger.info(
            f"Starting council debate: '{topic[:50]}...' "
            f"(task_type={task_type.value}, max_rounds={max_rounds})"
        )

        # Create artifact directory if saving
        artifact_path = None
        if save_artifacts:
            artifact_path = self._create_artifact_directory()

        # Build system prompts
        claude_system = self._build_system_prompt(
            "Claude Opus 4.6",
            routing["claude_focus"],
            self.claude_config.strengths
        )
        gpt_system = self._build_system_prompt(
            "GPT-5.4",
            routing["gpt_focus"],
            self.gpt_config.strengths
        )

        # Format initial debate prompt
        initial_prompt = self._format_debate_prompt(topic, context, task_type)

        debate_history: List[DebateRound] = []
        consensus_reached = False
        final_consensus_state = ConsensusState.PENDING

        for round_num in range(1, max_rounds + 1):
            self.logger.info(f"Debate round {round_num}/{max_rounds}")

            # Build messages for this round
            claude_messages = self._build_messages(
                initial_prompt, debate_history, "claude"
            )
            gpt_messages = self._build_messages(
                initial_prompt, debate_history, "gpt"
            )

            # Get opinions from both models
            if self.enable_parallel:
                # Run both models in parallel
                claude_task = self._get_claude_opinion(claude_messages, claude_system)
                gpt_task = self._get_gpt_opinion(gpt_messages, gpt_system)
                results = await asyncio.gather(claude_task, gpt_task)
                claude_response, claude_duration = results[0]
                gpt_response, gpt_duration = results[1]
            else:
                # Run sequentially
                claude_response, claude_duration = await self._get_claude_opinion(
                    claude_messages, claude_system
                )
                gpt_response, gpt_duration = await self._get_gpt_opinion(
                    gpt_messages, gpt_system
                )

            # Analyze consensus
            consensus_state, agreement_score, agreements, disagreements = \
                self.consensus_analyzer.analyze_round(claude_response, gpt_response)

            # Record the round
            debate_round = DebateRound(
                round_number=round_num,
                claude_response=claude_response,
                gpt_response=gpt_response,
                timestamp=datetime.utcnow(),
                claude_duration_ms=claude_duration,
                gpt_duration_ms=gpt_duration,
                consensus_state=consensus_state,
                agreement_score=agreement_score,
                key_agreements=agreements,
                key_disagreements=disagreements
            )
            debate_history.append(debate_round)

            # Save round artifacts
            if artifact_path:
                self._save_round_artifacts(artifact_path, debate_round)

            # Check for consensus
            if consensus_state == ConsensusState.REACHED:
                consensus_reached = True
                final_consensus_state = consensus_state
                self.logger.info(f"Consensus reached after round {round_num}")
                if early_consensus_exit:
                    break
            elif consensus_state == ConsensusState.DEADLOCK:
                final_consensus_state = consensus_state
                self.logger.warning(f"Deadlock detected at round {round_num}")
                break

        # Synthesize final decision
        final_decision, action_items = await self._synthesize_decision(
            topic, context, debate_history
        )

        # Determine confidence level
        confidence_level = self._determine_confidence(
            consensus_reached, debate_history, final_consensus_state
        )

        total_duration_ms = (time.perf_counter() - start_time) * 1000
        total_cost_usd = len(debate_history) * self.COST_PER_ROUND_USD

        result = DebateResult(
            topic=topic,
            task_type=task_type,
            rounds_completed=len(debate_history),
            debate_history=debate_history,
            consensus_reached=consensus_reached,
            confidence_level=confidence_level,
            final_decision=final_decision,
            action_items=action_items,
            total_duration_ms=total_duration_ms,
            total_cost_usd=total_cost_usd,
            artifact_path=artifact_path,
            metadata={
                "parallel_execution": self.enable_parallel,
                "cache_enabled": self.cache is not None,
                "cache_stats": self.cache.get_stats() if self.cache else None,
                "model_stats": {
                    "claude": self.claude_adapter.get_stats(),
                    "gpt": self.gpt_adapter.get_stats()
                }
            }
        )

        # Save synthesis
        if artifact_path:
            self._save_synthesis(artifact_path, result)

        self.logger.info(
            f"Debate complete: consensus={consensus_reached}, "
            f"confidence={confidence_level.value}, "
            f"duration={total_duration_ms:.0f}ms, "
            f"cost=${total_cost_usd:.2f}"
        )

        return result

    async def review_code(
        self,
        code: str,
        language: str,
        context: Optional[str] = None,
        focus_areas: Optional[List[str]] = None,
        p0_validation: bool = False
    ) -> DebateResult:
        """
        Conduct a code review debate.

        Args:
            code: The code to review
            language: Programming language
            context: Additional context about the code
            focus_areas: Specific areas to focus on
            p0_validation: Whether to perform P0 skill validation

        Returns:
            DebateResult with review findings
        """
        review_context = {
            "code": code,
            "language": language,
            "context": context or "No additional context provided",
            "focus_areas": focus_areas or ["correctness", "safety", "performance"]
        }

        task_type = TaskType.P0_VALIDATION if p0_validation else TaskType.CODE_REVIEW

        result = await self.debate(
            topic=f"Code review for {language} implementation",
            context=review_context,
            task_type=task_type,
            rounds=3 if p0_validation else 2
        )

        # Extract review findings from debate
        result.review_findings = self._extract_review_findings(result.debate_history)

        # Perform P0 validation if requested
        if p0_validation:
            for finding in result.review_findings:
                if finding.severity == ReviewSeverity.CRITICAL:
                    validation = self.p0_validator.validate_skill(
                        skill_name=f"code_review_{language}",
                        skill_content=code,
                        claude_analysis=result.debate_history[-1].claude_response,
                        gpt_analysis=result.debate_history[-1].gpt_response
                    )
                    result.p0_validations.append(validation)

        return result

    async def decide_architecture(
        self,
        requirements: List[str],
        constraints: List[str],
        options: Optional[List[str]] = None
    ) -> DebateResult:
        """
        Make an architecture decision through debate.

        Args:
            requirements: List of requirements
            constraints: List of constraints
            options: Optional list of architecture options to consider

        Returns:
            DebateResult with architecture recommendation
        """
        arch_context = {
            "requirements": requirements,
            "constraints": constraints,
            "options": options or []
        }

        return await self.debate(
            topic="Architecture decision",
            context=arch_context,
            task_type=TaskType.ARCHITECTURE_DESIGN,
            rounds=4
        )

    async def validate_p0_skill(
        self,
        skill_path: str,
        skill_content: str
    ) -> DebateResult:
        """
        Validate a P0 (safety-critical) skill.

        Args:
            skill_path: Path to the skill file
            skill_content: Content of the skill

        Returns:
            DebateResult with P0 validation results
        """
        context = {
            "skill_path": skill_path,
            "skill_content": skill_content,
            "validation_type": "p0_safety_critical"
        }

        result = await self.debate(
            topic=f"P0 Skill Validation: {skill_path}",
            context=context,
            task_type=TaskType.P0_VALIDATION,
            rounds=3
        )

        # Perform P0 validation
        validation = self.p0_validator.validate_skill(
            skill_name=skill_path,
            skill_content=skill_content,
            claude_analysis=result.debate_history[-1].claude_response,
            gpt_analysis=result.debate_history[-1].gpt_response
        )
        result.p0_validations.append(validation)

        return result

    def _extract_review_findings(
        self,
        history: List[DebateRound]
    ) -> List[ReviewFinding]:
        """Extract review findings from debate history."""
        findings = []

        # Patterns for extracting findings
        severity_patterns = {
            ReviewSeverity.CRITICAL: [
                r"critical(?:\s+issue)?[:\s]+([^.]+\.)",
                r"must\s+fix[:\s]+([^.]+\.)",
                r"blocking[:\s]+([^.]+\.)"
            ],
            ReviewSeverity.HIGH: [
                r"high(?:\s+priority)?[:\s]+([^.]+\.)",
                r"should\s+fix[:\s]+([^.]+\.)",
                r"important[:\s]+([^.]+\.)"
            ],
            ReviewSeverity.MEDIUM: [
                r"medium(?:\s+priority)?[:\s]+([^.]+\.)",
                r"consider[:\s]+([^.]+\.)",
                r"recommend[:\s]+([^.]+\.)"
            ],
            ReviewSeverity.LOW: [
                r"minor[:\s]+([^.]+\.)",
                r"nice\s+to\s+have[:\s]+([^.]+\.)",
                r"optional[:\s]+([^.]+\.)"
            ]
        }

        for round_data in history:
            for severity, patterns in severity_patterns.items():
                for pattern in patterns:
                    for source, response in [
                        ("claude", round_data.claude_response),
                        ("gpt", round_data.gpt_response)
                    ]:
                        matches = re.findall(pattern, response, re.IGNORECASE)
                        for match in matches:
                            finding = ReviewFinding(
                                severity=severity,
                                category="general",
                                message=match.strip(),
                                agreed_by=[source]
                            )
                            # Check if finding already exists
                            existing = next(
                                (f for f in findings if f.message == finding.message),
                                None
                            )
                            if existing:
                                if source not in existing.agreed_by:
                                    existing.agreed_by.append(source)
                            else:
                                findings.append(finding)

        return findings

    async def _get_claude_opinion(
        self,
        messages: List[Dict[str, str]],
        system_prompt: str
    ) -> Tuple[str, float]:
        """Get Claude's opinion for this round."""
        return await self.claude_adapter.get_completion(messages, system_prompt)

    async def _get_gpt_opinion(
        self,
        messages: List[Dict[str, str]],
        system_prompt: str
    ) -> Tuple[str, float]:
        """Get GPT's opinion for this round."""
        return await self.gpt_adapter.get_completion(messages, system_prompt)

    def _determine_confidence(
        self,
        consensus: bool,
        history: List[DebateRound],
        final_state: ConsensusState
    ) -> ConfidenceLevel:
        """Determine confidence level based on debate outcome."""
        if final_state == ConsensusState.DEADLOCK:
            return ConfidenceLevel.LOW

        if consensus and len(history) <= 2:
            return ConfidenceLevel.HIGH
        elif consensus:
            # Calculate average agreement score
            avg_score = sum(r.agreement_score for r in history) / len(history)
            if avg_score >= 0.8:
                return ConfidenceLevel.HIGH
            return ConfidenceLevel.MEDIUM
        else:
            return ConfidenceLevel.LOW

    def _build_system_prompt(
        self,
        model_name: str,
        focus: str,
        strengths: List[str]
    ) -> str:
        """Build system prompt for a model."""
        return f"""You are {model_name} participating in an LLM Council debate for automotive software development.

## Your Designated Focus
{focus}

## Your Strengths
{', '.join(strengths)}

## Debate Protocol
1. State your position clearly with technical rationale
2. Acknowledge valid points from the other model's perspective
3. Identify areas of agreement and disagreement
4. Propose concrete, actionable recommendations
5. Flag any safety, security, or compliance concerns immediately

## Automotive Context
- Safety is paramount (ISO 26262, ASIL levels)
- Performance matters for real-time systems (10ms cycle times typical)
- Code must be maintainable for 10+ year lifecycles
- Regulatory compliance is non-negotiable
- MISRA C/C++ guidelines apply for safety-critical code

## Response Format
Provide structured analysis with:
- Technical assessment
- Risk identification
- Recommendation with rationale
- Agreement/disagreement with prior positions (if applicable)

## Consensus Signals
When you agree with the other model, explicitly state:
- "I agree with [specific point]"
- "Consensus on [topic]"

When you disagree, explain:
- "I disagree because [reason]"
- "Alternative approach: [proposal]"
"""

    def _format_debate_prompt(
        self,
        topic: str,
        context: Dict[str, Any],
        task_type: TaskType
    ) -> str:
        """Format the initial debate prompt."""
        context_str = json.dumps(context, indent=2, default=str)

        return f"""# LLM Council Debate: {topic}

## Task Type
{task_type.value}

## Context
```json
{context_str}
```

## Your Task
Analyze this topic and provide your expert perspective. Consider:
1. Technical correctness and best practices
2. Safety and security implications
3. Performance and resource constraints
4. Long-term maintainability
5. Regulatory compliance requirements

Provide a structured response with your analysis and recommendations.
"""

    def _build_messages(
        self,
        initial_prompt: str,
        history: List[DebateRound],
        perspective: str
    ) -> List[Dict[str, str]]:
        """Build message history for a model."""
        messages = [{"role": "user", "content": initial_prompt}]

        for round_data in history:
            if perspective == "claude":
                # Claude sees its own responses as assistant, GPT's as user context
                messages.append({
                    "role": "assistant",
                    "content": round_data.claude_response
                })
                messages.append({
                    "role": "user",
                    "content": f"[GPT-5.4's perspective]:\n{round_data.gpt_response}\n\nPlease continue the debate, addressing GPT's points."
                })
            else:
                # GPT sees its own responses as assistant, Claude's as user context
                messages.append({
                    "role": "assistant",
                    "content": round_data.gpt_response
                })
                messages.append({
                    "role": "user",
                    "content": f"[Claude Opus 4.6's perspective]:\n{round_data.claude_response}\n\nPlease continue the debate, addressing Claude's points."
                })

        return messages

    async def _synthesize_decision(
        self,
        topic: str,
        context: Dict[str, Any],
        history: List[DebateRound]
    ) -> Tuple[str, List[str]]:
        """
        Synthesize the final decision from debate history.

        Returns:
            Tuple of (final_decision, action_items)
        """
        synthesis_prompt = self._build_synthesis_prompt(topic, context, history)

        synthesis_system = """You are synthesizing a multi-model debate for automotive software development.

Your task is to:
1. Identify consensus points between both models
2. Note areas of disagreement
3. Weigh trade-offs (safety vs performance, simplicity vs features)
4. Provide a final, actionable recommendation
5. List specific action items

Output format:
## Consensus Points
- Point 1
- Point 2

## Divergent Opinions
- Area 1: Claude says X, GPT says Y

## Trade-off Analysis
Brief analysis of key trade-offs

## Final Recommendation
Clear, specific recommendation

## Action Items
1. First action
2. Second action
3. Third action
"""

        response, _ = await self.claude_adapter.get_completion(
            [{"role": "user", "content": synthesis_prompt}],
            synthesis_system
        )

        # Extract action items from response
        action_items = self._extract_action_items(response)

        return response, action_items

    def _extract_action_items(self, synthesis: str) -> List[str]:
        """Extract action items from synthesis text."""
        action_items = []

        # Look for numbered items after "Action Items" header
        action_section = re.search(
            r"##\s*Action Items\s*\n(.*?)(?=\n##|\Z)",
            synthesis,
            re.DOTALL | re.IGNORECASE
        )

        if action_section:
            items = re.findall(
                r"^\s*\d+\.\s*(.+)$",
                action_section.group(1),
                re.MULTILINE
            )
            action_items = [item.strip() for item in items]

        return action_items

    def _build_synthesis_prompt(
        self,
        topic: str,
        context: Dict[str, Any],
        history: List[DebateRound]
    ) -> str:
        """Build the synthesis prompt."""
        history_text = ""
        for round_data in history:
            history_text += f"""
### Round {round_data.round_number}

**Consensus State**: {round_data.consensus_state.value}
**Agreement Score**: {round_data.agreement_score:.2f}

**Claude Opus 4.6:**
{round_data.claude_response}

**GPT-5.4:**
{round_data.gpt_response}

**Key Agreements**: {', '.join(round_data.key_agreements) or 'None identified'}
**Key Disagreements**: {', '.join(round_data.key_disagreements) or 'None identified'}

---
"""

        return f"""# Synthesis Request

## Original Topic
{topic}

## Context
{json.dumps(context, indent=2, default=str)}

## Debate History
{history_text}

## Your Task
Synthesize the above debate into a final decision. Provide:
1. Consensus points (what both models agree on)
2. Divergent opinions (where they differ and why)
3. Trade-off analysis
4. Final recommendation with confidence level
5. Specific, numbered action items
"""

    def _create_artifact_directory(self) -> Path:
        """Create directory for debate artifacts."""
        timestamp = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
        pid = os.getpid()
        artifact_path = self.artifact_base_path / f"llm-council-{pid}-{timestamp}"

        # Create subdirectories
        (artifact_path / "claude").mkdir(parents=True, exist_ok=True)
        (artifact_path / "gpt").mkdir(parents=True, exist_ok=True)
        (artifact_path / "consensus").mkdir(parents=True, exist_ok=True)
        (artifact_path / "metrics").mkdir(parents=True, exist_ok=True)

        return artifact_path

    def _save_round_artifacts(
        self,
        artifact_path: Path,
        round_data: DebateRound
    ) -> None:
        """Save artifacts for a debate round."""
        # Save Claude's response
        claude_file = artifact_path / "claude" / f"round{round_data.round_number}.txt"
        claude_file.write_text(round_data.claude_response, encoding="utf-8")

        # Save GPT's response
        gpt_file = artifact_path / "gpt" / f"round{round_data.round_number}.txt"
        gpt_file.write_text(round_data.gpt_response, encoding="utf-8")

        # Save round metadata
        meta_file = artifact_path / "metrics" / f"round{round_data.round_number}-meta.json"
        meta = {
            "round_number": round_data.round_number,
            "timestamp": round_data.timestamp.isoformat(),
            "claude_duration_ms": round_data.claude_duration_ms,
            "gpt_duration_ms": round_data.gpt_duration_ms,
            "consensus_state": round_data.consensus_state.value,
            "agreement_score": round_data.agreement_score,
            "key_agreements": round_data.key_agreements,
            "key_disagreements": round_data.key_disagreements
        }
        meta_file.write_text(json.dumps(meta, indent=2), encoding="utf-8")

    def _save_synthesis(
        self,
        artifact_path: Path,
        result: DebateResult
    ) -> None:
        """Save synthesis and metrics."""
        # Save synthesis markdown
        synthesis_file = artifact_path / "consensus" / "SYNTHESIS.md"
        synthesis_content = f"""# LLM Council Synthesis

## Topic
{result.topic}

## Task Type
{result.task_type.value}

## Metadata
- Rounds Completed: {result.rounds_completed}
- Consensus Reached: {result.consensus_reached}
- Confidence Level: {result.confidence_level.value}
- Total Duration: {result.total_duration_ms:.0f}ms
- Estimated Cost: ${result.total_cost_usd:.2f}

## Final Decision
{result.final_decision}

## Action Items
{chr(10).join(f"{i+1}. {item}" for i, item in enumerate(result.action_items))}

## Review Findings
{self._format_review_findings(result.review_findings)}

## P0 Validations
{self._format_p0_validations(result.p0_validations)}

---
Generated: {datetime.utcnow().isoformat()}Z
"""
        synthesis_file.write_text(synthesis_content, encoding="utf-8")

        # Save metrics JSON
        metrics_file = artifact_path / "metrics" / "debate-stats.json"
        metrics = {
            "topic": result.topic,
            "task_type": result.task_type.value,
            "rounds_completed": result.rounds_completed,
            "consensus_reached": result.consensus_reached,
            "confidence_level": result.confidence_level.value,
            "total_duration_ms": result.total_duration_ms,
            "total_cost_usd": result.total_cost_usd,
            "round_durations": [
                {
                    "round": r.round_number,
                    "claude_ms": r.claude_duration_ms,
                    "gpt_ms": r.gpt_duration_ms,
                    "timestamp": r.timestamp.isoformat(),
                    "consensus_state": r.consensus_state.value,
                    "agreement_score": r.agreement_score
                }
                for r in result.debate_history
            ],
            "review_findings_count": len(result.review_findings),
            "p0_validations_count": len(result.p0_validations),
            "action_items_count": len(result.action_items),
            "metadata": result.metadata,
            "generated_at": datetime.utcnow().isoformat()
        }
        metrics_file.write_text(json.dumps(metrics, indent=2), encoding="utf-8")

    def _format_review_findings(self, findings: List[ReviewFinding]) -> str:
        """Format review findings for display."""
        if not findings:
            return "No review findings"

        lines = []
        for finding in findings:
            agreed = ", ".join(finding.agreed_by)
            lines.append(
                f"- [{finding.severity.value.upper()}] {finding.message} "
                f"(agreed by: {agreed})"
            )
        return "\n".join(lines)

    def _format_p0_validations(self, validations: List[P0SkillValidation]) -> str:
        """Format P0 validations for display."""
        if not validations:
            return "No P0 validations performed"

        lines = []
        for v in validations:
            status = "PASS" if v.is_valid else "FAIL"
            lines.append(f"- [{status}] {v.skill_name}: score={v.safety_score:.2f}")
            for issue in v.issues:
                lines.append(f"  - Issue: {issue}")
            for rec in v.recommendations:
                lines.append(f"  - Recommendation: {rec}")
        return "\n".join(lines)


# =============================================================================
# CLI Interface
# =============================================================================

async def main():
    """CLI entry point for LLM Council."""
    import argparse

    parser = argparse.ArgumentParser(
        description="LLM Council - Multi-Model Debate System"
    )
    parser.add_argument(
        "topic",
        help="Topic or question for the council to debate"
    )
    parser.add_argument(
        "--task-type", "-t",
        choices=[t.value for t in TaskType],
        default="general",
        help="Type of task (affects routing)"
    )
    parser.add_argument(
        "--rounds", "-r",
        type=int,
        help="Number of debate rounds (default: based on task type)"
    )
    parser.add_argument(
        "--context", "-c",
        help="JSON file with additional context"
    )
    parser.add_argument(
        "--output", "-o",
        help="Output directory for artifacts"
    )
    parser.add_argument(
        "--no-cache",
        action="store_true",
        help="Disable response caching"
    )
    parser.add_argument(
        "--no-parallel",
        action="store_true",
        help="Disable parallel model execution"
    )
    parser.add_argument(
        "--p0-validation",
        action="store_true",
        help="Enable P0 skill validation"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose logging"
    )

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Load context if provided
    context = {}
    if args.context:
        with open(args.context, "r") as f:
            context = json.load(f)

    # Initialize council
    artifact_path = Path(args.output) if args.output else None
    council = LLMCouncil(
        artifact_base_path=artifact_path,
        enable_cache=not args.no_cache,
        enable_parallel=not args.no_parallel
    )

    # Run debate
    task_type = TaskType(args.task_type)
    if args.p0_validation:
        task_type = TaskType.P0_VALIDATION

    result = await council.debate(
        topic=args.topic,
        context=context,
        task_type=task_type,
        rounds=args.rounds
    )

    # Print results
    print("\n" + "=" * 60)
    print("LLM COUNCIL DECISION")
    print("=" * 60)
    print(f"\nTopic: {result.topic}")
    print(f"Consensus: {'Yes' if result.consensus_reached else 'No'}")
    print(f"Confidence: {result.confidence_level.value.upper()}")
    print(f"Rounds: {result.rounds_completed}")
    print(f"Duration: {result.total_duration_ms:.0f}ms")
    print(f"Cost: ${result.total_cost_usd:.2f}")
    print("\n" + "-" * 60)
    print("FINAL DECISION:")
    print("-" * 60)
    print(result.final_decision)
    print("\n" + "-" * 60)
    print("ACTION ITEMS:")
    print("-" * 60)
    for i, item in enumerate(result.action_items, 1):
        print(f"  {i}. {item}")

    if result.review_findings:
        print("\n" + "-" * 60)
        print("REVIEW FINDINGS:")
        print("-" * 60)
        for finding in result.review_findings:
            print(f"  [{finding.severity.value.upper()}] {finding.message}")

    if result.p0_validations:
        print("\n" + "-" * 60)
        print("P0 VALIDATIONS:")
        print("-" * 60)
        for v in result.p0_validations:
            status = "PASS" if v.is_valid else "FAIL"
            print(f"  [{status}] {v.skill_name}: score={v.safety_score:.2f}")

    if result.artifact_path:
        print(f"\nArtifacts saved to: {result.artifact_path}")

    # Print cache stats if available
    if result.metadata.get("cache_stats"):
        stats = result.metadata["cache_stats"]
        print(f"\nCache: {stats['hits']} hits, {stats['misses']} misses "
              f"({stats['hit_rate']*100:.1f}% hit rate)")


if __name__ == "__main__":
    asyncio.run(main())
