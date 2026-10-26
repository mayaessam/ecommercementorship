import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/api_client.dart';
import '../widgets/shimmer_loading.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  static const gold = Color(0xFF7B5D36);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _api = ApiClient();
  bool _loading = true;
  bool _hasSession = false;
  Map<String, dynamic>? _user;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (mounted) setState(() => _loading = true);
    Map<String, dynamic>? user;
    var hasSession = false;
    String? loadError;
    try {
      hasSession = await _api.hasSession();
      if (hasSession) {
        user = await _api.currentUser();
      }
    } catch (error) {
      hasSession = await _api.hasSession();
      if (hasSession) loadError = _api.errorMessage(error);
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _hasSession = hasSession && user != null;
      _user = user;
      _loadError = loadError;
    });
  }

  Future<void> _openAuth(Widget page) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) await _loadUser();
  }

  Future<void> _signOut() async {
    try {
      await _api.logout();
    } catch (_) {
      // ApiClient clears local credentials even if the API cannot be reached.
    }
    if (!mounted) return;
    setState(() {
      _hasSession = false;
      _user = null;
      _loadError = null;
    });
    _showMessage('You have been signed out.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadUser,
      color: AccountScreen.gold,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 32.h),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROFILE & SETTINGS',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: AccountScreen.gold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'My Account',
                      style: TextStyle(
                        fontSize: 25.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh account',
                onPressed: _loading ? null : _loadUser,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (_loading)
            const AccountShimmer()
          else if (_loadError != null)
            _errorCard()
          else if (!_hasSession)
            _signedOutCard()
          else ...[
            _profileCard(),
            SizedBox(height: 18.h),
            _detailsCard(),
            SizedBox(height: 22.h),
            SizedBox(
              height: 52.h,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('SIGN OUT'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF171719),
                  side: const BorderSide(color: Color(0xFFE2DCD5)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _signedOutCard() => Container(
    padding: EdgeInsets.all(18.w),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your AURA account',
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6.h),
        Text(
          'Sign in or create an account to see your profile.',
          style: TextStyle(fontSize: 12.sp, color: const Color(0xFF77716C)),
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _openAuth(const LoginScreen()),
                child: const Text('SIGN IN'),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: FilledButton(
                onPressed: () => _openAuth(const RegisterScreen()),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF171719),
                ),
                child: const Text('REGISTER'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _errorCard() => Container(
    padding: EdgeInsets.all(18.w),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Could not load your account',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6.h),
        Text(
          _loadError!,
          style: TextStyle(fontSize: 12.sp, color: const Color(0xFF77716C)),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _loadUser,
            icon: const Icon(Icons.refresh),
            label: const Text('TRY AGAIN'),
          ),
        ),
      ],
    ),
  );

  Widget _profileCard() {
    final name = _user?['fullName']?.toString().trim() ?? '';
    final email = _user?['email']?.toString().trim() ?? '';
    final picture = _user?['profilePicture']?.toString().trim() ?? '';
    final displayName = name.isNotEmpty ? name : 'AURA Member';

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32.r,
            backgroundColor: const Color(0xFFE2D5C5),
            child: picture.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      picture,
                      width: 64.r,
                      height: 64.r,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.person,
                        size: 36.sp,
                        color: AccountScreen.gold,
                      ),
                    ),
                  )
                : Icon(Icons.person, size: 36.sp, color: AccountScreen.gold),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  SizedBox(height: 5.h),
                  Text(
                    email,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF77716C),
                    ),
                  ),
                ],
                SizedBox(height: 8.h),
                Text(
                  'AURA MEMBER',
                  style: TextStyle(
                    color: AccountScreen.gold,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: .7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard() {
    final email = _user?['email']?.toString() ?? '';
    final userId = _user?['userId']?.toString() ?? '';
    final name = _user?['fullName']?.toString() ?? '';
    final rows = <(IconData, String, String)>[];
    if (name.trim().isNotEmpty) {
      rows.add((Icons.badge_outlined, 'Full name', name));
    }
    if (email.trim().isNotEmpty) {
      rows.add((Icons.email_outlined, 'Email address', email));
    }
    if (userId.trim().isNotEmpty) {
      rows.add((Icons.fingerprint, 'Account ID', userId));
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: _cardDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(2.w, 12.h, 2.w, 8.h),
            child: Text(
              'ACCOUNT DETAILS',
              style: TextStyle(
                color: AccountScreen.gold,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: .8,
              ),
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            _detailRow(rows[i].$1, rows[i].$2, rows[i].$3),
            if (i < rows.length - 1)
              const Divider(height: 1, color: Color(0xFFF0EEEB)),
          ],
          if (rows.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text(
                'No profile details were returned by the server.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF77716C),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: EdgeInsets.symmetric(vertical: 13.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19.sp, color: AccountScreen.gold),
        SizedBox(width: 12.w),
        SizedBox(
          width: 95.w,
          child: Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF77716C)),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  BoxDecoration _cardDecoration({Color color = const Color(0xFFF4F1EF)}) =>
      BoxDecoration(color: color, borderRadius: BorderRadius.circular(14.r));
}
