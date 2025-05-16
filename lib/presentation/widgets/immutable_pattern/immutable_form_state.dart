import 'package:flutter/material.dart';

/// 불변성 패턴을 적용한 폼 상태 클래스
///
/// 불변성 패턴을 따르는 상태 관리 예시를 제공합니다.
/// 상태 변경 시 항상 새 객체를 생성하여 불변성을 유지합니다.
class ImmutableFormState {
  final String name;
  final String email;
  final String password;
  final bool isNameValid;
  final bool isEmailValid;
  final bool isPasswordValid;
  final bool isSubmitting;
  final bool isSubmitted;
  final String? errorMessage;

  /// 생성자
  const ImmutableFormState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.isNameValid = false,
    this.isEmailValid = false,
    this.isPasswordValid = false,
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.errorMessage,
  });

  /// 초기 상태
  factory ImmutableFormState.initial() {
    return const ImmutableFormState();
  }

  /// 불변성 패턴을 위한 복사 생성 메서드
  ImmutableFormState copyWith({
    String? name,
    String? email,
    String? password,
    bool? isNameValid,
    bool? isEmailValid,
    bool? isPasswordValid,
    bool? isSubmitting,
    bool? isSubmitted,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ImmutableFormState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      isNameValid: isNameValid ?? this.isNameValid,
      isEmailValid: isEmailValid ?? this.isEmailValid,
      isPasswordValid: isPasswordValid ?? this.isPasswordValid,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// 모든 필드가 유효한지 검사
  bool get isValid => isNameValid && isEmailValid && isPasswordValid;

  /// 폼 제출 가능 상태인지 검사
  bool get isSubmittable => isValid && !isSubmitting && !isSubmitted;

  /// 이름 유효성 검사 결과를 적용한 새 상태 반환
  ImmutableFormState validateName() {
    final isValid = name.isNotEmpty && name.length >= 2;
    return copyWith(isNameValid: isValid, clearError: true);
  }

  /// 이메일 유효성 검사 결과를 적용한 새 상태 반환
  ImmutableFormState validateEmail() {
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    final isValid = emailRegex.hasMatch(email);
    return copyWith(isEmailValid: isValid, clearError: true);
  }

  /// 비밀번호 유효성 검사 결과를 적용한 새 상태 반환
  ImmutableFormState validatePassword() {
    final isValid = password.isNotEmpty && password.length >= 6;
    return copyWith(isPasswordValid: isValid, clearError: true);
  }

  /// 모든 필드 유효성 검사 결과를 적용한 새 상태 반환
  ImmutableFormState validateAll() {
    return this
        .validateName()
        .validateEmail()
        .validatePassword();
  }

  /// 제출 중 상태로 변경한 새 상태 반환
  ImmutableFormState submitting() {
    return copyWith(isSubmitting: true, clearError: true);
  }

  /// 제출 완료 상태로 변경한 새 상태 반환
  ImmutableFormState submitted() {
    return copyWith(isSubmitting: false, isSubmitted: true, clearError: true);
  }

  /// 에러 상태로 변경한 새 상태 반환
  ImmutableFormState withError(String message) {
    return copyWith(isSubmitting: false, errorMessage: message);
  }

  /// 상태 초기화
  ImmutableFormState reset() {
    return ImmutableFormState.initial();
  }
}