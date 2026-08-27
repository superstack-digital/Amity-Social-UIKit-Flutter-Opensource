import 'dart:developer';

import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/view/user/medie_component.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../native_social_override.dart';
import '../../components/alert_dialog.dart';
import 'package:mobile_app_padel/features/community/data/models/event.dart';
import 'package:mobile_app_padel/features/community/data/repositories/community_repository.dart';
import 'package:mobile_app_padel/features/community/data/models/community_settings.dart';
import 'package:mobile_app_padel/features/community/data/repositories/community_settings_repository.dart';
import 'package:mobile_app_padel/app_controller.dart';
import 'package:mobile_app_padel/shared/constants.dart';
import 'package:mobile_app_padel/shared/feature_flags.dart';
import 'package:mobile_app_padel/shared/functions.dart';

enum CommunityTabType {
  timeline,
  events,
  coaching,
  standings,
  rankings,
  matches,
  gallery,
}

class CommuFeedVM extends ChangeNotifier {
  MediaType _selectedMediaType = MediaType.photos;
  void doSelectMedieType(MediaType mediaType) {
    _selectedMediaType = mediaType;
    log(_selectedMediaType.toString());
    notifyListeners();
  }

  TabController? userFeedTabController;
  void changeTab() {
    notifyListeners();
  }

  MediaType getMediaType() => _selectedMediaType;
  bool isCurrentUserIsAdmin = false;
  bool isLeagueCommunity = false;
  bool isAcademyCommunity = false;
  int? latestCompetitionId;
  bool isLoadingStandings = false;
  final _amityCommunityFeedPosts = <AmityPost>[];

  /// True only once a native community-feed fetch has actually succeeded for
  /// *this* screen instance — deliberately not the same thing as
  /// NativeSocialOverride.isActive, which just means the user is enrolled
  /// in the feed cohort generally. If a native fetch fails and
  /// initAmityCommunityFeed falls back to _controllerCommu.fetchNextPage(),
  /// that Amity result has to reach _amityCommunityFeedPosts too — guarding
  /// the listener on the global isActive instead of this would silently
  /// swallow the fallback's own results, leaving the timeline blank
  /// forever with nothing to show and nothing to explain why.
  bool _usingNativeFeed = false;

  var _communityEventList = <Event>[];

  late PagingController<AmityPost> _controllerCommu;

  final _amityCommunityImageFeedPosts = <AmityPost>[];

  late PagingController<AmityPost> _controllerImageCommu;

  final _amityCommunityVideoFeedPosts = <AmityPost>[];

  late PagingController<AmityPost> _controllerVideoCommu;

  final scrollcontroller = ScrollController();

  final _amityCommunityPendingFeedPosts = <AmityPost>[];

  late PagingController<AmityPost> _controllerPendingPost;

  final pendingScrollcontroller = ScrollController();
  final isLoading = ValueNotifier<bool>(false);

  AmityCommunity? community;
  List<AmityPost> getCommunityPosts() {
    return _amityCommunityFeedPosts;
  }

  List<AmityPost> getCommunityImagePosts() {
    return _amityCommunityImageFeedPosts;
  }

  List<AmityPost> getCommunityVideoPosts() {
    return _amityCommunityVideoFeedPosts;
  }

  List<AmityPost> getCommunityPendingPosts() {
    return _amityCommunityPendingFeedPosts;
  }

  void addLoadingTime({int miliseconds = 3000}) {
    isLoading.value = true;
    notifyListeners();
    Future.delayed(Duration(milliseconds: miliseconds), () {
      isLoading.value = false;
      notifyListeners();
    });
  }

  List<Event> getCommunityEventList() {
    return _communityEventList;
  }

  List<Event> get _setpointGatedEvents => _communityEventList;

  /// Events tab: everything that is NOT a group coaching session.
  List<Event> get communityEventsForEventsTab =>
      _setpointGatedEvents.where((e) => !e.isGroupCoaching).toList();

  /// Coaching Sessions tab: any group coaching event (native TPS or Setpoint-mirrored).
  List<Event> get communityCoachingSessions =>
      _setpointGatedEvents.where((e) => e.isGroupCoaching).toList();

