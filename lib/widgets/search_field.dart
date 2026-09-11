import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/theme.dart';

/// 검색 화면 상단의 입력창.
class SearchField extends StatelessWidget {
  const SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  /// 시안 값. icon 토큰(16 / 20) 중 16과 같지만 입력창 전용이라 여기 둔다.
  static const double _iconSize = 16;

  /// 입력창 높이 40과 좌우 여백 12는 space 토큰에 없는 시안 값이다.
  static const double _fieldHeight = 40;
  static const double _fieldPadding = 12;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        dimens.space4,
        dimens.space2,
        dimens.space4,
        dimens.space3,
      ),
      child: Container(
        height: _fieldHeight,
        padding: const EdgeInsets.symmetric(horizontal: _fieldPadding),
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(dimens.radiusMd),
          border: Border.all(
            color: colors.borderStrong,
            width: dimens.borderHairline,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.search_rounded,
              size: _iconSize,
              color: colors.textTertiary,
            ),
            SizedBox(width: dimens.space2),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                cursorColor: colors.accentDefault,
                style: AppTextStyles.rowPrimary.copyWith(
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: '종목명 또는 종목코드',
                  hintStyle: AppTextStyles.rowPrimary.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ),
            SizedBox(width: dimens.space2),
            // 시안에는 입력 전에도 지우기 버튼이 그려져 있어 항상 보여준다.
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.close_rounded,
                size: _iconSize,
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
