# PatentCloud AI Search Constitution

## Project Vision

**Vision Statement:**
Transform patent search from a keyword-matching exercise into an intelligent discovery experience that understands user intent, semantic meaning, and domain context.

**Mission Statement:**
Build an AI-powered search module for PatentCloud that goes beyond traditional query clarification to actively assist users in discovering relevant patents through natural language understanding, semantic analysis, and intelligent query expansion.

**Who We Serve:**

- Patent researchers and analysts seeking comprehensive prior art
- IP professionals exploring technology landscapes
- Innovation teams tracking competitive intelligence
- Legal practitioners building infringement or validity arguments

**Value Proposition:**
Reduce search time and increase recall by combining the best of Smart Search (natural language), Advanced Search (structured queries), and Semantic Search (conceptual matching) into a unified AI-assisted experience.

---

## Core Principles

### I. Intelligence-First Design (NON-NEGOTIABLE)

**Principle:** AI Search must provide intelligent assistance beyond simple query clarification.

**Guidelines:**

- **Active Assistance:** The system proactively suggests improvements, expansions, and refinements
- **Contextual Understanding:** Analyze user intent from title, abstract, claims context
- **Multi-Modal Support:** Handle natural language, structured fields, and concept-based queries simultaneously
- **Transparent Reasoning:** Users must understand *why* suggestions are made

**Rationale:** Users expect AI Search to be smarter than existing tools. If it only clarifies queries without adding semantic intelligence or strategic expansion, it fails to justify its existence alongside Smart/Advanced/Semantic Search modes.

**Implementation Requirements:**

- Must integrate semantic understanding (concept similarity)
- Must support automatic synonym expansion
- Must offer query reformulation options with explanations
- Must NOT degrade to simple keyword matching

---

### II. User Intent Recognition

**Principle:** Understand and adapt to different search strategies and user expertise levels.

**Guidelines:**

- **Strategy Detection:** Identify whether user is doing exploratory search, targeted validation, landscape analysis, or competitive monitoring
- **Expertise Adaptation:** Adjust terminology and granularity based on user's domain knowledge
- **Multi-Turn Refinement:** Support iterative query building with memory of previous interactions
- **Scope Guidance:** Help users define appropriate breadth (too broad vs. too narrow)

**Rationale:** Patent search is strategic. The same query means different things in landscape analysis vs. validity search. AI Search must recognize context and guide users appropriately.

**Quality Gates:**

- User intent must be explicitly confirmed before expanding queries
- System must detect over-broad or over-narrow scope and warn users
- Refinement suggestions must align with detected search strategy

---

### III. Hybrid Search Architecture

**Principle:** Integrate multiple search paradigms without forcing users to choose upfront.

**Guidelines:**

- **Unified Interface:** Single input handles natural language, Boolean expressions, and semantic concepts
- **Mode Fusion:** Combine keyword precision (Advanced), NLU convenience (Smart), and semantic depth simultaneously
- **Graceful Degradation:** If semantic model fails, fall back to keyword + synonym expansion
- **Explainable Results:** Users must see which modes contributed to each result

**Rationale:** Users shouldn't need to predict which search mode works best. AI Search should apply all relevant techniques and show the reasoning.

**Architecture Requirements:**

- Query decomposition layer (parse intent → route to appropriate engines)
- Result fusion layer (merge and rank multi-source results)
- Provenance tracking (tag each result with contributing search modes)

---

### IV. Semantic Coherence

**Principle:** Semantic understanding must be domain-aware and patent-specific.

**Guidelines:**

- **Patent-Tuned Models:** Use embeddings trained on patent corpus, not general web text
- **Claim-Aware Analysis:** Treat claims differently from abstracts/titles (legal vs. descriptive language)
- **Technical Taxonomy Grounding:** Anchor semantic expansion to CPC/IPC/UPC classification anchors
- **Cross-Lingual Consistency:** Ensure semantic similarity works across patent languages

**Rationale:** Generic semantic models produce false positives (e.g., "bank" financial vs. riverbank). Patent-specific tuning is mandatory.

**Implementation Standards:**

- Semantic models must be benchmarked against patent retrieval datasets
- Must use CPC/IPC anchors to constrain semantic drift
- Must support multilingual patent families (INPADOC)

---

### V. Transparency & Control (NON-NEGOTIABLE)

**Principle:** Users must understand and control all AI-driven modifications to their queries.

**Guidelines:**

- **No Black Box:** Every expansion, synonym, or reformulation must be shown
- **User Veto:** Users can reject individual suggestions without losing entire query
- **Undo/Redo History:** Full query evolution history with rollback capability
- **Confidence Scores:** Show system confidence for each suggestion (high/medium/low)

