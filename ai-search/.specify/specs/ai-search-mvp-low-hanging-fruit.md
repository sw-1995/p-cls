# Feature Specification: AI Search MVP - Low-Hanging Fruit

## Overview

### Purpose

This MVP focuses on **quick-win features** that address the most painful patent search bottlenecks with minimal infrastructure investment. Instead of building complex semantic models and multilingual pipelines, we start with high-impact features that leverage existing PatentCloud data and proven NLP techniques.

### MVP Philosophy: 80/20 Rule

**Target:** Deliver 80% of user value with 20% of the effort by prioritizing:
- Features using **existing data** (no new corpus collection)
- **Deterministic algorithms** (no complex ML model training)
- **UI/UX improvements** (transparent suggestions, progress indicators)
- **Quick feedback loops** (user acceptance/rejection drives iteration)

### Goals (8-Week MVP)

1. **Reduce Query Crafting Time by 40%** - Automatic synonym expansion from existing thesaurus
2. **Increase Classification Coverage by 25%** - Suggest adjacent CPC/IPC classes from hierarchy
3. **Improve Assignee Search Accuracy by 60%** - Normalize common assignee name variants
4. **Decrease User Frustration by 50%** - Transparent progress indicators and escape hatches

### Non-Goals (Deferred to Future Phases)

- ❌ Semantic search (requires training/hosting large embedding models)
- ❌ Multilingual query expansion (requires translation infrastructure)
- ❌ Active learning ranking (requires feedback data collection pipeline)
- ❌ NPL integration (requires API licensing and legal review)
- ❌ Specialized chemistry/biotech features

---

## Low-Hanging Fruit Feature Selection

### Feature Prioritization Matrix

| **Feature** | **Impact** | **Complexity** | **Time-to-Value** | **Priority** |
|-------------|-----------|---------------|-------------------|--------------|
| **1. Synonym Expansion (Thesaurus)** | High | Low | 2 weeks | **P0** |
| **2. Assignee Name Normalization** | High | Low | 1 week | **P0** |
| **3. Adjacent Classification Suggestions** | High | Medium | 2 weeks | **P0** |
| **4. Query Quality Feedback** | Medium | Low | 1 week | **P1** |
| **5. Progress Indicators & Escape Hatches** | Medium | Low | 1 week | **P1** |
| **6. Search History & Quick Retry** | Medium | Low | 1 week | **P1** |
| **7. Patent Family Deduplication UI** | Medium | Medium | 2 weeks | **P2** |

**Total MVP Scope:** P0 + P1 features = **8 weeks**

---

## MVP Features Detailed Specification

### Feature 1: Synonym Expansion (Thesaurus-Based) [P0]

**Bottleneck Addressed:** Vocabulary mismatch (synonyms, jargon, acronyms)

**Why Low-Hanging Fruit:**
- Leverage **existing patent thesaurus data** (no training required)
- Simple string matching and expansion logic
- Transparent UI (users see all suggestions)
- No inference latency (pre-computed lookup table)

#### Requirements

**FR1.1: Technical Term Detection**
- Use simple NLP (spaCy NER) to identify technical noun phrases
- Pattern matching for acronyms (all-caps words, e.g., "BMS", "IoT")
- Compound term detection (e.g., "battery management system" as single unit)

**FR1.2: Thesaurus Lookup**
- Use PatentCloud's existing CPC/IPC term thesaurus
- Fall back to WordNet for general technical terms
- Include common acronym expansions (manually curated list of top 500 patent acronyms)

**FR1.3: Expansion UI**
```
Original Query: "BMS for lithium-ion batteries"

AI Suggestions:
┌────────────────────────────────────────────────────────────┐
│ Synonyms Detected                                           │
├────────────────────────────────────────────────────────────┤
│ ☑ BMS → Battery Management System                          │
│ ☐ BMS → Building Management System (click to include)      │
│ ☑ lithium-ion → Li-ion, lithium ion                       │
│ ☑ batteries → cell, energy storage, accumulator           │
│                                                             │
│ Enhanced Query Preview:                                     │
│ (BMS OR "Battery Management System") AND                   │
│ ("lithium-ion" OR "Li-ion" OR "lithium ion") AND          │
│ (batteries OR cell OR "energy storage")                   │
│                                                             │
│ Estimated Results: ~5,200 patents (was 1,800)             │
└────────────────────────────────────────────────────────────┘
```

