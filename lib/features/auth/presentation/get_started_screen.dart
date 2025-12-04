import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late List<OnboardingItem> _items;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _items = [
      OnboardingItem(
        title: 'Find Perfect Courts',
        description:
            'Discover the best futsal courts near you with just a few taps.',
        visual: _buildLocationVisual(),
      ),
      OnboardingItem(
        title: 'Book Instantly',
        description:
            'Secure your spot in seconds. No more phone calls or waiting.',
        visual: _buildBookingVisual(),
      ),
      OnboardingItem(
        title: 'Play & Compete',
        description: 'Join the community, challenge teams, and enjoy the game.',
        visual: _buildCommunityVisual(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Decorative Elements (Layers of Logo/Brand)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Skip Button
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  flex: 3,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo or Illustration with layered visuals
                            _items[index].visual,
                            const SizedBox(height: 48),
                            Text(
                              _items[index].title,
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _items[index].description,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Page Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _items.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? theme.primaryColor
                                  : theme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Next / Get Started Button
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentPage == _items.length - 1) {
                                context.push('/login');
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              _currentPage == _items.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationVisual() {
    final theme = Theme.of(context);
    return SizedBox(
      height: 200,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.map_outlined,
              size: 180, color: theme.primaryColor.withOpacity(0.1)),
          Positioned(
            top: 40,
            right: 40,
            child: Icon(Icons.location_on, size: 60, color: theme.primaryColor),
          ),
          Positioned(
            bottom: 40,
            left: 40,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(Icons.search,
                  size: 30, color: theme.colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingVisual() {
    final theme = Theme.of(context);
    return SizedBox(
      height: 200,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.calendar_today,
              size: 160, color: theme.primaryColor.withOpacity(0.1)),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 50, color: Colors.green),
                const SizedBox(height: 8),
                Text(
                  "Booked!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityVisual() {
    final theme = Theme.of(context);
    return SizedBox(
      height: 200,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20,
            top: 20,
            child: Icon(Icons.sports_soccer,
                size: 80, color: theme.primaryColor.withOpacity(0.2)),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Icon(Icons.emoji_events,
                size: 80, color: theme.colorScheme.secondary.withOpacity(0.2)),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.primaryColor, width: 2),
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: Icon(Icons.groups, size: 40, color: theme.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final Widget visual;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.visual,
  });
}
