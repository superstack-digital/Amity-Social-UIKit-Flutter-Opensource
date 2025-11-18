import 'dart:developer';

import 'package:amity_sdk/amity_sdk.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app_padel/features/community/data/repositories/community_repository.dart';

class MyCommunityVM with ChangeNotifier {
  // Existing members...

  final scrollcontroller = ScrollController();
  bool loadingNextPage = false;

  // The list of communities.
  final List<AmityCommunity> _amityCommunities = [];
  final List<AmityCommunity> _amityCommunitiesForFeed = [];

  // The controller for handling pagination.
  // late PagingController<AmityCommunity> _communityController;
  late CommunityLiveCollection communityLiveCollection;
  late CommunityLiveCollection communityFeedLiveCollection;

  // Getter for _amityCommunities for external classes to use.
  List<AmityCommunity> get amityCommunities => _amityCommunities;

  List<AmityCommunity> get amityCommunitiesForFeed => _amityCommunitiesForFeed;
  final textEditingController = TextEditingController();

  Future<void> initMyCommunity([String? keyword]) async {
    final repository = AmitySocialClient.newCommunityRepository()
        .getCommunities()
        .filter(AmityCommunityFilter.MEMBER)
        .includeDeleted(false);

    if (keyword != null && keyword.isNotEmpty) {
      repository.withKeyword(
          keyword); // Add keyword filtering only if keyword is provided and not empty
    }

    communityLiveCollection = repository.getLiveCollection(pageSize: 50);
    communityLiveCollection
        .getStreamController()
        .stream
        .listen((event) {
      _amityCommunities.clear();
      _amityCommunities.addAll(event);

      notifyListeners();
    }).onError((error, stackTrace) {
      log("error:${error.error.toString()}");
      // await AmityDialog().showAlertErrorDialog(
      //     title: "Error!",
      //     message: _communityController.error.toString());
    });
    communityLiveCollection.loadNext();
    scrollcontroller.removeListener(() {});
    scrollcontroller.addListener(loadNextPage);
  }

  Future<void> initMyCommunityFeed() async {
    final repository = AmitySocialClient.newCommunityRepository()
        .getCommunities()
        .filter(AmityCommunityFilter.MEMBER)
        .sortBy(AmityCommunitySortOption.DISPLAY_NAME)
        .includeDeleted(false);

    communityFeedLiveCollection = repository.getLiveCollection(pageSize: 50);
    communityFeedLiveCollection
        .getStreamController()
        .stream
        .listen((event) {
      _amityCommunitiesForFeed.clear();
      _amityCommunitiesForFeed.addAll(event);

      notifyListeners();
    }).onError((error, stackTrace) {
      // log("error:${error.error.toString()}");
      // await AmityDialog().showAlertErrorDialog(
      //     title: "Error!",
      //     message: _communityController.error.toString());
    });
    communityFeedLiveCollection.loadNext();
  }

  void loadNextPage() async {
    if ((scrollcontroller.position.pixels >
        scrollcontroller.position.maxScrollExtent - 800)) {
      print("hasMore: ${communityLiveCollection.hasNextPage()}");
    }
    if ((scrollcontroller.position.pixels >
        scrollcontroller.position.maxScrollExtent - 800) &&
        communityLiveCollection.hasNextPage() &&
        !loadingNextPage) {
      loadingNextPage = true;
      notifyListeners();
      log("loading Next Page...");

      await communityLiveCollection.loadNext().then((value) {
        loadingNextPage = false;
        notifyListeners();
      });
    }
  }
}

class SearchCommunityVM with ChangeNotifier {
  // Existing members...

  final scrollcontroller = ScrollController();
  bool loadingNextPage = false;

  // The list of communities.
  final List<AmityCommunity> _amityCommunities = [];

  // Getter for _amityCommunities for external classes to use.
  List<AmityCommunity> get amityCommunities => _amityCommunities;
  final textEditingController = TextEditingController();

  // The controller for handling pagination.
  late PagingController<AmityCommunity> communityController;

  final List<AmityCommunity> allCommunities = [];

  void clearSearch() {
    amityCommunities.clear();
  }

  void getAllCommunities(List<String>? tags) async {
    allCommunities.clear();
    final res = await AmitySocialClient.newCommunityRepository().getCommunities()
        .sortBy(AmityCommunitySortOption.DISPLAY_NAME)
        .filter(AmityCommunityFilter.ALL)
        .tags(tags != null ? tags : [])
        .includeDeleted(false).getPagingData(limit: 99);
    res.data.sort((a, b) => b.membersCount?.compareTo(a.membersCount ?? 0) ?? 0);
    allCommunities.addAll(res.data);
    notifyListeners();
  }

