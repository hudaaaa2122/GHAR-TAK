import 'package:flutter/material.dart';

import '../../core/order/edit_order_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// Website `AllowSubstitutionCheckbox` — cart grocery substitution preference.
class AllowSubstitutionCheckbox extends StatefulWidget {
  const AllowSubstitutionCheckbox({super.key});

  @override
  State<AllowSubstitutionCheckbox> createState() =>
      _AllowSubstitutionCheckboxState();
}

class _AllowSubstitutionCheckboxState extends State<AllowSubstitutionCheckbox> {
  static const _tooltip =
      'If a product goes out of stock, we can replace it with a similar item.';

  bool _checked = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final next = await getAllowSubstitution();
    if (!mounted) return;
    setState(() {
      _checked = next;
      _loaded = true;
    });
  }

  Future<void> _onChanged(bool? value) async {
    final next = value == true;
    setState(() => _checked = next);
    await setAllowSubstitution(next);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: _loaded ? _checked : true,
              onChanged: _onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: const BorderSide(color: Color(0xFFB8C0CC), width: 1.5),
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return Colors.white;
              }),
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _onChanged(!_checked),
              child: Text(
                'Allow substitutions',
                style: AppFonts.style(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Tooltip(
            message: _tooltip,
            preferBelow: false,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            textStyle: AppFonts.style(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.45,
            ),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