**Rationale:** Patent search is legally consequential. Users cannot trust AI that makes invisible changes. Full transparency builds trust and enables learning.

**UI Requirements:**

- Visual diff showing original vs. AI-modified query
- Click-to-remove for each auto-added term
- Explanation tooltip for every suggestion ("Added because: similar to 'battery management'")

---

### VI. Performance & Scalability

**Principle:** Balance AI quality with perceived responsiveness through progressive disclosure and transparent progress indicators.

**Guidelines:**

- **Progressive Disclosure:** Show quick initial results, then enhance with AI analysis
- **Visible AI Progress:** Display clear "AI is thinking" states with specific activity labels
- **Incremental Streaming:** Stream results and suggestions as they become available
- **Caching Strategy:** Cache semantic embeddings for common technical terms
- **Graceful Load Handling:** Degrade to faster keyword search under high load with user notification

**Rationale:** Users tolerate longer latency when they understand the value being created and can see progress. Transparent AI processing builds trust and manages expectations better than artificial speed limits that compromise quality.

**Performance Targets:**

- **Immediate Feedback:** < 200ms acknowledgment that query is processing
- **Initial Results:** < 3 seconds (keyword-based or cached results)
- **AI-Enhanced Results:** < 10 seconds with visible progress indicators
- **Progress Updates:** Every 1-2 seconds showing current AI activity (e.g., "Analyzing semantic similarity...", "Expanding technical synonyms...", "Ranking by relevance...")
- **Maximum Wait:** < 15 seconds before offering "Show partial results now" option

**Required Progress Indicators:**

- **Activity Label:** Specific description of current AI task
- **Visual Indicator:** Progress bar, spinner, or stage indicator (Step 1 of 3)
- **Estimated Time:** Show remaining time if > 5 seconds
- **Escape Hatch:** "Skip AI enhancement" or "Show results now" button always available

---

### VII. Evaluation-Driven Development

**Principle:** All AI Search improvements must be validated with quantitative metrics.

**Guidelines:**

- **Baseline Metrics:** Measure recall@k, precision@k, NDCG vs. existing search modes
- **User Validation:** A/B test new features with real users
- **Error Analysis:** Track false positives/negatives, categorize failure modes
- **Iteration Loops:** Each release must improve ≥1 core metric by ≥5%

**Rationale:** "AI Search" is meaningless without proof it works better than alternatives.

**Mandatory Metrics:**

- **Recall@100:** Did we find relevant patents that keyword search missed?
- **User Acceptance Rate:** % of AI suggestions accepted by users
- **Search Session Time:** Did AI reduce time to find target patents?
- **Query Reformulation Rate:** Are users refining less after AI assistance?

---

## Decision Making

### Architecture Changes

**Scope Definition:**
Changes affecting semantic model selection, query processing pipeline, or result fusion logic.

**Decision Process:**

1. **Proposal:** Author submits Architecture Decision Record (ADR) with:
   - Problem statement
   - Evaluated alternatives
   - Quantitative comparison (latency, accuracy, cost)
   - Migration path
2. **Review:** Team reviews within 3 business days
3. **Approval:** Requires consensus from tech lead + PM + ≥1 patent domain expert
4. **Documentation:** Update architecture diagrams, API contracts, and runbooks

**Example ADR Topics:**

- Switching semantic embedding model (e.g., sentence-transformers → patent-BERT)
- Adding new search mode (e.g., image-based prior art search)
- Changing result ranking algorithm

---

### Feature Development

**Alignment Check:**
Every feature must answer:

1. **Does it reduce user effort or improve result quality?**
2. **Is it measurably better than existing Smart/Advanced/Semantic modes?**
3. **Can users understand and control it?**

**Gating Criteria:**

- [ ] Functional spec approved by PM
- [ ] Prototype tested with ≥3 real users
- [ ] Metrics show ≥5% improvement on ≥1 core KPI
- [ ] Latency impact < 200ms
- [ ] Backward compatible OR has migration plan

**Incremental Delivery:**
Break complex features into:

1. **MVP (Minimal Viable Product):** Core functionality, limited scope
2. **Beta:** Expanded coverage, refined UX
3. **GA (General Availability):** Full integration, production-ready

---

### Experimental Features

**Purpose:** Test high-risk/high-reward ideas without disrupting production.

**Guidelines:**

- Flag as "Experimental" in UI
- Collect explicit user consent
- Monitor error rates and user feedback
- Remove if adoption < 10% after 3 months

