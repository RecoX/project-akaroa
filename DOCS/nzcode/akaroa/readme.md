# Project Akaroa, Main Application Document

---

## 1. Introduction

### Elevator Pitch

Project Akaroa is a persistent online world where players build wealth through skill, effort, and commerce with each other. A 2.5D isometric MMORPG with faction warfare, real-time combat, and a peer-to-peer marketplace — from the developers of Argentum Online, designed for players tired of cash shops deciding who wins.

### Game Summary

Project Akaroa is a massively multiplayer online role-playing game that takes the proven gameplay systems, player-driven economy, and faction-based PvP of Argentum Online and migrates them into a modern engine with original art, original music, and a new fantasy world. The game features real-time combat, a peer-to-peer marketplace for characters and items, a faction warfare system, crafting, and open-world exploration — all systems that have been validated with a live player base over years of operation.

The developer has been working on Argentum Online since 2017, with focused technology migration experiments beginning in 2020 using Unity and C++ server-side, before settling on Godot 4 (client) with Rust/C++ server architecture. Every core system in Project Akaroa has been prototyped and tested in production through Argentum Online's live environment and dedicated Battle Server.

### Target Audiences

**Primary: Latin American MMO Players (18–35)**
Latin America has one of the most passionate and established MMO communities in the world. Titles like Argentum Online, Tibia, MU Online, and Ragnarok Online have maintained active player bases for over two decades — these aren't nostalgia players, they're active daily users. This audience values community, social interaction, PvP, and accessible gameplay over high-end graphics. They reject pay-to-win aggressively. The founder's Argentine background, native Spanish fluency, and track record shipping Argentum Online on Steam provide a direct, zero-cost acquisition channel to this market.

Existing community reach (Argentum Online):
- 80,000+ accounts created (direct email targeting potential)
- Steam: ~200 concurrent players, 821 reviews (Mostly Positive), Free to Play
- Discord: 5,800 members
- Twitch: 4,800 followers
- Instagram: 1,600 followers
- MarketAO: 976 completed transactions, US$90,332 distributed to the community
- Press coverage: Pagina 12, La Nacion, El Dia (major Argentine newspapers)
- Patreon: 1,214 active members (470 paid), growing steadily since 2021

<table>
<tr>
<td width="100%"><img src="../images/patreon.png" width="100%"/></td>
</tr>
<tr>
<td><em>Patreon community growth — Active members over time</em></td>
</tr>
</table>

These are players who already play the exact genre Project Akaroa is building in — reachable immediately without paid acquisition.

**Secondary: Global Mid-core MMO Players (25–40)**
Players with deep MMO experience (World of Warcraft, Guild Wars 2, RuneScape, Albion Online) who are fatigued by monetisation-heavy games. They want a persistent world where progression is earned, not purchased. The "no pay-to-win, player-driven economy" positioning resonates strongly — it's the number one complaint in every MMO community. These players will find Project Akaroa through Steam discovery, content creators, and word-of-mouth.

**Tertiary: Mobile and Multiplatform Players**
The isometric MMORPG format translates naturally to mobile and tablet. Games like Albion Online and Old School RuneScape have proven that this audience exists and is willing to play the same persistent world across devices. Project Akaroa's Godot 4 engine supports multiplatform deployment natively, and the game's control scheme (tap-to-move, hotkey abilities) maps directly to touch input. This opens the massive mobile gaming markets in Southeast Asia, Brazil, and the broader international audience who consume MMOs primarily on mobile.

**Quaternary: Collectors and Traders**
Players who gravitate toward games with real economies — RuneScape's Grand Exchange, CS2's skin market, Diablo's trading. They enjoy finding rare items, flipping markets, and building wealth. Project Akaroa's P2P marketplace (MAO — Mercado Argentum Online) for both items and characters creates a trading ecosystem that gives every gameplay session tangible economic value. This audience is highly engaged, highly retentive, and drives organic word-of-mouth.

---

## 2. Gameplay

### Heritage: Argentum Online as the Foundation

Project Akaroa is not being designed in a vacuum. Its gameplay systems are direct evolutions of Argentum Online (AO), a classic Argentine top-down isometric MMORPG originally released on December 30, 1999, that has maintained active servers and a dedicated community for over two decades across Latin America. The founder has operated AO since 2017 and released it on Steam, accumulating deep knowledge of what works in this genre through live player data and community feedback.

