// labeled_border_container.dart
import 'package:flutter/material.dart';

class LabeledBorderContainer extends StatefulWidget {
  final String label;
  final Widget child;
  final bool isRequired;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color labelColor;
  final bool hasValue; // 값이 선택/입력되었는지 여부

  const LabeledBorderContainer({
    Key? key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.borderColor = Colors.grey,
    this.focusedBorderColor = Colors.orange,
    this.labelColor = Colors.black,
    this.hasValue = false, // 기본적으로 비어있음
  }) : super(key: key);

  @override
  State<LabeledBorderContainer> createState() => _LabeledBorderContainerState();
}

class _LabeledBorderContainerState extends State<LabeledBorderContainer> {
  bool _hasFocus = false;
  bool _isHovered = false;

  void _updateFocus(bool focus) {
    if (_hasFocus != focus) {
      setState(() {
        _hasFocus = focus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 다크 모드 감지
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 값이 있거나 포커스/호버 상태일 때 하이라이트
    final bool isActive = _hasFocus || _isHovered || widget.hasValue;
    final Color activeBorderColor = isActive ? widget.focusedBorderColor : widget.borderColor;
    final Color activeLabelColor = isActive ? widget.focusedBorderColor : widget.labelColor;

    // 텍스트 및 배경 색상 조정
    final Color backgroundColor = isDarkMode ? const Color(0xFF383838) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : activeLabelColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Border container
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: activeBorderColor,
                  width: isActive ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: backgroundColor,
              ),
              child: FocusScope(
                onFocusChange: _updateFocus,
                child: widget.child,
              ),
            ),
          ),
          // Label
          Positioned(
            left: 12,
            top: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  if (widget.isRequired)
                    const Text(
                      ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Specialized version for text fields
class LabeledTextField extends StatelessWidget {
  final String label;
  final String hint;
  final bool isRequired;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color labelColor;
  final TextInputType keyboardType;
  final bool? hasValueOverride; // 외부에서 값 유무를 직접 설정할 수 있는 속성

  const LabeledTextField({
    Key? key,
    required this.label,
    required this.hint,
    this.isRequired = false,
    this.controller,
    this.onChanged,
    this.maxLines = 1,
    this.borderColor = Colors.grey,
    this.focusedBorderColor = Colors.orange,
    this.labelColor = Colors.black,
    this.keyboardType = TextInputType.text,
    this.hasValueOverride, // 새로운 매개변수 추가
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 다크 모드 감지
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 텍스트 필드에 값이 있는지 확인
    // 외부에서 hasValueOverride가 설정되었으면 그 값을, 아니면 controller의 text가 비어있지 않은지 확인
    final bool hasValue = hasValueOverride ?? (controller != null && controller!.text.isNotEmpty);

    return LabeledBorderContainer(
      label: label,
      isRequired: isRequired,
      borderColor: borderColor,
      focusedBorderColor: focusedBorderColor,
      labelColor: labelColor,
      hasValue: hasValue, // 값 유무 전달
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          keyboardType: keyboardType,
          // 다크 모드에서 텍스트 색상 조정
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            // 다크 모드에서 힌트 텍스트 색상 조정
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.grey.shade400.withOpacity(0.7) : Colors.grey.shade400,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
          ),
        ),
      ),
    );
  }
}

// Specialized version for dropdowns
class LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final String hint;
  final bool isRequired;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color labelColor;
  final bool? hasValueOverride; // 외부에서 값 유무를 직접 설정할 수 있는 속성

  const LabeledDropdown({
    Key? key,
    required this.label,
    required this.hint,
    this.isRequired = false,
    this.value,
    required this.items,
    this.onChanged,
    this.borderColor = Colors.grey,
    this.focusedBorderColor = Colors.orange,
    this.labelColor = Colors.black,
    this.hasValueOverride, // 새로운 매개변수 추가
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 다크 모드 감지
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 드롭다운에 값이 선택되었는지 확인
    // 외부에서 hasValueOverride가 설정되었으면 그 값을, 아니면 value != null 확인
    final bool hasValue = hasValueOverride ?? (value != null);

    return LabeledBorderContainer(
      label: label,
      isRequired: isRequired,
      borderColor: borderColor,
      focusedBorderColor: focusedBorderColor,
      labelColor: labelColor,
      hasValue: hasValue, // 값 유무 전달
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            value: value,
            hint: Text(
              hint,
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
              ),
            ),
            // 다크 모드에서 드롭다운 아이템 텍스트 색상 조정
            dropdownColor: isDarkMode ? const Color(0xFF383838) : Colors.white,
            // 드롭다운 아이콘 색상 조정
            iconEnabledColor: isDarkMode ? Colors.white : Colors.grey.shade800,
            // 기본 텍스트 스타일 (선택된 항목)
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 16,
            ),
            items: items,
            onChanged: onChanged,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
          ),
        ),
      ),
    );
  }
}