import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../models/activity_measure_type.dart';

class TimeStepper extends StatefulWidget {
  const TimeStepper({
    super.key,
    required this.value,
    required this.timeUnit,
    required this.onValueChanged,
    required this.onTimeUnitChanged,
    this.min = 0,
  });

  final int value;
  final ActivityTimeUnit timeUnit;
  final ValueChanged<int> onValueChanged;
  final ValueChanged<ActivityTimeUnit> onTimeUnitChanged;
  final int min;

  @override
  State<TimeStepper> createState() => _TimeStepperState();
}

class _TimeStepperState extends State<TimeStepper> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(covariant TimeStepper oldWidget) {
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
    widget.onValueChanged(clamped);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<ActivityTimeUnit>(
          segments: const [
            ButtonSegment(
              value: ActivityTimeUnit.hour,
              label: Text('시'),
            ),
            ButtonSegment(
              value: ActivityTimeUnit.minute,
              label: Text('분'),
            ),
          ],
          selected: {widget.timeUnit},
          onSelectionChanged: (selection) {
            widget.onTimeUnitChanged(selection.first);
          },
        ),
        const SizedBox(height: 12),
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
                widget.timeUnit.label,
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