**FR1.4: User Control**
- Check/uncheck individual synonym suggestions
- "Accept All" and "Reject All" buttons
- Undo/redo for expansion choices
- "Remember my preference" for common terms (e.g., always expand "BMS" to Battery)

#### Technical Design

**Data Source:**
```json
// synonym_thesaurus.json (pre-built from CPC definitions + manual curation)
{
  "BMS": {
    "expansions": [
      { "term": "Battery Management System", "domain": "electrical", "confidence": 0.95 },
      { "term": "Building Management System", "domain": "construction", "confidence": 0.85 }
    ],
    "default_selection": ["Battery Management System"]  // Auto-checked
  },
  "lithium-ion": {
    "expansions": [
      { "term": "Li-ion", "confidence": 0.98 },
      { "term": "lithium ion", "confidence": 0.95 }
    ]
  }
}
```

**API Endpoint:**
```http
POST /api/v1/query/expand-synonyms
{
  "query": "BMS for lithium-ion batteries",
  "domain_hint": "electrical"  // Optional, from user profile or CPC filter
}

Response:
{
  "expansions": [
    {
      "original": "BMS",
      "suggestions": [
        { "term": "Battery Management System", "checked": true, "confidence": 0.95 },
        { "term": "Building Management System", "checked": false, "confidence": 0.85 }
      ]
    },
    ...
  ],
  "enhanced_query": "(BMS OR \"Battery Management System\") AND ...",
  "estimated_results": 5200
}
```

**Implementation Effort:** 2 weeks
- Week 1: Build thesaurus from CPC/IPC terms + curate top 500 acronyms
- Week 2: API endpoint + frontend UI with checkbox controls

**Success Metrics:**
- 70%+ user acceptance rate for suggestions
- 40%+ reduction in query reformulation attempts
- 30%+ increase in results retrieved (recall improvement)

---

### Feature 2: Assignee Name Normalization [P0]

**Bottleneck Addressed:** Data quality issues (inconsistent assignee names)

**Why Low-Hanging Fruit:**
- PatentCloud already has assignee data
- Simple fuzzy string matching (no ML required)
- High user pain point (searching "IBM" misses "International Business Machines Corp.")
- Immediate visible benefit

#### Requirements

**FR2.1: Assignee Variant Detection**
- Fuzzy match assignee input against PatentCloud's assignee database
- Detect common patterns:
  - Legal suffixes: "Inc.", "Corp.", "Co., Ltd.", "GmbH"
  - Abbreviations: "IBM" ↔ "International Business Machines"
  - Acquisitions: "Motorola" → "Google" (2012-2014) → "Lenovo" (2014+)

**FR2.2: Unified Search UI**
```
Assignee Search: "Samsung"

AI Detected Variants:
┌────────────────────────────────────────────────────────────┐
│ ☑ Samsung Electronics Co., Ltd.        (45,234 patents)   │
│ ☑ Samsung Display Co., Ltd.            (12,456 patents)   │
│ ☑ Samsung SDI Co., Ltd.                (8,901 patents)    │
│ ☑ 삼성전자 (Samsung Electronics KR)      (23,112 patents)   │
│ ☐ Samsung Heavy Industries              (3,456 patents)   │
│                                                             │
│ Total Selected: 89,703 patents                             │
│ [Search with Selected Variants]                            │
└────────────────────────────────────────────────────────────┘
```

**FR2.3: Assignee Knowledge Base**
- Pre-built mapping table for top 1,000 assignees
- Manual curation of acquisition history (e.g., Motorola → Google → Lenovo)
- User-contributed corrections (crowdsourcing)

#### Technical Design

