import re
import time
from datetime import datetime, timedelta

def read_progress():
    try:
        with open('assets/translation_progress.txt', 'r', encoding='utf-8') as f:
            content = f.read()
        
        progress_match = re.search(r'Progress: (\d+)/(\d+)', content)
        start_match = re.search(r'Started: (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})', content)
        
        if progress_match and start_match:
            completed = int(progress_match.group(1))
            total = int(progress_match.group(2))
            start_time = datetime.strptime(start_match.group(1), '%Y-%m-%d %H:%M:%S')
            return completed, total, start_time
    except:
        pass
    return None, None, None

# 첫 번째 측정
completed1, total, start_time = read_progress()
if completed1 is None:
    print("진행 파일을 읽을 수 없습니다.")
    exit(1)

print(f"\n=== 속도 측정 중 ===")
print(f"현재 완료: {completed1:,} / {total:,}")
print(f"진행률: {(completed1/total*100):.1f}%")
print(f"\n10초 대기 중...")

# 10초 대기
time.sleep(10)

# 두 번째 측정
completed2, _, _ = read_progress()
if completed2 is None:
    print("진행 파일을 읽을 수 없습니다.")
    exit(1)

diff = completed2 - completed1
speed_per_second = diff / 10
remaining = total - completed2

if speed_per_second > 0:
    estimated_seconds = remaining / speed_per_second
    estimated_time = timedelta(seconds=int(estimated_seconds))
    now = datetime.now()
    estimated_completion = now + estimated_time
    
    print(f"\n=== 속도 측정 결과 ===")
    print(f"10초 후 완료: {completed2:,} / {total:,}")
    print(f"진행률: {(completed2/total*100):.1f}%")
    print(f"\n10초 동안 완료된 작업: {diff:,} 개")
    print(f"초당 처리 속도: {speed_per_second:.2f} 개/초")
    print(f"분당 처리 속도: {speed_per_second * 60:.1f} 개/분")
    print(f"\n남은 작업: {remaining:,} 개")
    print(f"예상 남은 시간: 약 {str(estimated_time).split('.')[0]}")
    print(f"예상 완료 시간: {estimated_completion.strftime('%Y-%m-%d %H:%M:%S')}")
    
    # 이전 속도와 비교
    if start_time:
        elapsed = datetime.now() - start_time
        if elapsed.total_seconds() > 0 and completed2 > 0:
            overall_speed = completed2 / elapsed.total_seconds()
            print(f"\n전체 평균 속도: {overall_speed:.2f} 개/초")
            print(f"시작 후 경과 시간: {str(elapsed).split('.')[0]}")
else:
    print(f"\n진행이 없거나 매우 느립니다. 잠시 후 다시 확인해주세요.")

