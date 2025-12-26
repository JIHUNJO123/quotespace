import re
from datetime import datetime, timedelta

with open('assets/translation_progress.txt', 'r', encoding='utf-8') as f:
    content = f.read()

progress_match = re.search(r'Progress: (\d+)/(\d+)', content)
current_match = re.search(r'Current: (.+)', content)
start_match = re.search(r'Started: (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})', content)

if progress_match:
    completed = int(progress_match.group(1))
    total = int(progress_match.group(2))
    remaining = total - completed
    percent = round((completed / total) * 100, 1)
    
    print("\n=== 번역 진행 상황 ===")
    print(f"완료: {completed:,} / {total:,} ({percent}%)")
    print(f"남은 작업: {remaining:,} 개")
    
    if current_match:
        print(f"현재 작업: {current_match.group(1)}")
    
    if start_match and completed > 0:
        start_time = datetime.strptime(start_match.group(1), '%Y-%m-%d %H:%M:%S')
        now = datetime.now()
        elapsed = now - start_time
        avg_time = elapsed.total_seconds() / completed
        estimated_remaining_seconds = remaining * avg_time
        estimated_remaining = now + timedelta(seconds=estimated_remaining_seconds)
        
        print(f"\n시작 시간: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"경과 시간: {str(elapsed).split('.')[0]}")
        print(f"항목당 평균: {avg_time:.2f}초")
        print(f"예상 남은 시간: 약 {str(timedelta(seconds=int(estimated_remaining_seconds))).split('.')[0]}")
        print(f"예상 완료 시간: {estimated_remaining.strftime('%Y-%m-%d %H:%M:%S')}")