**Data Source:**
```json
// assignee_variants.json
{
  "Samsung Electronics": {
    "variants": [
      "Samsung Electronics Co., Ltd.",
      "Samsung Electronics Co Ltd",
      "Samsung Display Co., Ltd.",
      "Samsung SDI Co., Ltd.",
      "삼성전자"
    ],
    "subsidiaries": ["Samsung Display", "Samsung SDI"],
    "acquisition_history": []
  },
  "IBM": {
    "variants": [
      "International Business Machines",
      "International Business Machines Corporation",
      "IBM Corp.",
      "I.B.M."
    ],
    "acquisition_history": [
      { "acquired": "Red Hat", "date": "2019-07-09" }
    ]
  }
}
```

**Fuzzy Matching Algorithm:**
- Use `fuzzywuzzy` library (Levenshtein distance)
- Threshold: 85%+ similarity score
- Remove legal suffixes before matching ("Inc.", "Corp.", "Ltd.")

**API Endpoint:**
```http
POST /api/v1/assignee/normalize
{
  "assignee": "Samsung"
}

Response:
{
  "normalized_name": "Samsung Electronics",
  "variants": [
    { "name": "Samsung Electronics Co., Ltd.", "patent_count": 45234, "checked": true },
    { "name": "Samsung Display Co., Ltd.", "patent_count": 12456, "checked": true },
    ...
  ],
  "total_patents": 89703
}
```

**Implementation Effort:** 1 week
- Days 1-2: Build assignee variant database from PatentCloud data
- Days 3-4: Implement fuzzy matching API
- Day 5: Frontend UI with checkbox selection

**Success Metrics:**
- 60%+ reduction in "no results found" for assignee searches
- 80%+ user acceptance of variant suggestions
- Top 100 assignees have 95%+ variant coverage

---

### Feature 3: Adjacent Classification Suggestions [P0]

**Bottleneck Addressed:** Classification complexity (missing adjacent/parent classes)

**Why Low-Hanging Fruit:**
- CPC/IPC hierarchy is publicly available (no data collection)
- Simple graph traversal algorithm (no ML)
- High impact (users often miss relevant classes by 1-2 levels)
- Transparent explanations ("Also in parent class H01M")

#### Requirements

**FR3.1: Classification Hierarchy Navigation**
- Load CPC/IPC hierarchy as directed graph
- Given user's selected class (e.g., H01M10/42), suggest:
  - **Parent classes:** H01M10, H01M (broader scope)
  - **Sibling classes:** H01M10/44, H01M10/48 (same level)
  - **Child classes:** H01M10/425, H01M10/4235 (narrower scope)

**FR3.2: Suggestion UI with Rationale**
```
Selected Classification: H01M10/42 (Battery monitoring)

AI Suggestions:
┌────────────────────────────────────────────────────────────┐
│ Expand to Related Classifications                          │
├────────────────────────────────────────────────────────────┤
│ ☑ H01M10/48 - Battery testing (sibling, 2,345 patents)    │
│   Rationale: Often paired with monitoring systems          │
│                                                             │
│ ☐ H01M10 - Battery construction (parent, 45,678 patents)  │
│   Rationale: Broader scope, includes all battery tech      │
│                                                             │
│ ☑ G01R31/36 - Battery measurement (cross-ref, 1,234)      │
│   Rationale: Measurement techniques for monitoring         │
│                                                             │
│ ☐ H02J7/00 - Charging circuits (related, 8,901 patents)   │
│   Rationale: Charging often requires monitoring            │
└────────────────────────────────────────────────────────────┘
```

**FR3.3: Classification Coverage Visualization**
```
Results Distribution by Classification:
┌────────────────────────────────────────────────────────────┐
│ H01M10/42 ████████████████████████░░░░ 60% (3,456 patents)│
│ H01M10/48 ██████░░░░░░░░░░░░░░░░░░ 15% (863 patents)     │
│ G01R31/36 ████░░░░░░░░░░░░░░░░░░░░ 10% (576 patents)     │
│ H02J7/00  ██░░░░░░░░░░░░░░░░░░░░░░  5% (288 patents)     │
│ Others    ██████░░░░░░░░░░░░░░░░░░ 10% (576 patents)     │
│                                                             │
│ 💡 Tip: 40% of results are outside your primary class     │
│    Consider adding H01M10/48 to improve recall            │
└────────────────────────────────────────────────────────────┘
```

#### Technical Design

**Data Source:**
- CPC/IPC XML hierarchy files (publicly available from EPO/USPTO)
- Pre-processed into graph database (Neo4j) or JSON structure

