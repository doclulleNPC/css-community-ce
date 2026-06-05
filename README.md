## Counter Strike Source: Community Edition

**Counter Strike Source: Community Edition** is open source port of the leaked 2007 Source engine leak of the award winner Counter Strike Source. 

This mod is orient to Community so everyone can grow the mod whit his Contributions.
Currently this mod is in a pre-alpha state so don’t expected any class of bugs.

### Goals

- [x] Finish the port of the game to Source 2013
- [ ] Make fully functional the cut VIP mode so everyone can play it without server plugins
- [ ] Make fully functional the cut Prison Scape so everyone can play it without server plugins
- [ ] Implement a DM mode like CSPromod
- [ ] Redo the Bots and hostage’s AI using the [(Nextbot System)](https://developer.valvesoftware.com/wiki/NextBot)
- [ ] Implement the Vote System so everyone can vote without using plugins
- [ ] Implement Class Based Hands Like CSGO
- [ ] Implement CSPromod's Shadows RTT
- [ ] Bring back to life the shield.

### Warning

Although this mod is based on SourcePlusPlus's CSS Port, some things will not work has expected.

### Bug status (code-audited 2026-06-05)

The original bug list was audited against the actual source. Most of the
historically-reported bugs **could not be reproduced in the code** — several were
already fixed or were mis-diagnosed. Verdicts and evidence below. (A "verdict"
here reflects static code review only; intermittent runtime bugs can still exist
where the code path looks correct.)

#### Fixed since the audit

- **Ragdoll bullet-impact crash — FIXED** (working tree). Tracing a bullet against
  a ragdoll whose bones weren't set up dereferenced an unset bone-to-world matrix.
  Guarded in `bone_setup.cpp` (`SweepBoxToStudio`/`TraceToStudio` now skip hitboxes
  with a null `hitboxbones[pbox->bone]`) with defense-in-depth in
  `game/client/fx_impact.cpp` (skip unloaded studio models, force `SetupBones`
  before the engine traces).
- **Bot use-after-free crash — FIXED** (`c5c7d63`). `m_attacker` raw pointer →
  `CHandle`. (Supersedes the "Bots may crash — INCONCLUSIVE" item below.)
- **Round-timer spawn crash — FIXED** (`cdfced7`). `swprintf` round-timer crash on
  spawn fixed; GameUI2 now yields input in-game.
- **Friendly target-ID showed literal `%s` — FIXED** (`7115f70`). Now displays the
  teammate's health.

- **Prop physics — janky collision** (*not audited*). "Sometimes you pass through
  a prop, other times it pushes the player." Not yet reviewed against the code.

- **Round doesn't end at 0:00 — REFUTED.** The round *is* ended:
  `CCSGameRules::BombRoundEndCheck()`
  (`game/shared/cstrike/cs_gamerules.cpp:1728`) calls `TerminateRound( Target_Bombed )`
  / `Bomb_Defused` when the bomb explodes or is defused, and
  `CheckRoundTimeExpired()` (`:2725`) handles the timer for bomb/hostage/escape/VIP
  maps. A planted bomb *intentionally* keeps the round running past 0:00 (see the
  comment at `:2737`) until it resolves. **Latent edge case:** the porters' "New
  code to get rid of round draws" (`:2733`) removed the draw fallback, so a map
  with *no* objective type (no bomb target, rescue/escape/VIP zone) has no timer
  resolution. Standard CS maps are unaffected.

- **Flashbang doesn't disappear — REFUTED (in render code).**
  `CCSViewRender::PerformFlashbangEffect()` (`game/client/cstrike/cs_view_scene.cpp:168`)
  returns once `m_flFlashBangTime < curtime` (`:175`) and fades alpha as
  `maxAlpha * (flashBangTime - curtime) / flashDuration` (`:226`) — the standard
  CSS effect. No stuck-forever path in the renderer. If observed, look at how
  `m_flFlashBangTime`/`m_flFlashDuration` are networked, not the render code.

- **Animation stuck on first frame — REFUTED / already done.** The project uses the
  genuine CS:S animation system, not HL2MP's. `CCSPlayerAnimState`
  (`game/shared/cstrike/cs_playeranimstate.cpp:57`, subclass of `CBasePlayerAnimState`)
  is created with `LEGANIM_9WAY` on **both** sides
  (`cs_player.cpp:346`, `c_cs_player.cpp:717`) and updated with eye angles, so
  remote players animate correctly. (`CBasePlayerAnimState` is just the shared base
  class — it is *not* the broken HL2MP animstate.)

- **Classmenu model lighting "estranged colors" — UNCONFIRMED.** Candidate:
  `game/client/game_controls/basemodelpanel.cpp:601` declares a `white[6]` ambient
  array set to `Vector(0.4,0.4,0.4)` (dim gray, misnamed), with
  `SetAmbientLight(0.4,0.4,0.4)` at `:599`. This is the *generic* model panel and
  produces dim, not wrong-hued, lighting — so it doesn't clearly match "estranged
  colors." Treat as a candidate, not a confirmed cause.

- **Dynamic crosshair cvars don't work — REFUTED.** All six cvars
  (`cl_dynamiccrosshair`, `cl_crosshaircolor`, `cl_scalecrosshair`,
  `cl_crosshairscale`, `cl_crosshairalpha`, `cl_crosshairusealpha`) are declared
  and used in `CWeaponCSBase::DrawCrosshair()` (`game/shared/cstrike/weapon_csbase.cpp`).
  Minor smell: `m_flCrosshairDistance` / `m_iAmmoLastCheck` are not initialized in
  the constructor.

- **Bots may crash — ONE CAUSE FIXED, otherwise INCONCLUSIVE.** A concrete bot
  use-after-free (`m_attacker` raw pointer) was found and fixed in `c5c7d63`
  (raw pointer → `CHandle`). Beyond that, no further crash is provable by static
  review: bot init/spawn (`game/server/cstrike/bot/`) has nav-mesh guards and
  null-checks the bot profile; the only remaining smell is an unsafe
  `strcpy( m_name, GetPlayerName() )` (`cs_bot_init.cpp:355`). Any other crash
  needs a repro + debugger to diagnose.

### Credits

|           **Valve**            |           Source Engine and Counter Strike Source            |
| :----------------------------: | :----------------------------------------------------------: |
| **Joshua Ashton And SCell555** |            **Original creator of SourcePlusPlus**            |
|         **PeterScout**         | **Modified SourcePlusPlus's CSS (witch is based this port)** |
|         **NicolasDe**          |                 **For his amazing GameUI2**                  |
|        **TotallyMehis**        | **Creator of Zombie Master: Reborn and some code that is used here** |
|         **Spirrwell**          |                   **FMOD Implementation**                    |
