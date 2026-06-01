import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

class CountStepper extends StatefulWidget {
  const CountStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.compact = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final bool compact;

  @override
  State<CountStepper> createState() => _CountStepperState();
}

class _CountStepperState extends State<CountStepper> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(covariant CountStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value.toString() != _controller.text) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update(int next) {
    final clamped = next < widget.min ? widget.min : next;
    widget.onChanged(clamped);
    _controller.text = '$clamped';
  }

  void _applyText(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed == null) {
      _controller.text = '${widget.value}';
      return;
    }
    _update(parsed);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 112,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: _applyText,
                    onEditingComplete: () => _applyText(_controller.text),
                  ),
                ),
                Text(
                  '회',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CompactStepButton(
                  label: '-5',
                  onPressed: () => _update(widget.value - 5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactStepButton(
                  label: '-1',
                  onPressed: () => _update(widget.value - 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactStepButton(
                  label: '+1',
                  onPressed: () => _update(widget.value + 1),
                  filled: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactStepButton(
                  label: '+5',
                  onPressed: () => _update(widget.value + 5),
                  filled: true,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '횟수',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: _applyText,
                  onEditingComplete: () => _applyText(_controller.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StepButton(
                  label: '-5',
                  onPressed: () => _update(widget.value - 5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StepButton(
                  label: '-1',
                  onPressed: () => _update(widget.value - 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StepButton(
                  label: '+1',
                  onPressed: () => _update(widget.value + 1),
                  filled: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StepButton(
                  label: '+5',
                  onPressed: () => _update(widget.value + 5),
                  filled: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactStepButton extends StatelessWidget {
  const _CompactStepButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: filled ? AppColors.accentMuted : AppColors.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: filled ? AppColors.accent : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: filled ? AppColors.onAccent : AppColors.accent,
      ),
    );

    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: EdgeInsets.zero,
        ),
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: EdgeInsets.zero,
      ),
      child: child,
    );
  }
}
