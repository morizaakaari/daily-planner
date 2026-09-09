# VibeFlow Command Center

یک برنامه‌ی Flutter محلی برای مدیریت برنامه‌ی روزانه، اسپرینت‌های X،
فلش‌کارت‌های AI و ابزارهای مبتنی بر Gemini.

## اجرا

پروژه عمداً پوشه‌ی تولیدشده‌ی Android را در مخزن نگه نمی‌دارد. قبل از اولین اجرا:

```bash
flutter create . --platforms=android
flutter pub get
flutter run
```

برای تولید APK می‌توانید workflow با نام **Build Android APK** را از بخش Actions
اجرا کنید. خروجی با نام `app-release` در artifacts همان اجرا قرار می‌گیرد.

## نکات مهم

- کلید Gemini فقط در حافظه‌ی محلی برنامه ذخیره می‌شود.
- برای اعلان دقیق در Android 13 به بعد، دسترسی Notification و Exact Alarm را تأیید کنید.
- اخبار، دوره‌ها و هکاتون‌های تولیدشده توسط مدل ممکن است نیازمند بررسی منبع باشند.