**Graph Representation:**
```json
{
  "H01M10/42": {
    "label": "Monitoring or testing of batteries",
    "parent": "H01M10",
    "siblings": ["H01M10/44", "H01M10/48"],
    "children": ["H01M10/425", "H01M10/4285"],
    "cross_references": ["G01R31/36", "H02J7/00"],
    "patent_count": 3456
  }
}
```

**API Endpoint:**
```http
POST /api/v1/classification/suggest-adjacent
{
  "selected_classes": ["H01M10/42"],
  "max_suggestions": 5
}

Response:
{
  "suggestions": [
    {
      "class": "H01M10/48",
      "label": "Battery testing",
      "relationship": "sibling",
      "patent_count": 2345,
      "rationale": "Often paired with monitoring systems"
    },
    ...
  ]
}
```

**Implementation Effort:** 2 weeks
- Week 1: Build CPC/IPC hierarchy graph from XML, compute relationships
- Week 2: API endpoint + frontend visualization

**Success Metrics:**
- 25%+ increase in classifications explored per search session
- 50%+ of users accept at least one adjacent class suggestion
- 20%+ improvement in recall for multi-class searches

---

### Feature 4: Query Quality Feedback [P1]

**Bottleneck Addressed:** Inexperienced search strategy (no feedback on query quality)

**Why Low-Hanging Fruit:**
- Simple heuristic rules (no ML)
- Instant feedback (no API latency)
- Educational value (helps novices learn)

#### Requirements

**FR4.1: Query Analysis Heuristics**

Detect common query issues:
1. **Over-broad:** Single generic term (e.g., "battery") → 500K+ results
2. **Over-narrow:** Too many ANDs (e.g., "battery AND lithium AND charging AND BMS AND safety") → <10 results
3. **Missing classification:** No CPC/IPC filter on broad search
4. **Ambiguous acronyms:** "BMS", "AI", "ML" without context
5. **Incorrect operators:** Using OR when AND is intended (e.g., "battery OR charger" likely wants both)

**FR4.2: Feedback UI**
```
Query: "AI"

⚠️ Query Quality Issues Detected:
┌────────────────────────────────────────────────────────────┐
│ 🔴 Over-Broad Query                                        │
│ "AI" returns 1.2M patents across all technology domains.   │
│                                                             │
│ Suggestions:                                                │
│ • Add classification filter (e.g., G06N for AI/ML)         │
│ • Specify application domain (e.g., "AI for medical")      │
│ • Narrow to specific technique (e.g., "neural network")    │
│                                                             │
│ ⚠️ Ambiguous Acronym                                       │
│ "AI" could mean:                                            │
│ • Artificial Intelligence (most common in patents)          │
│ • Analog Instruments                                        │
│                                                             │
│ [Apply Suggested Refinements] [Proceed Anyway]             │
└────────────────────────────────────────────────────────────┘
```

**FR4.3: Educational Tooltips**
- Explain why suggestion is made
- Link to search best practices guide
- Show examples of improved queries

#### Technical Design

**Heuristic Rules (Client-Side JavaScript):**
```javascript
function analyzeQueryQuality(query, estimatedResults) {
  const issues = [];

  // Over-broad detection
  if (estimatedResults > 100000) {
    issues.push({
      severity: "error",
      type: "over_broad",
      message: `Query returns ${estimatedResults.toLocaleString()} patents. Consider adding filters.`,
      suggestions: ["Add classification filter", "Specify application domain"]
    });
  }

  // Ambiguous acronym detection
  const ambiguousAcronyms = ["AI", "ML", "BMS", "IoT", "EV"];
  for (const acronym of ambiguousAcronyms) {
    if (query.includes(acronym) && !query.includes('"')) {
      issues.push({
        severity: "warning",
        type: "ambiguous_acronym",
        message: `"${acronym}" may be ambiguous`,
        suggestions: [`Expand to full term`, `Add classification filter`]
      });
    }
  }

  return issues;
}
```

**No API Required** - All logic runs client-side for instant feedback

**Implementation Effort:** 1 week
- Days 1-3: Build heuristic rules library
- Days 4-5: Frontend UI integration