  void getAllCommunitiesWithLocation({
    List<String>? communityIds,
  }) async {
    allCommunities.clear();

    try {
      List<AmityCommunity> communities;

      if (communityIds != null) {
        // Use location-based filtering with provided community IDs
        // If communityIds is empty, it means no communities in that location
        if (communityIds.isEmpty) {
          communities = [];
        } else {
          // Call external API/repository to get communities by IDs
          communities = await _getCommunitiesByIds(communityIds);
        }
      } else {
        // Use old filtering method without location
        final res = await AmitySocialClient.newCommunityRepository()
            .getCommunities()
            .sortBy(AmityCommunitySortOption.DISPLAY_NAME)
            .filter(AmityCommunityFilter.ALL)
            .includeDeleted(false)
            .getPagingData(limit: 99);
        communities = res.data;
      }

      // Sort by members count in descending order
      communities.sort((a, b) => b.membersCount?.compareTo(a.membersCount ?? 0) ?? 0);

      allCommunities.addAll(communities);
      notifyListeners();
    } catch (e) {
      log("Error in getAllCommunitiesWithLocation: $e");
      allCommunities.clear();
      notifyListeners();
    }
  }

  // Helper method to get communities by IDs
  Future<List<AmityCommunity>> _getCommunitiesByIds(List<String> communityIds) async {
    return await CommunityRepository.getInstance().getCommunitiesByIds(communityIds);
  }

  // Search in allCommunities (client-side search)
  void searchInAllCommunities(String? keyword) {
    amityCommunities.clear();

    if (keyword == null || keyword.isEmpty) {
      // No keyword - show all communities
      amityCommunities.addAll(allCommunities);
    } else {
      // Filter communities by keyword (search in displayName)
      final filtered = allCommunities.where((community) {
        final displayName = community.displayName?.toLowerCase() ?? '';
        final searchKeyword = keyword.toLowerCase();
        return displayName.contains(searchKeyword);
      }).toList();

      amityCommunities.addAll(filtered);
    }

    notifyListeners();
  }

  Future<void> initSearchCommunity([String? keyword, List<String>? communityIds]) async {
    // If communityIds is provided, use client-side search in allCommunities
    if (communityIds != null) {
      // Client-side search logic
      searchInAllCommunities(keyword);
      return;
    }

    // Otherwise, use old server-side search logic
    communityController = PagingController(
      pageFuture: (token) {
        final repository = AmitySocialClient.newCommunityRepository()
            .getCommunities()
            .sortBy(AmityCommunitySortOption.FIRST_CREATED)
            .filter(AmityCommunityFilter.ALL)
            .includeDeleted(false);
        if (keyword != null && keyword.isNotEmpty) {
          repository.withKeyword(
              keyword); // Add keyword filtering only if keyword is provided and not empty
        }
        return repository.getPagingData(token: token, limit: 99);
      },
      pageSize: 99,
    )
      ..addListener(
            () async {
          if (communityController.error == null) {
            amityCommunities.clear();
            // Sort by membersCount in descending order
            communityController.loadedItems.sort((a, b) =>
            b.membersCount?.compareTo(a.membersCount ?? 0) ?? 0);

            amityCommunities.addAll(communityController.loadedItems);
            // Call any additional methods like sortedUserListWithHeaders here if needed.
            notifyListeners();
          } else {
            log("error: ${communityController.error.toString()}");
            // await AmityDialog().showAlertErrorDialog(
            //     title: "Error!", message: communityController.error.toString());
          }
        },
      );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      communityController.fetchNextPage();
    });

    scrollcontroller.removeListener(() {});
    scrollcontroller.addListener(loadNextPage);
  }

  void loadNextPage() async {
    if ((scrollcontroller.position.pixels >
        scrollcontroller.position.maxScrollExtent - 800)) {
      print("hasMore: ${communityController.hasMoreItems}");
    }
    if ((scrollcontroller.position.pixels >
        scrollcontroller.position.maxScrollExtent - 800) &&
        communityController.hasMoreItems &&
        !loadingNextPage) {
      loadingNextPage = true;
      notifyListeners();
      log("loading Next Page...");
      // Call any additional methods like sortedUserListWithHeaders here if needed.
      await communityController.fetchNextPage().then((value) {
        loadingNextPage = false;
        notifyListeners();
      });
    }
  }
}
