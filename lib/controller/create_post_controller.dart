import 'package:mime/mime.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:dio/dio.dart' as dioo;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:task_1/core/functions.dart';
import 'dart:convert';
import 'package:task_1/model/item.dart';
import 'package:task_1/model/media.dart';
import 'package:task_1/services/api.dart';
import 'package:video_player/video_player.dart';

class CreatePostController extends GetxController {
  @override
  void onInit() {
    contentc = TextEditingController();
    medias = RxList([]);
    mediasFiles = RxList([]);
    super.onInit();
  }

  void _pickMedias() async {
    var picker = ImagePicker();
    final List<XFile> mediasFsiles = await picker.pickMultipleMedia();
    mediasFiles.addAll(mediasFsiles);
    isLoading = false;
  }
  void pickMedias()
  {
    isLoading = true;
    _pickMedias();
  }
  void createPost() async {
    Item item;
    late VideoPlayerController? controller;
    print("medafiles $mediasFiles");
    print("medas $medias");
    print("content ${contentc.text}");
    if (mediasFiles.isNotEmpty) {
      
      for (var xFile in mediasFiles) {
        // Assuming xFile is an object
        File file = File(xFile.path);
        String fileName = basename(xFile.path);
        var refStorage = FirebaseStorage.instance.ref('posts/media/$fileName');
        await refStorage.putFile(file);
        
        //SrcUrl
        String? srcUrl = await refStorage.getDownloadURL();
        final fullPath = refStorage.fullPath;
        final mimeType = lookupMimeType(file.path);
        final mediaType = mimeType!.startsWith('image') ? 'Image' : 'Video';
        if (mediaType == 'Video') {
          controller = VideoPlayerController.file(file)..initialize();
        }
         medias.add(Media(
          srcUrl: srcUrl,
          collectionName: 'media',
          mimeTypeString: mimeType,
          mediaTypeString: mediaType,
          srcThum: '',
          srcIcon: '',
          fullPath: fullPath,
          width: mediaType == 'Video'
              ? controller!.value.size.width.round()
              : null,
          height: mediaType == 'Video'
              ? controller!.value.size.height.toInt()
              : null,
          size: await file.length(),
        )
          ..setType()
          ..controller = mediaType == 'Video' ? controller : null);
      }
    } 
    if (mediasFiles.isEmpty) {
      if (contentc.text.isNotEmpty) {
        item = Item(
          content: contentc.text,
        );
      } else {
        showMessage("Content is missing", "Please,type your content");
        return ;
      }
    } else {
      item = Item(
        content: contentc.text,
      )..mediasObj = medias;
    }

    dioo.Dio dio = dioo.Dio();

    try {
      dioo.FormData formData = dioo.FormData.fromMap(item.toJson());
      print("data ${formData.fields}");
      dioo.Response response = await dio.post(
        "${Api.apiUrl}/add",
        data: formData,
        options: dioo.Options(headers: Api.headers),
      );
      if (response.statusCode == 201 &&
          response.data['message'] == "Post added successfully.") {
               Get.back();
        showMessage("Post Created", "Post added successfully.");
     
      }
    } on dioo.DioException catch (e) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        print(e.response!.data);
        print(e.response!.headers);
        print(e.response!.requestOptions);
      } else {
        // Something happened in setting up or sending the request that triggered an Error
        print(e.requestOptions);
        print(e.message);
      }
      showMessage("Post Created", "Please type content or add media");
    }
  }
  set isLoading (bool isLoading) => _isLoading.value = isLoading;
  bool get isLoading => _isLoading.value;
  late TextEditingController contentc;
  late RxList<Media> medias;
  final RxBool _isLoading = RxBool(false);
  late RxList<XFile> mediasFiles ;
}