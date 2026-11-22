import 'package:flutter/material.dart';

// 로고 기반 메인 초록색 계열
const PRIMARY_COLOR = Color(0xFF009E49);       // 메인 에메랄드 그린 (버튼, 활성 탭, OTP 코드)
const DARK_GREEN_COLOR = Color(0xFF005C2B);    // 딥그린 (자물쇠 아이콘, 포인트 강조)
const LIGHT_GREEN_COLOR = Color(0xFF33EB85);   // 밝은 민트 (보조 강조용)

// 무채색 계열 (Colors.grey[숫자]는 런타임에 값을 꺼내오므로 final 사용)
final LIGHT_GREY_COLOR = Colors.grey[200]!;    // 연한 회색 (프로그레스 바 배경, 구분선 등)
final DARK_GREY_COLOR = Colors.grey[600]!;     // 진한 회색 (비활성 탭, 수정 아이콘, 서브 텍스트)

// 상태 알림 색상
const ERROR_COLOR = Colors.red;                // 잠금, 삭제, 비밀번호 오류
const WARNING_COLOR = Colors.orange;           // PIN 설정 경고 스낵바