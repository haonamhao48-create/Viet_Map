import 'package:flutter/material.dart';

import '../../data/models/campaign_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/event_participation_model.dart';

class CampaignStatusChip extends StatelessWidget {
  const CampaignStatusChip({super.key, required this.status});

  final CampaignStatus status;

  @override
  Widget build(BuildContext context) {
    return _StatusChip(
      label: status.label,
      background: _campaignColor(status),
    );
  }

  Color _campaignColor(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.active:
        return const Color(0xFF0F766E);
      case CampaignStatus.completed:
        return const Color(0xFF64748B);
      case CampaignStatus.cancelled:
        return const Color(0xFFDC2626);
      case CampaignStatus.draft:
        return const Color(0xFF94A3B8);
      case CampaignStatus.unknown:
        return const Color(0xFF94A3B8);
    }
  }
}

class EventStatusChip extends StatelessWidget {
  const EventStatusChip({super.key, required this.status});

  final EventStatus status;

  @override
  Widget build(BuildContext context) {
    return _StatusChip(
      label: status.label,
      background: _eventColor(status),
    );
  }

  Color _eventColor(EventStatus status) {
    switch (status) {
      case EventStatus.upcoming:
        return const Color(0xFF2563EB);
      case EventStatus.ongoing:
        return const Color(0xFF0F766E);
      case EventStatus.completed:
        return const Color(0xFF64748B);
      case EventStatus.cancelled:
        return const Color(0xFFDC2626);
      case EventStatus.unknown:
        return const Color(0xFF94A3B8);
    }
  }
}

class ParticipationStatusChip extends StatelessWidget {
  const ParticipationStatusChip({super.key, required this.status});

  final ParticipationStatus status;

  @override
  Widget build(BuildContext context) {
    return _StatusChip(
      label: status.label,
      background: _participationColor(status),
    );
  }

  Color _participationColor(ParticipationStatus status) {
    switch (status) {
      case ParticipationStatus.registered:
        return const Color(0xFF2563EB);
      case ParticipationStatus.attended:
        return const Color(0xFF0F766E);
      case ParticipationStatus.cancelled:
        return const Color(0xFFDC2626);
      case ParticipationStatus.absent:
        return const Color(0xFFF59E0B);
      case ParticipationStatus.unknown:
        return const Color(0xFF94A3B8);
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.background,
  });

  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: background.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: background,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
