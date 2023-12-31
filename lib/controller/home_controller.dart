import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:task_1/model/item.dart';
import 'package:dio/dio.dart' as dio;
import 'package:task_1/services/api.dart';
import 'package:path/path.dart';
import 'package:video_player/video_player.dart';
import '../model/media.dart';

class HomeController extends GetxController {
  @override
  void dispose() {
    sc.dispose();
    super.dispose();
  }

  void onInit() async {
    selectedIndex = 0.obs;
    await fetchItems();
    // if (items.isNotEmpty && items.length >= limit) {
    //   isLoadMoreRunning = true;
    // }
   
    //   ..addListener(() {
    //     if (sc.position.pixels >= sc.position.maxScrollExtent - 200) {
    //       fetchItems();
    //     }
    //   });
    if (items.isNotEmpty && items.length >= limit) {
      isLoadMoreRunning = true;
    }
     sc = ScrollController()..addListener(() { if (sc.offset >=
        sc.position.maxScrollExtent * 0.5 &&
        !sc.position.outOfRange 
        ) {
      fetchItems();
    } });
     
    super.onInit();
  }
  void refresh()
  {
    page = 1;
    items = [];
    fetchItems();
  }
  Future<void> fetchItems() async {
    Directory directory = await getApplicationDocumentsDirectory();
    dio.Dio dioo = dio.Dio();
    try {
      dio.Response response = await dioo.get("${Api.apiUrl}/all",
          options: dio.Options(
            headers: Api.headers,
            //  sendTimeout: 5000,
            // receiveTimeout: 3000,
          ),
          queryParameters: {
            'limit': limit,
            'page': page,
          });
      page += 1;

      if (response.statusCode == 200 &&
          response.data['message'] == "Here are all posts!") {
        List<dynamic> itemsJson = response.data['data']['items'];

        if (itemsJson.length < limit) {
          isLoadMoreRunning = false;
        }
        List<Item> temp = [];
        for (var i in itemsJson) {
          List<Media> publisherMedias = [];
          List<Media> postMedias = [];
          Item item = Item.fromJson(i);
          if (item.publisher!.medias.isNotEmpty) {
            for (var m in item.publisher!.medias) {
              publisherMedias.add(Media.fromJson(m)..setType());
            }
            item.publisher!.mediasObj = publisherMedias;
            for (Media m in publisherMedias) {
              if (m.collectionName == 'profile') {
                item.publisher!.imgProfile = m.srcUrl;
                break;
              }
            }
          }
          if (item.medias!.isNotEmpty) {
            for (var m in item.medias!) {
              final Reference refStorage =
                  FirebaseStorage.instance.refFromURL(m['src_url']);
              try {
                dio.Response res = await dioo.get(m['src_url']);
                print("name ${refStorage.name}");
                final path = "${directory.path}/${refStorage.name}";
                File file = File(path);
                await refStorage.writeToFile(file);
                print("file file");
                postMedias.add(Media.fromJson(m)
                  ..setType()
                  ..mediaFile = file);
              } on dio.DioException catch (e) {
                if (e.response != null) {
                  print("data ${e.response!.data}");
                  print("headers ${e.response!.headers}");
                  print("requestOptions ${e.response!.requestOptions}");
                } else {
                  // Something happened in setting up or sending the request that triggered an Error
                  print("requestOptions ${e.requestOptions}");
                  print("error message ${e.message}");
                }
              }
            }
            item.mediasObj = postMedias;
          }
          temp.add(item);
        }
        items.addAll(temp);
      }
    } on dio.DioException catch (e) {
      if (e.response != null) {
        print("data ${e.response!.data}");
        print("headers ${e.response!.headers}");
        print("requestOptions ${e.response!.requestOptions}");
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        print("requestOptions ${e.requestOptions}");
        print("error message ${e.message}");
      }
    }
  }

  final int limit = 10;
  late int page = 1;
  late RxBool _hasNextPage = true.obs;
  late RxBool _isLoadMoreRunning;
  late RxBool _isFirstLoadingRunning = false.obs;
  late ScrollController sc;
  late bool isLoading;
  final RxList<Item> _items = RxList([]);
  late RxInt selectedIndex;
  List<Item> get items => _items;
  bool get isLoadMoreRunning => _isLoadMoreRunning.value;
  bool get hasNextPage => _hasNextPage.value;
  bool get isFirstLoadingRunning => _isFirstLoadingRunning.value;
  set isLoadMoreRunning(bool isLoadMoreRunning) =>
      _isLoadMoreRunning = isLoadMoreRunning.obs;
  set hasNextPage(bool hasNextPage) => _hasNextPage = hasNextPage.obs;
  set isFirstLoadingRunning(bool isFirstLoadingRunning) =>
      _isFirstLoadingRunning = isFirstLoadingRunning.obs;
  set items(List<Item> items) => _items.value = items;
}
