# kinkin 🍽️

แอพ Flutter ภาษาไทยสำหรับหาร้านอาหารและสุ่มร้านตามฟิลเตอร์

## ฟีเจอร์

- เลือกประเภทอาหารหลายประเภท (เลือกอย่างใดอย่างหนึ่ง): ไทย ญี่ปุ่น เกาหลี จีน อิตาเลียน ซีฟู้ด มังสวิรัติ คาเฟ่
- ระยะทาง 1–10 กม., เปิดอยู่, คะแนน 4.5 ขึ้นไป และค้นชื่อในผลลัพธ์
- เรียงร้านจากใกล้ไปไกล พร้อมระยะทางและสถานะเปิดที่ทราบ
- สุ่มจากผลลัพธ์ชุดเดียวกับหน้าร้าน ไม่สุ่มร้านเดิมติดกันเมื่อมีร้านอื่น
- Google Maps พร้อมหมุดและเส้นทาง; ขอ GPS เมื่อกดปุ่มตำแหน่ง
- Loading, empty, retry และข้อความเมื่อไม่ได้รับสิทธิ์ GPS
- โหมดตัวอย่างไม่ต้องมี API key (ร้านสมมติบริเวณสยาม ไม่ใช่ข้อมูลร้านจริง)

## เริ่มใช้งาน

ต้องมี Flutter stable รุ่นปัจจุบัน, Android Studio/Android SDK สำหรับ Android หรือ macOS + Xcode สำหรับ iOS และ Node.js 22+ สำหรับ API

โฟลเดอร์นี้มี source code; ต้องสร้าง platform runners ด้วย Flutter SDK ก่อน เพราะเครื่องที่สร้างโปรเจกต์ยังไม่มี Flutter SDK

```powershell
cd C:\kinkin
.\tool\bootstrap.ps1
flutter run -d chrome --web-port 3000
```

โหมดเริ่มต้นเป็น demo และยังไม่แสดง Google Maps จึงใช้ตรวจ UI, ฟิลเตอร์และระบบสุ่มได้โดยไม่ใช้บริการ Google
หาก Flutter สร้าง `test/widget_test.dart` ตัวอย่าง counter มา ให้ลบเฉพาะไฟล์ตัวอย่างนั้นก่อนรัน tests (โปรเจกต์นี้ใช้ `test/app_test.dart`)

## เชื่อมข้อมูลจริง

1. สร้าง Google Cloud project และเปิด billing, Places API (New) รวมถึง Maps SDK for Android / Maps SDK for iOS หรือ Maps JavaScript API ตามแพลตฟอร์ม
2. แยก key สำหรับ Places บนเซิร์ฟเวอร์และ Maps บนอุปกรณ์ จำกัด Places key ตาม API และ IP ของเซิร์ฟเวอร์ และจำกัด Maps key ตาม package/SHA-1, bundle ID หรือ HTTP referrer ที่เหมาะสม
3. รัน backend:

```powershell
cd C:\kinkin\server
Copy-Item .env.example .env
# แก้ GOOGLE_PLACES_API_KEY ใน .env (ไฟล์นี้ถูก gitignore)
npm start
```

4. ตั้งค่า Maps และสิทธิ์ตำแหน่งตามแพลตฟอร์มด้านล่าง
5. รันเว็บด้วย:

```powershell
cd C:\kinkin
flutter run -d chrome --web-port 3000 --dart-define=DEMO_MODE=false --dart-define=MAPS_ENABLED=true --dart-define=API_BASE_URL=http://localhost:8080
```

Android emulator ใช้ `http://10.0.2.2:8080` แทน localhost; อุปกรณ์จริงใช้ HTTPS URL ของ backend ที่เข้าถึงได้
การทดสอบ HTTP บน Android ต้องอนุญาต cleartext เฉพาะ debug manifest; release ใช้ HTTPS
backend เริ่มต้น bind ที่ loopback สำหรับ local development; ตั้ง HOST ตาม environment เมื่อ deploy
ก่อนเปิด API สู่สาธารณะต้องมี authentication, rate limit และ quota/budget บน gateway/Google Cloud เนื่องจาก endpoint ตัวอย่างนี้ไม่มีระบบบัญชีผู้ใช้

### Android

ใน `android/app/src/main/AndroidManifest.xml` ใต้ `<manifest>` เพิ่ม:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

ใน `<application>` เพิ่ม:

```xml
<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_RESTRICTED_ANDROID_MAPS_KEY" />
```

ตั้ง minSdk อย่างน้อย 24 ใน `android/app/build.gradle.kts` และใช้ compileSdk ที่ Flutter/plugin กำหนด

### iOS