**Success Metrics:**
- 50%+ of users with quality issues accept at least one suggestion
- 30% reduction in "no results found" errors
- 40% reduction in over-broad searches (>100K results)

---

### Feature 5: Progress Indicators & Escape Hatches [P1]

**Bottleneck Addressed:** User frustration with unclear processing time

**Why Low-Hanging Fruit:**
- Pure UI/UX improvement (no backend changes required)
- Aligns with Constitutional v1.1.0 (performance with transparency)
- High user satisfaction impact

#### Requirements

**FR5.1: Specific Progress Messages**
```
AI Search in Progress...

┌────────────────────────────────────────────────────────────┐
│ ⚙️ Analyzing query...                    ✅ Complete (0.5s)│
│ 🔍 Expanding synonyms...                 ⏳ In progress    │
│ 🏷️ Mapping classifications...           ⏸️ Pending         │
│ 🌐 Searching patent database...         ⏸️ Pending         │
│ 📊 Ranking results...                    ⏸️ Pending         │
│                                                             │
│ Estimated time remaining: 6 seconds                         │
│                                                             │
│ [Skip AI Enhancement - Show Basic Results Now]             │
└────────────────────────────────────────────────────────────┘
```

**FR5.2: Escape Hatch Button**
- Always visible "Skip AI Enhancement" button
- Falls back to basic keyword search
- Shows what user is missing (e.g., "Skipped synonym expansion")

**FR5.3: Estimated Time Display**
- Show countdown timer if process > 3 seconds
- Update progress bar based on completed stages

#### Technical Design

**Frontend State Machine:**
```javascript
const searchStages = [
  { name: "Analyzing query", duration: 500 },
  { name: "Expanding synonyms", duration: 1500 },
  { name: "Mapping classifications", duration: 2000 },
  { name: "Searching patent database", duration: 4000 },
  { name: "Ranking results", duration: 2000 }
];

function ProgressIndicator({ currentStage, onSkip }) {
  const totalDuration = searchStages.reduce((sum, s) => sum + s.duration, 0);
  const elapsed = searchStages.slice(0, currentStage).reduce((sum, s) => sum + s.duration, 0);
  const remaining = totalDuration - elapsed;

  return (
    <div>
      <ProgressBar percent={elapsed / totalDuration * 100} />
      <p>Estimated time remaining: {remaining / 1000}s</p>
      <button onClick={onSkip}>Skip AI Enhancement</button>
    </div>
  );
}
```

**Implementation Effort:** 1 week
- Days 1-2: Design progress UI components
- Days 3-4: Implement stage tracking and time estimation
- Day 5: Integrate with existing search flow

**Success Metrics:**
- < 5% of users hit "Skip" button (means wait time is acceptable)
- 80%+ user satisfaction with search responsiveness
- Zero complaints about "hanging" or "no feedback"

---

### Feature 6: Search History & Quick Retry [P1]

**Bottleneck Addressed:** Lack of iterative loop (users lose previous query attempts)

**Why Low-Hanging Fruit:**
- Simple database persistence (PostgreSQL/Redis)
- Standard "recent searches" UI pattern
- Enables A/B comparison of query variations

#### Requirements

**FR6.1: Persistent Search History**
- Save last 50 searches per user
- Include query string, filters, result count, timestamp
- Quick reload of previous search

**FR6.2: History UI with Comparison**
```
Search History (Last 7 Days)

┌────────────────────────────────────────────────────────────┐
│ 🕐 2 hours ago                                             │
│ "battery management system" + H01M10/42                    │
│ 1,234 results • [Reload] [Compare with Current]            │
│                                                             │
│ 🕐 Yesterday                                                │
│ "BMS" (no filters)                                          │
│ 45,678 results • [Reload] [Compare with Current]           │
│                                                             │
│ 🕐 3 days ago                                               │
│ "battery state of charge" + H01M10/42                      │
│ 2,345 results • [Reload] [Compare with Current]            │
└────────────────────────────────────────────────────────────┘

💡 Notice: Expanding "BMS" to "battery management system"
   reduced results by 97% (45,678 → 1,234). Consider filters!
```

