import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/components/alert_dialog.dart';
import 'package:amity_uikit_beta_service/components/custom_textfield.dart';
import 'package:amity_uikit_beta_service/view/UIKit/social/category_list.dart';
import 'package:amity_uikit_beta_service/viewmodel/category_viewmodel.dart';
import 'package:amity_uikit_beta_service/viewmodel/community_viewmodel.dart';
import 'package:amity_uikit_beta_service/viewmodel/configuration_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // For using File class
import 'package:mobile_app_padel/features/booking/presentation/screens/search_location_screen.dart';
import 'package:mobile_app_padel/features/booking/data/models/court.dart';
import 'package:mobile_app_padel/features/booking/data/models/search_location.dart';
import 'package:mobile_app_padel/features/booking/data/repositories/booking_repository.dart';
import 'package:mobile_app_padel/features/community/presentation/screens/select_club_screen.dart';
import 'package:mobile_app_padel/features/community/presentation/screens/select_competitions_screen.dart';
import 'package:get/get.dart';


enum CommunityType { public, private }

class AmityEditCommunityScreen extends StatefulWidget {
  final AmityCommunity community;

  const AmityEditCommunityScreen(this.community, {Key? key}) : super(key: key);

  @override
  AmityEditCommunityScreenState createState() =>
      AmityEditCommunityScreenState();
}

class AmityEditCommunityScreenState extends State<AmityEditCommunityScreen> {
  CommunityType communityType = CommunityType.public;
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _clubsController = TextEditingController();
  final TextEditingController _competitionsController = TextEditingController();


  bool _isPublic = true;
  RxList<int> selectedClubs = <int>[].obs;
  RxList<int> selectedCompetitions = <int>[].obs;
  String clubIds = "";
  String competitionIds = "";

  // Store selected location with coordinates
  dynamic _selectedLocation;

