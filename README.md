# Lab 06 สร้างตัวละคร 3D

โปรเจกต์ Godot นี้คัดลอกจากต้นฉบับ Lab05 **Potato Islands** แล้วเปลี่ยนเฉพาะ Player visual, skeleton, animation และขนาดแคปซูลให้เหมาะกับ Somchai เกมยังมีสองด่าน เก็บเหรียญด่านละ 5 เหรียญ กระโดดข้ามเกาะ ไปถึงธง และ Restart ตามเดิม

## เปิดและเล่น

1. เปิด `project.godot` ด้วย **Godot 4.7** และรอ import GLB ให้เสร็จ
2. กด **F5** เพื่อเริ่มจาก Level 1
3. ใช้ **W A S D** วิ่ง, กด **Ctrl ค้างพร้อม W A S D** เพื่อเดินช้า, **Space** กระโดด, **Mouse** หมุนกล้อง, **Esc** ปล่อยเมาส์
4. เก็บเหรียญให้ครบ **5/5** ก่อนเข้าธงแต่ละด่าน เมื่อชนะกด **Restart**

ความเร็ววิ่งเดิม 6 และแรงกระโดดใน Scene เดิม 6 ยังคงอยู่; Ctrl เพิ่มความเร็วเดิน 3.6 เพื่อแสดง Walk animation โดยไม่เปลี่ยนเส้นทางเล่นหลัก

## ตัวละครและแอนิเมชัน

- `assets/characters/somchai/model/Somchai_rigged.blend` คือไฟล์ Blender สำหรับแก้ไข Somchai; `Somchai_rigged.glb` คือโมเดลที่ Godot ใช้จริง พร้อม mesh, UV, materials, skin และ armature 32 bones
- `assets/characters/somchai/SomchaiBoneMap.tres` แมปกระดูก 32 จุดกับ Godot `SkeletonProfileHumanoid`: Root/Hips/Spine/Chest/Neck/Head, แขน, มือ, นิ้วหลัก, ขา, เท้า และปลายเท้า กระดูกเสริมที่โมเดลไม่มีปล่อยว่าง
- GLB มี AnimationLibrary ภายในของตัวละครเอง: **Idle, Walk, Run, Jump, Fall, Flip**; ไม่มี T-pose ระหว่างเล่น Idle เริ่มใน `_ready()` และ Walk/Run loop
- Lab05 ไม่มี Skeleton, AnimationTree, Mixamo BoneMap หรือ `MeleeLib.res` / `ShooterLib.res` ต้นฉบับ จึงใช้คลิปที่สร้างให้ Somchai ใน Blender โดยตรง ไม่ได้อ้างว่า retarget คลิป Mixamo หรือ library ภายนอกที่ไม่มีในโปรเจกต์
- BoneMap เตรียมไว้สำหรับทดสอบ retarget คลิปภายนอกในภายหลัง แต่คลิปจาก skeleton อื่นอาจต้องปรับ rest pose ก่อนใช้จริง

Player root ยังคงเป็น `CharacterBody3D` พร้อม controller, กล้อง, เสียงเดิน และ particle เดิม โดย `scenes/player.tscn` วาง Somchai ไว้ใต้ `Visual/Juice/Motion/Alignment` แทน Potato; การชนใช้ `CollisionShape3D` แบบ Capsule สูง 1.78 เมตร รัศมี 0.39 เมตร ไม่ใช้ mesh ตัวละครเป็น collider

## ไฟล์สำคัญ

- `scenes/levels/level_1.tscn` — Main Scene
- `scenes/levels/level_2.tscn` — ด่านสอง
- `scenes/player.tscn` — Player และ Somchai visual
- `Scripts/player.gd` — controller เดิมกับทางเชื่อมแอนิเมชันและ Ctrl walk
- `Scripts/gameplay/level.gd` — เปลี่ยนด่าน/หน้าชนะ
- `tools/test_lab06.gd` — ตรวจ character, animation, movement, jump, camera, capsule
- `tools/playthrough.gd` — เล่นทดสอบทั้งสองด่านด้วย Input จริง

`README_GAME.md` และ assets ของ Lab05 ยังอยู่เป็นเอกสาร/ต้นฉบับอ้างอิง รวมถึงเครดิตและเงื่อนไขการใช้งานเดิมใน `LICENSE.md` ไม่มีการนำ library แอนิเมชันภายนอกเข้ามาเพิ่ม

## ผลทดสอบและ Web

ทดสอบด้วย Godot **4.7 stable**: เปิด/import โปรเจกต์ได้, Somchai แสดงในเกมโดยไม่เป็น T-pose, Idle/Walk/Run/Jump/Fall เล่นได้, เดินและกระโดดเก็บเหรียญครบทั้งสองด่าน, กล้อง/การชน/Goal/Win/Restart ผ่าน โปรเจกต์ใช้ Compatibility renderer และ preset `Web` ใน `export_presets.cfg`; คำสั่ง export-release Web สร้าง `index.html`, `.pck`, `.wasm` สำเร็จ และเปิดเล่นผ่าน local HTTP server ในเบราว์เซอร์ได้

หน้าแสดงผลงานคือ `docs/index.html` โดยมีปุ่ม **เล่น Lab 06 สร้างตัวละคร 3D** ไปที่ `docs/Lab06/index.html`; Web export ทั้งชุดอยู่ใน `docs/Lab06/` การเปิดไฟล์ HTML โดยตรงแบบ `file://` ไม่เหมาะกับ Godot Web ให้ใช้เว็บเซิร์ฟเวอร์หรือ GitHub Pages

ภาพตัวอย่างที่ทดสอบสร้างด้วย `tools/capture_lab06.gd` ส่วน source ของ Lab05 จากงานครั้งก่อนบันทึกไว้ใน `README_GAME.md` และ `PROGRESS.md`