**FR6.3: Side-by-Side Comparison**
```
┌────────────────────────┬────────────────────────┐
│ Query A (Current)      │ Query B (Yesterday)    │
├────────────────────────┼────────────────────────┤
│ "battery management    │ "BMS"                  │
│  system" + H01M10/42   │ (no filters)           │
│                        │                        │
│ 1,234 results          │ 45,678 results         │
│ Top Result:            │ Top Result:            │
│ US10234567 (Rel: 0.95) │ US98765432 (Rel: 0.42) │
│                        │                        │
│ Classifications:        │ Classifications:        │
│ H01M10/42 (60%)        │ H01M10/42 (2%)         │
│ G01R31/36 (20%)        │ H02J7/00 (15%)         │
│                        │ B60L (30%)             │
│                        │ Others (53%)           │
└────────────────────────┴────────────────────────┘

✅ Query A is more focused (better precision)
⚠️ Query B may have better recall but lower relevance
```

#### Technical Design

**Data Model:**
```typescript
interface SearchHistoryEntry {
  searchId: string;
  userId: string;
  timestamp: Date;
  query: {
    raw: string;
    enhanced: string;
    filters: {
      classifications: string[];
      dateRange: { start: Date, end: Date };
      assignees: string[];
    };
  };
  results: {
    count: number;
    topPatents: string[];  // First 10 patent IDs
    classificationDistribution: { class: string, count: number }[];
  };
}
```

**API Endpoints:**
```http
GET /api/v1/search/history?limit=50
POST /api/v1/search/compare?searchIdA=abc&searchIdB=def
```

**Implementation Effort:** 1 week
- Days 1-2: Database schema and API endpoints
- Days 3-5: Frontend history list and comparison UI

**Success Metrics:**
- 40%+ of users reload a previous search within a session
- 20%+ of users use comparison feature
- 30% reduction in redundant search attempts

---

### Feature 7: Patent Family Deduplication UI [P2]

**Bottleneck Addressed:** Data quality (family inflation, duplicate viewing)

**Why Medium Priority:**
- PatentCloud already has family data (INPADOC)
- Simple deduplication logic
- High value for landscape analysis users
- Lower priority than P0/P1 (not blocking basic search)

#### Requirements

**FR7.1: Family Grouping Toggle**
```
Results: 1,234 patents (345 unique families)

Display Mode: ○ Show All Patents  ● Show One Per Family

┌────────────────────────────────────────────────────────────┐
│ 📄 US10234567B2 - Battery monitoring system               │
│ 👥 Family: 12 members (US, EP, JP, CN, KR...)             │
│ [Expand Family] [Show All Jurisdictions]                   │
│                                                             │
│ Priority: US2018/123456 (2018-05-01)                       │
│ Assignee: Tesla Inc.                                        │
│ Key Claims: [Auto-extracted summary]                       │
└────────────────────────────────────────────────────────────┘
```

**FR7.2: Family Expansion on Demand**
```
📄 US10234567B2 - Battery monitoring system
👥 Family Members (12):

┌────────────────────────────────────────────────────────────┐
│ ✅ US10234567B2 (US Grant, 2020-03-15)                    │
│ ☐ EP3456789A1 (EP Application, 2019-11-20)                │
│ ☐ JP2020-123456A (JP Application, 2020-01-10)             │
│ ☐ CN109876543A (CN Application, 2019-12-05)               │
│ ... 8 more members                                          │
│                                                             │
│ [View All in New Tab] [Add Selected to Results]            │
└────────────────────────────────────────────────────────────┘
```

**FR7.3: Representative Member Selection**
- Prefer granted patents over applications
- Prefer English-language over translations
- Prefer most recent publication
- Allow user override

#### Technical Design

**Data Query:**
```sql
SELECT
  p.patent_id,
  f.family_id,
  f.family_size,
  p.publication_date,
  p.legal_status
FROM patents p
JOIN patent_families f ON p.family_id = f.family_id
WHERE p.is_representative = TRUE  -- Pre-computed flag
ORDER BY relevance_score DESC;
```

**API Endpoint:**
```http
GET /api/v1/search/results?deduplicate_families=true
GET /api/v1/patent/{patentId}/family
```

