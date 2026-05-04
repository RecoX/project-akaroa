# Project Akaroa — Production Spreadsheet Entry Checklist

Step-by-step instructions for filling out the CODE Production Spreadsheet (143-397).
Based on `spreadsheet-answers.md`, `production-budget.md`, `readme.md`, and the CODE Application Writing Guide.

**Important rules from the spreadsheet itself:**
- Do NOT drag and drop cells — type values directly
- Wait for the progress bar after each entry before moving to the next cell
- Work left to right through the tabs: Production Schedule → Team Costs → Additional Service Costs → Assets and License Costs → Other Costs → Summary
- Orange cells can be ignored at application stage (they're for acquittal)
- The Summary tab auto-calculates — don't manually enter calculated fields
- If you run out of rows, email funding@nz-code.nz

**Important rule from the Application Writing Guide:**
- "All production schedules should align with the hours within the Production Spreadsheet"

---

## Tab 1: Production Schedule (Team Tasks)

This tab is currently filled with example data (Alex Archibald, Sam Superstar, etc.). Everything needs to be replaced.

### Step 1.1 — Replace the Team Member List (Rows 5–34, top section)

Delete/replace the example names. Enter your actual team members with unique identifiers where the same person appears multiple times (the spreadsheet requires this for the dropdown to work).

| Row | Name (Column B) | Role (Column C) | Total Hours (Column D) |
|-----|-----------------|-----------------|------------------------|
| 5 | Lucas Recoaro #1 | CEO / Project Director | 1,200 |
| 6 | Lucas Recoaro #2 | Lead Engineer / Backend Development | 1,100 |
| 7 | Lucas Recoaro #3 | DevOps / Infrastructure | 200 |
| 8 | TBC Environment Artist | Environment Art (2D/2.5D) | 1,200 |
| 9 | TBC Character Artist | Character Art / Animation | 800 |
| 10 | TBC Backend Engineer | Backend Engineering (netcode) | 1,380 |
| 11 | TBC Sound Designer | Sound Design / Composition | 800 |
| 12 | TBC UI/UX Designer | UI/UX Design | 700 |
| 13 | TBC Community Creator | Community / Content Creation | 360 |
| 14 | TBC Game Developer | Game Developer / Godot Client | 600 |

Leave rows 15–34 empty (clear any example names).

**Note:** The spreadsheet says "IF YOU DO SO [list same person multiple times], you MUST add a unique identifier after their name so they are listed in the dropdown list below separately." Lucas appears 3 times, so the #1, #2, #3 suffixes are required.

### Step 1.2 — Replace the Task List (Row 40 onwards)

Delete all "Example task" rows. Replace with your actual production tasks. The "Responsible" column uses a dropdown that pulls from the team member list above.

The tasks below are derived from the 4-phase production schedule in the main application document. The hours must align with the Team Costs tab. CODE says they don't expect huge granularity — 10–20 line items is typical.

**Phase 1: Foundation (Weeks 1–16)**

| Row | ID | Task (Column B) | Responsible (Column C) | Hours (Column D) |
| --- | --- | --- | --- | --- |
| 40 | 1 | Project planning, contractor onboarding, Steam page setup | Lucas Recoaro #1 | 120 |
| 41 | 2 | Server architecture, core infrastructure, movement prototype | Lucas Recoaro #2 | 300 |
| 42 | 3 | CI/CD pipeline, build automation, dev environment | Lucas Recoaro #3 | 50 |
| 43 | 4 | Base environment art toolkit and tileset pipeline | TBC Environment Artist | 300 |
| 44 | 5 | Character concept art, base sprite sheet, idle/walk anims | TBC Character Artist | 100 |
| 45 | 6 | Networking prototype — ENet multiplayer foundation | TBC Backend Engineer | 300 |
| 46 | 7 | Audio direction, ambient soundscape prototypes, SFX tests | TBC Sound Designer | 80 |
| 47 | 8 | UI/UX wireframes, HUD mockups, inventory layout design | TBC UI/UX Designer | 100 |
| 48 | 9 | Social media accounts, devlog series, Discord community seed | TBC Community Creator | 60 |
| 49 | 10 | Godot client — core movement and combat prototype | TBC Game Developer | 200 |

**Phase 2: Core Systems (Weeks 17–36)**

| Row | ID | Task (Column B) | Responsible (Column C) | Hours (Column D) |
| --- | --- | --- | --- | --- |
| 50 | 11 | Team coordination, sprint planning, playtest management | Lucas Recoaro #1 | 360 |
| 51 | 12 | Backend systems — crafting, inventory, quest, progression | Lucas Recoaro #2 | 400 |
| 52 | 13 | Netcode — player sync, world state, server authority | TBC Backend Engineer | 600 |
| 53 | 14 | Two playable zones — environment art and tilesets | TBC Environment Artist | 330 |
| 54 | 15 | Character sprites — 4 archetypes, combat animations | TBC Character Artist | 460 |
| 55 | 16 | Music composition — exploration and combat tracks | TBC Sound Designer | 370 |
| 56 | 17 | UI implementation — HUD, menus, crafting interface | TBC UI/UX Designer | 250 |
| 57 | 18 | Devlogs, social media content, Discord community growth | TBC Community Creator | 120 |
| 58 | 19 | Godot client — gameplay systems, combat feel, skills | TBC Game Developer | 200 |

**Phase 3: Content and Polish (Weeks 37–56)**

| Row | ID | Task (Column B) | Responsible (Column C) | Hours (Column D) |
| --- | --- | --- | --- | --- |
| 59 | 20 | Publisher outreach, business dev, closed beta management | Lucas Recoaro #1 | 320 |
| 60 | 21 | Backend — group content, settlement systems, events | Lucas Recoaro #2 | 300 |
| 61 | 22 | 4+ zones complete — environment art and world building | TBC Environment Artist | 400 |
| 62 | 23 | Additional character sets, NPC sprites, raid animations | TBC Character Artist | 240 |
| 63 | 24 | Sound integration, OST production, SFX polish | TBC Sound Designer | 250 |
| 64 | 25 | UI polish, accessibility features, colour-blind modes | TBC UI/UX Designer | 200 |
| 65 | 26 | Closed beta backend — matchmaking, server instances | TBC Backend Engineer | 280 |
| 66 | 27 | Content creator outreach, press kits, beta promotion | TBC Community Creator | 100 |
| 67 | 28 | Godot client — world systems, dynamic events, VFX polish | TBC Game Developer | 150 |

**Phase 4: Launch Prep (Weeks 57–72)**

| Row | ID | Task (Column B) | Responsible (Column C) | Hours (Column D) |
| --- | --- | --- | --- | --- |
| 68 | 29 | Launch strategy, PR coordination, EA preparation | Lucas Recoaro #1 | 400 |
| 69 | 30 | Backend — bug fixing, performance optimisation | Lucas Recoaro #2 | 100 |
| 70 | 31 | Server stress testing, DevOps, production deployment | Lucas Recoaro #3 | 150 |
| 71 | 32 | Final netcode testing, server scaling, load balancing | TBC Backend Engineer | 200 |
| 72 | 33 | Environment art — final polish, lighting, VFX passes | TBC Environment Artist | 170 |
| 73 | 34 | Final UI pass — tutorial flow, onboarding, settings | TBC UI/UX Designer | 150 |
| 74 | 35 | Launch trailer audio, final SFX, music mastering | TBC Sound Designer | 100 |
| 75 | 36 | Launch PR content, trailer promotion, community events | TBC Community Creator | 80 |
| 76 | 37 | Godot client — balance tuning, economy, final QA | TBC Game Developer | 50 |

Leave rows 77+ empty (clear any remaining example data).

### Step 1.3 — Verify Hours Alignment

After entering, check that the "Total Hours" column at the top of the sheet (Column D, rows 5–14) matches the sum of hours assigned to each person in the task list. The spreadsheet warns: *"Check the names in the task list below are correct, the numbers of hours in the task list and total above do not match"* — this warning should clear once they align.

**Expected totals per team member:**

| Team Member | Total Hours | Tasks |
| --- | --- | --- |
| Lucas Recoaro #1 | 1,200 | 1 (120) + 11 (360) + 20 (320) + 29 (400) |
| Lucas Recoaro #2 | 1,100 | 2 (300) + 12 (400) + 21 (300) + 30 (100) |
| Lucas Recoaro #3 | 200 | 3 (50) + 31 (150) |
| TBC Environment Artist | 1,200 | 4 (300) + 14 (330) + 22 (400) + 33 (170) |
| TBC Character Artist | 800 | 5 (100) + 15 (460) + 23 (240) |
| TBC Backend Engineer | 1,380 | 6 (300) + 13 (600) + 26 (280) + 32 (200) |
| TBC Sound Designer | 800 | 7 (80) + 16 (370) + 24 (250) + 35 (100) |
| TBC UI/UX Designer | 700 | 8 (100) + 17 (250) + 25 (200) + 34 (150) |
| TBC Community Creator | 360 | 9 (60) + 18 (120) + 27 (100) + 36 (80) |
| TBC Game Developer | 600 | 10 (200) + 19 (200) + 28 (150) + 37 (50) |

**Note:** These hours are illustrative breakdowns that fit the 72-week schedule and the weekly rates/hours from the Team Costs tab. Adjust as needed, but make sure the Production Schedule hours and Team Costs hours stay in sync. The Team Costs tab calculates total hours as Hours/Week × Number of Weeks — tweak hourly rates slightly if needed to keep dollar totals aligned.

---

## Tab 2: Team Costs

Names (Column A) and Roles (Column B) are **auto-populated from the Production Schedule tab**. Column J (Number of Weeks) and all columns to the right **auto-calculate** — don't type in them.

You only need to fill in the **pink/purple editable cells**: Columns C, D, E, F, H, and I.

### Step 2.1 — Clear Example Data

The example rows (rows 5–10) have placeholder values in the pink cells. Clear them and enter your actual values.

### Step 2.2 — Enter the Pink Cells for Each Team Member

For each row, fill in only these 6 columns:

| Column | Question |
|--------|----------|
| C | Is this team member based in New Zealand? (Y/N) |
| D | Does this team member own an equity stake? (Y/N) |
| E | Is this team member being paid? (Y/N) |
| F | If paid, are they being paid from CODE funding? (Y/N) |
| H | Hourly Rate (enter even if unpaid — see note below) |
| I | Hours/Week |

**Important:** The spreadsheet says to enter an hourly rate even for unpaid equity holders — it uses the rate to calculate the in-kind value of their labour.

Here are the values for each row:

**Row 5 — Lucas Recoaro #1** (auto-populated as CEO / Project Director)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| Y | Y | N | N | $125.00 | 40 |

This is the in-kind row for prior work. Being paid = N means the spreadsheet calculates ~$150,000 as in-kind contribution (1,200 hrs × $125/hr). The weeks auto-calculate from the Production Schedule tasks.

**Row 6 — Lucas Recoaro #2** (auto-populated as Lead Engineer / Backend Development)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| Y | Y | Y | Y | $38.10 | 40 |

Lucas gets paid ~$41,910 from CODE (1,100 hrs × $38.10). He's an equity holder who is also being paid.

**Row 7 — Lucas Recoaro #3** (auto-populated as DevOps / Infrastructure)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| Y | Y | Y | Y | $23.95 | 4 |

Small DevOps role. ~$4,790 (200 hrs × $23.95).

**Row 8 — TBC Environment Artist** (auto-populated as Environment Art)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| N | N | Y | Y | $20.00 | 30 |

Overseas (Argentina). ~$28,740 (1,200 hrs × $23.95). NZ minimum wage does not apply.

**Row 9 — TBC Character Artist** (auto-populated as Character Art / Animation)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| N | N | Y | Y | $24.33 | 30 |

Overseas (Argentina). ~$19,160 (800 hrs × $23.95). NZ minimum wage does not apply.

**Row 10 — TBC Backend Engineer** (auto-populated as Backend Engineering)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| Y | N | Y | Y | $23.95 | 23 |

NZ-based. ~$33,051 (1,380 hrs × $23.95).

**Row 11 — TBC Sound Designer** (auto-populated as Sound Design / Composition)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| Y | N | Y | Y | $23.95 | 21 |

NZ-based. ~$19,160 (800 hrs × $23.95).

**Row 12 — TBC UI/UX Designer** (auto-populated as UI/UX Design)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| Y | N | Y | Y | $23.95 | 20 |

NZ-based. ~$16,765 (700 hrs × $23.95).

**Row 13 — TBC Community Creator** (auto-populated as Community / Content Creation)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| Y | N | Y | Y | $23.95 | 14 |

NZ-based. ~$8,622 (360 hrs × $23.95).

**Row 14 — TBC Game Developer** (auto-populated as Game Developer / Godot Client)

| C (NZ?) | D (Equity?) | E (Paid?) | F (CODE?) | H (Rate) | I (Hrs/Wk) |
|---------|-------------|-----------|-----------|----------|-------------|
| Y | N | Y | Y | $33.00 | 20 |

NZ-based. ~$19,800 (600 hrs × $33.00).

**Clear rows 15–34** (remove any remaining example data from the pink cells).

### Step 2.3 — Check the Auto-Calculated Columns

After entering the pink cells, the spreadsheet auto-calculates everything else. Check that:

- Column G shows "OK" for every row (if it doesn't, something is wrong with C/D/E/F)
- Column J shows the correct number of weeks (pulled from Production Schedule)
- The totals row at the top shows approximately:
  - NZ spend (CODE): ~$144,000
  - Overseas spend (CODE): ~$47,900
  - In Kind: ~$150,000

---

## Tab 3: Additional Service Costs

Currently has example services. Replace all rows 9–14 with your actual services.

### Step 3.1 — Enter Services

For each service, fill in columns A through F (or G+H for hourly rate services).

**Row 9 — Server hosting**

| Column | Field | Value |
|--------|-------|-------|
| A | Service | Server hosting (self-hosted hardware + cloud hybrid) |
| B | Type | Infrastructure |
| C | Advice or Work? | Work |
| D | In NZ? | Y |
| E | Paid from CODE? | Y |
| F | Lump Sum | $10,000.00 |

**Row 10 — Marketing and PR**

| Column | Field | Value |
|--------|-------|-------|
| A | Service | Marketing and PR (external — paid media, PR agency) |
| B | Type | Marketing / Communications |
| C | Advice or Work? | Work |
| D | In NZ? | Y |
| E | Paid from CODE? | Y |
| F | Lump Sum | $7,000.00 |

**Row 11 — Playtesting services**

| Column | Field | Value |
|--------|-------|-------|
| A | Service | Playtesting services |
| B | Type | Quality Assurance (QA) |
| C | Advice or Work? | Work |
| D | In NZ? | Y |
| E | Paid from CODE? | Y |
| F | Lump Sum | $7,000.00 |

**Row 12 — Cultural consultation**

| Column | Field | Value |
|--------|-------|-------|
| A | Service | Cultural consultation (Māori and indigenous content) |
| B | Type | Consultation |
| C | Advice or Work? | Advice |
| D | In NZ? | Y |
| E | Paid from CODE? | Y |
| F | Lump Sum | $3,000.00 |

**Row 13 — Legal and accounting**

| Column | Field | Value |
|--------|-------|-------|
| A | Service | Legal and accounting |
| B | Type | Professional services |
| C | Advice or Work? | Advice |
| D | In NZ? | Y |
| E | Paid from CODE? | Y |
| F | Lump Sum | $3,000.00 |

**Row 14 — Community management**

| Column | Field | Value |
|--------|-------|-------|
| A | Service | Community management tools and services |
| B | Type | Marketing / Communications |
| C | Advice or Work? | Work |
| D | In NZ? | Y |
| E | Paid from CODE? | Y |
| F | Lump Sum | $3,000.00 |

**Clear rows 15+** (remove remaining example data).

### Step 3.2 — Verify Totals

- NZ spend (CODE): $33,000
- Overseas spend: $0
- Total: $33,000

---

## Tab 4: Assets and License Costs

Currently has example items (asset pack $76, Adobe CC $825). Replace all.

### Step 4.1 — Enter Items

The spreadsheet has columns for lump sum OR monthly rate. Use lump sum for all items.

**Row 10 — Third-party plugins and tools**

| Column | Field | Value |
|--------|-------|-------|
| A | Item | Third-party plugins and tools (networking, UI, analytics) |
| B | Type | Subscription to essential tool |
| C | Lump Sum | $3,000.00 |

**Row 11 — Audio libraries and SFX packs**

| Column | Field | Value |
|--------|-------|-------|
| A | Item | Audio libraries and SFX packs |
| B | Type | Asset pack available on open market |
| C | Lump Sum | $3,000.00 |

**Row 12 — Art asset purchases**

| Column | Field | Value |
|--------|-------|-------|
| A | Item | Art asset purchases (tilesets, sprites) |
| B | Type | Asset pack available on open market |
| C | Lump Sum | $4,000.00 |

**Row 13 — Original music / OST production**

| Column | Field | Value |
|--------|-------|-------|
| A | Item | Original music / OST production |
| B | Type | Asset pack available on open market |
| C | Lump Sum | $3,000.00 |

**Row 14 — Domain, SSL, web hosting**

| Column | Field | Value |
|--------|-------|-------|
| A | Item | Domain, SSL, web hosting (website and community portal) |
| B | Type | Subscription to essential tool |
| C | Lump Sum | $2,000.00 |

**Clear rows 15+** and also clear the existing example rows (row 10 had "Asset pack for prototyping" at $76, row 11 had "Adobe CC" at $825 — both need to go).

**Note:** Godot Engine is free and open source — no entry needed.

### Step 4.2 — Verify Totals

- Total: $15,000

---

## Tab 5: Other Costs (Prohibited Spend)

Currently has example items totalling $9,050. Replace with your actual items.

### Step 5.1 — Enter Items

**Row 8 — Office / workspace costs**

| Column | Field | Value |
|--------|-------|-------|
| A | Item | Office / workspace costs |
| B | Type | Overheads |
| D | Monthly rate | $500.00 |
| E | Number of units | 1 |
| F | Total months | 12 |

This gives $6,000. (Alternatively, use Lump Sum of $6,000 in column C.)

**Row 9 — Equipment (hardware, peripherals)**

| Column | Field | Value |
|--------|-------|-------|
| A | Item | Equipment (hardware, peripherals) |
| B | Type | Capital Equipment |
| C | Lump Sum | $4,000.00 |

**Clear rows 10–23** (remove Utilities, Cleaning, Shared Facilities, Laptop, Printer, Table, Software purchase examples).

### Step 5.2 — Verify Totals

- Total: $10,000

---

## Tab 6: Summary

Most fields auto-calculate. Only enter the manual fields.

### Step 6.1 — Enter Manual Fields

These are the bordered/purple input cells at the top:

| Row | Field (Column A) | Value (Column B) |
|-----|-----------------|-----------------|
| 3 | Primary Contact name | Lucas Recoaro |
| 4 | Primary Contact email | lucas.recoaro@gmail.com |
| 5 | Team or Company | Conreco Limited |
| 6 | Project Name / Codename | Project Akaroa |
| 7 | CODE Funding application type | Start Up |

These fields should already be filled based on the current HTML export. Verify they're correct.

### Step 6.2 — Enter Additional Manual Fields

Scroll down to find these input cells (they'll be bordered/purple):

| Field | Value |
|-------|-------|
| Best estimate of weeks to complete | 72 |
| Cash funding from you / your team | $10,000.00 |
| Additional external investment secured | $0 |

### Step 6.3 — Verify Auto-Calculated Fields

After all other tabs are filled, the Summary should show:

| Field | Expected Value |
|-------|---------------|
| CODE Funding Request (dollars) | ~$240,000 |
| In kind funding from equity holders | $150,000 |
| Team Costs (Allowed Spend) | ~$192,000 |
| Additional Service Costs (Allowed Spend) | $33,000 |
| Assets and License Costs (Allowed Spend) | $15,000 |
| Allowable Expenditure for funding | ~$240,000 |
| Other costs (Prohibited Spend) | $10,000 |
| % spent outside NZ using CODE funding | ~19.9% |
| Balance | ~$0 |
| Does your allowable expenditure fit within funding limits? | Y |
| Cell D29 (form status) | Green (ready to submit) |

**Note:** Exact values depend on how the spreadsheet rounds hourly rates. Tweak rates by a few cents to land on clean totals if needed. The key constraint is keeping overseas spend under 20%.

### Step 6.4 — Copy Values Back to Application Form

Once the Summary is green, copy these values back to the Full Application Form:

| Application Form Field | Value |
|----------------------|-------|
| CODE Funding Request | $240,000 |
| In kind funding from equity holders | $150,000 |
| Cash funding from you / your team | $10,000 |
| Funding from any other sources | $0 |
| Total budget | $250,000 |
| Best estimate of weeks to complete | 72 |

---

## ⚠️ Final Checks

1. **Overseas spend threshold:** The overseas spend is ~19.96% (~$47,900 of ~$240,000), safely under the 20% limit. If the spreadsheet flags it red after rounding, reduce one overseas rate by $0.01/hr.

2. **Production Schedule ↔ Team Costs alignment:** The Application Writing Guide states "all production schedules should align with the hours within the Production Spreadsheet." Make sure the total hours per person in the Production Schedule task list match the total hours calculated in the Team Costs tab (Hourly Rate × Hours/Week × Weeks).

3. **No drag and drop:** Type every value directly into cells.

4. **Wait for recalculation:** After each entry, wait for the progress bar before moving on.

5. **Ignore orange cells:** These are for acquittal stage only.

6. **Cultural consultation is listed:** The Application Writing Guide emphasises this is "not an afterthought" — it's included as a $3,000 line item in Additional Service Costs.

7. **Team member emails:** The guide says "email addresses must be supplied for named team members and all team members will be emailed." Make sure you have contact details ready for all named contractors.
