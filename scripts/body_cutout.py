#!/usr/bin/env python3
"""人体透视图抠图：白底转透明，裁到头顶～大腿根，底边渐隐。

用法（在仓库根目录）：
  python3 scripts/body_cutout.py male
  python3 scripts/body_cutout.py female

原图在 app/assets/body/source/<sex>.png，产物写到 app/assets/body/<sex>.webp。
换了原图后，CROP 与 GAP_SEEDS 要按新图重新确认；裁剪改了的话，
app/lib/ui/body_map_points.dart 里的点位也要重标。
"""
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

# 背景判定：RGB 三个通道都不低于这个值。再低会漏进白衣服。
THRESHOLD = 245
# 保留的纵向范围（原图像素）与底边渐隐高度。
CROP = (40, 1620)
FADE = 160
# 叉腰时手臂与腰之间封闭的背景块，不和图片边缘相连，要单独给种子点。
GAP_SEEDS = {
    'male': [(276, 942), (786, 948)],
    'female': [(216, 954), (744, 972)],
}


def main(sex):
    src = f'app/assets/body/source/{sex}.png'
    out = f'app/assets/body/{sex}.webp'
    im = Image.open(src).convert('RGB')
    w, h = im.size
    r, g, b = im.split()
    darkest = ImageChops.darker(ImageChops.darker(r, g), b)
    mask = darkest.point(lambda v: 255 if v >= THRESHOLD else 0)

    # 从四边连通的"像背景"区域 + 手臂空隙，标成 128。
    for x in range(0, w, 4):
        for y in (0, h - 1):
            if mask.getpixel((x, y)) == 255:
                ImageDraw.floodfill(mask, (x, y), 128)
    for y in range(0, h, 4):
        for x in (0, w - 1):
            if mask.getpixel((x, y)) == 255:
                ImageDraw.floodfill(mask, (x, y), 128)
    for seed in GAP_SEEDS[sex]:
        ImageDraw.floodfill(mask, seed, 128)
    bg = mask.point(lambda v: 255 if v == 128 else 0)

    # 闭运算吃掉背景里的压缩噪点；再收缩一像素、羽化，边缘不留白边。
    bg = bg.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.MinFilter(7))
    bg = bg.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(1.2))
    rgba = im.copy()
    rgba.putalpha(ImageChops.invert(bg))

    top, bottom = CROP
    crop = rgba.crop((0, top, w, bottom))
    ch = bottom - top
    grad = Image.new('L', (w, ch), 255)
    d = ImageDraw.Draw(grad)
    for i in range(FADE):
        d.line([(0, ch - FADE + i), (w, ch - FADE + i)],
               fill=int(255 * (1 - (i + 1) / FADE)))
    crop.putalpha(ImageChops.multiply(crop.getchannel('A'), grad))
    crop.save(out, 'WEBP', quality=90, method=6)
    print(out, crop.size)


if __name__ == '__main__':
    main(sys.argv[1])
