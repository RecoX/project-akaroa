# Project Akaroa — Production Spreadsheet Entry Checklist

Step-by-step instructions for filling out the CODE Production Spreadsheet.
Based on `spreadsheet-answers.md`, `production-budget.md`, and `readme.md`.

**Grant type:** KickStart ($60,000)
**Duration:** 72 weeks
**Team:** 5 members (1 founder + 2 overseas contractors + 1 lead dev + 1 trainee)

**Important rules:**
- Do NOT drag and drop cells — type values directly
- Wait for the progress bar after each entry before moving to the next cell
- Work left to right through tabs: Production Schedule → Team Costs → Additional Service Costs → Assets and License Costs → Other Costs → Summary
- Orange cells can be ignored at application stage
- If you run out of rows, email funding@nz-code.nz

---

## Tab 1: Production Schedule (Team Tasks)

### Step 1.1 — Replace the Team Member List (Rows 5–34)

Delete example names. Enter:

| Row | Name (Column B) | Role (Column C) | Total Hours (Column D) |
|-----|-----------------|-----------------|------------------------|
| 5 | Lucas Recoaro | Engineer / Project Director | 2,880 |
| 6 | TBC Environment Artist | Environment Art (2D/2.5D) | 800 |
| 7 | TBC Character Artist | Character Art / Animation | 400 |
| 8 | TBC Lead Developer | Lead Developer | 2,880 |
| 9 | TBC Trainee | Trainee / Junior Developer | 200 |

Leave rows 10–34 empty.

**Hours logic:**
- Lucas: 72 weeks × 40 hrs/wk = 2,880
- Environment Artist: 20 weeks × 40 hrs/wk = 800
- Character Artist: 10 weeks × 40 hrs/wk = 400
- Lead Developer: 72 weeks × 40 hrs/wk = 2,880
- Trainee: 5 weeks × 40 hrs/wk = 200

### Step 1.2 — Replace the Task List (Row 40 onwards)

Delete all example tasks. Enter:

**Phase 1: Core Loop (Weeks 1–20)**

| Row | Task | Responsible | Hours |
|-----|------|-------------|-------|
| 40 | Project planning, architecture, Steam page setup | Lucas Recoaro | 200 |
| 41 | Core combat and movement systems (Godot 4) | Lucas Recoaro | 600 |
| 42 | Base environment tileset and art pipeline | TBC Environment Artist | 400 |
| 43 | Character sprites — base archetypes, idle/walk/combat | TBC Character Artist | 200 |
| 44 | Core systems development, networking foundation | TBC Lead Developer | 800 |

**Phase 2: Systems (Weeks 21–44)**

| Row | Task | Responsible | Hours |
|-----|------|-------------|-------|
| 45 | P2P marketplace prototype, faction system, crafting | Lucas Recoaro | 960 |
| 46 | One complete playable zone — environment art | TBC Environment Artist | 400 |
| 47 | Additional character sets, NPC sprites | TBC Character Artist | 200 |
| 48 | Multiplayer systems, server architecture | TBC Lead Developer | 960 |
| 49 | Assisted development tasks, QA, documentation | TBC Trainee | 200 |

**Phase 3: Polish & Validation (Weeks 45–64)**

| Row | Task | Responsible | Hours |
|-----|------|-------------|-------|
| 50 | Sound integration, UI polish, community playtesting | Lucas Recoaro | 800 |
| 51 | Systems polish, performance, bug fixing | TBC Lead Developer | 800 |

**Phase 4: Vertical Slice (Weeks 65–72)**

| Row | Task | Responsible | Hours |
|-----|------|-------------|-------|
| 52 | Final vertical slice build, documentation, wishlist campaign | Lucas Recoaro | 320 |
| 53 | Final integration, deployment, QA | TBC Lead Developer | 320 |

Leave rows 54+ empty.

### Step 1.3 — Verify Hours Alignment

| Team Member | Total Hours | Check |
|-------------|-------------|-------|
| Lucas Recoaro | 2,880 | 200 + 600 + 960 + 800 + 320 = 2,880 ✓ |
| TBC Environment Artist | 800 | 400 + 400 = 800 ✓ |
| TBC Character Artist | 400 | 200 + 200 = 400 ✓ |
| TBC Lead Developer | 2,880 | 800 + 960 + 800 + 320 = 2,880 ✓ |
| TBC Trainee | 200 | 200 = 200 ✓ |

---

## Tab 2: Team Costs

