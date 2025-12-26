import json
import os

# GPT-4o mini 가격 (2024년 기준)
# Input: $0.15 per 1M tokens
# Output: $0.60 per 1M tokens

INPUT_PRICE_PER_MILLION = 0.15
OUTPUT_PRICE_PER_MILLION = 0.60

# 명언 데이터 로드
with open('assets/quotes.json', 'r', encoding='utf-8') as f:
    quotes = json.load(f)

# 각 명언의 평균 길이 계산
total_input_chars = 0
total_output_chars = 0

for quote in quotes:
    # 입력: 영어 명언 + 프롬프트 (약 100자 추가)
    quote_text = quote.get('quote', '')
    author = quote.get('author', '')
    input_text = f"Translate the following quote to {{language}}: '{quote_text}' by {author}"
    total_input_chars += len(input_text)
    
    # 출력: 번역된 명언 (원본과 비슷한 길이로 가정)
    total_output_chars += len(quote_text) + len(author)

# 문자를 토큰으로 변환 (영어: 1 토큰 ≈ 4자, 한국어/중국어/일본어: 1 토큰 ≈ 2자)
# 평균적으로 1자 ≈ 0.3 토큰으로 계산
avg_chars_per_quote = total_input_chars / len(quotes)
avg_output_chars_per_quote = total_output_chars / len(quotes)

# 총 번역 작업 수
num_quotes = len(quotes)
num_languages = 6  # Korean, Japanese, Chinese, Spanish, French, Portuguese
total_translations = num_quotes * num_languages

# 각 번역당 토큰 수 추정
# 입력: 프롬프트 + 명언 (약 150 토큰)
# 출력: 번역된 명언 (약 50 토큰)
tokens_per_input = 150
tokens_per_output = 50

total_input_tokens = total_translations * tokens_per_input
total_output_tokens = total_translations * tokens_per_output

# 비용 계산
input_cost = (total_input_tokens / 1_000_000) * INPUT_PRICE_PER_MILLION
output_cost = (total_output_tokens / 1_000_000) * OUTPUT_PRICE_PER_MILLION
total_cost = input_cost + output_cost

print("\n=== GPT-4o mini API 비용 계산 ===")
print(f"\n작업량:")
print(f"  - 총 명언 수: {num_quotes:,}개")
print(f"  - 번역 언어: {num_languages}개")
print(f"  - 총 번역 작업: {total_translations:,}개")
print(f"\n토큰 사용량:")
print(f"  - 입력 토큰: {total_input_tokens:,} 토큰 ({total_input_tokens/1_000_000:.2f}M)")
print(f"  - 출력 토큰: {total_output_tokens:,} 토큰 ({total_output_tokens/1_000_000:.2f}M)")
print(f"  - 총 토큰: {total_input_tokens + total_output_tokens:,} 토큰 ({(total_input_tokens + total_output_tokens)/1_000_000:.2f}M)")
print(f"\n비용 (GPT-4o mini 가격 기준):")
print(f"  - 입력 비용: ${input_cost:.4f}")
print(f"  - 출력 비용: ${output_cost:.4f}")
print(f"  - 총 비용: ${total_cost:.4f} (약 ${total_cost:.2f} 달러)")
print(f"\n한국 원화 환산 (1 USD = 1,300원 기준):")
print(f"  - 총 비용: 약 {int(total_cost * 1300):,}원")
print(f"\n참고:")
print(f"  - GPT-4o mini는 가장 저렴한 모델입니다")
print(f"  - 실제 비용은 명언 길이에 따라 달라질 수 있습니다")
print(f"  - 현재 진행률 21.5% 기준 이미 사용된 비용: 약 ${total_cost * 0.215:.4f}")