  CommunitySettings? _settings;
  CommunitySettings? get settings => _settings;

  List<CommunityTabType> get activeTabs {
    final tabs = [CommunityTabType.timeline];

    final eventsEnabled = _settings?.isEventsEnabled ?? true;
    if (eventsEnabled) {
      tabs.add(CommunityTabType.events);
    }

    final showCoaching = AppController.isCommunityCoachingTabEnabled &&
        (_settings != null ? _settings!.isCoachingEnabled : isAcademyCommunity);
    if (showCoaching) {
      tabs.add(CommunityTabType.coaching);
    }

    final competitionsEnabled = _settings?.isCompetitionsEnabled ?? true;
    if (isLeagueCommunity && competitionsEnabled) {
      tabs.add(CommunityTabType.standings);
    }

    final rankingsEnabled = _settings?.isRankingEnabled ?? true;
    if (rankingsEnabled) {
      tabs.add(CommunityTabType.rankings);
    }

    final matchesEnabled = _settings?.isMatchesEnabled ?? true;
    if (matchesEnabled) {
      tabs.add(CommunityTabType.matches);
    }

    tabs.add(CommunityTabType.gallery);

    return tabs;
  }

  bool get showCoachingSessionsTab =>
      activeTabs.contains(CommunityTabType.coaching);

  int get coachingSessionsTabIndex =>
      activeTabs.indexOf(CommunityTabType.coaching);

  int get standingsTabIndex => activeTabs.indexOf(CommunityTabType.standings);

  int get rankingsTabIndex => activeTabs.indexOf(CommunityTabType.rankings);

  int get matchesTabIndex => activeTabs.indexOf(CommunityTabType.matches);

  int get galleryTabIndex => activeTabs.indexOf(CommunityTabType.gallery);

  int get communityDetailTabCount => activeTabs.length;

  void addPostToFeed(AmityPost post) {
    _amityCommunityFeedPosts.insert(0, post);
    notifyListeners();
  }

  Future<void> getUpcomingEvents(String communityId) async {
    try {
      _communityEventList.clear();
      notifyListeners();
      final data = await CommunityRepository.getInstance()
          .getAllCommunityUpcomingEvents(communityId);
      _communityEventList.addAll([...data]);
      notifyListeners();
    } catch (e) {
      // Keep partial results; do not leave the tab blank after a fetch failure.
      debugPrint('getUpcomingEvents failed for $communityId: $e');
    }
  }

  int postCount = 0;
  Future<void> getPostCount(AmityCommunity community) async {
    // Reset per-community state to avoid stale data from previous community
    isLeagueCommunity = false;
    isAcademyCommunity = false;
    latestCompetitionId = null;
    isLoadingStandings = false;
    _settings = null;
    notifyListeners();

    getUpcomingEvents(community.communityId!);

    isAcademyCommunity = await CommunityRepository.getInstance()
        .isSetpointAcademyCommunity(community.communityId!);

    try {
      _settings = await CommunitySettingsRepository.getInstance()
          .getSettings(community.communityId!);
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to fetch community settings: $e");
      _settings = null;
      notifyListeners();
    }

    await AmitySocialClient.newCommunityRepository()
        .getCommunity(community.communityId!)
        .then((value) {
      community = value;
      isLeagueCommunity = (community?.categories
                  ?.indexWhere((item) => item?.name == "League") ??
              -1) >
          -1;
      notifyListeners();
    });

    if (isLeagueCommunity) {
      isLoadingStandings = true;
      notifyListeners();
      latestCompetitionId = await CommunityRepository.getInstance()
          .getLatestCompetitionIdByCommunity(community.communityId!);
      isLoadingStandings = false;
      notifyListeners();
    }
    community.getPostCount(AmityFeedType.PUBLISHED).then((value) async {
      //success
      postCount = value;

      // Update UI
    }).onError((error, stackTrace) {
      // Handle error
    });
  }

  int reviewingPostCount = 0;
  void getReviewingPostCount(AmityCommunity community) {
    community.getPostCount(AmityFeedType.REVIEWING).then((value) {
      //success
      reviewingPostCount = value;
      // Update UI
    }).onError((error, stackTrace) {
      // Handle error
    });
  }

