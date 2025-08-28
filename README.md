# ALU — Waterfall Case‑Study

> **Project mode:** Documentation‑centric Waterfall lifecycle demonstration. By default, **no new code is written**; existing artifacts (reports, diagrams, example benches) are cited as *evidence* where appropriate. If a pure green‑field is required, switch the **Evidence** sections to “N/A”.

---

## 0. Purpose & Fit

This repository demonstrates the **Waterfall** development process across five sequential layers using a modest, well‑bounded subject: an **Arithmetic Logic Unit (ALU)**. The emphasis is on **process clarity, traceability, and reviewability** rather than on implementation volume. A reviewer (“client”) can evaluate scope, feasibility, acceptance criteria, risks, and test adequacy **without reading or running code**.

**Who is the consumer?** Instructors, reviewers, or a future team deciding whether to adopt or fund the design. They need concise documents that answer: 
- *What are we building?*
- *Why?* 
- *How does the architecture satisfy concerns?* 
- *What proves it works?* 
- *What will it cost in time and risk?*

**What this is not:** A feature‑factory or an implementation sprint. Coding is optional and, if present, is strictly **evidence** for requirements/design decisions.

---

## 1. Five Waterfall Layers

> Each layer has **(a)** its own document, **(b)** acceptance checklist, and **(c)** traceability links. 
> All requirement IDs use the form `REQ‑###`.

### 1. Goals & Specifications (SRS)

**Doc:** `docs/srs.md`

**Intent.** Define problem, scope, stakeholders, assumptions, constraints, and **testable** requirements for the ALU (ops/opcodes, widths, signed/unsigned semantics, Z/N/C/V flags, timing/clock/reset assumptions, environmental constraints, acceptance criteria).

**Must contain.**

* Clear goal statement and out‑of‑scope boundaries.
* Atomic, unambiguous, verifiable requirements (each labeled `REQ‑…`).
* Acceptance criteria mapping (`AC‑…`) and quality attributes (e.g., correctness, portability to FPGA toolchains).

**Outputs.** SRS v1.0 + change‑log.
**Traceability.** `REQ‑…` → (Design items, Tests).

---

### 2. Architecture Description (AD)

**Doc:** `docs/architecture.md`

**Intent.** Describe how the system is structured to satisfy stakeholder concerns. Use recognized views and note key **decisions** (controller vs core split, flag handling strategy, testability seams).

**Must contain.**

