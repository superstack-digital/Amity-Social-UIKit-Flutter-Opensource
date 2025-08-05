import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/components/alert_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:mobile_app_padel/shared/functions.dart';
import 'package:mobile_app_padel/shared/constants.dart';
import 'package:mobile_app_padel/shared/widgets/create_post_text_field.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:mobile_app_padel/shared/widgets/mention_text_field.dart';

class EditCommentVM with ChangeNotifier {
  List<Mention> mentions = [];
  bool loadingComment = true;

  GlobalKey<MentionTextFieldState> textFieldKey = GlobalKey<MentionTextFieldState>();
  FlutterTaggerController mentionTextFieldController = FlutterTaggerController();

  bool get isCommentValid {
    // Check if the text is empty
    return mentionTextFieldController.text.isNotEmpty;
  }

  void inits(AmityComment comment) {
    mentionTextFieldController.clear();
    textFieldKey.currentState?.clear();

    mentions = comment.metadata?['mentions'] != null
        ? (comment.metadata!['mentions'] as List)
        .map((mention) => Mention.fromJson(mention))
        .toList()
        : [];

    if (mentions.isNotEmpty) {
      Future.delayed(Duration(milliseconds: 200), () async {
        final postText = (comment.data as CommentTextData).text ?? "";

        int currentIndex = 0;
        for (int i = 0; i < mentions.length; i++) {
          final mention = mentions[i];
          mentionTextFieldController.text +=
              postText.substring(currentIndex, mention.index + 1);
          mentionTextFieldController.selection = TextSelection.fromPosition(
            TextPosition(offset: mentionTextFieldController.text.length),
          );

          print(mention.text);

          final username = mention.text.replaceAll(' ', '\u00A0');
          print(username);
          await Future.delayed(Duration(milliseconds: 100), () {
            mentionTextFieldController.addTag(id: mention.userId, name: username);
            if(mentionTextFieldController.text.isNotEmpty){
              mentionTextFieldController.text.trim();
            }
          });
          currentIndex = mention.index + mention.length;

          if (i == mentions.length - 1) {
            mentionTextFieldController.text +=
                postText.substring(mention.index + mention.length);
            loadingComment = false;
            notifyListeners();
          }
        }
      });
    } else {
      mentionTextFieldController.text = (comment.data as CommentTextData).text ?? "";
      loadingComment = false;
    }
  }

  void onMentionsChanged(List<Mention> mentions) {
    this.mentions = mentions;
    notifyListeners();
  }

  void onTextChanged(String text) {

  }

  Future<List<AmityCommunityMember>> onSearchMentions(
      {required String keyword, required String communityId}) async {
    final res = await AmityCommunityRepository()
        .membership(communityId)
        .searchMembers(keyword)
        .getPagingData(limit: 5);

    if (res.data.isNotEmpty) {
      return res.data;
    } else {
      return [];
    }
  }

  void updateComment(AmityComment comment) async {
    Map<String, dynamic> metadata = {};
    if(mentions.isNotEmpty){
      metadata = {
        "mentions": mentions.map((mention) => mention.toJson()).toList(),
      };
    }

    final userIds = mentions
        .map((mention) => mention.userId)
        .where((userId) => userId != null)
        .toList();

    comment
        .edit()
        .text(mentionTextFieldController.text)
        .mentionUsers(userIds)
        .metadata(metadata)
        .build()
        .update()
        .then((value) {})
        .onError((error,
        stackTrace) async {
      log("unflag error ${error.toString()}");
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }
}