Names and Roles auto-populate from Production Schedule. Only fill the **pink/purple editable cells** (Columns C, D, E, F, H, I).

### Step 2.1 — Enter Values

**Row 5 — Lucas Recoaro #1** (Engineer / Project Director — prior work, in-kind)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| Y | Y | N | N | $125.00 | 40 |

→ Not paid. In-kind only. Assign task "Prior development — AO operations 2017–2025" with 7,200 hours in Production Schedule. Result: $125 × 7,200 = $900,000 in-kind.

**Row 6 — Lucas Recoaro #2** (Engineer / Project Director — current project, in-kind)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| Y | Y | N | N | $64.10 | 20 |

→ Not paid. In-kind. Assign tasks totalling 1,440 hours across the 72-week project.

**Row 7 — TBC Environment Artist** (Environment Art)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| N | N | Y | Y | $10.00 | 40 |

→ 800 hours of tasks. Auto-calculates to 20 weeks. $10 × 800 = $8,000 Overseas.

**Row 8 — TBC Character Artist** (Character Art / Animation)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| N | N | Y | Y | $10.00 | 40 |

→ 400 hours of tasks. Auto-calculates to 10 weeks. $10 × 400 = $4,000 Overseas. **Note:** To get exactly $3,999, enter $9.998/hr or reduce task hours to 399.

**Row 9 — TBC Lead Developer** (Lead Developer)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| Y | N | Y | Y | $14.93 | 40 |

→ 2,880 hours of tasks. Auto-calculates to 72 weeks. $14.93 × 2,880 = $43,001 NZ.

**Row 10 — TBC Trainee** (Trainee / Junior Developer)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| Y | N | Y | Y | $10.00 | 40 |

→ 200 hours of tasks. Auto-calculates to 5 weeks. $10 × 200 = $2,000 NZ.

Clear rows 10–34.

### Step 2.2 — Verify Totals

- NZ spend (CODE): $45,001
- Overseas spend (CODE): $11,999
- In kind: $900,000
- Team total: $57,000

---

## Tab 3: Additional Service Costs

Clear example rows. Enter:

| Row | Service (Col A) | NZ Spend CODE (Col B) |
|-----|-----------------|----------------------|
| 9 | Server hosting (development/testing) | $2,000 |

All NZ-based, all CODE-funded. Overseas = $0.

**Total: $2,000**

---

## Tab 4: Assets and License Costs

Clear example rows. Enter:

| Row | Item (Col A) | Lump Sum |
|-----|-------------|----------|
| 10 | Domain, SSL, web hosting | $1,000 |

**Total: $1,000**

---

## Tab 5: Other Costs (Prohibited Spend)

Clear example rows. Enter:

| Row | Item | Lump Sum |
|-----|------|----------|
| 8 | Equipment (hardware, peripherals) | $8,000 |
| 9 | Office / workspace costs | $7,000 |

**Total: $15,000** (self-funded, not CODE)

---

## Tab 6: Summary

### Manual entry fields:

| Field | Value |
|-------|-------|
| Primary Contact name | Lucas Recoaro |
| Primary Contact email | lucas.recoaro@gmail.com |
| Team or Company | Conreco Limited |
| Project Name / Codename | Project Akaroa |
| CODE Funding application type | KickStart |
| Best estimate of weeks to complete | 52 |
| Cash funding from you / your team | $15,000 |
| Additional external investment secured | $0 |

### Expected auto-calculated values:

| Field | Expected Value |
|-------|---------------|
| Team Costs (Allowed Spend) | $57,000 |
| Additional Service Costs (Allowed Spend) | $2,000 |
| Assets and License Costs (Allowed Spend) | $1,000 |
| Allowable Expenditure for funding | $60,000 |
| Other costs (Prohibited Spend) | $15,000 |
| % spent outside NZ using CODE funding | 19.99% |
| In kind funding from equity holders | $900,000 |
| Cash funding from you / your team | $15,000 |
| Balance | $0 |
| Does your allowable expenditure fit within funding limits? | Y |
| Form Status | Green ✓ |

---

## ⚠️ Final Checks

1. **Overseas spend:** $11,999 of $60,000 = 19.99%. Under 20% ✓
2. **Hours alignment:** Production Schedule hours must match Team Costs hours (auto-calculated from rate × hrs/wk × weeks)
3. **KickStart max:** $60,000 allowable. Verify the spreadsheet shows $60,000 as the CODE request
4. **No drag and drop** — type everything directly
5. **Wait for progress bar** between entries
