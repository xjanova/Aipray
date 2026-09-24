import 'package:aipray/models/release_notes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Body of the v1.2.4 GitHub release, the same since v1.2.1. xman4289.com's
/// update check sends it as `changelog` (checked 2026-09-24).
const v124Body = '''
## Aipray v1.2.4 - สวดมนต์อัจฉริยะ

### ดาวน์โหลด APK
- **aipray-universal.apk** — ใช้ได้กับทุกอุปกรณ์ (แนะนำ)
- **aipray-arm64.apk** — สำหรับมือถือรุ่นใหม่ (เล็กกว่า)
- **aipray-arm32.apk** — สำหรับมือถือรุ่นเก่า

### วิธีติดตั้ง
1. ดาวน์โหลดไฟล์ APK ที่ตรงกับอุปกรณ์ (ไม่แน่ใจให้เลือก universal)
2. เปิดไฟล์บนมือถือ Android
3. อนุญาต "ติดตั้งจากแหล่งที่ไม่รู้จัก" ถ้ามี popup
4. กด "ติดตั้ง"

### คุณสมบัติ
- บทสวดมนต์ 20+ บท พร้อมตัวอักษรไทย
- ฟังเสียงสวดจับตำแหน่งอัตโนมัติ (AI)
- นับรอบอัตโนมัติ พร้อมสั่นเตือน
- บันทึกประวัติการสวดมนต์
- อัพเดทอัตโนมัติภายในแอพ
- ใช้งานออฟไลน์ได้
''';

/// The body the release workflow writes with PR #11 (self-update from
/// xman4289.com), as it would read for v1.2.5.
const pr11Body = '''
## Aipray v1.2.5 - สวดมนต์อัจฉริยะ

### วิธีติดตั้ง
1. ดาวน์โหลดไฟล์ APK จาก xman4289.com (ใช้ได้กับมือถือ Android ทุกรุ่น)
2. เปิดไฟล์บนมือถือ Android
3. อนุญาต "ติดตั้งจากแหล่งที่ไม่รู้จัก" ถ้ามี popup
4. กด "ติดตั้ง"

### คุณสมบัติ
- บทสวดมนต์ 20+ บท พร้อมตัวอักษรไทย
- ฟังเสียงสวดจับตำแหน่งอัตโนมัติ (AI)
- นับรอบอัตโนมัติ พร้อมสั่นเตือน
- บันทึกประวัติการสวดมนต์
- อัพเดทอัตโนมัติภายในแอพ
- ใช้งานออฟไลน์ได้
''';

/// The notes as the dialog lays them out: a blank line where it leaves a
/// gap, and `•` or the number in front of list items.
String shown(String markdown) => [
      for (final line in parseReleaseNotes(markdown)) ...[
        if (line.gapBefore) '',
        switch (line.kind) {
          NoteKind.bullet => '• ${line.text}',
          NoteKind.numbered => '${line.number} ${line.text}',
          _ => line.text,
        },
      ],
    ].join('\n');

List<String> headings(String markdown) => [
      for (final line in parseReleaseNotes(markdown))
        if (line.kind == NoteKind.heading) line.text,
    ];

List<String> boldText(String markdown) => [
      for (final line in parseReleaseNotes(markdown))
        for (final span in line.spans)
          if (span.bold) span.text,
    ];

final urlText =
    RegExp(r'://|www\.|github\.|githubusercontent', caseSensitive: false);

