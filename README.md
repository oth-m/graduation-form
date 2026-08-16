# استمارة حجز زي التخرج — دليل الملفات والإعداد

## الملفات
- **index.html** — الموقع كامل (استمارة الطلاب + لوحة إدارة القائد/القادة المساعدين). ملف واحد يحوي كل شي (HTML + CSS + JS)، ومربوط حالياً بمشروع Supabase الخاص بك.
- **supabase_schema.sql** — سكربت إنشاء الجداول وقواعد الحماية (RLS) في Supabase. شغّله مرة وحدة بس عند إعداد مشروع جديد.

## ربط الموقع بقاعدة بياناتك
داخل `index.html`، دوّر عن هذا السطرين قرب بداية كود الجافاسكربت:

```js
const SUPABASE_URL = 'https://ccywrqmlgzhiotfrulkg.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_uh7HWDqd5u324Nyz78etkA_3KxI00yD';
```

إذا سويت مشروع Supabase جديد بأي وقت، بدّل هالقيمتين بس (من Project Settings → API)، وباقي الكود ما يحتاج أي تعديل.

## خطوات الإعداد من الصفر (لو احتجتها مرة ثانية)
1. سوّي مشروع جديد على supabase.com (مجاني).
2. **SQL Editor → New Query** → الصق محتوى `supabase_schema.sql` كامل → **Run**.
3. **Authentication → Users → Add user**: بريد + كلمة مرور، وفعّل **Auto Confirm User**.
4. انسخ **User UID** لهذا المستخدم.
5. **Table Editor → profiles** → أضف صف: `auth_user_id` = الـ UID، `full_name` = عثمان جليل الصالح، `role` = leader.
6. **Project Settings → API** → انسخ **Project URL** و **anon public key** وحطهم بمكان السطرين أعلاه بـ `index.html`.

## نشر الموقع للطلاب
- افتح `index.html` كـ Claude Artifact داخل المحادثة، واضغط **Publish artifact** من قائمة (⋮) لتحصل على رابط عام تشاركه مع الطلاب.
- أو ارفع `index.html` لأي استضافة ملفات ثابتة (Netlify, GitHub Pages, Vercel) — يشتغل فيها كمان بنفس الطريقة لأن كل البيانات محفوظة على Supabase مو على المتصفح.

## تسجيل الدخول
- **الطلاب:** بس الاسم الثلاثي، بدون باسورد.
- **القائد/القادة المساعدون:** من رابط "دخول القائد / القائد المساعد" أسفل الصفحة، بالبريد وكلمة المرور المسجّلة بـ Supabase Authentication.

## تعيين قائد مساعد جديد
من لوحة الإدارة (بعد دخول القائد) → تبويب "القادة المساعدون":
1. سوّي حساب بريد/كلمة مرور له من Supabase Dashboard (Authentication → Users، وفعّل Auto Confirm).
2. انسخ الـ User UID تبعه.
3. الصق اسمه والـ UID داخل الموقع واضغط "تعيين قائد مساعد".

## ملاحظة أمان مهمة
لا تشارك أبداً الـ **Secret key** (يبدأ بـ `sb_secret_...`) لأي جهة أو تلصقه داخل أي كود يشتغل بالمتصفح. المستخدم بهذا الملف هو **anon/publishable key** فقط، وهو آمن للاستخدام بالمتصفح لأنه مقيّد بقواعد الحماية (RLS) المعرّفة بـ `supabase_schema.sql`.
