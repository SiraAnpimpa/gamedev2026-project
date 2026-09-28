# Lab06 — Somchai Islands progress

Updated 2026-09-28. Lab05 source was copied into this project; its original progress is retained below.

## Lab06 objective and structure
- Replace the Lab05 Potato visual with Somchai while preserving `CharacterBody3D`, movement, camera, collision behavior, two levels, coins, goals and UI.
- `scenes/player.tscn` is the Player scene; `Scripts/player.gd` is the controller. The visual branch now instances Somchai GLB under `Visual/Juice/Motion/Alignment`, separate from the capsule and camera.
- `Somchai_rigged.glb` has one skinned mesh, one armature with 32 humanoid bones, and Idle/Walk/Run/Jump/Fall/Flip clips. `SomchaiBoneMap.tres` maps all 32 available bones to Godot's humanoid profile; unused optional profile bones remain blank.

## Lab06 completed and verified
- Preserved Blender source, UV/materials and exported rigged GLB. Adjusted capsule to height 1.78, radius 0.39, with feet near ground.
- Connected Idle at startup, Walk via Ctrl + movement, Run at the original speed, and Jump/Fall/Flip from the existing controller. Updated the win-screen animation path.
- Godot 4.7 stable imported the project and all six clips. `tools/test_lab06.gd` passed 30 character/controller checks, including the physical Ctrl binding and all 32 BoneMap entries. Rendered Idle/Walk/Run screenshots showed a natural relaxed stance and no T-pose.
- Rendered `tools/playthrough.gd` passed the full two-level route, five coins per level, gaps, camera, win panel and Restart with zero failures.
- Web export-release produced HTML/PCK/WASM successfully. The exported game launched in a local HTTP browser preview and visibly displayed Somchai in Level 1. Unused legacy demo meshes produced old surface-format warnings during export.
- Lab05 did not contain Mixamo BoneMap, MeleeLib or ShooterLib. This project uses the model's own imported AnimationLibrary. External library retargeting remains untested and may need rest-pose adjustment.

## Lab06 delivery
- Copied the verified source into `gamedev2026-project`, preserving `docs/Lab05` and its published Lab05 web export.
- Fresh Godot import and `tools/test_lab06.gd` passed in the target Git folder. Git changes remain uncommitted and unpushed for review.
- Added a Lab 06 card to `docs/index.html` and a Web build in `docs/Lab06`, with the exact title "Lab 06 สร้างตัวละคร 3D". Local HTTP browser preview loaded the game.
- Remaining optional work: retarget any separately supplied Mixamo animation library after checking its license and rest pose.

---

# Potato Islands — Lab05 progress

Updated 2026-09-14. Original project was edited in place; do not restart it.

## Completed
- Inspected the starter controller, player scene, gimbal camera, coin scripts, score autoload, audio and dead zone.
- Backed up edited original files under the Codex task's `work/original_backup`.
- Normalized `Assets` to `assets` and `Scenes` to `scenes`, updating resource paths for portability.
- Extracted both supplied ZIPs and copied the supplied Potato GLB into the project. No assets downloaded.
- Retained the original CharacterBody3D, capsule, gimbal/camera, movement script and actual scene jump force of 6.0 (the script default is 5.0), speed 6.0, gravity 19.6 and double jump.
- Replaced the visual with Potato and simple Idle / Run / Jump / Fall / Flip animations. Stretch affects visuals only. Moved the same controller loop to physics ticks; fixed delayed double-jump consumption.
- Built editable Grass Islands and Stone Islands levels, five coins each, mesh-matched static collision, bridge, decorations, goal lock, transition, win UI and Restart.
- Input-driven traversal completed both levels and clicked Restart successfully. Fall recovery and locked-goal checks passed.
- Fixed a scene-serialization issue that created duplicate cameras. New validation checks the active camera and follow distance.

## Current work
- Implementation complete. Final rendered playthrough passes all 35 checks, including camera follow, both goals, fall recovery and actual Restart click.
- Fresh project import without .godot cache succeeds; main scene starts successfully.
- Resource audit: no missing files, case mismatches, or external GLB images.
- All requested gameplay work is complete. README_GAME.md contains usage, file locations, changes and tested limitations. Deliverables are stored in the Codex task outputs folder.

## Scenes
- `res://scenes/player.tscn`
- `res://scenes/levels/level_1.tscn` (main scene)
- `res://scenes/levels/level_2.tscn`
- `res://scenes/gameplay/coin.tscn`

## Scripts
Modified: `Scripts/player.gd`, `CameraMovement.gd`, `Coin.gd`, `GameManager.gd`, `GameUI.gd`, `DeadZone.gd`.
New: `Scripts/gameplay/level.gd`, `Scripts/gameplay/goal.gd`.
Development tools: `tools/build_levels.gd`, `tools/preview.gd`, `tools/playthrough.gd`.

## Assets
`assets/player/potato.glb`; Small Platformer Kit under `assets/small_platformer`; Ultimate Platformer Pack under `assets/ultimate_platformer`.
Platforms and coins use Small. Ultimate adds bridge, clouds, signs, fences, plants, crates, bricks, rocks, tower, chest, final flag. No enemy/combat/trap features.

## Runtime and verification
Installed engine: `C:/Users/ADMIN/Desktop/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe` reports 4.7 stable, not 4.7.2.
Task workspace: `C:/Users/ADMIN/Documents/Codex/2026-09-14/files-mentioned-by-the-user-3d`.
Logs under `work`, screenshots and `test_results.json` under `outputs` in that workspace.
Set `APPDATA` to task `work/runtime` for sandboxed engine runs; set `POTATO_CAPTURE_DIR` to task `outputs` for test capture.
Playthrough: Godot `--path <project> --script res://tools/playthrough.gd --resolution 1280x720`.
Headless import: Godot `--headless --path <project> --editor --import`.

## Known diagnostics
- Host emits Failed to read the root certificate store in the restricted runtime; offline game does not use networking.
- Fixed old cloud mesh format, OGG metadata, legacy texture references, stale audio UIDs and paused walking-audio teardown.
- No remaining gameplay parse, missing-resource, scene-transition, collision, or camera errors in tested flow.
- Tested engine is 4.7 stable; 4.7.2 was not installed. No executable export requested or produced.