ตั้ง deployment target อย่างน้อย iOS 15 ตาม plugin ที่ resolve ได้ ใน `ios/Runner/Info.plist` เพิ่ม:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>kinkin ใช้ตำแหน่งเพื่อค้นหาร้านอาหารใกล้คุณเมื่อกดค้นหาตำแหน่ง</string>
```

ใน AppDelegate.swift เพิ่ม `import GoogleMaps` และเรียก `GMSServices.provideAPIKey("YOUR_RESTRICTED_IOS_MAPS_KEY")` ภายใน `didFinishLaunchingWithOptions` ก่อน register plugins
ตั้ง `BYPASS_PERMISSION_LOCATION_ALWAYS=1` สำหรับ geolocator_apple ใน Podfile ตามเอกสาร plugin เพราะแอพขอเฉพาะตำแหน่งขณะใช้งาน

### Web

เพิ่มใน `<head>` ของ `web/index.html` ก่อน Flutter bootstrap:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_RESTRICTED_WEB_MAPS_KEY"></script>
```

GPS บนเว็บต้องใช้ HTTPS หรือ localhost; ALLOWED_ORIGIN บน server ต้องตรง origin เว็บ (ค่าเริ่มต้น http://localhost:3000)
อย่าใส่ Places server key ใน Dart, dart-define หรือ HTML

## ตรวจสอบ

```powershell
flutter analyze
flutter test test/restaurant_test.dart test/app_test.dart
cd server
npm test
```

Tests ครอบคลุมตัวกรองร่วมกัน, ค่า rating/open ที่ไม่มีข้อมูล, ระยะทาง, การสุ่มและกรณีไม่มีร้าน, การตรวจ input ของ API และความผิดพลาดจาก Google
ยังไม่ได้รัน Flutter build/analyze/tests ในเครื่องที่สร้างโค้ด เนื่องจากไม่มี Flutter SDK
ตรวจ logic validation ของ backend ผ่าน JavaScript runtime แล้ว (ประเภทอาหารและ invalid input 4 กรณี) และตรวจ syntax ของ PowerShell bootstrap ผ่านแล้ว ส่วนการทดสอบ HTTP ถูก environment ปฏิเสธการเชื่อมต่อ loopback จึงยังไม่ยืนยัน integration tests

## โครงสร้าง

- `lib/main.dart`: UI, GPS, แผนที่และสุ่ม
- `lib/models.dart`: restaurant model, ตัวกรองและเลือกแบบสุ่ม
- `lib/restaurant_service.dart`: demo fixtures และ client ของ backend
- `server/server.mjs`: Places API proxy แบบไม่ใช้ npm dependencies
- `test/`: Flutter unit/widget tests

Google Nearby Search คืนผลสูงสุด 20 ร้านต่อคำขอ จึงสุ่มเฉพาะร้านในผลลัพธ์ ไม่ใช่ทุกร้านในพื้นที่ ส่วนคะแนนและเวลาเปิดอาจไม่มีข้อมูล; เมื่อเลือกตัวกรองนั้นจะไม่รวมร้านที่ไม่มีข้อมูล
ตำแหน่งเริ่มต้นคือสยาม กดปุ่มตำแหน่งเพื่อเปลี่ยนเป็น GPS; ไม่มีการติดตามเบื้องหลัง

เอกสาร: [Nearby Search](https://developers.google.com/maps/documentation/places/web-service/nearby-search), [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter), [Geolocator](https://pub.dev/packages/geolocator)

## เลือกพื้นที่ค้นหา
กดชื่อพื้นที่บนแถบด้านบนเพื่อเลือก GPS, ค้นหาสถานที่, ปักหมุด หรือมหาวิทยาลัยธุรกิจบัณฑิตย์ ปักหมุดต้องยืนยันก่อนใช้; กดย้อนกลับเพื่อยกเลิก ค้นหาสถานที่ใช้ Places API (New) Text Search ผ่าน /locations และใช้ server key เดิม หลังแก้ backend ต้องรีสตาร์ต server ส่วน demo ค้นหาได้เฉพาะสยามและธุรกิจบัณฑิตย์ ร้านตัวอย่างยังอยู่แถวสยาม จึงไม่มีร้านตัวอย่างรอบมหาวิทยาลัย


## หลัง clone จาก Git
ไฟล์ web/index.html ที่มี API key ถูกเก็บไว้เฉพาะเครื่อง ให้คัดลอก web/index.html.example เป็น web/index.html แล้วแทน YOUR_WEB_MAPS_API_KEY ด้วย key สำหรับเว็บของคุณ ส่วน server/.env ให้คัดลอกจาก server/.env.example และใส่ server key เอง


Repository: https://github.com/yoyoxlr00/kinkin-app