Every system described below has been validated in production with real players. The KickStart prototype will take these proven systems and implement them in Godot 4 with modern technology, original assets, and a new world setting.

**Reference:** [Argentum Online Wiki](https://www.argentumonline.com.ar/wiki)

<table>
<tr>
<td width="50%"><img src="../images/image.png" width="100%"/></td>
<td width="50%"><img src="../images/1image.png" width="100%"/></td>
</tr>
<tr>
<td><em>Town NPCs and shops — Isometric gameplay view</em></td>
<td><em>Carpentry workshop — Crafting NPC interaction</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/2image.png" width="100%"/></td>
<td width="50%"><img src="../images/4image.png" width="100%"/></td>
</tr>
<tr>
<td><em>Temple and priestess — Healing and resurrection</em></td>
<td><em>Magic shop — Spell vendor NPC</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/5image.png" width="100%"/></td>
<td width="50%"><img src="../images/11image.png" width="100%"/></td>
</tr>
<tr>
<td><em>Blacksmith NPC — Equipment trading dialogue</em></td>
<td><em>Island world — Minimap navigation</em></td>
</tr>
</table>

### Core Gameplay Loop

```
Explore → Combat → Loot → Trade → Progress → Explore
```

1. **Explore** — Players traverse an open world with distinct biomes. Exploration reveals resources, enemies, quest NPCs, and hidden areas.
2. **Combat** — Real-time top-down combat with keyboard-driven movement, hotkey abilities, and positioning. Supports melee, ranged, and magic archetypes.
3. **Loot** — Enemies and world interactions drop items, gold, and rare equipment. Rarity drives the economy.
4. **Trade** — Players trade directly with each other through the P2P marketplace. No auction house controlled by the game — all commerce is between players.
5. **Progress** — Character advancement through experience, skill development, faction rank, and gear acquisition. Both vertical (power) and horizontal (breadth of capability) progression.

### Races and Classes

Inherited from AO's proven system, Project Akaroa features multiple playable races (Humans, Elves, Dark Elves, Dwarves, Gnomes) each with distinct attribute bonuses and playstyle tendencies. Classes determine combat role: Warriors, Mages, Assassins, Paladins, Druids, Bards, Clerics, and Hunters — each with unique skill progressions and equipment requirements.

Skills are classified into four families: magical, combat, professions, and social. The higher the skill level, the more effective the player becomes, creating a rewarding long-term progression curve that has kept AO players engaged for years.

### Faction Warfare System

The world is divided by a core factional conflict that drives PvP gameplay and community organisation:

- **Armada Real (Royal Army):** The forces of order. Players must prove themselves by eliminating criminals (50 kills minimum) and reaching Level 25 to enlist. Members progress through ranks — Apprentice, Knight, Guardian, Champion of Light — each requiring increasing kills, gold, and level thresholds. The faction enforces strict codes of conduct: members must defend citizens, cannot ally with criminals, and face expulsion for violations.

- **Legión Oscura (Dark Legion):** The forces of chaos. Players who embrace the criminal path can join by killing 50 citizens and reaching Level 25. Ranks progress from Minion through Dark Knight, Condemned Protector, Soul Devourer, to Chaos Bearer. The Legion has its own exclusive city, equipment requirements per class and level, and internal hierarchy with councils.

- **Neutral / Independent:** Players who choose neither faction, operating as citizens or criminals outside the formal faction structure.

**Above factions sit player-created Guilds** — alliances formed between users that add another layer of social organisation, territory control, and group identity. Guilds operate across faction lines and create emergent political dynamics.

This system has been running live in AO for years. It creates organic, player-driven conflict and community structure that no scripted content can replicate. Project Akaroa will implement this same factional framework with the new world's lore.

<table>
<tr>
<td width="50%"><img src="../images/3321image.png" width="100%"/></td>
<td width="50%"><img src="../images/opimage.png" width="100%"/></td>
</tr>
<tr>
<td><em>Dark Legion throne room — Faction headquarters</em></td>
<td><em>Player tests — community playtesting session</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/Tancredo.png" width="100%"/></td>
</tr>
<tr>
<td><em>Tancredo (Royal King) — full 3D render</em></td>
</tr>
</table>

### P2P Marketplace (MarketAO Model)

One of Project Akaroa's strongest differentiators is its peer-to-peer marketplace for both items and characters. Based on the MarketAO system running in Argentum Online:

- **Item Trading:** Players list items for sale at their own prices. Buyers browse and purchase directly from other players. No game-controlled auction house — the economy is entirely player-driven, creating real supply/demand dynamics.
- **Character Trading:** Players can list entire characters for sale or trade. This creates a secondary market where time investment has tangible value, and players can enter the game at different progression points.
- **No Pay-to-Win:** Nothing in the marketplace is generated by the game or sold by the developer. Every item and character was earned by a player through gameplay. The marketplace simply facilitates player-to-player commerce.

This model has been validated live with the AO community. It drives long-term engagement because players know their time investment has real value within the game's economy.

**Reference:** [MarketAO](https://www.argentumonline.com.ar/mercadoao)

<table>
<tr>
<td width="50%"><img src="../images/0image.png" width="100%"/></td>
<td width="50%"><img src="../images/12555image.png" width="100%"/></td>
</tr>
<tr>
<td><em>Merchant trading UI — Player-driven commerce</em></td>
<td><em>Bank storage system — Item management</em></td>
</tr>
</table>

### Unique Selling Points

- A persistent MMO world with a fully player-driven P2P economy — no pay-to-win, no cash shop.
- Faction warfare system validated over years of live operation with real players.
- Character and item trading marketplace creating tangible value for player time investment.
- Nine years of live data and community feedback informing every design decision.
- Multiplatform target (PC, mobile, console) using modern engine technology.

---

## 3. Art and Animation

### Art Pipeline: 3D to 2D Sprite Migration

Project Akaroa's art pipeline is built on an innovative workflow developed during Argentum Online's ongoing development:

1. **3D Modelling** — All characters, NPCs, items, and environmental objects are built as full 3D models.
2. **Sprite Rendering** — The 3D models are rendered down to 2D sprite sheets for use in the isometric game view. This gives pixel-perfect control over the final look while maintaining the flexibility of 3D source assets.
3. **Dual-Use for Project Akaroa** — Because the source assets are already in 3D, Project Akaroa can use them directly as full 3D graphics in its 2.5D environment. The existing art library built for AO becomes immediately usable at higher fidelity.

This pipeline means the team already has a substantial library of 3D assets (characters, NPCs, items, equipment) that can be deployed in Project Akaroa's 2.5D world without starting from scratch. New assets follow the same pipeline, ensuring visual consistency.

**3D model → 2D sprite pipeline demonstration:**

<table>
<tr>
<td width="50%"><img src="../images/aimage.png" width="100%"/></td>
<td width="50%"><img src="../images/vimage.png" width="100%"/></td>
</tr>
<tr>
<td><em>3D troll alongside its rendered 2D sprite in-game</em></td>
<td><em>Full 3D troll model — source asset</em></td>
</tr>
</table>

**Before and after — 3D models replacing legacy sprites:**

<table>
<tr>
<td width="50%"><img src="../images/pirate%20old.png" width="100%"/></td>
<td width="50%"><img src="../images/pirate%20new.png" width="100%"/></td>
</tr>
<tr>
<td><em>Pirate NPC — old 2D sprite</em></td>
<td><em>Pirate NPC — new 3D model</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/chaos%20king%20old.png" width="100%"/></td>
<td width="50%"><img src="../images/chaos%20king.png" width="100%"/></td>
</tr>
<tr>
<td><em>Chaos King — old 2D sprite</em></td>
<td><em>Chaos King — new 3D model</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/tancredo%20old.jpeg" width="100%"/></td>
<td width="50%"><img src="../images/tancredo%20new.png" width="100%"/></td>
</tr>
<tr>
<td><em>Tancredo (Royal King) — old 2D sprite</em></td>
<td><em>Tancredo (Royal King) — new 3D model</em></td>
</tr>
</table>

**3D character models ready for Project Akaroa:**

<table>
<tr>
<td width="50%"><img src="../images/12image.png" width="100%"/></td>
<td width="50%"><img src="../images/132image.png" width="100%"/></td>
</tr>
<tr>
<td><em>Skeleton King — 3D boss character</em></td>
<td><em>Dark Elf warrior — 3D character</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/155image.png" width="100%"/></td>
<td width="50%"><img src="../images/123image.png" width="100%"/></td>
</tr>
<tr>
<td><em>Dark Elf rogue — 3D character</em></td>
<td><em>Dragon creature — 3D enemy model</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/53image.png" width="100%"/></td>
<td width="50%"><img src="../images/32image.png" width="100%"/></td>
</tr>
<tr>
<td><em>Prisoner NPC — 3D model</em></td>
<td><em>Steampunk golem — 3D model rotations</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/765Anubis.png" width="100%"/></td>
<td width="50%"><img src="../images/66GoblinFondo.png" width="100%"/></td>
</tr>
<tr>
<td><em>Anubis — 3D boss model</em></td>
<td><em>Goblin — 3D enemy model</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/11Montura.png" width="100%"/></td>
<td width="50%"><img src="../images/1123image.png" width="100%"/></td>
</tr>
<tr>
<td><em>Mount — 3D rideable creature</em></td>
<td><em>Orc warrior — 3D model with rigging</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/Elfo_Mago.png" width="100%"/></td>
<td width="50%"><img src="../images/Mago_del_Caos.png" width="100%"/></td>
</tr>
<tr>
<td><em>Elf Mage — 3D character</em></td>
<td><em>Chaos Mage — 3D character</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/Mago_Imperial.png" width="100%"/></td>
<td width="50%"><img src="../images/Guardia_Enano.png" width="100%"/></td>
</tr>
<tr>
<td><em>Imperial Mage — 3D character</em></td>
<td><em>Dwarf Guard — 3D character</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/Guardia_Elfo.png" width="100%"/></td>
<td width="50%"><img src="../images/Rey_Elfo.png" width="100%"/></td>
</tr>
<tr>
<td><em>Elf Guard — 3D character</em></td>
<td><em>Elf King — 3D character</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/Rey_Enano.png" width="100%"/></td>
<td width="50%"><img src="../images/Elfo_Rey_Trono.png" width="100%"/></td>
</tr>
<tr>
<td><em>Dwarf King — 3D character</em></td>
<td><em>Elf King on Throne — 3D scene</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/Enano_Rey_Trono.png" width="100%"/></td>
<td width="50%"><img src="../images/Enano_Ballestero.png" width="100%"/></td>
</tr>
<tr>
<td><em>Dwarf King on Throne — 3D scene</em></td>
<td><em>Dwarf Crossbowman — 3D character</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/ingame12image.png" width="100%"/></td>
</tr>
<tr>
<td><em>In-game graveyard — characters in a dark environment</em></td>
</tr>
</table>

**Mount system — 3D armored horse variants:**

<table>
<tr>
<td width="50%"><img src="../images/improve%201.png" width="100%"/></td>
<td width="50%"><img src="../images/improve%202.png" width="100%"/></td>
</tr>
<tr>
<td><em>Knight war horse — armored mount with barding</em></td>
<td><em>Cavalry horse — leather and plate armor variant</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/improve%203.png" width="100%"/></td>
<td width="50%"><img src="../images/improve%205.png" width="100%"/></td>
</tr>
<tr>
<td><em>Dark Legion war horse — evil faction mount</em></td>
<td><em>Elven horse — ornate turquoise-accented mount</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/improve%206.png" width="100%"/></td>
<td width="50%"><img src="../images/improve%207.png" width="100%"/></td>
</tr>
<tr>
<td><em>Undead horse and beast mount — skeletal variants</em></td>
<td><em>Mule and riding pony — utility mounts</em></td>
</tr>
</table>

**3D modelling workflow in Blender:**

<table>
<tr>
<td width="50%"><img src="../images/montu.png" width="100%"/></td>
<td width="50%"><img src="../images/captura8.png" width="100%"/></td>
</tr>
<tr>
<td><em>Mount model — rendered sprite from 3D source</em></td>
<td><em>Horse model in Blender viewport — texture painting stage</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/captura6.png" width="100%"/></td>
<td width="50%"><img src="../images/captura5.png" width="100%"/></td>
</tr>
<tr>
<td><em>Griffin head sculpt — high-poly detail work</em></td>
<td><em>Griffin wing feathers — particle/geometry system in Blender</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/captura%203.png" width="100%"/></td>
<td width="50%"><img src="../images/Captura_de_pantalla_2025-05-07_a_las_11.44.32_a._m..png" width="100%"/></td>
</tr>
<tr>
<td><em>Griffin full body — sculpted creature model</em></td>
<td><em>Griffin top view — wings spread in flight pose</em></td>
</tr>
<tr>
<td width="100%"><img src="../images/Captura_de_pantalla_2025-05-07_a_las_11.44.45_a._m..png" width="100%"/></td>
</tr>
<tr>
<td><em>Griffin rigged skeleton — bone structure for animation</em></td>
</tr>
</table>

**2D sprite sheets rendered from 3D models:**

<table>
<tr>
<td width="50%"><img src="../images/4104.png" width="100%"/></td>
<td width="50%"><img src="../images/4106.png" width="100%"/></td>
</tr>
<tr>
<td><em>NPC sprite sheets — merchants, vendors, boats</em></td>
<td><em>Character sprite sheets — blacksmiths, warriors</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/15image.png" width="100%"/></td>
</tr>
<tr>
<td><em>Armored character — rendered sprite</em></td>
</tr>
</table>

### Art Style

- 2.5D isometric perspective with full 3D character models and layered environments.
- Clean visual hierarchy ensuring gameplay readability at MMO scale.

<table>
<tr>
<td width="50%"><img src="../images/88image.png" width="100%"/></td>
<td width="50%"><img src="../images/55image.png" width="100%"/></td>
</tr>
<tr>
<td><em>Giant turtle dungeon entrance — Environment art</em></td>
<td><em>World map — Full continent overview</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/980image.png" width="100%"/></td>
<td width="50%"><img src="../images/77image.png" width="100%"/></td>
</tr>
<tr>
<td><em>Library interior — Detailed environment</em></td>
<td><em>Catacumba dungeon — Level design</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/Sin_titulo-3.png" width="100%"/></td>
<td width="50%"><img src="../images/177image.png" width="100%"/></td>
</tr>
<tr>
<td><em>NPC portrait — Character art style</em></td>
<td><em>Dwarf scholar — Concept art</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/craiyon_094057_image.png" width="100%"/></td>
<td width="50%"><img src="../images/craiyon_143728_image.png" width="100%"/></td>
</tr>
<tr>
<td><em>Orc blacksmith — NPC concept</em></td>
<td><em>Orc merchant — NPC concept</em></td>
</tr>
</table>

### Influences

- **Argentum Online** — Classic top-down isometric MMO aesthetic, proven community appeal.
- **Albion Online** — Clean isometric art balancing visual clarity with world detail.
- **RuneScape** — Longevity through deep crafting, questing, and player-driven economy in an isometric format.

---

## 4. Sound Design

### Original Soundtrack

The team has original musical compositions already produced and ready to be remastered for Project Akaroa. This is not speculative — the music exists and has been composed specifically for this universe.

The team has proven experience producing and releasing original game soundtracks commercially:

**Reference:** [Argentum 20 Original Soundtrack on Steam](https://store.steampowered.com/app/2137450/Argentum_20_Original_Soundtrack/)

The OST for Project Akaroa will:
- Feature orchestral and ambient compositions that shift dynamically based on location, time of day, and combat state.
- Draw on a wide range of genres — progressive, classical, rock, ambient, natural soundscapes — with the style shifting depending on the area and biome the player is in.
- Include calm atmospheric tracks for exploration, percussive compositions for combat, and warm communal tones for settlement hubs.

### Sound Effects

- Environmental audio priority: native birdsong, wind, volcanic rumbling, ocean surf.
- Impactful combat SFX with clear audio feedback for hits, blocks, dodges, and skill activations.
- Satisfying tactile sound design for crafting and gathering.

---

## 5. Localization

Project Akaroa is designed from day one as a multilingual title targeting global audiences:

| Language | Rationale |
|---|---|
| **English** | Primary market language, NZ base |
| **Spanish** | Core audience — Latin American MMO community, founder's native language |
| **Portuguese** | Brazilian gaming market, massive MMO audience |
| **Te Reo Māori** | Cultural commitment to Aotearoa, unique differentiator |
| **French** | European market expansion |
| **Italian** | European market expansion |
| **Chinese (Simplified)** | Largest gaming market globally |

The game's text system is being built with localization as a core architecture decision, not a retrofit. All strings are externalized from code, UI layouts accommodate variable text lengths, and the team has native fluency in English and Spanish with professional translation planned for other languages.

Te Reo Māori localization will be developed in consultation with appropriate cultural advisors to ensure accuracy and respect.

---

## 6. Production

### What the Grant Enables

The $60,000 CODE KickStart grant will fund the development of Project Akaroa's prototype from its current early state to a functioning vertical slice that demonstrates the core gameplay loop and is ready to attract Start Up funding, publisher investment, or platform deals.

The prototype already exists in basic form (Godot 4, tile-based movement, combat system, NPC interactions, chunk-streamed world). The grant enables dedicated full-time development to bring it to a "found the fun" state with:

- Core combat and progression systems fully playable.
- P2P trading prototype functional.
- Faction system implemented.
- One complete playable zone with final art direction.
- Networking foundation for multiplayer testing.
- Original soundtrack integrated.
- Steam page live and wishlist building underway.

### Technology Migration Context

The path to Project Akaroa's current technology stack was not arbitrary — it was the result of years of experimentation:

| Period | Experiment | Outcome |
|---|---|---|
| 2017–2019 | Argentum Online operations, VB6/legacy codebase | Deep understanding of MMO systems, community, economy |
| 2020–2021 | Unity client + C++ server experiments | Validated real-time combat feel, identified Unity licensing concerns |
| 2021–2022 | Rust server-side experiments | Validated performance for MMO-scale concurrent connections |
| 2023–present | Godot 4 client + Rust/C++ server | Current stack — open source, performant, multiplatform |

Every experiment informed the final architecture. The team is not learning how to build an MMO — the team has been building and operating one for nine years and is now migrating proven systems to modern technology.

<table>
<tr>
<td width="50%"><img src="../images/22.png" width="100%"/></td>
<td width="50%"><img src="../images/22image.png" width="100%"/></td>
</tr>
<tr>
<td><em>Map editor — Collision and tile system</em></td>
<td><em>Zone information panel — Game tools</em></td>
</tr>
<tr>
<td width="50%"><img src="../images/44image.png" width="100%"/></td>
<td width="50%"><img src="../images/777image.png" width="100%"/></td>
</tr>
<tr>
<td><em>World editor — Town building tools</em></td>
<td><em>Building asset — 3D to tile rendering</em></td>
</tr>
</table>

### High-Level Production Schedule

| Phase | Duration | Key Milestones |
|---|---|---|
| **Phase 1: Core Loop** | Weeks 1–16 | Combat system complete, character progression, basic networking, art pipeline producing final assets |
| **Phase 2: Systems** | Weeks 17–32 | P2P marketplace prototype, faction system, crafting, one complete zone, multiplayer testing |
| **Phase 3: Polish & Validation** | Weeks 33–48 | Sound integration, UI polish, community playtesting via Battle Server model, Steam page live |
| **Phase 4: Vertical Slice** | Weeks 49–52 | Final vertical slice build, documentation for Start Up / publisher pitch, wishlist campaign active |

### Validation Methodology

All features are validated before reaching the public through a proven two-stage process developed during AO operations:

1. **Battle Server** — A secondary server under Steam Betas where all new features are tested with a dedicated community of testers before going live. This model will be replicated for Project Akaroa.
2. **Live Analytics** — Real-time player data tracking (reference: [AO Production Statistics](https://estadisticas.ao20.com.ar/produccion/)) informing design decisions with actual player behaviour data, not assumptions.

This is not theoretical — this validation infrastructure exists and is actively used today.

### Risk Management

| Risk | Likelihood | Mitigation |
|---|---|---|
| Scope creep | High | KickStart scope is deliberately limited to core loop + one zone. Vertical slice only. |
| Technical complexity | Low | All systems have been built before in AO. This is a migration, not invention. |
| Art production bottleneck | Medium | Existing 3D asset library from AO accelerates production. Pipeline proven. |
| Team availability | Low | Core work done by founder full-time. Contractors on fixed deliverables. |

### Beyond the Grant Period

The KickStart prototype positions Project Akaroa to pursue:

- **CODE Start Up Grant** ($60K–$250K) for full production.
- **Publisher partnerships** with a playable vertical slice as the pitch asset.
- **Platform deals** (Xbox ID@Xbox, PlayStation Indies, Nintendo) with multiplatform Godot build.
- **Steam Early Access revenue** once the game reaches sufficient content depth.

---

## 7. Finances

### Current Investment

Conreco Limited has invested approximately $15,000 NZD in Project Akaroa to date, covering prototype development, market research, and business planning.

Additionally, Lucas Recoaro has contributed nine years of consistent development time (since 2017) — weekends and weekday evenings — valued at approximately $900,000 NZD in-kind (based on a conservative $100,000 NZD per annum for a senior developer). This covers MMO architecture, netcode, server management, community systems, player economy design, technology migration experiments (Unity/C++, Rust, Godot), and live operations knowledge that directly informs Project Akaroa's design, with focused Project Akaroa rework since 2020.

### Funding Plan

| Source | Amount | Status |
|---|---|---|
| CODE KickStart Grant | $60,000 | Applied |
| Personal cash investment | $5,000 | Confirmed |
| **Total prototype budget** | **$65,000** | |

### Post-Prototype Funding Strategy

| Source | Amount | Timeline |
|---|---|---|
| CODE Start Up Grant | $60K–$250K | Apply after KickStart completion |
| Publisher advance | $100K–$300K | Pursue with vertical slice |
| Steam Early Access revenue | $50K–$150K | Post-production launch |

At KickStart level, definitive answers on post-prototype funding are not expected, but the strategy is clear: use the vertical slice to demonstrate the product and attract production-level investment.

### Budget Breakdown

| Category | CODE Funded (NZ) | CODE Funded (Overseas) | Self Funded | Total |
|---|---|---|---|---|
| Team Costs | $45,001 | $11,999 | $0 | $57,000 |
| Additional Service Costs | $2,000 | $0 | $0 | $2,000 |
| Assets and Licenses | $1,000 | $0 | $0 | $1,000 |
| Other Costs (Prohibited) | $0 | $0 | $5,000 | $5,000 |
| **Totals** | **$48,001** | **$11,999** | **$5,000** | **$65,000** |

**Allowable expenditure (CODE funded):** $60,000
**Overseas spend as % of CODE funding:** 19.99% (under 20% threshold)

---

## 8. Go-to-Market

### Marketing Strategy: Argentum Online as Launchpad

The single greatest marketing advantage Project Akaroa has is an existing, active community of MMO players who already play the game's spiritual predecessor. The marketing strategy leverages this directly:

**Phase 1 — Wishlist Building (During KickStart)**
- Steam page live with trailer and screenshots from the vertical slice.
- Cross-promotion through Argentum Online's existing Steam presence and community channels.
- Devlog series showing the technology migration journey — "from AO to Akaroa."
- Discord community seeded from AO player base.
- Target: 2,000+ wishlists by end of KickStart period.

**Phase 2 — Content Creator Strategy (Post-KickStart)**
- Outreach to MMO and indie game YouTubers/streamers with playable build.
- Focus on Latin American content creators who cover the isometric MMO genre.
- Behind-the-scenes content showing the 3D-to-2D art pipeline and AO heritage.

**Phase 3 — Traditional Media & PR (Production Phase)**
- NZ gaming media coverage (NZ-made MMO angle).
- Latin American gaming press (AO successor angle).
- International indie game press (unique P2P economy angle).

**Pre-Release Strategy:**
- Build hype through wishlist accumulation and community engagement.
- Validate with community through Battle Server beta access.
- Release when wishlist numbers and community feedback indicate readiness.

### Audience Analysis

**Primary: Latin American MMO Players**
The largest and most directly reachable audience. Argentum Online has maintained active servers for 20+ years in this region. These players already understand and love the genre, the systems, and the gameplay loop. The founder's Argentine background and direct community access make this audience immediately reachable without paid acquisition.

**Secondary: Global Mid-core MMO Players**
Players seeking a persistent world with genuine player-driven economy. The "no pay-to-win" positioning resonates strongly with this audience who are fatigued by monetisation-heavy MMOs.

**Tertiary: NZ/Pacific Gaming Community**
A smaller but strategically important audience for CODE's mission. The NZ setting and Te Reo localization create a unique cultural identity that differentiates Project Akaroa globally.

### Genre and Competitive Positioning

| Title | Similarity | Project Akaroa's Differentiation |
|---|---|---|
| Argentum Online | Direct predecessor | Modern engine, 2.5D graphics, multiplatform, new world setting |
| Albion Online | Player economy, isometric | PvE-focused, faction system, character trading |
| RuneScape | Isometric MMO, crafting | Real-time combat, modern engine, no pay-to-win |
| Path of Exile | NZ-made, online RPG | Open-world MMO, not ARPG, persistent world |

### Market Validation

**Already achieved:**
- Nine years operating a live MMO with active player base (AO since 2017).
- Steam release and storefront presence for Argentum Online.
- Real-time analytics dashboard tracking player behaviour ([estadisticas.ao20.com.ar/produccion](https://estadisticas.ao20.com.ar/produccion/)).
- Active community providing continuous feedback on systems and features.
- Battle Server validation model proving feature viability before public release.

**Planned during KickStart:**
- Steam page live for Project Akaroa (wishlist tracking begins).
- Discord community established with cross-promotion from AO.
- First playtest events with AO community members.
- Social media presence (Twitter/X, TikTok) with devlog content.

### Marketing Mentorship

The team would welcome CODE's marketing mentorship support in:
- Optimising Steam page conversion and wishlist strategy for a new IP built on an existing community.
- Identifying the right content creators for the isometric MMO niche across multiple regions.
- Refining the "AO heritage" messaging to appeal to both existing fans and new players.
- Planning the transition from KickStart prototype marketing to production-scale campaigns.

---

## 9. Team

### Core Team

**Lucas Recoaro — Founder, Engineer, Project Director**
Senior Software Engineer and Solutions Architect with 14+ years of experience across cloud engineering, full-stack development, and system architecture. Has operated Argentum Online since 2017, released it on Steam, and has been working on the technology migration and rework since 2020. Previously worked at Noland Studios integrating game engines with cloud backends. Deep experience with .NET, C++, Rust, GDScript, Node.js, and cloud infrastructure (AWS, Azure, GCP). Conreco Limited has delivered solutions for clients including BurgerFuel, IAG, and TVNZ.

*Full CV included as supplementary material.*

### Expanded Team (Contractors)

| Role | Status | Location | Funded By |
|---|---|---|---|
| Environment Artist (2D/2.5D) | Identified, to be contracted | Argentina | CODE grant |
| Character Artist / Animator | Identified, to be contracted | Argentina | CODE grant |
| Lead Developer | To be recruited | NZ | CODE grant |
| Trainee / Junior Developer | To be recruited | NZ | CODE grant |

### Studio Goals

Conreco Limited is an established New Zealand software consultancy expanding into original game development. The long-term vision is to grow from a solo founder with contractors into a sustainable game studio of 5–8 people, funded by game revenue. Project Akaroa is the flagship title, built on nine years of MMO operations experience and a proven community.

---

## 10. Build

A playable prototype of Project Akaroa is included with this application. The prototype demonstrates:

- Core movement and camera controls (top-down isometric).
- Real-time combat system (melee, ranged, spells) against AI enemies.
- Spell casting with mana management and cooldowns.
- NPC interactions and dialogue.
- Chunk-streamed world with tile-based movement.
- HUD with inventory, quest log, and hotkey bar.
- Basic networking stub (multiplayer foundation).

**Platform:** Windows (PC)
**Engine:** Godot 4.6 (open source)
**Install instructions:** Included in the build package.

The prototype uses placeholder art in many areas. The purpose is to demonstrate the feel of isometric movement, combat systems, and the technical foundation — not final visual quality. Final art direction is demonstrated through the existing 3D asset pipeline used in Argentum Online production.

---

## 11. Supplementary Material

The following documents are included with this application:

- Lucas Recoaro CV (1 page)
- Production Spreadsheet (CODE template)
- Prototype build (Windows PC)
- Argentum Online Steam page reference
- Original Soundtrack Steam page reference
- AO Production Statistics dashboard reference
