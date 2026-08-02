# Geo Master v1.3

تطبيق مساحي احترافي لـ Android و iOS

## المميزات الكاملة

- نقاط / خطوط / مساحات + Stakeout
- طبقات + تعديل وحذف
- GNSS Bluetooth + NMEA + NTRIP
- Base + Rover (فرق نسبي)
- أنظمة إحداثيات: WGS84 / UTM / Local Grid
- مزامنة سحابية (Firebase Auth + Firestore)
- تصدير CSV / KML / GPX / DXF
- تقارير + حساب أحجام
- عربي + إنجليزي

## التشغيل
```bash
flutter create .
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

أضف:
- Google Maps API Key
- Firebase (google-services.json / GoogleService-Info.plist)
- صلاحيات Bluetooth والموقع

## ملاحظة
أعلى دقة (سنتيمتر) = جهاز GNSS خارجي + NTRIP.
وضع Base/Rover بالموبايل يحسن الدقة النسبية لكنه لا يصل لدقة المساحة الاحترافية.