**Examples:**

- AI-generated claim chart suggestions
- Automated invalidation search workflows
- Cross-domain technology transfer discovery

---

## Quality Standards

### Code Quality

**Standards:**

- **Readability:** Code must be understandable by patent domain experts (minimize ML jargon)
- **Modularity:** Separate query parsing, semantic analysis, and result fusion into independent modules
- **Error Handling:** Graceful fallback for all AI model failures
- **Logging:** Structured logs for all AI decisions (query expansion, ranking adjustments)

**Enforcement:**

- Linter rules for naming conventions
- Pre-commit hooks for formatting
- Mandatory code review by ≥1 team member

---

### Testing

**Test Coverage Requirements:**

- **Unit Tests:** ≥80% coverage for business logic
- **Integration Tests:** Cover query pipeline end-to-end
- **Semantic Regression Tests:** Fixed dataset of 100 query-patent pairs, track MAP@10
- **Performance Tests:** Load testing at 10x peak traffic

**Critical Test Scenarios:**

1. **Ambiguous Queries:** "bank", "Apple", "cell" (financial vs. biology vs. electrochemistry)
2. **Multi-Lingual:** English query → Japanese patent results
3. **Edge Cases:** Empty results, network timeouts, malformed inputs
4. **Adversarial:** Injection attacks via Boolean operators

---

### Documentation

**Required Docs:**

1. **User Guide:** How to use AI Search (with examples)
2. **API Documentation:** OpenAPI spec for all endpoints
3. **Model Cards:** For each semantic model (training data, limitations, performance)
4. **Runbooks:** Incident response, model retraining, cache invalidation

**Maintenance:**

- Update docs within same PR as code changes
- Quarterly review of accuracy

---

### Performance

**SLAs:**

- **P50 Latency:** < 2 seconds
- **P95 Latency:** < 5 seconds
- **Availability:** 99.9% uptime
- **Error Rate:** < 0.1% requests

**Monitoring:**

- Real-time dashboards (Grafana/Datadog)
- Alerts for latency spikes or error rate > 1%
- Weekly performance review meetings

---

## Collaboration

### Communication

**Channels:**

- **Daily Standup:** Progress, blockers
- **Weekly Sync:** Metrics review, roadmap adjustments
- **Slack/Email:** Async updates, documentation

**Guidelines:**

- **Be Patent-Literate:** Learn basic patent terminology (claims, prior art, CPC)
- **Show, Don't Tell:** Use examples from real patent searches
- **Disagree Respectfully:** Focus on data and user outcomes

---

### Code Review

**Standards:**

- **Response Time:** Initial review within 24 hours
- **Constructive Feedback:** Suggest alternatives, don't just criticize
- **Knowledge Sharing:** Explain domain concepts (e.g., why claims matter)

**Checklist:**

- [ ] Code follows style guide
- [ ] Tests pass and coverage ≥80%
- [ ] Documentation updated
- [ ] No performance regressions
- [ ] Semantic model changes include ablation study

---

### Knowledge Sharing

**Practices:**

- **Bi-weekly Patent Tech Talks:** Team members present patent search techniques
- **Model Review Sessions:** Discuss semantic model performance, failure cases
- **User Interview Debriefs:** Share insights from user research

---

## Evolution

**Constitution Review:**

- Quarterly review of principles
- Annual update based on technology shifts (e.g., new LLM capabilities)

**Amendment Process:**

1. Propose change via GitHub issue
2. Team discussion (async + meeting)
3. Approval requires consensus
4. Update version number (semantic versioning: MAJOR.MINOR.PATCH)

**Version History:**

- **v1.1.0** (2025-10-19): Updated Performance & Scalability principle to prioritize perceived responsiveness over raw speed; added progress indicator requirements
- **v1.0.0** (2025-10-19): Initial constitution for AI Search feature

---

## Governance

**Hierarchy:**

1. **This Constitution:** Overrides all other documents
2. **Architecture Decision Records (ADRs):** Document specific technical choices
3. **Feature Specs:** Implementation details

**Compliance:**

- All PRs must reference constitutional principles in description
- Code reviews must verify compliance
- Non-compliance requires explicit justification + tech lead approval

**Conflict Resolution:**

- **First:** Return to core principles (Intelligence-First, Transparency, User Focus)
- **Second:** Consult user research data
- **Third:** Escalate to PM + Tech Lead
- **Last Resort:** User A/B test to decide

---

**Version:** 1.1.0
**Ratified:** 2025-10-19
**Last Amended:** 2025-10-19
**Owner:** AI Search Team (PatentCloud by InQuartik)
