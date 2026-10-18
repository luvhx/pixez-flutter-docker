import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pixez/document_plugin.dart';
import 'package:pixez/er/hoster.dart';
import 'package:pixez/er/lprinter.dart';
import 'package:pixez/er/toaster.dart';
import 'package:pixez/i18n.dart';
import 'package:pixez/main.dart';
import 'package:pixez/models/illust.dart';
import 'package:pixez/models/task_persist.dart';
import 'package:pixez/net/endpoints.dart';
import 'package:pixez/net/http_adapter.dart';
import 'package:pixez/network/network_mode.dart';
import 'package:pixez/store/save_store.dart';
import 'package:quiver/collection.dart';

class TaskBean {
  String? url;
  Illusts? illusts;
  String? fileName;
  String? savePath;
  String? source;
  String? host;
  NetworkMode? networkMode;

  TaskBean({
    required this.url,
    required this.illusts,
    required this.fileName,
    this.savePath,
    this.networkMode,
    this.host,
    this.source,
  });
}

/// Web task queue.
///
/// The public surface mirrors the native fetcher so that the rest of the app
/// (job page, save store, settings) keeps working unchanged.
class Fetcher {
  BuildContext? context;
  List<TaskBean> queue = [];
  List<String> urlPool = [];
  LruMap<String, JobEntity> jobMaps = LruMap();
  TaskPersistProvider taskPersistProvider = TaskPersistProvider();

  Fetcher();

  Future<void> start(String pictureSource) async {
    await taskPersistProvider.open();
    await taskPersistProvider.getAllAccount();
  }

  Future<void> save(String url, Illusts illusts, String fileName) async {
    final bean = TaskBean(url: url, illusts: illusts, fileName: fileName);
    queue.add(bean);
    if (!urlPool.contains(url)) urlPool.add(url);

    final job = JobEntity()
      ..status = 1
      ..min = 0
      ..max = 1;
    jobMaps[url] = job;

    try {
      final dio = Dio(BaseOptions(headers: Hoster.header(url: url)));
      dio.httpClientAdapter = await createImageAdapter(
        source: userSetting.pictureSource,
        mode: userSetting.networkMode,
      );
      final response = await dio.get<List<int>>(
        webImageUrl(url),
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 5),
        ),
        onReceiveProgress: (received, total) {
          job.min = received;
          if (total > 0) job.max = total;
        },
      );
      final raw = response.data;
      final bytes = raw == null ? Uint8List(0) : Uint8List.fromList(raw);
      if (bytes.isEmpty) {
        throw StateError('empty response for $url');
      }

      await DocumentPlugin.save(bytes, fileName);
      job
        ..status = 2
        ..min = 1
        ..max = 1;

      final persist = await taskPersistProvider.getAccount(url);
      if (persist != null) {
        await taskPersistProvider.update(persist..status = 2);
      }

      final ctx = context;
      if (ctx != null) {
        Toaster.downloadOk("${illusts.title} ${I18n.of(ctx).saved}");
      }
    } catch (e) {
      LPrinter.d(e);
      job.status = 3;
      final persist = await taskPersistProvider.getAccount(url);
      if (persist != null) {
        await taskPersistProvider.update(persist..status = 3);
      }
    } finally {
      queue.removeWhere((element) => element.url == url);
      urlPool.remove(url);
    }
  }

  void stop() {}

  void reloadNetwork() {}
}