**Implementation Effort:** 2 weeks
- Week 1: API logic for deduplication and family expansion
- Week 2: Frontend toggle and family expansion UI

**Success Metrics:**
- 60%+ of landscape analysis users enable family deduplication
- 50% reduction in duplicate patent viewing
- Faster result screening (measured by time to review top 100)

---

## 8-Week Implementation Plan

### Sprint 1-2 (Weeks 1-2): Foundation [P0]
**Goal:** Synonym expansion + Assignee normalization

**Week 1:**
- [x] Day 1-2: Build synonym thesaurus from CPC definitions
- [x] Day 3: Curate top 500 patent acronyms
- [x] Day 4-5: Synonym expansion API endpoint

**Week 2:**
- [x] Day 1-2: Build assignee variant database
- [x] Day 3: Fuzzy matching API
- [x] Day 4: Frontend UI for synonym checkbox selection
- [x] Day 5: Frontend UI for assignee variant selection

**Deliverable:** Users can expand synonyms and search unified assignee names

---

### Sprint 3-4 (Weeks 3-4): Classification Intelligence [P0]
**Goal:** Adjacent classification suggestions

**Week 3:**
- [x] Day 1-3: Parse CPC/IPC XML hierarchy into graph
- [x] Day 4-5: Compute parent/sibling/cross-reference relationships

**Week 4:**
- [x] Day 1-2: API endpoint for adjacent class suggestions
- [x] Day 3-4: Frontend classification suggestion UI
- [x] Day 5: Results distribution visualization

**Deliverable:** Users see adjacent classes with rationale and coverage stats

---

### Sprint 5-6 (Weeks 5-6): UX Polish [P1]
**Goal:** Query quality feedback + Progress indicators + Search history

**Week 5:**
- [x] Day 1-2: Build query quality heuristic rules
- [x] Day 3-4: Frontend feedback UI (warnings, suggestions)
- [x] Day 5: Progress indicator state machine

**Week 6:**
- [x] Day 1-2: Progress indicator UI components
- [x] Day 3-4: Search history database schema and API
- [x] Day 5: Search history list UI

**Deliverable:** Users receive instant quality feedback, see progress, and can reload searches

---

### Sprint 7-8 (Weeks 7-8): Testing & Polish [P1 + P2]
**Goal:** Integration testing, bug fixes, family deduplication

**Week 7:**
- [x] Day 1-3: End-to-end testing of all P0/P1 features
- [x] Day 4-5: Bug fixes and performance optimization

**Week 8:**
- [x] Day 1-3: Patent family deduplication (P2)
- [x] Day 4: Beta user testing session (internal)
- [x] Day 5: Documentation and deployment prep

**Deliverable:** Production-ready MVP with 7 low-hanging fruit features

---

## Success Metrics (8-Week MVP)

### User Impact Metrics

| Metric | Baseline | MVP Target | Measurement |
|--------|----------|------------|-------------|
| **Query Crafting Time** | 10 min avg | 6 min (-40%) | Time from query input to first search execution |
| **Classification Coverage** | 1.5 classes/search | 2.0 classes (+25%) | Avg classifications explored per session |
| **Assignee Search Accuracy** | 40% find all variants | 90% (+60%) | % of users finding unified assignee results |
| **User Satisfaction (CSAT)** | 65% | 80% (+15 pts) | Post-search survey rating |
| **"No Results" Error Rate** | 12% | 6% (-50%) | % of searches returning zero results |

### Feature Adoption Metrics

| Feature | Target Adoption | Success Threshold |
|---------|----------------|-------------------|
| Synonym Expansion | 60% of searches | ≥1 suggestion accepted |
| Assignee Normalization | 70% of assignee searches | ≥1 variant selected |
| Adjacent Classifications | 40% of searches | ≥1 adjacent class added |
| Query Quality Feedback | 50% of flagged queries | ≥1 suggestion accepted |
| Search History Reload | 30% of users | ≥1 previous search reloaded |

### Technical Performance Metrics

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| **Synonym Expansion Latency** | < 1s P95 | > 2s |
| **Assignee Normalization Latency** | < 500ms P95 | > 1s |
| **Classification Suggestion Latency** | < 2s P95 | > 3s |
| **Total AI Enhancement Time** | < 5s P95 | > 10s |
| **API Error Rate** | < 0.5% | > 1% |

