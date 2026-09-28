# Potato Islands — Lab05 reference notes

เอกสารนี้บันทึกงาน Lab05 เดิม โปรดอ่าน `README.md` สำหรับ Lab06 และตัวละคร Somchai

เกม 3D Platformer ขนาดเล็ก 2 ด่าน ใช้ 3D Platformer Starter Kit เดิมเป็นฐาน

## วิธีเปิดและเล่น

1. เปิด Godot แล้ว Import ไฟล์ `project.godot` ในโฟลเดอร์นี้
2. รอ Godot Import Asset ให้เสร็จ
3. กด **F6** หากกำลังเปิดด่านที่ต้องการทดสอบ หรือ **F5** เพื่อเริ่มเกมตามปกติจาก Level 1
4. **W A S D** เดิน, **Space** กระโดด, **Mouse** หมุนกล้อง
5. **Esc** ปล่อยเมาส์; คลิกในเกมเพื่อควบคุมกล้องต่อ
6. เก็บเหรียญให้ครบ **5 / 5** แล้วเดินเข้าธง เพื่อไปด่านถัดไป
7. หลังจบ Level 2 จะแสดง **YOU WIN!** กด **Restart** เพื่อกลับ Level 1

ตกเกาะแล้วจะกลับจุดเกิด เหรียญที่เก็บแล้วในด่านนั้นยังอยู่ ระบบกระโดดสองครั้งของ Starter Kit ยังใช้ได้ แต่เส้นทางปกติผ่านได้ด้วยการกระโดดครั้งเดียวทุกช่อง

## Scene สำคัญ

| รายการ | ตำแหน่ง |
|---|---|
| Player | `res://scenes/player.tscn` |
| Level 1 / Main Scene | `res://scenes/levels/level_1.tscn` |
| Level 2 | `res://scenes/levels/level_2.tscn` |
| Coin | `res://scenes/gameplay/coin.tscn` |
| Starter demo เดิม | `res://scenes/demo_scene.tscn` |

## สิ่งที่สร้าง

- Level 1: Grass Islands พร้อมเกาะหญ้า ต้นไม้ สะพาน และเหรียญ 5 เหรียญ
- Level 2: Stone Islands พร้อมพื้นหิน หอคอยใกล้ Goal และเหรียญ 5 เหรียญ
- Coin scene ที่ใช้ `Coin.glb` จาก Small Platformer Kit
- `Scripts/gameplay/level.gd`: เริ่มด่าน เปลี่ยนด่าน และแสดงผลชนะ
- `Scripts/gameplay/goal.gd`: ตรวจจำนวนเหรียญเมื่อผู้เล่นเข้าธง
- Potato visual และ AnimationPlayer สำหรับ Idle, Run, Jump, Fall และการกระโดดครั้งที่สอง
- UI แสดงชื่อด่าน จำนวนเหรียญ ข้อความ Goal และหน้าชนะพร้อม Restart
- เครื่องมือพัฒนาภายใต้ `tools/` และเอกสารนี้

## สิ่งที่แก้

- `project.godot`: ตั้งชื่อ Potato Islands, Main Scene, หน้าต่าง 1280×720 และ Compatibility renderer
- `scenes/player.tscn`: เปลี่ยนเฉพาะส่วนภาพเป็น Potato และปรับมุม/ระยะกล้องเดิม
- `Scripts/player.gd`: เชื่อม Animation ใหม่ ย้ายลูปเดิมไป physics tick ให้การเคลื่อนที่สม่ำเสมอ แก้การใช้สิทธิ์ double jump ที่เคยรอ Animation ให้ squash/stretch กระทบเฉพาะภาพ และหยุดเสียงเดินเมื่อเปลี่ยนฉากหรือปิดเกม
- `Scripts/CameraMovement.gd`: หมุนกล้องเฉพาะเมื่อจับเมาส์อยู่
- `Scripts/Coin.gd`: ใช้การเก็บเหรียญ/คะแนน/เสียงเดิม พร้อมป้องกันการนับซ้ำและหมุนเหรียญตามเวลา
- `Scripts/GameManager.gd`: รีเซ็ตเหรียญต่อด่าน ตรวจเงื่อนไข Goal และ Restart
- `Scripts/GameUI.gd`: แสดง `Coins: 0 / 5`, ข้อความ และหน้าชนะ
- `Scripts/DeadZone.gd`: กลับจุดเกิดและล้างความเร็วขณะตก
- เปลี่ยนตัวพิมพ์โฟลเดอร์ `Assets` → `assets`, `Scenes` → `scenes` และแก้เส้นทางอ้างอิงให้ตรงกัน เพื่อเปิดได้บนระบบที่แยกตัวพิมพ์ใหญ่/เล็ก
- ซ่อม Texture path เก่าของ Gobot และฝัง palette เดิมใน GLB cloud/coin/flag ของ Starter Kit
- บันทึก cloud particle mesh ใหม่ให้เข้ากับ Godot ปัจจุบัน และแก้เฉพาะ metadata comment ของเสียงเดิน โดยไม่แก้ข้อมูลเสียง

