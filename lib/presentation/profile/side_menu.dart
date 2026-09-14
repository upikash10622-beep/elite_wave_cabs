import 'package:flutter/material.dart';

import '../../../core/colors.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();

    // ============================================================
    // MAIN ANIMATION CONTROLLER
    // ============================================================

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // ============================================================
    // FADE ANIMATION
    // ============================================================

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // ============================================================
    // SCALE ANIMATION
    // ============================================================

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    // ============================================================
    // HEADER SLIDE ANIMATION
    // ============================================================

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.35, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // ANIMATED MENU ITEM
  // ============================================================

  Widget _animatedMenuItem({
    required int index,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final double start = (0.10 + (index * 0.09)).clamp(0.0, 0.65);

    final double end = (start + 0.35).clamp(0.0, 1.0);

    final Animation<double> animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double value = animation.value;

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              -45 * (1 - value),
              0,
            ),
            child: Transform.scale(
              scale: 0.88 + (0.12 * value),
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            splashColor: AppColors.primaryBlue.withValues(alpha: 0.12),
            highlightColor: AppColors.primaryBlue.withValues(alpha: 0.05),
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                children: [
                  // ==================================================
                  // ICON CONTAINER
                  // ==================================================

                  AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 250,
                    ),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primaryBlue,
                      size: 23,
                    ),
                  ),

                  const SizedBox(width: 15),

                  // ==================================================
                  // TITLE
                  // ==================================================

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  const Spacer(),

                  // ==================================================
                  // ARROW
                  // ==================================================

                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader() {
    return SlideTransition(
      position: _headerSlideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            12,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue,
                  AppColors.primaryBlue.withValues(alpha: 0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(23),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.30),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Row(
              children: [
                // ==================================================
                // PROFILE ICON ANIMATION
                // ==================================================

                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.45,
                    end: 1.0,
                  ),
                  duration: const Duration(
                    milliseconds: 1000,
                  ),
                  curve: Curves.elasticOut,
                  builder: (
                    context,
                    scale,
                    child,
                  ) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primaryBlue,
                      size: 35,
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                // ==================================================
                // PROFILE TEXT ANIMATION
                // ==================================================

                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: 1.0,
                    ),
                    duration: const Duration(
                      milliseconds: 850,
                    ),
                    curve: Curves.easeOutCubic,
                    builder: (
                      context,
                      value,
                      child,
                    ) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(
                            30 * (1 - value),
                            0,
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: const Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Elite Wave Cabs',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: Colors.white,
      elevation: 20,

      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.centerLeft,
              child: child,
            ),
          );
        },

        child: SafeArea(
          child: Column(
            children: [
              // ==================================================
              // PROFILE HEADER
              // ==================================================

              _buildProfileHeader(),

              const SizedBox(height: 10),

              // ==================================================
              // MENU ITEMS
              // ==================================================

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _animatedMenuItem(
                        index: 0,
                        icon: Icons.home_rounded,
                        title: 'Home',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),

                      _animatedMenuItem(
                        index: 1,
                        icon: Icons.person_outline_rounded,
                        title: 'Profile',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),

                      _animatedMenuItem(
                        index: 2,
                        icon: Icons.history_rounded,
                        title: 'Ride History',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),

                      _animatedMenuItem(
                        index: 3,
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Wallet',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),

                      _animatedMenuItem(
                        index: 4,
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),

                      _animatedMenuItem(
                        index: 5,
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ==================================================
              // DIVIDER
              // ==================================================

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                ),
                child: Divider(
                  color: Colors.grey.shade200,
                  thickness: 1,
                ),
              ),

              // ==================================================
              // LOGOUT
              // ==================================================

              _animatedMenuItem(
                index: 6,
                icon: Icons.logout_rounded,
                title: 'Logout',
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              // ==================================================
              // FOOTER
              // ==================================================

              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 2,
                    bottom: 18,
                  ),
                  child: Text(
                    'Elite Wave Cabs',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}