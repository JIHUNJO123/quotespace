#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GPT-4o mini를 사용하여 모든 명언을 주요 6개 언어로 미리 번역
"""

import json
import os
import sys
import time
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock

# Windows 콘솔 인코딩 설정
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# OpenAI API 설정
API_KEY = os.environ.get('OPENAI_API_KEY', '')
API_URL = 'https://api.openai.com/v1/chat/completions'

# 번역할 주요 언어 6개
TARGET_LANGUAGES = {
    'ko': 'Korean',
    'ja': 'Japanese',
    'zh': 'Chinese (Simplified)',
    'es': 'Spanish',
    'fr': 'French',
    'pt': 'Portuguese',
}

def translate_quote(quote_text, target_lang_code, target_lang_name, retry_count=3):
    """GPT-4o mini를 사용하여 명언 번역 (재시도 로직 포함)"""
    if not API_KEY:
        print("ERROR: OPENAI_API_KEY environment variable not set")
        return None
    
    for attempt in range(retry_count):
        try:
            response = requests.post(
                API_URL,
                headers={
                    'Content-Type': 'application/json',
                    'Authorization': f'Bearer {API_KEY}',
                },
                json={
                    'model': 'gpt-4o-mini',
                    'messages': [
                        {
                            'role': 'system',
                            'content': f'Translate this English quote to {target_lang_name}. Keep the meaning and style. Return only the translation.',
                        },
                        {
                            'role': 'user',
                            'content': quote_text,
                        },
                    ],
                    'temperature': 0.3,
                    'max_tokens': 500,
                },
                timeout=15
            )
            
            if response.status_code == 200:
                data = response.json()
                translation = data['choices'][0]['message']['content'].strip()
                
                # 에러 체크
                if translation and not any(word in translation.lower() for word in ['error', 'sorry', 'cannot']):
                    return translation
            elif response.status_code == 429:  # Rate limit
                wait_time = 2 ** attempt  # Exponential backoff
                time.sleep(wait_time)
                continue
            else:
                if attempt < retry_count - 1:
                    time.sleep(0.5)
                    continue
                else:
                    print(f"API Error: {response.status_code}")
                    
        except requests.exceptions.Timeout:
            if attempt < retry_count - 1:
                time.sleep(0.5)
                continue
        except Exception as e:
            if attempt < retry_count - 1:
                time.sleep(0.5)
                continue
            else:
                print(f"Translation error: {e}")
    
    return None

def translate_task(quote_id, quote_text, lang_code, lang_name, total, start_time):
    """번역 작업 단위"""
    translation = translate_quote(quote_text, lang_code, lang_name)
    return (quote_id, lang_code, lang_name, translation)

def main():
    if not API_KEY:
        print("ERROR: Please set OPENAI_API_KEY environment variable")
        print("Example: export OPENAI_API_KEY='your-api-key'")
        return
    
    # 명언 데이터 로드
    print("Loading quotes...")
    with open('assets/quotes.json', 'r', encoding='utf-8') as f:
        quotes = json.load(f)
    
    print(f"Total quotes: {len(quotes)}")
    print(f"Target languages: {list(TARGET_LANGUAGES.keys())}")
    
    # 번역 데이터 구조 초기화
    translations = {}
    for quote in quotes:
        translations[quote['id']] = {
            'quote': quote['quote'],
            'translations': {}
        }
    
    # 모든 번역 작업 생성
    tasks = []
    for quote in quotes:
        quote_id = quote['id']
        quote_text = quote['quote']
        for lang_code, lang_name in TARGET_LANGUAGES.items():
            tasks.append((quote_id, quote_text, lang_code, lang_name))
    
    total = len(tasks)
    completed = 0
    progress_file = 'assets/translation_progress.txt'
    start_time = time.strftime('%Y-%m-%d %H:%M:%S')
    lock = Lock()
    
    print(f"\nStarting parallel translation with 20 workers...")
    print(f"Total tasks: {total}")
    print(f"Start time: {start_time}\n")
    
    # 병렬 처리 (20개 동시 요청 - 최대 속도)
    with ThreadPoolExecutor(max_workers=20) as executor:
        # 모든 작업 제출
        future_to_task = {
            executor.submit(translate_task, quote_id, quote_text, lang_code, lang_name, total, start_time): 
            (quote_id, lang_code, lang_name) 
            for quote_id, quote_text, lang_code, lang_name in tasks
        }
        
        # 완료된 작업 처리
        for future in as_completed(future_to_task):
            quote_id, lang_code, lang_name = future_to_task[future]
            
            try:
                result_quote_id, result_lang_code, result_lang_name, translation = future.result()
                
                with lock:
                    completed += 1
                    progress_pct = (completed / total) * 100
                    
                    if translation:
                        translations[result_quote_id]['translations'][result_lang_code] = translation
                        status = "OK"
                    else:
                        status = "FAIL"
                    
                    # 진행 상황 저장
                    with open(progress_file, 'w', encoding='utf-8') as pf:
                        pf.write(f"Progress: {completed}/{total} ({progress_pct:.1f}%)\n")
                        pf.write(f"Current: Quote {result_quote_id} -> {result_lang_name}\n")
                        pf.write(f"Started: {start_time}\n")
                    
                    # 진행 상황 출력 (10개마다 또는 완료 시)
                    if completed % 10 == 0 or completed == total:
                        print(f"[{completed}/{total}] ({progress_pct:.1f}%) Quote {result_quote_id} -> {result_lang_name} [{status}]")
                
            except Exception as e:
                with lock:
                    completed += 1
                    print(f"[ERROR] Quote {quote_id} -> {lang_name}: {e}")
    
    # 번역 데이터 저장
    output_file = 'assets/quotes_translations.json'
    print(f"\nSaving translations to {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(translations, f, ensure_ascii=False, indent=2)
    
    print(f"\n[SUCCESS] Translation complete!")
    print(f"  Total quotes: {len(quotes)}")
    print(f"  Languages: {len(TARGET_LANGUAGES)}")
    print(f"  Output file: {output_file}")

if __name__ == '__main__':
    main()

