import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/match_provider.dart';
import '../video_call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _matchNavigationScheduled = false;
  bool _isPickingImage = false;

  Future<void> _pickProfileImage(MatchProvider provider) async {
    if (_isPickingImage) {
      return;
    }

    setState(() => _isPickingImage = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      final imageBytes = await pickedFile.readAsBytes();
      if (!mounted) {
        return;
      }

      provider.setProfileImageBytes(imageBytes);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load profile photo: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, provider, child) {
        _scheduleMatchNavigation(provider);

        return Scaffold(
          body: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        provider.statusMessage,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Server status: ${provider.serverStatus}',
                        style: TextStyle(
                          fontSize: 16,
                          color: provider.socketConnected ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildProfileAvatar(provider),
                      const SizedBox(height: 20),
                      if (provider.isSearching)
                        const SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(color: Colors.pinkAccent, strokeWidth: 6),
                        )
                      else ...[
                        _buildNameField(provider),
                        const SizedBox(height: 20),
                        _buildGenderField(provider),
                        const SizedBox(height: 20),
                        _buildPreferenceField(provider),
                        const SizedBox(height: 40),
                        _buildMatchButton(provider),
                        const SizedBox(height: 20),
                        if (!provider.socketConnected) _buildRetryButton(provider),
                        const SizedBox(height: 20),
                        _buildTestCallButton(context),
                      ],
                    ],
                  ),
                ),
              ),
              if (provider.hasIncomingCall) _buildIncomingCallDialog(provider),
            ],
          ),
        );
      },
    );
  }

  void _scheduleMatchNavigation(MatchProvider provider) {
    if (provider.matchRoomId == null || _matchNavigationScheduled) {
      return;
    }

    _matchNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || provider.matchRoomId == null) {
        _matchNavigationScheduled = false;
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(channelName: provider.matchRoomId!),
        ),
      ).then((_) {
        provider.clearMatch();
        _matchNavigationScheduled = false;
      });
    });
  }

  Widget _buildProfileAvatar(MatchProvider provider) {
    final hasImage = provider.profileImageBytes != null;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: hasImage
                  ? Container(
                      key: const ValueKey('profile-image'),
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.memory(
                          provider.profileImageBytes!,
                          fit: BoxFit.cover,
                          width: 104,
                          height: 104,
                          gaplessPlayback: true,
                        ),
                      ),
                    )
                  : Container(
                      key: const ValueKey('profile-placeholder'),
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: const Icon(Icons.person, size: 56, color: Colors.white54),
                    ),
            ),
            if (_isPickingImage)
              const Padding(
                padding: EdgeInsets.all(6),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Colors.pinkAccent,
                  ),
                ),
              )
            else
              InkWell(
                onTap: () => _pickProfileImage(provider),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, size: 18, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          hasImage ? 'Profile photo ready' : 'Tap to add a profile photo',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildIncomingCallDialog(MatchProvider provider) {
    final imageBytes = provider.incomingCallPartnerImageBytes;

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.pinkAccent, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Incoming Vibe Match',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
                child: ClipOval(
                  child: imageBytes != null
                      ? Image.memory(imageBytes, fit: BoxFit.cover)
                      : const Icon(Icons.person, size: 52, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                provider.incomingCallPartnerName ?? 'Someone',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.acceptIncomingCall,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Accept', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.rejectIncomingCall,
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text('Reject', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField(MatchProvider provider) {
    return TextField(
      controller: provider.nameController,
      decoration: InputDecoration(
        labelText: 'Your Name',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        prefixIcon: const Icon(Icons.person, color: Colors.pink),
      ),
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildGenderField(MatchProvider provider) {
    return DropdownButtonFormField<String>(
      initialValue: provider.selectedGender,
      decoration: InputDecoration(
        labelText: 'I am',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      items: ['Male', 'Female', 'Other'].map((String value) {
        return DropdownMenuItem(value: value, child: Text(value));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          provider.updateGender(value);
        }
      },
    );
  }

  Widget _buildPreferenceField(MatchProvider provider) {
    return DropdownButtonFormField<String>(
      initialValue: provider.selectedPreference,
      decoration: InputDecoration(
        labelText: 'Looking for',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      items: ['All', 'Male', 'Female'].map((String value) {
        return DropdownMenuItem(value: value, child: Text(value));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          provider.updatePreference(value);
        }
      },
    );
  }

  Widget _buildMatchButton(MatchProvider provider) {
    return ElevatedButton.icon(
      onPressed: provider.startMatching,
      icon: const Icon(Icons.favorite, color: Colors.white),
      label: const Text('Find My Vibe', style: TextStyle(fontSize: 18, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildRetryButton(MatchProvider provider) {
    return ElevatedButton.icon(
      onPressed: provider.retryConnection,
      icon: const Icon(Icons.refresh, color: Colors.white),
      label: const Text('Retry Connection', style: TextStyle(color: Colors.white, fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildTestCallButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VideoCallScreen(channelName: 'test_room'),
          ),
        );
      },
      icon: const Icon(Icons.video_call, color: Colors.greenAccent),
      label: const Text(
        'Direct Test Call (No Server)',
        style: TextStyle(color: Colors.greenAccent, fontSize: 16),
      ),
    );
  }
}