  @override
  void initState() {
    super.initState();

    final communityProvider = Provider.of<CommunityVM>(context, listen: false);
    communityProvider.pickedFile = null;
    _displayNameController.text = widget.community.displayName ?? "";
    _descriptionController.text = widget.community.description ?? "";
    _locationController.text = widget.community.metadata?["location"] ?? "";
    _clubsController.text =
    "${widget.community.metadata?["club_ids"]?.length.toString() ?? "0"} clubs selected";

    final competitionLength = widget.community.metadata?["competition_ids"]?.length ?? 0;
    if(competitionLength > 0){
      _competitionsController.text =
        "${competitionLength} competition${competitionLength > 1 ? "s" : ""} selected";
    } else {
      _competitionsController.text = "Link competitions with community";
    }
    selectedClubs.value =
        ((widget.community.metadata?["club_ids"] ?? [] )as List<dynamic>).map((item) =>
            int.parse(item.toString())).toList() ?? [];
    selectedCompetitions.value =
        ((widget.community.metadata?["competition_ids"] ?? [] )as List<dynamic>).map((item) =>
            int.parse(item.toString())).toList() ?? [];


    var categories = widget.community.categories;
    if (categories != null && categories.isNotEmpty) {
      _categoryController.text = categories[0]!.name ?? "No Name";
      final categoryId = categories[0]?.categoryId;
      if (categoryId != null) {
        Provider.of<CategoryVM>(context, listen: false).setSelectedCategory(categoryId);
      }
    } else {
      _categoryController.text = "No Category";
    }
    communityType = widget.community.isPublic!
        ? CommunityType.public
        : CommunityType.private;
    _isPublic = widget.community.isPublic!;

    // Initialize selected location from metadata if available
    if (widget.community.metadata?["latitude"] != null &&
        widget.community.metadata?["longitude"] != null) {
      _selectedLocation = {
        'latitude': widget.community.metadata?["latitude"],
        'longitude': widget.community.metadata?["longitude"],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AmityCommunity>(
        stream: widget.community.listen.stream,
        builder: (context, snapshot) {
          var community = snapshot.data ?? widget.community;
          return Scaffold(
            backgroundColor: Provider
                .of<AmityUIConfiguration>(context)
                .appColors
                .baseBackground,
            appBar: AppBar(
              title: Text(
                "Edit Community",
                style: Provider
                    .of<AmityUIConfiguration>(context)
                    .titleTextStyle
                    .copyWith(
                    color: Provider
                        .of<AmityUIConfiguration>(context)
                        .appColors
                        .base),
              ),
              backgroundColor: Colors.transparent,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.chevron_left,
                    color: Provider
                        .of<AmityUIConfiguration>(context)
                        .appColors
                        .base,
                    size: 30),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    AmityLoadingDialog.showLoadingDialog();
                    var imageProvider =
                    Provider.of<CommunityVM>(context, listen: false);
                    await imageProvider.uploadSelectedFileToAmity();
                    await Provider.of<CommunityVM>(context, listen: false)
                        .updateCommunity(
                        community.communityId ?? "",
                        imageProvider.amityImages ?? community.avatarImage,
                        _displayNameController.text,
                        _descriptionController.text,
                        Provider.of<CategoryVM>(context, listen: false)
                            .getSelectedCategory(),
                       _isPublic,
                      selectedClubs?.map((e) => e).toList() ?? [],
                      _locationController.text,
                      _selectedLocation is Map ? _selectedLocation['latitude'] : _selectedLocation?.latitude,
                      _selectedLocation is Map ? _selectedLocation['longitude'] : _selectedLocation?.longitude,
                      community.metadata?["channel_id"],
                      community,
                      selectedCompetitions?.map((e) => e).toList() ?? [],
                    );
                    AmityLoadingDialog.hideLoadingDialog();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Save",
                    style: TextStyle(
                      color: Provider
                          .of<AmityUIConfiguration>(context)
                          .appColors
                          .primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(0.0),
              child: ListView(
                children: [
                  GestureDetector(
                    onTap: () {
                      Provider.of<CommunityVM>(context, listen: false)
                          .selectFile();
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: MediaQuery
                              .of(context)
                              .size
                              .width * 0.7,
                          decoration: BoxDecoration(
                              color: Provider
                                  .of<AmityUIConfiguration>(context)
                                  .appColors
                                  .primaryShade3,
                              image: DecorationImage(
                                image: getCustomImageProvider(widget
                                    .community.avatarImage
                                    ?.getUrl(AmityImageSize.LARGE)),
                                fit: BoxFit.cover,
                              )),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(
                                  0.4), // Applying a 40% dark filter to the entire container
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(
                                5.0), // Adding rounded corners
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize
                                .min, // Making the row only as wide as the children need
                            children: [
                              Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ), // Adding a camera icon
                              SizedBox(
                                  width:
                                  8.0), // Adding some space between the icon and the text
                              Text(
                                'Upload image',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        TextFieldWithCounter(
                          controller: _displayNameController,
                          title: 'Community name',
                          hintText: 'Name your community',
                          maxCharacters: 30,
                        ),
                        const SizedBox(height: 16.0),
                        TextFieldWithCounter(
                          isRequired: false,
                          controller: _descriptionController,
                          title: 'About',
                          hintText: 'Enter description',
                          maxCharacters: 180,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                        ),
                        const SizedBox(height: 16.0),
                        TextFieldWithCounter(
                            isRequired: false,
                            controller: _locationController,
                            title: 'Location',
                            showChevron: true,
                            hintText: 'Select location',
                            maxCharacters: 180,
                            showCount: false,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            onTap: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                  const SearchLocationScreen(title: 'Location'),
                                ),
                              );

                              if (result != null) {
                                _locationController.text = result.mainText;

                                // Fetch lat/long if not already present
                                if ((result.latitude == null || result.longitude == null) &&
                                    result.placeId.isNotEmpty) {
                                  try {
                                    final latLng = await BookingRepository.getInstance()
                                        .getLocationDetails(result.placeId);
                                    _selectedLocation = SearchLocation(
                                      mainText: result.mainText,
                                      placeId: result.placeId,
                                      description: result.description,
                                      latitude: latLng.latitude,
                                      longitude: latLng.longitude,
                                    );
                                  } catch (e) {
                                    print("Failed to fetch location details: $e");
                                    _selectedLocation = result;
                                  }
                                } else {
                                  _selectedLocation = result;
                                }
                              }
                            }
                        ),
                        const SizedBox(height: 16.0),
                        TextFieldWithCounter(
                            isRequired: false,
                            controller: _clubsController,
                            title: 'Link clubs',
                            showChevron: true,
                            showCount: false,
                            hintText: 'Link clubs to show their matches',
                            maxCharacters: 180,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            onTap: () {
                              Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SelectClubScreen(isMultiSelect: true,
                                            selectedClubIds: selectedClubs.toList(),
                                            onResult: (result) {
                                              if (result != null) {
                                                _clubsController.text =
                                                "${result.length} clubs selected";
                                                selectedClubs.assignAll(
                                                    result.map((e) => e).toList());
                                              }
                                            }
                                        ),
                                  ));
                            }
                        ),
                        const SizedBox(height: 16.0),
                        TextFieldWithCounter(
                            isRequired: false,
                            controller: _competitionsController,
                            title: 'Link competitions',
                            showChevron: true,
                            showCount: false,
                            hintText: 'Link competitions with community',
                            maxCharacters: 180,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            onTap: () {
                              Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SelectCompetitionScreen(isMultiSelect: true,
                                            selectedCompetitionIds: selectedCompetitions.toList(),
                                            onResult: (result) {
                                              if (result != null) {
                                                _competitionsController.text =
                                                "${result.length} competition${result.length > 1 ? "s" : ""} selected";
                                                selectedCompetitions.assignAll(
                                                    result.map((e) => e).toList());
                                              }
                                            }
                                        ),
                                  ));
                            }
                        ),
                        const SizedBox(height: 16.0),
                        TextFieldWithCounter(
                          controller: _categoryController,
                          title: 'Category',
                          hintText: 'Select category',
                          showCount: false,
                          maxCharacters: 30,
                          onTap: () async {
                            String? category =
                            await Navigator.of(context).push<String>(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      CategoryList(
                                        categoryTextController:
                                        _categoryController,
                                      )),
                            );
                            if (category != null) {
                              _categoryController.text = category;
                            }
                          },
                        ),
                        const SizedBox(height: 16.0),
                        Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.public),
                              ),
                              title: Text(
                                'Public',
                                style: TextStyle(
                                    color: Provider
                                        .of<AmityUIConfiguration>(
                                        context)
                                        .appColors
                                        .base),
                              ),
                              subtitle: Text(
                                'Anyone can join, view and search this community',
                                style: TextStyle(
                                    color: Provider
                                        .of<AmityUIConfiguration>(
                                        context)
                                        .appColors
                                        .base),
                              ),
                              trailing: Radio(
                                activeColor:
                                Provider
                                    .of<AmityUIConfiguration>(context)
                                    .appColors
                                    .primary,
                                value: true,
                                groupValue: _isPublic,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isPublic = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.lock),
                              ),
                              title: Text(
                                'Private',
                                style: TextStyle(
                                    color: Provider
                                        .of<AmityUIConfiguration>(
                                        context)
                                        .appColors
                                        .base),
                              ),
                              subtitle: Text(
                                'Only members invited by the moderators can join, view and search this community',
                                style: TextStyle(
                                    color: Provider
                                        .of<AmityUIConfiguration>(
                                        context)
                                        .appColors
                                        .base),
                              ),
                              trailing: Radio(
                                activeColor:
                                Provider
                                    .of<AmityUIConfiguration>(context)
                                    .appColors
                                    .primary,
                                value: true,
                                groupValue: !_isPublic,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isPublic = !value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  getCustomImageProvider(String? url) {
    var imageProvider = Provider.of<CommunityVM>(context, listen: true);

    if ((imageProvider.pickedFile != null)) {
      return FileImage(Provider
          .of<CommunityVM>(context)
          .pickedFile!);
    }
    if (url != null) {
      return NetworkImage(url);
    } else {
      return const AssetImage("assets/images/IMG_5637.JPG",
          package: 'amity_uikit_beta_service');
    }
  }
}
