import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/viewmodel/user_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../components/alert_dialog.dart';
import 'package:mobile_app_padel/shared/functions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_app_padel/shared/constants.dart';
import 'package:mobile_app_padel/features/community/presentation/controllers/community_open_matches_controller.dart';
import 'package:mobile_app_padel/features/community/data/repositories/community_repository.dart';
import 'package:get/get.dart';



enum CommunityListType { my, recommend, trending }

enum CommunityFeedMenuOption { edit, members }

enum CommunityType { public, private }

class CommunityVM extends ChangeNotifier {
  var _amityTrendingCommunities = <AmityCommunity>[];
  var _amityRecommendCommunities = <AmityCommunity>[];
  var _amityMyCommunities = <AmityCommunity>[];

  var linkedClubIds = <int>[];


  void updateLinkedClubs(List<int> ids){
    linkedClubIds = ids; 
    notifyListeners();
  }

  List<AmityCommunity> getAmityTrendingCommunities() {
    return _amityTrendingCommunities;
  }

  List<AmityCommunity> getAmityRecommendCommunities() {
    return _amityRecommendCommunities;
  }

  List<AmityCommunity> getAmityMyCommunities() {
    return _amityMyCommunities;
  }

  void initAmityTrendingCommunityList() async {
    log("initAmityTrendingCommunityList");

    if (_amityTrendingCommunities.isNotEmpty) {
      _amityTrendingCommunities.clear();
      notifyListeners();
    }

    AmitySocialClient.newCommunityRepository()
        .getTrendingCommunities()
        .then((List<AmityCommunity> trendingCommunites) {
      _amityTrendingCommunities = trendingCommunites;
      notifyListeners();
    }).onError((error, stackTrace) async {
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }
//ป่าวๆ

  Future<AmityCommunity?> createCommunity({
    required BuildContext context,
    required String name,
    required String description,
    required AmityImage? avatar,
    List<String>? tags,
    required List<String> categoryIds,
    required bool isPublic,
    Map<String, String>? metadata,
    List<String>? userIds,
    List<int>? clubIds,
    String? location,
    double? latitude,
    double? longitude,
    List<int>? competitionIds
  }) async {
    try {
      // if(clubIds?.isEmpty == true){
      //   showStyledSnackBar("Please select at least one club", SnackBarType.error);
      //   return null;
      // }
      
      AmityChannel? channel;

      var channelQuery = AmityChatClient.newChannelRepository().createChannel().communityType().withDisplayName(name);

      if(avatar != null) {
        channelQuery.avatar(avatar).metadata({"avatar": avatar.getUrl(AmityImageSize.SMALL), "type": "community_channel"});
      } else {
        channelQuery.metadata({"type": "community_channel"});
      }

      channel = await channelQuery.create();

      // Create tags from location
      List<String> communityTags = [];
      if (location != null && location.isNotEmpty) {
        communityTags.add(location.toLowerCase().trim());
      }
      // Add additional tags if provided
      if (tags != null && tags.isNotEmpty) {
        communityTags.addAll(tags);
      }

      final communityBuilder = AmitySocialClient.newCommunityRepository()
          .createCommunity(name)
          .description(description)
          .categoryIds(categoryIds).metadata({
        "club_ids": clubIds,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
        "channel_id": channel.channelId,
        "competition_ids": competitionIds
      });

      // Add tags if available
      if (communityTags.isNotEmpty) {
        communityBuilder.tags(communityTags);
      }

      if (isPublic) {
        communityBuilder.isPublic(true);
      } else {
        communityBuilder.isPublic(false);
        communityBuilder.userIds(userIds!);
      }

      if (avatar != null) {
        communityBuilder.avatar(avatar);
      }

      if(userIds?.isNotEmpty == true){
        AmityChatClient.newChannelRepository().addMembers(channel?.channelId ?? "",   userIds ?? []);
      }

      AmityCommunity createdCommunity = await communityBuilder.create();
      print("Created community ${createdCommunity.displayName}");

      // Save community information to Supabase
      if (latitude != null && longitude != null) {
        try {
          await CommunityRepository.getInstance().upsertCommunityInformation(
            communityId: createdCommunity.communityId!,
            latitude: latitude,
            longitude: longitude,
          );
        } catch (e) {
          print("Failed to save community information: $e");
        }
      }

      notifyListeners();
      Navigator.of(context).pop();
      final userProvider = Provider.of<UserVM>(context, listen: false);
      userProvider.clearselectedCommunityUsers();

      return createdCommunity;
    } catch (error) {
      print("Failed to create community: $error");
      return null;
    }
  }

  Future<void> updateCommunity(
      String communityId,
      AmityImage? avatar,
      String displayName,
      String description,
      List<String> categoryIds,
      bool isPublic,
      List<int>? clubIds,
      String? location,
      double? latitude,
      double? longitude,
      String channelId,
      AmityCommunity community,
      List<int>? competitionIds
      ) async {
    Map<String, dynamic> metadata = community.metadata ?? {};

    metadata["club_ids"] = clubIds;
    metadata["location"] = location;
    metadata["latitude"] = latitude;
    metadata["longitude"] = longitude;
    metadata["channel_id"] = channelId;
    metadata["competition_ids"] = competitionIds;

    print('metadata');
    print(metadata);

    // Create tags from location
    List<String> communityTags = [];
    if (location != null && location.isNotEmpty) {
      communityTags.add(location.toLowerCase().trim());
    }

    if (avatar != null) {
      final updateBuilder = AmitySocialClient.newCommunityRepository()
          .updateCommunity(communityId)
          .avatar(avatar)
          .displayName(displayName)
          .description(description)
          .categoryIds(categoryIds)
          .isPublic(isPublic)
          .metadata(metadata);

      if (communityTags.isNotEmpty) {
        updateBuilder.tags(communityTags);
      }

      await updateBuilder
          .update()
          .then((value) => notifyListeners())
          .onError((error, stackTrace) async {
        await AmityDialog()
            .showAlertErrorDialog(title: "Error!", message: error.toString());
        await AmityChatClient
            .newChannelRepository()
            .updateChannel(channelId)
            .avatar(avatar);
      });
    } else {
      final updateBuilder = AmitySocialClient.newCommunityRepository()
          .updateCommunity(communityId)
          .displayName(displayName)
          .description(description)
          .categoryIds(categoryIds)
          .isPublic(isPublic)
          .metadata(metadata);

      if (communityTags.isNotEmpty) {
        updateBuilder.tags(communityTags);
      }

      await updateBuilder
          .update()
          .then((value) => notifyListeners())
          .onError((error, stackTrace) async {
        await AmityDialog()
            .showAlertErrorDialog(title: "Error!", message: error.toString());
      });
    }

    // Save community information to Supabase
    if (latitude != null && longitude != null) {
      try {
        await CommunityRepository.getInstance().upsertCommunityInformation(
          communityId: communityId,
          latitude: latitude,
          longitude: longitude,
        );
      } catch (e) {
        print("Failed to save community information: $e");
      }
    }

    final isLeague = community.categories?.isNotEmpty == true && community.categories?.first?.name == "League";
    CommunityOpenMatchesController openMatchCommunityController;

    if(Get.isRegistered<CommunityOpenMatchesController>()){
      openMatchCommunityController = Get.find<CommunityOpenMatchesController>(tag: communityId);
    } else {
      openMatchCommunityController = Get.put(CommunityOpenMatchesController(
          communityId: communityId, isLeagueCommunity: isLeague), tag: communityId);
    }
    openMatchCommunityController.initData();
  }

  void initAmityRecommendCommunityList() async {
    log("initAmityRecommendCommunityList");
    if (_amityRecommendCommunities.isNotEmpty) {
      _amityRecommendCommunities.clear();
      notifyListeners();
    }

    AmitySocialClient.newCommunityRepository()
        .getRecommendedCommunities()
        .then((List<AmityCommunity> recommendCommunites) async {
      _amityRecommendCommunities = recommendCommunites;
      notifyListeners();
    }).onError((error, stackTrace) async {
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  void joinCommunity(String communityId,
      {CommunityListType? type,
      required void Function(bool isSuccess) callback}) async {
    AmitySocialClient.newCommunityRepository()
        .joinCommunity(communityId)
        .then((value) {
      if (type != null) {
        refreshCommunity(type);
      }

      notifyListeners();
      callback(true); // Calling the callback with success status
    }).onError((error, stackTrace) async {
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  Future<void> leaveCommunity(String communityId,
      {CommunityListType? type,
      required void Function(bool isSuccess) callback}) async {
    AmitySocialClient.newCommunityRepository()
        .leaveCommunity(communityId)
        .then((value) {
      if (type != null) {
        refreshCommunity(type);
      }
      showCommunityToastMessage(
          "Successfully left the community");
      notifyListeners();
      callback(true); // Calling the callback with success status
    }).onError((error, stackTrace) async {
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
      callback(false); // Calling the callback with failure status
    });
  }

  void refreshCommunity(CommunityListType type) {
    switch (type) {
      case CommunityListType.my:
        initAmityMyCommunityList();
        break;
      case CommunityListType.recommend:
        initAmityRecommendCommunityList();
        break;
      case CommunityListType.trending:
        initAmityTrendingCommunityList();
        break;
      default:
        break;
    }
  }

  void initAmityMyCommunityList() async {
    log("initAmityMyCommunityList");
    if (_amityMyCommunities.isNotEmpty) {
      _amityMyCommunities.clear();
      notifyListeners();
    }

    AmitySocialClient.newCommunityRepository()
        .getCommunities()
        .filter(AmityCommunityFilter.MEMBER)
        .sortBy(AmityCommunitySortOption.LAST_CREATED)
        .includeDeleted(false)
        .getPagingData(limit: 100)
        .then((value) {
      _amityMyCommunities = value.data;
      notifyListeners();
    });
  }

  Future<AmityCommunity> getAmityCommunity(String communityId) async {
    var commuObj = await AmitySocialClient.newCommunityRepository()
        .getCommunity(communityId);
    return commuObj;
  }

  AmityImage? amityImages;
  File? pickedFile;

  Future addFile() async {
    final XFile? xFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      pickedFile = File(xFile.path);
      notifyListeners();
      AmityLoadingDialog.showLoadingDialog();
      //log(xFile.path);

      AmityCoreClient.newFileRepository()
          .uploadImage(pickedFile!)
          .stream
          .listen((amityUploadResult) {
        amityUploadResult.when(
          progress: (uploadInfo, cancelToken) {
            int progress = uploadInfo.getProgressPercentage();
            log(progress.toString());
          },
          complete: (file) {
            //check if the upload result is complete
            log("complete");
            AmityLoadingDialog.hideLoadingDialog();
            final AmityImage uploadedImage = file;
            amityImages = uploadedImage;
            //proceed result with uploadedImage
          },
          error: (error) async {
            final AmityException amityException = error;
            //handle error
            await AmityDialog().showAlertErrorDialog(
                title: "Error!", message: error.toString());
          },
          cancel: () {
            //upload is cancelled
          },
        );
      });
    }
  }

  XFile? _seletedFIle;
  Future selectFile() async {
    _seletedFIle = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (_seletedFIle != null) {
      pickedFile = File(_seletedFIle!.path);
      notifyListeners();

      //log(xFile.path);
    }
  }

  Future<void> uploadSelectedFileToAmity() async {
    final completer = Completer<void>();
    if (pickedFile != null) {
      AmityCoreClient.newFileRepository()
          .uploadImage(pickedFile!)
          .stream
          .listen(
        (amityUploadResult) {
          amityUploadResult.when(
            progress: (uploadInfo, cancelToken) {
              int progress = uploadInfo.getProgressPercentage();
              log(progress.toString());
            },
            complete: (file) {
              //check if the upload result is complete
              log("complete");
              final AmityImage uploadedImage = file;
              amityImages = uploadedImage;
              //proceed result with uploadedImage
              completer.complete();
            },
            error: (error) async {
              final AmityException amityException = error;
              //handle error
              await AmityDialog().showAlertErrorDialog(
                title: "Error!",
                message: error.toString(),
              );
              completer.completeError(error);
            },
            cancel: () {
              //upload is cancelled
              completer.completeError(Exception('Upload cancelled'));
            },
          );
        },
      );
    } else {
      completer.complete();
    }

    // Wait for the completer to complete, which happens in the listener above.
    return completer.future;
  }

  void deleteCommunity(String communityId, {required Function(bool) callback}) {
    AmitySocialClient.newCommunityRepository()
        .deleteCommunity(communityId)
        .then((value) {
      //success
      _amityMyCommunities
          .removeWhere((element) => element.communityId == communityId);
      AmitySuccessDialog.showTimedDialog("Community deleted");
      notifyListeners(); // To update the UI after removing the community

      callback(true); // Success status
    }).onError((error, stackTrace) async {
      //handle error
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
      callback(false); // Failure status
    });
  }

  void configPostReview(
      {required String communityId,
      required bool isEnabled,
      required bool ispublic,
      required}) {
    AmitySocialClient.newCommunityRepository()
        .updateCommunity(communityId)
        .isPublic(ispublic)
        .postSetting(isEnabled
            ? AmityCommunityPostSettings.ADMIN_REVIEW_POST_REQUIRED
            : AmityCommunityPostSettings.ANYONE_CAN_POST)
        .update()
        .then((value) {
      //handle result
      log("success");
    }).onError((error, stackTrace) async {
      //handle error
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  void configStoryCommentEnabled(
      {required String communityId,
      required bool isEnabled,
      required bool ispublic,
      required}) {
    AmitySocialClient.newCommunityRepository()
        .updateCommunity(communityId)
        .isPublic(ispublic)
        .storySettings( isEnabled
            ? AmityCommunityStorySettings(allowComment: true)
            : AmityCommunityStorySettings(allowComment: false))
        .update()
        .then((value) {
      //handle result
      log("success");
    }).onError((error, stackTrace) async {
      //handle error
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  Future<void> addMembers(String communityId, List<String> userIds) async {
    await AmitySocialClient.newCommunityRepository()
        .membership(communityId)
        .addMembers(userIds)
        .then((members) {})
        .onError((error, stackTrace) async {
      //handle error
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }
}
