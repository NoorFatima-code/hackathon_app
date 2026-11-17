import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _getStarted(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7F8FF), Color(0xFFEEF2FF)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.accent,
                                      AppColors.primary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.sm,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.groups_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'TeamUp',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(fontSize: 24),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                            isWide ? AppSpacing.xl : AppSpacing.lg,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF172554), Color(0xFF3730A3)],
                            ),
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                          ),
                          child: isWide
                              ? Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _heroCopy(context),
                                    ),
                                    const SizedBox(width: AppSpacing.lg),
                                    const Expanded(
                                      flex: 2,
                                      child: _TeamIllustration(),
                                    ),
                                  ],
                                )
                              : _heroCopy(context),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'A better way to build your team',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (isWide)
                          const Row(
                            children: [
                              Expanded(
                                child: _FeatureCard(
                                  icon: Icons.person_search_outlined,
                                  title: 'Find your people',
                                  description:
                                      'Discover students with skills that complement yours.',
                                ),
                              ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _FeatureCard(
                                  icon: Icons.auto_awesome_outlined,
                                  title: 'Get matched',
                                  description:
                                      'Explore teammates who share your project interests.',
                                ),
                              ),
                              SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _FeatureCard(
                                  icon: Icons.groups_outlined,
                                  title: 'Build together',
                                  description:
                                      'Bring your ideas to life with the right team.',
                                ),
                              ),
                            ],
                          )
                        else
                          const Column(
                            children: [
                              _FeatureCard(
                                icon: Icons.person_search_outlined,
                                title: 'Find your people',
                                description:
                                    'Discover students with skills that complement yours.',
                              ),
                              SizedBox(height: AppSpacing.sm),
                              _FeatureCard(
                                icon: Icons.auto_awesome_outlined,
                                title: 'Get matched',
                                description:
                                    'Explore teammates who share your project interests.',
                              ),
                              SizedBox(height: AppSpacing.sm),
                              _FeatureCard(
                                icon: Icons.groups_outlined,
                                title: 'Build together',
                                description:
                                    'Bring your ideas to life with the right team.',
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _heroCopy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Text(
            'YOUR NEXT GREAT PROJECT STARTS HERE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFFC7D2FE),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Find your people.\nBuild something great.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Team up with students who share your interests and bring the skills your next idea needs.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFFE0E7FF),
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: () => _getStarted(context),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Get started'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _TeamIllustration extends StatelessWidget {
  const _TeamIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
          const Positioned(
            top: 44,
            left: 52,
            child: _AvatarTile(
              icon: Icons.person_rounded,
              color: Color(0xFF99F6E4),
            ),
          ),
          const Positioned(
            top: 44,
            right: 52,
            child: _AvatarTile(
              icon: Icons.person_rounded,
              color: Color(0xFFFDE68A),
            ),
          ),
          const Positioned(
            bottom: 42,
            child: _AvatarTile(
              icon: Icons.person_rounded,
              color: Color(0xFFC4B5FD),
            ),
          ),
          const Icon(Icons.link_rounded, color: Colors.white, size: 36),
        ],
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF172554), size: 30),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
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