void main() {
  group('parseReleaseNotes', () {
    test('turns the v1.2.4 release body into plain lines', () {
      expect(shown(v124Body), '''
Aipray v1.2.4 - สวดมนต์อัจฉริยะ

ดาวน์โหลด APK
• aipray-universal.apk — ใช้ได้กับทุกอุปกรณ์ (แนะนำ)
• aipray-arm64.apk — สำหรับมือถือรุ่นใหม่ (เล็กกว่า)
• aipray-arm32.apk — สำหรับมือถือรุ่นเก่า

วิธีติดตั้ง
1. ดาวน์โหลดไฟล์ APK ที่ตรงกับอุปกรณ์ (ไม่แน่ใจให้เลือก universal)
2. เปิดไฟล์บนมือถือ Android
3. อนุญาต "ติดตั้งจากแหล่งที่ไม่รู้จัก" ถ้ามี popup
4. กด "ติดตั้ง"

คุณสมบัติ
• บทสวดมนต์ 20+ บท พร้อมตัวอักษรไทย
• ฟังเสียงสวดจับตำแหน่งอัตโนมัติ (AI)
• นับรอบอัตโนมัติ พร้อมสั่นเตือน
• บันทึกประวัติการสวดมนต์
• อัพเดทอัตโนมัติภายในแอพ
• ใช้งานออฟไลน์ได้''');
    });

    test('makes the v1.2.4 headings and **file names** bold', () {
      expect(headings(v124Body), [
        'Aipray v1.2.4 - สวดมนต์อัจฉริยะ',
        'ดาวน์โหลด APK',
        'วิธีติดตั้ง',
        'คุณสมบัติ',
      ]);
      expect(boldText(v124Body), [
        'aipray-universal.apk',
        'aipray-arm64.apk',
        'aipray-arm32.apk',
      ]);
    });

    test('turns the PR #11 body into plain lines and keeps xman4289.com', () {
      expect(shown(pr11Body), '''
Aipray v1.2.5 - สวดมนต์อัจฉริยะ

วิธีติดตั้ง
1. ดาวน์โหลดไฟล์ APK จาก xman4289.com (ใช้ได้กับมือถือ Android ทุกรุ่น)
2. เปิดไฟล์บนมือถือ Android
3. อนุญาต "ติดตั้งจากแหล่งที่ไม่รู้จัก" ถ้ามี popup
4. กด "ติดตั้ง"

คุณสมบัติ
• บทสวดมนต์ 20+ บท พร้อมตัวอักษรไทย
• ฟังเสียงสวดจับตำแหน่งอัตโนมัติ (AI)
• นับรอบอัตโนมัติ พร้อมสั่นเตือน
• บันทึกประวัติการสวดมนต์
• อัพเดทอัตโนมัติภายในแอพ
• ใช้งานออฟไลน์ได้''');
    });

    test('reads Windows line endings the same way', () {
      expect(shown(v124Body.replaceAll('\n', '\r\n')), shown(v124Body));
    });

    test('drops links and URLs, so no GitHub link is ever shown', () {
      const markdown = '''
### แก้ไข
- ดู[วิธีใช้](https://github.com/xjanova/Aipray/wiki)ในแอป
- ![ภาพหน้าจอ](https://user-images.githubusercontent.com/1/screen.png)
- แก้เสียงสะดุด (https://github.com/xjanova/Aipray/issues/12)
- แก้ปุ่มดาวน์โหลด <https://github.com/xjanova/Aipray/pull/11>
- <a href="https://github.com/xjanova/Aipray">หน้าโปรเจกต์</a> ปิดแล้ว
- คู่มือใหม่ www.github.com/xjanova/Aipray/wiki
- หน้าดาวน์โหลดเดิม github.com/xjanova/Aipray/releases
- ดาวน์โหลด: https://xman4289.com/apps/aipray/download/1.2.5
- เอกสาร: xjanova.github.io
- ดาวน์โหลดไฟล์ APK จาก xman4289.com

[wiki]: https://github.com/xjanova/Aipray/wiki
''';
      expect(shown(markdown), '''
แก้ไข
• ดูวิธีใช้ในแอป
• แก้เสียงสะดุด
• แก้ปุ่มดาวน์โหลด
• หน้าโปรเจกต์ ปิดแล้ว
• คู่มือใหม่
• หน้าดาวน์โหลดเดิม
• ดาวน์โหลดไฟล์ APK จาก xman4289.com''');
      expect(shown(markdown), isNot(contains(urlText)));
    });

    test('drops the URLs in release notes GitHub generates', () {
      const markdown = '''
<!-- Release notes generated using configuration in .github/release.yml at main -->

## What's Changed
* Self-update from xman4289.com by @xjanova in https://github.com/xjanova/Aipray/pull/11


**Full Changelog**: https://github.com/xjanova/Aipray/compare/v1.2.4...v1.2.5''';
      expect(shown(markdown), '''
What's Changed
• Self-update from xman4289.com by @xjanova in''');
      expect(shown(markdown), isNot(contains(urlText)));
    });

    test('takes out the other Markdown marks', () {
      const markdown = '''
# ใหม่ #
> ข้อความ *สำคัญ* ใช้ `ปุ่มนับรอบ` ได้
* ข้อหนึ่ง
+ [x] ข้อสอง
1) ข้อสาม
---
__หนา__ และ **หนา**
''';
      expect(shown(markdown), '''
ใหม่
ข้อความ สำคัญ ใช้ ปุ่มนับรอบ ได้
• ข้อหนึ่ง
• ข้อสอง
1) ข้อสาม

หนา และ หนา''');
      expect(boldText(markdown), ['หนา', 'หนา']);
    });

    test('leaves nothing when there is nothing to read', () {
      for (final markdown in [
        '',
        '\n\n',
        '---\n***',
        '## ',
        '**',
        'https://github.com/xjanova/Aipray/releases/tag/v1.2.5',
      ]) {
        expect(parseReleaseNotes(markdown), isEmpty, reason: markdown);
      }
    });
  });
}
