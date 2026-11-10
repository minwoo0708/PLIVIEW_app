# PLIVIEW 앱 (Flutter)

Spotify 곡·앨범·플레이리스트에 별점(0.5 단위)과 한 줄 평을 남기는 앱.
설명은 한국어로, 쉽게 해 주세요.

## 먼저 읽을 것
- 인수인계서: `C:\Users\USER\Documents\back\docs\FLUTTER_HANDOFF.md` (처음부터 끝까지)
- API 명세(요청·응답 기준): `C:\Users\USER\Documents\back\docs\API.md`
- 서버 폴더 `C:\Users\USER\Documents\back`은 **읽기만**. 수정·커밋·브랜치 전환 금지. 서버를 고쳐야 하면 사용자에게 알리기.

## 결정된 사항 (사용자 확인 완료)
- 플랫폼: **안드로이드 + iOS**. 웹은 디자인이 없어서 **보류**(web 폴더 제거함). Windows PC라 iOS는 빌드 안 함, 확인은 안드로이드 에뮬레이터로.
- 시작하기(01) 초록 "Spotify 계정으로 시작" 버튼 → **"이메일로 시작하기"(회원가입)**, 아래 링크는 "이미 계정이 있나요? 로그인". Spotify 연동은 나중에 설정으로.
- 플리 총점: 세 점수(컨셉·흐름·발견성) 평균을 **0.5 단위로 반올림** `(avg * 2).round() / 2`
- 홈 히어로 "이주의 앨범": `GET /api/feed/popular?type=ALBUM&days=7&limit=1` 첫 항목, 없으면 카드 숨김
- 알림(🔔) 버튼: **숨김**
- Spotify PKCE(재생 기록 탭)는 2단계라 이번 범위 아님. 04 탭은 "Spotify 연동하면 볼 수 있어요" 안내 화면.

## 서버
- IntelliJ에서 실행, 확인 `GET http://localhost:8080/api/hello`
- 에뮬레이터 Base URL `http://10.0.2.2:8080`, iOS 시뮬레이터 `http://localhost:8080`. `--dart-define=API_BASE_URL=...`로 덮어쓸 수 있게.
- 안드로이드 http 허용(`usesCleartextTraffic`), INTERNET 권한, iOS 로컬 네트워크 허용은 이미 설정됨.

## 디자인
- Figma 파일 `lqM2Jzs3WPJbTmEE1xJ9N2`, 페이지 **`PLIVIEW v2` (9:2)만** 사용. 다른 페이지는 옛 버전.
- 화면별 node id는 인수인계서 3.1장. Figma MCP `get_design_context`로 상세를 받고, 에셋은 `assets/images/`에 내려받아 쓰기(Figma 임시 URL을 코드에 넣지 않기).
- 토큰(색·글꼴 Jua / Gothic A1 / Space Grotesk·모서리)은 인수인계서 3.2장.
- `assets/images/`에 받아 둔 SVG(아직 커밋 안 됨): 시작 화면 커버 4개, spotify_logo, deco_ring, hero_ring, icon_back/eye/play/home/search/clock/user. 아이콘은 색이 고정돼 있으니 필요하면 `ColorFilter`로 색을 바꿔 쓰기.

## 진행 상황
- 끝남: 프로젝트·플랫폼 설정, 테마·공통 위젯·API 클라이언트·라우터, 인증(시작·로그인·가입), 탐색, 앨범·곡·플리 상세, 평가하기(작성·수정·삭제), 홈, 프로필, 랭킹, 설정, 재생 기록 안내 화면
- 안드로이드 에뮬레이터에서 회원가입 → 검색 → 앨범 평가(작성·수정) → 플리 평가까지 실제 서버로 확인함
- 남음: 프로필·랭킹·설정 화면 에뮬레이터 확인, iOS는 Mac에서만 빌드 가능, 2단계(Spotify PKCE 재생 기록)
- 서버 제약: Spotify 검색·앨범 목록은 limit 최대 10(11 이상이면 404). 플리 상세 응답에는 수록곡 목록이 없음(수록곡 섹션 없음).
- 에뮬레이터: AVD `Medium_Phone_API_37.0`, 실행 `flutter run -d emulator-5554`
- 완료 기준: 에뮬레이터에서 회원가입·로그인 → 검색 → 앨범·플리 상세 → 리뷰 작성·수정이 실제 서버와 동작. 디자인 토큰 적용.

## git 규칙
- 작성자: `minwoo0708` / `265934678+minwoo0708@users.noreply.github.com` (이 레포 git config에 설정됨)
- 커밋은 **기능 단위로 잘게, 많이**(GitHub 잔디용). 빈 커밋·의미 없는 커밋 금지. 메시지는 한국어 `feat:` / `fix:` / `chore:` / `docs:` 형식.
- 커밋 메시지·PR 본문에 **Claude 흔적 절대 금지**: `Co-Authored-By: Claude`, "Generated with Claude Code" 같은 줄을 넣지 않기.
- 기능마다 `feature/...` 브랜치 → push → PR. **머지는 사용자가** 함.
- GitHub 레포 `minwoo0708/PLIVIEW_app`은 사용자가 직접 만듦. 원격이 연결되기 전엔 레포를 만들지 말 것.
- 비밀값(Spotify Client Secret, 비밀번호 등)은 앱 코드에 넣지 않기.
