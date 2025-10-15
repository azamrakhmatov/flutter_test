#  플러터 실시간 채팅 애플리케이션

이 프로젝트는 **Flutter**와 **Supabase**를 사용하여 만든 실시간 채팅 애플리케이션입니다.  
사용자는 회원가입/로그인을 통해 채팅방에 접속하며, 메시지는 실시간으로 전송 및 수신됩니다.

##  주요 기능

- **사용자 인증 Auth**
  - 이메일 회원가입 및 로그인
  - Supabase 인증 서비스 사용

-  **실시간 채팅**
  - 메시지 실시간 전송/수신
  - Supabase Realtime 기능 사용

-  **환경 변수 (.env) 분리**
  - `SUPABASE_URL`, `ANON_KEY` 등 민감 정보는 `.env` 파일로 관리
  - `flutter_dotenv` 패키지 사용


##  사용된 기술

| 기술 | 설명 |
| Flutter | UI 제작 및 상태 관리 
| Supabase | 백엔드 (Auth & Database & Realtime) 
| PostgreSQL | 메시지 데이터 저장 
| flutter_dotenv | 환경 변수 관리 


## 환경 변수 설정 .env

SUPABASE_URL=https://xxxx.supabase.co..
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1...

## 프로젝트 실행 방법

flutter pub get
flutter run

웹에서 실행: flutter run -d chrome

## 향후 개선 예정

사용자 프로필 이미지 추가
1:1 채팅 또는 그룹 채팅 기능
메시지 읽음 표시 (읽음/안읽음)