  Future<void> initAmityCommunityFeed(String communityId) async {
    _usingNativeFeed = false;

    //inititate the PagingController
    _controllerCommu = PagingController(
      pageFuture: (token) => AmitySocialClient.newFeedRepository()
          .getCommunityFeed(communityId)
          //feedType could be AmityFeedType.PUBLISHED, AmityFeedType.REVIEWING, AmityFeedType.DECLINED
          .feedType(AmityFeedType.PUBLISHED)
          .includeDeleted(false)
          .getPagingData(token: token, limit: 20),
      pageSize: 20,
    )..addListener(
        () async {
          // TPS-0 native social pilot: same live-collection leak as
          // GlobalFeedBloc's own paging controller — Amity's collection can
          // push updates via its own socket independent of fetchNextPage(),
          // so this must stay silent whenever native is actually serving
          // this community's feed. Deliberately _usingNativeFeed, not the
          // global NativeSocialOverride.isActive: that only means the user
          // is enrolled in the cohort, not that the native fetch below
          // succeeded for *this* community — guarding on the global flag
          // swallowed this listener's own fallback results too, leaving
          // the timeline blank with nothing to show and nothing to explain
          // why.
          if (_usingNativeFeed) return;
          if (kDebugMode) log("initAmityCommunityFeed ID: $communityId");
          if (_controllerCommu.error == null) {
            //handle results, we suggest to clear the previous items
            //and add with the latest _controller.loadedItems
            _amityCommunityFeedPosts.clear();
            _amityCommunityFeedPosts.addAll(_controllerCommu.loadedItems);

            //update widgets
            notifyListeners();
          } else {
            //error on pagination controller
            // await AmityDialog().showAlertErrorDialog(
            //     title: "Error!", message: _controllerCommu.error.toString());
            //update widgets
          }
        },
      );

    // TPS-0 native social pilot: give install() a short window to finish
    // deciding isActive first — same race NativeSocialOverride.ready guards
    // against in GlobalFeedInit. A community screen opens well after login
    // in practice (the user has to navigate there), so this rarely actually
    // waits; it's cheap insurance against a fast navigation right after
    // cold start.
    await NativeSocialOverride.ready
        .timeout(const Duration(seconds: 3), onTimeout: () {});

    if (NativeSocialOverride.isActive &&
        NativeSocialOverride.communityFeedFetcher != null) {
      try {
        final native = await NativeSocialOverride.communityFeedFetcher!(
            communityId: communityId, limit: 20);
        _usingNativeFeed = true;
        _amityCommunityFeedPosts.clear();
        _amityCommunityFeedPosts.addAll(native);
        notifyListeners();
      } catch (e) {
        // Never strand the user on a blank timeline: fall back to Amity
        // for this community exactly as before the pilot existed.
        // _usingNativeFeed stays false, so the listener above actually
        // processes this fallback's results instead of discarding them.
        debugPrint('native community feed failed for $communityId: $e');
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          _controllerCommu.fetchNextPage();
        });
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _controllerCommu.fetchNextPage();
      });
    }

    _attachFeedScrollListener();

    // The PagingController above already fetches this exact first page; the
    // second unpaginated request that used to live here doubled the network
    // cost of opening a community and raced the paged result (the two queries
    // did not even use the same filters, so whichever landed last won).
    await checkIsCurrentUserIsAdmin(communityId);
  }

  Future<void> initAmityPendingCommunityFeed(
      String communityId, AmityFeedType amityFeedType) async {
    //inititate the PagingController
    _controllerPendingPost = PagingController(
      pageFuture: (token) => AmitySocialClient.newFeedRepository()
          .getCommunityFeed(communityId)
          //feedType could be AmityFeedType.PUBLISHED, AmityFeedType.REVIEWING, AmityFeedType.DECLINED
          .feedType(amityFeedType)
          .includeDeleted(false)
          .getPagingData(token: token, limit: 20),
      pageSize: 20,
    )..addListener(
        () async {
          if (kDebugMode) log(">>>PENDINGListener");
          if (_controllerPendingPost.error == null) {
            //handle results, we suggest to clear the previous items
            //and add with the latest _controller.loadedItems
            _amityCommunityPendingFeedPosts.clear();
            _amityCommunityPendingFeedPosts
                .addAll(_controllerPendingPost.loadedItems);

            //update widgets
            notifyListeners();
          } else {
            //error on pagination controller
            // await AmityDialog().showAlertErrorDialog(
            //     title: "Error!", message: _controllerPendingPost.error.toString());
            //update widgets
          }
        },
      );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controllerPendingPost.fetchNextPage();
    });

    _attachPendingScrollListener();

    // The PagingController above already fetches this exact first page; the
    // second unpaginated request that used to live here doubled the network
    // cost of opening a community and raced the paged result (the two queries
    // did not even use the same filters, so whichever landed last won).
    await checkIsCurrentUserIsAdmin(communityId);
  }

  Future<void> initAmityCommunityVideoFeed(String communityId) async {
    //inititate the PagingController
    _controllerVideoCommu = PagingController(
      pageFuture: (token) => AmitySocialClient.newPostRepository()
          .getPosts()
          .targetCommunity(communityId)
          .types([AmityDataType.VIDEO])
          //feedType could be AmityFeedType.PUBLISHED, AmityFeedType.REVIEWING, AmityFeedType.DECLINED
          .feedType(AmityFeedType.PUBLISHED)
          .getPagingData(token: token, limit: 20),
      pageSize: 20,
    )..addListener(
        () async {
          if (kDebugMode) log("communityListener");
          if (_controllerVideoCommu.error == null) {
            //handle results, we suggest to clear the previous items
            //and add with the latest _controller.loadedItems
            _amityCommunityVideoFeedPosts.clear();
            _amityCommunityVideoFeedPosts
                .addAll(_controllerVideoCommu.loadedItems);

            //update widgets
            notifyListeners();
          } else {
            //error on pagination controller
            // await AmityDialog().showAlertErrorDialog(
            //     title: "Error!", message: _controllerPendingPost.error.toString());
            //update widgets
          }
        },
      );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controllerVideoCommu.fetchNextPage();
    });

    _attachFeedScrollListener();

    // The PagingController above already fetches this exact first page; the
    // second unpaginated request that used to live here doubled the network
    // cost of opening a community and raced the paged result (the two queries
    // did not even use the same filters, so whichever landed last won).
    await checkIsCurrentUserIsAdmin(communityId);
  }

  Future<void> initAmityCommunityImageFeed(String communityId) async {
    isCurrentUserIsAdmin = false;

    //inititate the PagingController
    _controllerImageCommu = PagingController(
      pageFuture: (token) => AmitySocialClient.newPostRepository()
          .getPosts()
          .targetCommunity(communityId)
          .types([AmityDataType.IMAGE])
          .feedType(AmityFeedType.PUBLISHED)
          .includeDeleted(false)
          .getPagingData(token: token, limit: 20),
      pageSize: 20,
    )..addListener(
        () async {
          if (kDebugMode) log("communityListener");
          if (_controllerImageCommu.error == null) {
            _amityCommunityImageFeedPosts.clear();
            _amityCommunityImageFeedPosts
                .addAll(_controllerImageCommu.loadedItems);

            //update widgets
            notifyListeners();
          } else {
            //error on pagination controller
            // await AmityDialog().showAlertErrorDialog(
            //     title: "Error!", message: _controllerImageCommu.error.toString());
            //update widgets
          }
        },
      );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controllerImageCommu.fetchNextPage();
    });

    _attachFeedScrollListener();

    // The PagingController above already fetches this exact first page; the
    // second unpaginated request that used to live here doubled the network
    // cost of opening a community and raced the paged result (the two queries
    // did not even use the same filters, so whichever landed last won).
    await checkIsCurrentUserIsAdmin(communityId);
  }

  /// Re-registering the same tear-off stacks duplicate entries on the
  /// controller, so every feed initialiser used to add another copy of
  /// [loadnextpage]. Detach first so the listener is attached exactly once.
  void _attachFeedScrollListener() {
    scrollcontroller.removeListener(loadnextpage);
    scrollcontroller.addListener(loadnextpage);
  }

  void _attachPendingScrollListener() {
    pendingScrollcontroller.removeListener(loadnextpage);
    pendingScrollcontroller.addListener(loadnextpage);
  }

  void loadnextpage() {
    // TPS-0 native social pilot: native path currently returns a single
    // page (see initAmityCommunityFeed) — without this guard, scrolling to
    // the bottom of a native-sourced timeline would fetch an Amity page 2
    // and mix it into _amityCommunityFeedPosts via the listener above.
    // _usingNativeFeed, not the global isActive — see that field's comment.
    if (_usingNativeFeed) return;
    if ((scrollcontroller.position.pixels ==
            scrollcontroller.position.maxScrollExtent) &&
        _controllerCommu.hasMoreItems) {
      _controllerCommu.fetchNextPage();
    }
  }

  void loadCoomunityMember() {}

  void deletePost(AmityPost post, int postIndex,
      Function(bool success, String message) callback) async {
    AmitySocialClient.newPostRepository()
        .deletePost(postId: post.postId!)
        .then((value) {
      // Find the post by postId and remove it
      int postIndex =
          _amityCommunityFeedPosts.indexWhere((p) => p.postId == post.postId);
      if (postIndex != -1) {
        _amityCommunityFeedPosts.removeAt(postIndex);
        notifyListeners();
        callback(true, "Post deleted successfully.");
      } else {
        callback(false, "Post not found in the list.");
      }
    }).onError((error, stackTrace) async {
      String errorMessage = error.toString();
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: errorMessage);
      callback(false, errorMessage);
    });
  }

  void deletePendingPost(AmityPost post, int postIndex) async {
    log("deleting post....");
    AmitySocialClient.newPostRepository()
        .deletePost(postId: post.postId!)
        .then((value) {
      _amityCommunityPendingFeedPosts.removeAt(postIndex);
      notifyListeners();
    }).onError((error, stackTrace) async {
      await AmityDialog()
          .showAlertErrorDialog(title: "Error!", message: error.toString());
    });
  }

  Future<void> checkIsCurrentUserIsAdmin(String communityId) async {
    log("LOG1 :checkIsCurrentUserIsAdmin");
    await AmitySocialClient.newCommunityRepository()
        .getCurentUserRoles(communityId)
        .then((value) {
      log("LOG1$value");
      for (var role in value!) {
        if (role == "community-moderator") {
          isCurrentUserIsAdmin = true;
        }
      }
      notifyListeners();
    }).onError((error, stackTrace) {
      log("LOG1:$error");
    });
  }

  void acceptPost(
      {required String postId,
      required String communityId,
      required Function(bool) callback}) {
    AmitySocialClient.newPostRepository()
        .reviewPost(postId: postId)
        .approve()
        .then((value) {
      //success
      //optional: to remove the approved post from the current post collection
      //you will need manually remove the approved post from the collection
      //for example :
      _controllerPendingPost.removeWhere((element) => element.postId == postId);
      notifyListeners();
      initAmityCommunityFeed(communityId);
    }).onError((error, stackTrace) {
      print(error);
      //handle error
    });
  }

  void declinePost(
      {required String postId,
      required String communityId,
      required Function(bool) callback}) {
    AmitySocialClient.newPostRepository()
        .reviewPost(postId: postId)
        .decline()
        .then((value) {
      //success
      //optional: to remove the approved post from the current post collection
      //you will need manually remove the approved post from the collection
      //for example :
      _controllerPendingPost.removeWhere((element) => element.postId == postId);
      notifyListeners();
      initAmityCommunityFeed(communityId);
    }).onError((error, stackTrace) {
      print(error);
      //handle error
    });
  }

  void setLoadingValue(bool value) {
    isLoading.value = value;
    notifyListeners();
  }

  void onSwitchToEventsTab() {
    final index = activeTabs.indexOf(CommunityTabType.events);
    if (index != -1) {
      userFeedTabController?.animateTo(index);
    }
    notifyListeners();
  }
}
