from PIL import Image

img = Image.open('assets/icon/app_icon.png')
print(f'Mode: {img.mode}')
print(f'Size: {img.size}')
print(f'Has Alpha: {"A" in img.mode}')

# 알파 채널이 있으면 투명 픽셀 확인
if 'A' in img.mode:
    alpha = img.split()[-1]
    extrema = alpha.getextrema()
    print(f'Alpha range: {extrema}')
    if extrema[0] < 255:
        print('⚠️ 투명 픽셀이 있습니다! 이게 blur 원인입니다.')
        
        # 투명 → 흰색으로 변환
        background = Image.new('RGBA', img.size, (255, 255, 255, 255))
        background.paste(img, mask=img.split()[3])
        rgb = background.convert('RGB')
        rgb.save('assets/icon/app_icon_fixed.png')
        print('✅ app_icon_fixed.png 생성 완료 (투명→흰색)')