ยังใช้ CharacterBody3D, Capsule, Gimbal, Camera3D, Movement Script, เสียง, Gravity และระบบกระโดดจาก Starter Kit ค่าเดินจริง **6.0**, แรงกระโดดจริงจาก Scene **6.0**, Gravity **19.6** และ Capsule สูง **1.37478** ไม่ได้เปลี่ยน

## Asset

- `assets/player/potato.glb`: Potato Character by Polygonal Mind ที่ผู้ใช้ให้มา ไม่มี rig หรือ animation ใหม่
- `assets/small_platformer/`: พื้นและเกาะหลัก เหรียญ ต้นไม้ หิน และธงของด่านแรก
- `assets/ultimate_platformer/`: สะพาน ป้าย เมฆ รั้ว พืช ลัง อิฐ หิน หอคอย หีบ และธงของด่านสอง

ไม่ได้ดาวน์โหลด Asset เพิ่ม ไม่มีศัตรู Combat ระบบเลือด หรือกับดักใหม่ ไฟล์ Asset อื่นใน ZIP ถูกเก็บไว้ แต่ไม่ได้เพิ่มกลไกของมันลงในเกม

## ผลตรวจ

ทดสอบด้วย **Godot 4.7 stable (5b4e0cb0f)** ที่ติดตั้งในเครื่อง ผู้ใช้ระบุ 4.7.2 แต่ไม่มี binary เวอร์ชันนั้นให้ทดสอบ

ผ่านการทดสอบ 35 รายการในเกมที่เรนเดอร์จริงด้วยอินพุตเดินและกระโดดผ่าน Controller ที่ส่งมอบ:

- เริ่ม Level 1 และลงพื้นถูกต้อง
- Goal ปฏิเสธเมื่อเหรียญยังไม่ครบ พร้อมข้อความ
- เก็บเหรียญแล้วตกเกาะ กลับจุดเกิดได้และคะแนนยังอยู่
- เดิน/กระโดดผ่านทุกช่วงของทั้งสองด่าน โดยไม่ teleport ระหว่างการทดสอบเส้นทาง
- เก็บครบ 5 เหรียญในแต่ละด่าน ข้ามสะพานด้วยการเดิน
- กล้องตามผู้เล่นและมี active player camera เพียงตัวเดียว
- Level 1 → Level 2 → YOU WIN → คลิก Restart → Level 1, คะแนน 0 / 5
- ไม่พบ Script Error, Missing Resource, Invalid NodePath หรือ Scene Change Error ในการทดสอบเกมรอบสุดท้าย
- การตรวจ Resource path ไม่พบไฟล์ขาด ตัวพิมพ์ผิด หรือ GLB ที่อ้างอิงภาพภายนอก

ระบบ sandbox ของเครื่องแสดง `Failed to read the root certificate store` ตอนเริ่ม Godot เกมนี้เล่นแบบออฟไลน์และไม่ได้ใช้เครือข่าย จึงไม่กระทบการเล่น ส่วนแคช Editor เก่าอาจแจ้งเตือนชื่อโฟลเดอร์เดิมหรือ mesh ของฉาก Demo ซึ่งไม่ใช่ด่านหลัก

## เครื่องมือพัฒนา

ไม่ต้องรันเครื่องมือเหล่านี้เพื่อเล่นเกม:

- `tools/playthrough.gd`: ทดสอบเส้นทางด้วย Input และการชนจริง ตั้ง environment variable `POTATO_CAPTURE_DIR` เป็นโฟลเดอร์บันทึกผลที่มีอยู่ แล้วรัน Godot ด้วย `--path <โฟลเดอร์โปรเจกต์> --script res://tools/playthrough.gd`
- `tools/preview.gd`: สร้างภาพตัวอย่าง ใช้ `POTATO_CAPTURE_DIR` เช่นเดียวกัน
- `tools/build_levels.gd`: สร้าง Scene ที่จัดวางไว้ใหม่ **จะเขียนทับสองด่านและ Coin Scene** ไม่ต้องใช้เมื่อแก้ด่านด้วย Editor
- `PROGRESS.md`: สถานะงานสำหรับทำต่อ

ข้อจำกัดที่เหลือ: ยังไม่ได้ทดสอบบน binary 4.7.2 หรือ export เป็น EXE; โปรเจกต์พร้อมเปิดเล่นใน Godot และไม่มีงาน Gameplay ที่ค้างอยู่