---

## Testing Strategy (MVP)

### Unit Tests (80%+ Coverage)

**Critical Paths:**
1. Synonym expansion: Acronym detection, thesaurus lookup, multi-term expansion
2. Assignee normalization: Fuzzy matching accuracy, legal suffix removal
3. Classification graph: Parent/sibling/child traversal correctness
4. Query quality: Heuristic rule accuracy (over-broad, over-narrow detection)

**Test Framework:** `pytest` + mocking for database calls

---

### Integration Tests

**Test Scenarios:**
1. **End-to-End Synonym Flow:** User inputs query → API returns suggestions → User selects → Enhanced query executed
2. **Assignee Search:** User types "Samsung" → System finds 5 variants → User selects 3 → Search returns unified results
3. **Classification Exploration:** User selects H01M10/42 → System suggests H01M10/48 → User accepts → Results include both classes

**Test Framework:** `pytest` with test database (PostgreSQL)

---

### User Acceptance Testing (Beta)

**Beta Users:** 20 internal PatentCloud users (mix of examiners, attorneys, researchers)

**Testing Period:** 1 week (Week 8)

**Feedback Collection:**
- Daily survey: Feature usage, bugs encountered, satisfaction score
- End-of-week interview: Qualitative feedback, feature requests
- Usage analytics: Click-through rates, acceptance rates, time savings

**UAT Exit Criteria:**
- 80%+ user satisfaction
- < 5 critical bugs
- 60%+ feature adoption (at least one AI suggestion accepted per search)

---

## Rollout Plan (Week 9+)

### Soft Launch (Week 9)
- **Audience:** 10% of PatentCloud users (random selection)
- **Feature Flags:** All 7 features enabled by default, user can disable in settings
- **Monitoring:** Real-time dashboards for latency, errors, adoption

### Full Rollout (Week 10)
- **Audience:** 100% of users
- **Marketing:** Blog post, email announcement, in-app tutorial
- **Support:** FAQ, video walkthrough, customer success outreach

### Post-Launch (Week 11+)
- **Iteration:** Collect user feedback, prioritize next features (semantic search, multilingual, etc.)
- **Model Improvement:** Refine synonym thesaurus, expand assignee database
- **Documentation:** Update user guides, create advanced search tutorials

---

## Open Questions (MVP Scope)

1. **Synonym Thesaurus Coverage:**
   - Should we crowdsource user-contributed synonyms, or keep curated-only?
   - **Decision Needed By:** Week 2 (impacts data quality strategy)

2. **Assignee Acquisition Tracking:**
   - How often should we update the acquisition history database?
   - **Decision Needed By:** Week 2 (impacts data refresh pipeline)

3. **Classification Suggestion Limit:**
   - How many adjacent classes should we suggest? (Currently: 5)
   - **Decision Needed By:** Week 4 (impacts UI design)

4. **Progress Indicator Granularity:**
   - Should we show real-time progress (WebSocket) or estimated stages?
   - **Decision Needed By:** Week 6 (impacts infrastructure)

5. **Search History Retention:**
   - How long should we keep search history? (30 days? 90 days? Forever?)
   - **Decision Needed By:** Week 6 (impacts storage costs and privacy policy)

---

## Status

- [ ] Specification review (Constitutional compliance check)
- [ ] Design review (API and UI/UX)
- [ ] Sprint 1-2 complete (Synonym + Assignee)
- [ ] Sprint 3-4 complete (Classification)
- [ ] Sprint 5-6 complete (UX Polish)
- [ ] Sprint 7-8 complete (Testing + P2)
- [ ] UAT complete (Beta feedback positive)
- [ ] Deployed to production

---

## Changelog

| Date       | Author | Changes                                      |
|------------|--------|----------------------------------------------|
| 2025-10-19 | AI     | MVP specification focusing on low-hanging fruit |

---

**Created:** 2025-10-19
**Last Updated:** 2025-10-19
**Owner:** AI Search Team (PatentCloud by InQuartik)
**Constitutional Alignment:** v1.1.0
**Related Documents:** `ai-search-feature.md` (full roadmap)
