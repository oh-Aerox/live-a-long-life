# pdfbox-android：JPEG2000 解码器是可选依赖，没打进来。
-dontwarn com.gemalto.jp2.**
# pdfbox 按类名反射加载字体与编码表，混淆后 PDF 文字层抽取会静默失败。
-keep class com.tom_roush.pdfbox.** { *; }
-keep class com.tom_roush.fontbox.** { *; }
