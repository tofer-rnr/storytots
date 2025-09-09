import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants.dart';
import '../../../../data/repositories/profile_repository.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _page = PageController();
  final _repo = ProfileRepository();

  // ---- Topics with images ----
  static const _topics = [
    _TopicOpt('Fun & Adventure', 'assets/images/fun_and_adventure.png'),
    _TopicOpt('Arts',            'assets/images/arts.png'),
    _TopicOpt('Family & Friends','assets/images/family_and_friend.png'),
    _TopicOpt('Nature & Animals','assets/images/nature_and_animal.png'),
    _TopicOpt('Fantasy',         'assets/images/fantasy.png'),
    _TopicOpt('P.E. & Health',   'assets/images/Pe_and_health.png'),
  ];

  static const _goals = [
    'Reading Comprehension',
    'Vocabulary',
    'Improve English Language',
    'Improve Filipino Language',
  ];

  // ---- Avatars with images ----
  static const _avatars = [
    'assets/images/boy.png',
    'assets/images/cat.png',
    'assets/images/chimpmuck.png',
    'assets/images/dog.png',
    'assets/images/girl.png',
    'assets/images/hamster.png',
  ];

  // State
  final _selectedTopics = <String>{}; // store by label
  String? _selectedGoal;
  String? _selectedAvatar;

  static const _maxTopics = 3;

  void _next() {
    final i = _page.page?.round() ?? 0;
    if (i < 2) {
      _page.animateToPage(
        i + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Enhanced validation for topics step
  bool _canContinueFromTopics() {
    return _selectedTopics.isNotEmpty; // Can proceed with at least 1 topic
  }

  void _handleContinueFromTopics() {
    if (_selectedTopics.isEmpty) {
      _showNoTopicsDialog();
      return;
    }
    
    if (_selectedTopics.length < _maxTopics) {
      _showFewerTopicsConfirmationDialog();
      return;
    }
    
    _next(); // Proceed normally if 3 topics selected
  }

  void _showNoTopicsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Topics Selected'),
        content: const Text('Please select at least one topic to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFewerTopicsConfirmationDialog() {
    final topicCount = _selectedTopics.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proceed with fewer topics?'),
        content: Text(
          'You selected only $topicCount interest${topicCount == 1 ? '' : 's'}. Are you sure to proceed with this? For a better experience for your child, we recommend selecting 3 topics.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _next();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(brandPurple),
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceed Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndFinish() async {
    // Enhanced validation
    if (_selectedTopics.isEmpty) {
      _showNoTopicsDialog();
      _page.jumpToPage(0);
      return;
    }
    if (_selectedGoal == null) {
      _snack('Please choose a goal.');
      _page.jumpToPage(1);
      return;
    }
    if (_selectedAvatar == null) {
      _snack('Please choose an avatar.');
      _page.jumpToPage(2);
      return;
    }
    try {
      await _repo.updateInterests(_selectedTopics.toList());
      await _repo.updateGoal(_selectedGoal!);
      await _repo.updateAvatar(_selectedAvatar!);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } catch (e) {
      _snack('Could not save: $e');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/images/storytots_background.png', fit: BoxFit.cover),
        Container(color: Colors.white.withOpacity(0.94)),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Image.asset('assets/images/storytots_logo_front.png', height: 56),
              const SizedBox(height: 8),
              
              // Progress indicator
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: ((_page.hasClients ? _page.page?.round() ?? 0 : 0) + 1) / 3,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(brandPurple)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(_page.hasClients ? _page.page?.round() ?? 0 : 0) + 1} of 3',
                      style: const TextStyle(
                        color: Color(brandPurple),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Choose 3 Topics Your Child Loves',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(brandPurple),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Text(
                          'Selected: ${_selectedTopics.length}/$_maxTopics',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedTopics.length == _maxTopics 
                              ? Colors.green 
                              : _selectedTopics.isEmpty
                                ? Colors.red
                                : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _TopicsStep(
                            options: _topics,
                            selectedLabels: _selectedTopics,
                            maxSelection: _maxTopics,
                            onChanged: () => setState(() {}),
                            onMaxReached: () async {
                              await showDialog<void>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Maximum Topics Reached'),
                                  content: const Text(
                                    'For a better experience for your child, please choose only 3 topics. You can deselect a topic to choose a different one.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'What\'s Your Learning Goal?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(brandPurple),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: _GoalsStep(
                            goals: _goals,
                            selected: _selectedGoal,
                            onChanged: (g) => setState(() => _selectedGoal = g),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Choose Your Avatar',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(brandPurple),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: _AvatarsStep(
                            avatarAssets: _avatars,
                            selectedAsset: _selectedAvatar,
                            onChanged: (a) => setState(() => _selectedAvatar = a),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final i = _page.page?.round() ?? 0;
                          if (i == 0) {
                            _handleContinueFromTopics();
                          } else if (i == 1) {
                            _next();
                          } else {
                            _saveAndFinish();
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(brandPurple),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Builder(builder: (_) {
                          final i = _page.hasClients ? _page.page?.round() ?? 0 : 0;
                          if (i == 0) {
                            if (_selectedTopics.isEmpty) {
                              return const Text('Select at least 1 topic');
                            } else if (_selectedTopics.length < _maxTopics) {
                              return const Text('Continue');
                            } else {
                              return const Text('Continue');
                            }
                          }
                          return Text(i < 2 ? 'Continue' : 'Finish');
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Topic option model
class _TopicOpt {
  final String label;
  final String asset;
  const _TopicOpt(this.label, this.asset);
}

/// -------------------- TOPICS STEP (with images + max 3) --------------------
class _TopicsStep extends StatelessWidget {
  final List<_TopicOpt> options;
  final Set<String> selectedLabels;
  final int maxSelection;
  final VoidCallback onChanged;
  final Future<void> Function() onMaxReached;

  const _TopicsStep({
    required this.options,
    required this.selectedLabels,
    required this.maxSelection,
    required this.onChanged,
    required this.onMaxReached,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.05,
        children: options.map((opt) {
          final picked = selectedLabels.contains(opt.label);
          final canSelect = selectedLabels.length < maxSelection || picked;
          
          return GestureDetector(
            onTap: () async {
              if (picked) {
                selectedLabels.remove(opt.label);
                onChanged();
              } else {
                if (selectedLabels.length >= maxSelection) {
                  await onMaxReached();
                  return;
                }
                selectedLabels.add(opt.label);
                onChanged();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: AssetImage(opt.asset),
                  fit: BoxFit.cover,
                  colorFilter: !canSelect && !picked
                    ? ColorFilter.mode(Colors.grey.shade400, BlendMode.saturation)
                    : null,
                ),
                boxShadow: [
                  BoxShadow(
                    color: picked ? const Color(brandPurple).withOpacity(0.3) : Colors.black12,
                    blurRadius: picked ? 12 : 8,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: picked ? const Color(brandPurple) : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Stack(
                children: [
                  // dark gradient for label readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.35),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // label
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Text(
                      opt.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                      ),
                    ),
                  ),
                  // check mark when selected
                  if (picked)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(brandPurple),
                        child: Icon(Icons.check, size: 16, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// -------------------- GOALS STEP --------------------
class _GoalsStep extends StatelessWidget {
  final List<String> goals;
  final String? selected;
  final ValueChanged<String> onChanged;
  const _GoalsStep({
    required this.goals,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: goals.map((g) {
        final picked = g == selected;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: ListTile(
            tileColor: picked ? const Color(brandPurple) : Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(brandPurple), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              g,
              style: TextStyle(
                color: picked ? Colors.white : const Color(brandPurple),
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => onChanged(g),
          ),
        );
      }).toList(),
    );
  }
}

/// -------------------- AVATARS STEP (image avatars) --------------------
class _AvatarsStep extends StatelessWidget {
  final List<String> avatarAssets;
  final String? selectedAsset;
  final ValueChanged<String> onChanged;
  const _AvatarsStep({
    required this.avatarAssets,
    required this.selectedAsset,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        children: avatarAssets.map((asset) {
          final picked = asset == selectedAsset;
          return GestureDetector(
            onTap: () => onChanged(asset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: picked ? const Color(brandPurple).withOpacity(0.3) : Colors.black12,
                    blurRadius: picked ? 12 : 8,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: picked ? const Color(brandPurple) : Colors.transparent,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundImage: AssetImage(asset),
                backgroundColor: Colors.white,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}