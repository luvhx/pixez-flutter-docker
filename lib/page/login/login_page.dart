/*
 * Copyright (C) 2020. by perol_notsf, All rights reserved
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'package:pixez/platform/io.dart';

import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pixez/custom_tab_plugin.dart';
import 'package:pixez/er/leader.dart';
import 'package:pixez/i18n.dart';
import 'package:pixez/main.dart';
import 'package:pixez/models/account.dart';
import 'package:pixez/network/oauth_client.dart';
import 'package:pixez/page/about/about_page.dart';
import 'package:pixez/page/hello/setting/setting_quality_page.dart';
import 'package:pixez/page/login/token_page.dart';
import 'package:pixez/page/webview/webview_page.dart';
import 'package:pixez/weiss_plugin.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher_string.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController userNameController = TextEditingController();
  TextEditingController passWordController = TextEditingController();
  String? webError;
  bool webLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    userNameController.dispose();
    passWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => SettingQualityPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.message),
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => AboutPage()));
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(elevation: 0.0, backgroundColor: Colors.transparent),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Builder(
        builder: (context) {
          return _buildBody(context);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (kIsWeb) return _buildWebBody(context);
    return Container(
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(0),
          child: Column(
            children: <Widget>[
              Container(height: 20),
              Image.asset('assets/images/icon.png', height: 80, width: 80),
              Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SizedBox(height: 10),
                        FilledButton(
                          child: Text(I18n.of(context).login),
                          onPressed: () async {
                            try {
                              String url =
                                  await OAuthClient.generateWebviewUrl();
                              _launch(url);
                            } catch (e) {}
                          },
                        ),
                        SizedBox(height: 4),
                        FilledButton(
                          onPressed: () async {
                            try {
                              String url = await OAuthClient.generateWebviewUrl(
                                create: true,
                              );
                              _launch(url);
                            } catch (e) {}
                          },
                          child: Text(I18n.of(context).dont_have_account),
                        ),
                        SizedBox(height: 4),
                        OutlinedButton(
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (context) => TokenPage(),
                            );
                          },
                          child: Text("Token"),
                        ),
                        SizedBox(height: 4),
                        TextButton(
                          child: Text(I18n.of(context).terms),
                          onPressed: () async {
                            final url =
                                'https://www.pixiv.net/terms/?page=term';
                            try {
                              await launchUrlString(url);
                            } catch (e) {}
                          },
                        ),
                      ],
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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

  /// Web login.
  ///
  /// The native apps log in inside a WebView: Pixiv redirects to
  /// `pixiv://account/login?code=...`, which a WebView can intercept.  A
  /// browser cannot register that scheme, and Pixiv disabled the
  /// `grant_type=password` flow for the app client (error 1508), so the web
  /// build authenticates with a Pixiv refresh token instead.
  Widget _buildWebBody(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/icon.png',
                      height: 80,
                      width: 80,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'PixEz',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with a Pixiv refresh token',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: userNameController,
                    autofillHints: const [AutofillHints.password],
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Refresh token',
                      hintText: 'Paste your refresh token',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _webLogin(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: webLoading ? null : _webLogin,
                    child: webLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(I18n.of(context).login),
                  ),
                  if (webError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        webError!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('How do I get a refresh token?'),
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    children: [
                      Text(
                        'The browser cannot intercept the pixiv:// redirect that '
                        'the native apps use, so a token has to be obtained once '
                        'outside the browser.\n\n'
                        'Option A — use the bundled helper (needs Node.js + '
                        'Playwright):\n'
                        '    node tool/get_token.js\n'
                        'It opens Pixiv, you sign in, and it prints a refresh '
                        'token.\n\n'
                        'Option B — reuse the token from another PixEz session '
                        'or any Pixiv App-API tool you already trust.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () async {
                      try {
                        await launchUrlString(
                          'https://accounts.pixiv.net/signup',
                          webOnlyWindowName: '_blank',
                        );
                      } catch (_) {}
                    },
                    child: Text(I18n.of(context).dont_have_account),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await launchUrlString(
                          'https://www.pixiv.net/terms/?page=term',
                          webOnlyWindowName: '_blank',
                        );
                      } catch (_) {}
                    },
                    child: Text(I18n.of(context).terms),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _webLogin() async {
    final token = userNameController.text.trim();
    if (token.isEmpty) {
      setState(() => webError = 'Please paste a refresh token');
      return;
    }
    setState(() {
      webLoading = true;
      webError = null;
    });
    try {
      await oAuthClient.createDioClient();
      final response = await oAuthClient.postRefreshAuthToken(refreshToken: token);
      final accountResponse = Account.fromJson(response.data).response;
      final user = accountResponse.user;
      final accountProvider = AccountProvider();
      await accountProvider.open();
      await accountProvider.deleteByUserId(user.id);
      final accountPersist = AccountPersist(
        userId: user.id,
        userImage: user.profileImageUrls.px170x170,
        accessToken: accountResponse.accessToken,
        refreshToken: accountResponse.refreshToken,
        deviceToken: "",
        passWord: "no more",
        name: user.name,
        account: user.account,
        mailAddress: user.mailAddress,
        isPremium: user.isPremium ? 1 : 0,
        xRestrict: user.xRestrict,
        isMailAuthorized: user.isMailAuthorized ? 1 : 0,
      );
      await accountProvider.insert(accountPersist);
      await accountStore.fetch();
      if (!mounted) return;
      Leader.pushUntilHome(context);
    } on DioException catch (e) {
      if (!mounted) return;
      var message = e.message ?? e.toString();
      final data = e.response?.data;
      if (data is Map) {
        final error = data['error']?.toString();
        final system = data['errors']?['system']?['message']?.toString();
        if (error != null && error.isNotEmpty) {
          message = system == null ? error : '$error — $system';
        }
      }
      setState(() {
        webError = message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        webError = e.toString();
      });
    } finally {
      if (mounted) setState(() => webLoading = false);
    }
  }

  _launch(url) async {
    if (kIsWeb) {
      try {
        await launchUrlString(url, webOnlyWindowName: '_blank');
      } catch (e) {
        BotToast.showText(text: e.toString());
      }
      return;
    }
    if (Platform.isIOS) {
      final result = await Leader.push(context, WebViewPage(url: url));
      if (result == "OK") {
        Leader.pushUntilHome(context);
      }
      return;
    }
    if (Platform.isMacOS) {
      try {
        CustomTabPlugin.launch(url);
      } catch (e) {
        BotToast.showText(text: e.toString());
      }
      return;
    }
    if (userSetting.oauthNetworkMode.usesCompatibleConnection) {
      // await WeissServer.listener();
      await WeissPlugin.start();
      await WeissPlugin.proxy();
      Leader.push(context, WebViewPage(url: url));
    } else {
      try {
        CustomTabPlugin.launch(url);
      } catch (e) {
        BotToast.showText(text: e.toString());
      }
    }
  }
}