* Stakeholders & concerns table (possible instructor requirements: grading clarity; future team: reuse; verifier: test hooks).
* Views: Context (ALU in a larger CPU), Container (controller, ALU core, shifter, adder, logical unit), Component (module APIs, interfaces).
* Decision records (ADR‑###) for major trade‑offs; constraints/assumptions explicitly tied to SRS.

**Outputs.** Architecture pack with diagrams under `docs/diagrams/`.
**Traceability.** Viewpoints ↔ concerns; ADRs ↔ `REQ‑…`.

---

### 3. Design Specification

**Doc:** `docs/design.md`

**Intent.** Specify modules, interfaces, timing diagrams, invariants, and edge‑case rules. Define **oracles** for flags (Z/N/C/V), overflow/borrow semantics, and shift behavior.

**Must contain.**

* Interface tables (ports, widths, clock, reset behavior).
* Timing & state diagrams (where relevant).
* Error/edge handling (e.g., shift amount clamp, divide‑by‑zero N/A).
* Each design item cites its driving `REQ‑…`.

**Outputs.** Design spec + generated diagrams.
**Traceability.** `REQ‑…` → Design item(s) → (Planned tests).

---

### 4. Implementation Plan (Actualize Designs)

**Doc:** `docs/implementation_plan.md`

**Intent.** Even if no code is written, describe **how** the design would be built: work packages, roles, schedule, quality plan, configuration management, and risks.

**Must contain.**

* Work Breakdown Structure (WBS) aligned to design components.
* Roles/RACI (e.g., Lead, Architect, Test Lead, CM).
* Milestone schedule (Gantt or table) with buffers.
* Risk register with mitigations; change‑control policy.
* Definition of Done (per work package) tied to `REQ‑…` and tests.

**Outputs.** Implementation plan v1.0; risk & change logs.
**Traceability.** Work package ↔ Design item ↔ `REQ‑…`.

---

### 5. Test & Verification

**Doc:** `docs/test_plan.md`
**Matrix:** `docs/traceability.md`

**Intent.** Define test strategy (levels, techniques), test design, data, oracles, and pass/fail criteria. Provide a **Traceability Matrix** from `REQ‑…` to test cases and evidence.

**Must contain.**

* Test levels: unit (per module), integration (controller↔core), acceptance (per AC‑…).
* Techniques: requirements‑based, boundary, equivalence classes, property checks.
* Repro steps (even if conceptual): commands or pseudo‑scripts.
* Evidence locations (logs, waveforms, analysis notes) or “N/A (no‑code mode)”.

**Outputs.** Test plan v1.0 + sample artifacts folder `evidence/` (optional).
**Traceability.** `REQ‑…` → Test(s) → Evidence.

---

## 2. Scope & Non‑Goals

* **In scope:** Documentation artifacts, review readiness, traceability, risk/quality plans
* **Out of scope:** Shipping a synthesized ALU, performance benchmarking, toolchain‑specific optimization

If any coding is later permitted, it must be scoped as **evidence spikes** with explicit timeboxes and mapped to specific `REQ‑…` and tests.

---

## 3. Evidence Policy

Cite previous reports/figures/benches as *evidence* supporting feasibility or clarifying semantics.

* `Project/docs/latex_1/report.pdf` — gates & basic benches (examples for requirements precision).
* `Project/docs/latex_2/report.pdf` — n‑bit patterns & macro instantiation (design scalability).
* `Project/docs/latex_3/report.pdf` — controller vs core; opcodes; integration considerations.
* `Project/out/waveforms/*.vcd` — optional illustrative signals for acceptance examples.

---

## 4. How to Review

1. Read `docs/srs.md` for goals, `REQ‑…`, and acceptance criteria (`AC‑…`).
2. Skim `docs/architecture.md` (views/ADRs) and `docs/design.md` (interfaces, edge cases).
3. Open `docs/test_plan.md` and `docs/traceability.md`; pick any `REQ‑…` and follow the row to the associated tests (and evidence if present).

**General Decision prompts:**

* Are `REQ‑…` testable and bounded?
* Do architecture/design address stakeholder concerns?
* Are acceptance tests sufficient and reproducible (conceptually or concretely)?

---

## 5. Team & Roles (RACI)

| Role      | Responsibilities                     | Primary Artifacts        |
| --------- | ------------------------------------ | ------------------------ |
| Lead / PM | Schedule, risks, change control      | Impl Plan, Risk Register |
| Architect | Views, ADRs, constraints             | Architecture Doc         |
| Designer  | Interfaces, timing, invariants       | Design Spec              |
| Test Lead | Strategy, cases, oracles, evidence   | Test Plan, Traceability  |
| CM / QA   | Repo hygiene, reviews, quality gates | Checklists, Review logs  |

> Individuals may hold multiple roles; list names in `docs/team.md`.

---

## 6. Schedule (Semester Plan)

> Plan the schedule layout in `docs/implementation_plan.md` and `docs/test_plan.md`.

---

## 7. Repository Layout

```
/Project
  /docs
    /waterfall
      srs.md
      architecture.md
      design.md
      implementation_plan.md
      test_plan.md
      traceability.md
      team.md
      change_log.md
      /diagrams   # For any new diagrams developed
      ... Latex reports
    ... Project code, outputs, etc

# Refer to prior reports, waveforms, logs for evidence (if needed)
# Reference to diagram generators or doc helpers are also helpful
README.md
```

---

## 8. Quality Gates & Rubric Hints

* **Requirements quality:** atomic, unambiguous, verifiable; each has acceptance mapping.
* **Architecture adequacy:** views cover stakeholders; ADRs record decisions & trade‑offs.
* **Design clarity:** complete interfaces, timing, and edge‑case rules; invariants explicit.
* **Test completeness:** `REQ‑…` → test(s) → evidence (or clear rationale if no‑code).
* **Traceability:** any `REQ‑…` can be followed to design/test/evidence; nothing orphaned.

---

## 9. Change Management

> Use `docs/change_log.md` and ADRs (architecture decision records). 
> Any change to `REQ‑…` triggers review of linked design/tests (update the Matrix). 
> Capture rationale and impact.

---

## 10. References & Templates (quick links)

* **Waterfall basics / context**: W. Royce, *Managing the Development of Large Software Systems* (1970).
* **Requirements (SRS)**: ISO/IEC/IEEE 29148; public summaries and templates.
* **Architecture descriptions**: ISO/IEC/IEEE 42010; **C4 Model** (Context/Container/Component/Code).
* **Testing**: ISO/IEC/IEEE 29119 (concepts/process); requirements‑based testing.

> Add direct links your team prefers; include any course‑specific handouts.

---

## 11. Appendix A — Traceability Matrix (Template)

> Add any `REQ –…` and tests that can be traced to evidence.

---

## 12. Executive Summary (Template)

1. Start with the problem or need the project is solving
At the beginning of your executive summary, start by explaining why this document (and the project it represents) matter. Take 
some time to outline what the problem is, including any research or customer feedback you’ve gotten. Clarify how this problem is 
important and relevant to your customers, and why solving it matters.

For example, let’s imagine you work for a watch manufacturing company. Your project is to devise a simpler, cheaper watch that 
still appeals to luxury buyers while also targeting a new bracket of customers.

Example executive summary:
In recent customer feedback sessions, 52% of customers have expressed a need for a simpler and cheaper version of our product. In 
surveys of customers who have chosen competitor watches, price is mentioned 87% of the time. To best serve our existing customers, 
and to branch into new markets, we need to develop a series of watches that we can sell at an appropriate price point for this 
market.

> Here, we could develop a specialized ALU for machine learning application, that focuses on prioritizing the speed at which
> matrix multiplication can be performed.

**Sample Problem:**
AI chips are specialized for machine learning and are expensive to produce. We want to produce a cheaper version of the ALU that 
the chip utilizes while also making it faster at performing matrix operations, specifically matrix multiplication.

> For further studies on how ALU's are developed in processor cores, investigate Nvidia's Tensor Core architecture. They 
> enhance the performance of matrix multiplications, similar to our proposed goal.

**Sample Problem:**
Math operations are becoming more and more complex, resulting in more expensive software to be developed to handle them. We want
to develop a cheaper, faster, and more efficient version of the ALU's that these operations are performed on. Because ALU's are 
a mainstay in current processors, working on improving their processing power is a high priority in a world where software is 
increasing in complexity, dropping in performance, and rising in cost. 

2. Outline the recommended solution, or the project’s objectives
Now that you’ve outlined the problem, explain what your solution is. Unlike an abstract or outline, you should be prescriptive in 
your solution—that is to say, you should work to convince your readers that your solution is the right one. This is less of a 
brainstorming section and more of a place to support your recommended solution.

Because you’re creating your executive summary at the beginning of your project, it’s ok if you don’t have all of your 
deliverables and milestones mapped out. But this is your chance to describe, in broad strokes, what will happen during the 
project. If you need help formulating a high-level overview of your project’s main deliverables and timeline, consider creating a 
project roadmap before diving into your executive summary.

Continuing our example executive summary:
Our new watch series will begin at 20% cheaper than our current cheapest option, with the potential for 40%+ cheaper options 
depending on material and movement. In order to offer these prices, we will do the following:

Offer watches in new materials, including potentially silicone or wood

Use high-quality quartz movement instead of in-house automatic movement

Introduce customizable band options, with a focus on choice and flexibility over traditional luxury

Note that every watch will still be rigorously quality controlled in order to maintain the same world-class speed and precision of our current offerings.

> Here, solutions to the growing complexity of mathematical operations are suggested.

**Sample Solution:**
The development of faster processors have stagnated and have reached their physical limits. These limitations can be superseded
if we can develop a method to transfer the information from one processor to another in a faster and more efficient way. Here,
we propose the use of integrated photonic ALUs, which has undergone significant research in the last few years with real
prospects of success once development can be solidified. These ALUs are able to transmit information using the wavelengths light 
emits. Because of the sheer speed light can travel at, these ALUs performance metrics can be significantly improved.

> Research Photonic ALUs and 3D Stacking ALUs

3. Explain the solution’s value
At this point, you begin to get into more details about how your solution will impact and improve upon the problem you outlined in the beginning. What, if any, results do you expect? This is the section to include any relevant financial information, project risks, or potential benefits. You should also relate this project back to your company goals or OKRs. How does this work map to your company objectives?

Continuing our example executive summary:
With new offerings that are between 20% and 40% cheaper than our current cheapest option, we expect to be able to break into the casual watch market, while still supporting our luxury brand. That will help us hit FY22’s Objective 3: Expanding the brand. These new offerings have the potential to bring in upwards of three million dollars in profits annually, which will help us hit FY22’s Objective 1: 7 million dollars in annual profit.

Early customer feedback sessions indicate that cheaper options will not impact the value or prestige of the luxury brand, though this is a risk that should be factored in during design. In order to mitigate that risk, the product marketing team will begin working on their go-to-market strategy six months before the launch.

> With the introduction of the capabilities that Photonic ALUs could bring to the microprocessor market, early investments
> would help propagate the success of this innovation.

**Sample Value:**
With growing costs and the rampant increase in demand for high-end processing units, especially in applications like machine
learning, AI, GPU computing, and neural networks, Photonic ALUs have the potential to become a game-changer in the field. They would eliminate the physical limitations currently experienced by traditional processors, while having the ability to be integrated
seamlessly in already well-established systems and methods in the processing field. The applications Photonic ALUs could
be used for are extremely broad, as they can replace their predecessors (digital signals, analog signals, and even
quantum computing) while performing at significant, higher scales.

4. Wrap up with a conclusion about the importance of the work
Now that you’ve shared all of this important information with executive stakeholders, this final section is your chance to guide their understanding of the impact and importance of this work on the organization. What, if anything, should they take away from your executive summary?

To round out our example executive summary:
Cheaper and varied offerings not only allow us to break into a new market—it will also expand our brand in a positive way. With the attention from these new offerings, plus the anticipated demand for cheaper watches, we expect to increase market share by 2% annually. For more information, read our go-to-market strategy and customer feedback documentation.

> Here, the importance of the work is highlighted. We can reiterate that Photonic ALUs are a game-changer in the field and so on.

**Sample Conclusion:**
The research in Photonic ALUs has shown promising results and has the potential to become the next revolution in computer
science. These ALUs would transmit light across their microchips, utilizing the vast amount of wavelengths that light can
emit, to transfer information at record speeds, perhaps even faster than quantum computing. Photonic ALUs would enhance every
aspect of computing we currently do today and eliminate the most significant hurdle facing the microprocessor market today: the
stagnation of processor speeds and the physical limits that these processors are currently unable to overcome.

---