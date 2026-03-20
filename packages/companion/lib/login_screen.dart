import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import 'login_profile.dart';
import 'login_profile_store.dart';

enum _Stage { profileList, profileForm }

class LoginScreen extends StatefulWidget {
  final Future<void> Function() onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginProfileStore _store = LoginProfileStore();
  _Stage _stage = _Stage.profileList;

  /// Non-null when editing an existing profile.
  LoginProfile? _editingProfile;

  String? _errorMessage;
  bool _isLoggingIn = false;

  // Form state
  final _formKey = GlobalKey<FormState>();
  String _selectedScheme = 'https';
  bool _obscure = true;
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openForm(LoginProfile? profile) {
    String url = profile?.url ?? '';
    _selectedScheme = 'https';
    if (url.startsWith('http://')) {
      _selectedScheme = 'http';
      url = url.substring(7);
    } else if (url.startsWith('https://')) {
      _selectedScheme = 'https';
      url = url.substring(8);
    }
    _urlController.text = url;
    _usernameController.text = profile?.username ?? '';
    _passwordController.text = profile?.password ?? '';
    _obscure = true;
    _errorMessage = null;
    setState(() {
      _editingProfile = profile;
      _stage = _Stage.profileForm;
    });
  }

  void _backToList() {
    setState(() {
      _stage = _Stage.profileList;
      _errorMessage = null;
    });
  }

  Future<void> _login(LoginProfile profile) async {
    setState(() {
      _isLoggingIn = true;
      _errorMessage = null;
    });

    try {
      final server = di<DartCouchServer>() as HttpDartCouchServer;

      // Must be in a loginable state
      final state = server.connectionState.value;
      if (state == DartCouchConnectionState.connected ||
          state == DartCouchConnectionState.loggingIn) {
        await server.logout();
      }

      final result = await server.login(
        profile.url,
        profile.username,
        profile.password,
      );

      if (result == null) {
        // Network error
        setState(() {
          _errorMessage = 'Network error. Please check your connection.';
          _isLoggingIn = false;
        });
        return;
      }

      if (server.connectionState.value ==
          DartCouchConnectionState.wrongCredentials) {
        setState(() {
          _errorMessage = 'Login failed. Please check your credentials.';
          _isLoggingIn = false;
        });
        return;
      }

      // Success — register database
      await widget.onLoginSuccess();
      // isLoggingIn will be reset by the parent rebuilding with MyHomePage
    } catch (e) {
      setState(() {
        _errorMessage = 'Login error: $e';
        _isLoggingIn = false;
      });
    }
  }

  void _submitForm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    String url = _urlController.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = '$_selectedScheme://$url';
    }

    final profile = LoginProfile(
      url: url,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    _store.addOrUpdate(profile);
    _backToList();
  }

  void _deleteProfile(LoginProfile profile) {
    _store.remove(profile.url, profile.username);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _stage == _Stage.profileList
              ? 'Login Profiles'
              : _editingProfile != null
              ? 'Edit Profile'
              : 'New Profile',
        ),
        leading: _stage == _Stage.profileForm
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _isLoggingIn ? null : _backToList,
              )
            : null,
      ),
      body: _isLoggingIn
          ? const Center(child: CircularProgressIndicator())
          : _stage == _Stage.profileList
          ? _buildProfileList()
          : _buildProfileForm(),
      floatingActionButton: _stage == _Stage.profileList
          ? FloatingActionButton(
              onPressed: () => _openForm(null),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildProfileList() {
    final profiles = _store.loadProfiles();

    if (profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dns_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No login profiles yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add a server connection',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return ListTile(
          leading: const Icon(Icons.dns),
          title: Text(profile.username),
          subtitle: Text(profile.url),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
                onPressed: () => _openForm(profile),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Duplicate',
                onPressed: () => _openForm(
                  LoginProfile(
                    url: profile.url,
                    username: '',
                    password: profile.password,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete',
                onPressed: () => _deleteProfile(profile),
              ),
              IconButton(
                icon: const Icon(Icons.login),
                tooltip: 'Login',
                onPressed: () => _login(profile),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 1,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _editingProfile != null ? 'Edit Profile' : 'New Profile',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: _selectedScheme,
                          items: const [
                            DropdownMenuItem(
                              value: 'https',
                              child: Text('https'),
                            ),
                            DropdownMenuItem(
                              value: 'http',
                              child: Text('http'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedScheme = value);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _urlController,
                            decoration: const InputDecoration(
                              labelText: 'Server URL',
                              hintText: 'example.com',
                              prefixIcon: Icon(Icons.link),
                            ),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Please enter a server URL';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      obscureText: _obscure,
                      onFieldSubmitted: (_) => _submitForm(),
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'Please enter a password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _backToList,
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _submitForm,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
