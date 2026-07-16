import 'package:flutter/material.dart';

import '../../data/models/campaign_model.dart';
import '../utils/date_formatters.dart';
import 'status_chip.dart';

class CampaignCard extends StatelessWidget {
  const CampaignCard({
    super.key,
    required this.campaign,
    required this.onTap,
  });

  final CampaignModel campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (campaign.bannerUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  campaign.bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _BannerPlaceholder(
                    icon: Icons.campaign_outlined,
                  ),
                ),
              )
            else
              const AspectRatio(
                aspectRatio: 16 / 9,
                child: _BannerPlaceholder(icon: Icons.campaign_outlined),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          campaign.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      CampaignStatusChip(status: campaign.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    campaign.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          formatEventDateRange(
                            campaign.startDate,
                            campaign.endDate,
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F766E).withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          icon,
          size: 48,
          color: const Color(0xFF0F766E).withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
