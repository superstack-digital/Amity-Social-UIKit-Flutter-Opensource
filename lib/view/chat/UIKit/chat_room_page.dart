import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/viewmodel/chat_room_viewmodel.dart';
import 'package:amity_uikit_beta_service/viewmodel/configuration_viewmodel.dart';
import 'package:animation_wrappers/animations/faded_slide_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ChatRoomPage extends StatefulWidget {
  final String channelId;

  const ChatRoomPage({
    super.key,
    required this.channelId,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {

  ChatRoomVM? provider;

  @override
  void initState() {
    Provider.of<ChatRoomVM>(context, listen: false)
        .initSingleChannel(widget.channelId);

    super.initState();
  }

  final startTimeFormat = DateFormat('dd MMM, hh:mma');

  @override
  Widget build(BuildContext context) {
    final metadata = Provider
        .of<ChatRoomVM>(context)
        .channel
        ?.metadata;
    final myAppBar = AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: Provider
          .of<AmityUIConfiguration>(context)
          .messageRoomConfig
          .backgroundColor,
      leadingWidth: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Icon(Icons.chevron_left,
                  color:
                  Provider
                      .of<AmityUIConfiguration>(context)
                      .primaryColor,
                  size: 30)),
          Container(
            height: 45,
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: const BoxDecoration(shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(children: [if(metadata?["avatar"] != null)
              ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                      metadata?["avatar"],
                      height: 32, width: 32)),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Provider
                        .of<ChatRoomVM>(context)
                        .channel == null
                        ? ""
                        : Provider
                        .of<ChatRoomVM>(context)
                        .channel!
                        .displayName!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    metadata?["playerCount"] == null
                        ? ""
                        : "${metadata!["playerCount"]!

                        .toString()} players - ${metadata?['startTime'] != null
                        ? startTimeFormat.format(
                        DateTime.parse(metadata?['startTime']).toLocal()).toLowerCase()
                        : ""}",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w400, color: Colors.black54),
                  ),
                ],
              )
            ]),
          ),
        ],
      ),
    );

    final mediaQuery = MediaQuery.of(context);
    final bHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        myAppBar.preferredSize.height;
    const textfielHeight = 60.0;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: myAppBar,
      body: SafeArea(
        child: Stack(
          children: [
            FadedSlideAnimation(
              beginOffset: const Offset(0, 0.3),
              endOffset: const Offset(0, 0),
              slideCurve: Curves.linearToEaseOut,
              child: Provider
                  .of<ChatRoomVM>(context)
                  .channel == null
                  ? const SizedBox()
                  : SingleChildScrollView(
                reverse: true,
                controller:
                Provider
                    .of<ChatRoomVM>(context)
                    .scrollcontroller,
                child: MessageComponent(
                  bheight: bHeight - textfielHeight,
                  theme: theme,
                  mediaQuery: mediaQuery,
                  channelId: Provider
                      .of<ChatRoomVM>(context)
                      .channel!
                      .channelId!,
                  channel: Provider
                      .of<ChatRoomVM>(context)
                      .channel!,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ChatTextFieldComponent(
                    theme: theme,
                    textfielHeight: textfielHeight,
                    mediaQuery: mediaQuery),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatTextFieldComponent extends StatelessWidget {
  const ChatTextFieldComponent({
    Key? key,
    required this.theme,
    required this.textfielHeight,
    required this.mediaQuery,
  }) : super(key: key);

  final ThemeData theme;
  final double textfielHeight;
  final MediaQueryData mediaQuery;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: theme.canvasColor,
          border: Border(top: BorderSide(color: theme.highlightColor))),
      height: textfielHeight,
      width: mediaQuery.size.width,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Row(
        children: [
          // SizedBox(
          //   width: 5,
          // ),
          // Icon(
          //   Icons.emoji_emotions_outlined,
          //   color: theme.primaryIconTheme.color,
          //   size: 22,
          // ),
          const SizedBox(width: 10),
          SizedBox(
            width: mediaQuery.size.width * 0.7,
            child: TextField(
              controller: Provider
                  .of<ChatRoomVM>(context, listen: false)
                  .textEditingController,
              decoration: const InputDecoration(
                hintText: "Write your message",
                hintStyle: TextStyle(fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              Provider.of<ChatRoomVM>(context, listen: false).sendMessage();
            },
            child: Icon(
              Icons.send,
              color: Provider
                  .of<AmityUIConfiguration>(context)
                  .primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(
            width: 5,
          ),
        ],
      ),
    );
  }
}

class MessageComponent extends StatelessWidget {
  const MessageComponent({
    Key? key,
    required this.theme,
    required this.mediaQuery,
    required this.channelId,
    required this.bheight,
    required this.channel,
  }) : super(key: key);
  final String channelId;
  final AmityChannel channel;

  final ThemeData theme;

  final MediaQueryData mediaQuery;

  final double bheight;

  String getTimeStamp(AmityMessage msg) {
    if (msg.editedAt == null) {
      return '';
    }
    var timeFormat = DateFormat('hh:mm a');

    DateTime? localEditTime = msg.editedAt!.toLocal();

    return timeFormat.format(localEditTime).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatRoomVM>(builder: (context, vm, _) {
      return Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: vm.amitymessage.length,
          itemBuilder: (context, index) {
            var data = vm.amitymessage[index].data;
            var user = vm.amitymessage[index].user;

            bool isSendbyCurrentUser = vm.amitymessage[index].userId !=
                AmityCoreClient
                    .getCurrentUser()
                    .userId;

            return Column(
              crossAxisAlignment: isSendbyCurrentUser
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: isSendbyCurrentUser
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
                  children: [
                    if(isSendbyCurrentUser && user?.avatarCustomUrl != null)
                      ClipRRect(borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                              user!.avatarCustomUrl!, height: 40, width: 40)),

                    Column(mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: isSendbyCurrentUser
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                        children: [
                          if(isSendbyCurrentUser)
                            Padding(padding: EdgeInsets.only(left: 10, top: 12),
                                child: Text(user?.displayName ?? "", style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black54,
                                    fontSize: 13))),
                          vm.amitymessage[index].type != AmityMessageDataType.TEXT
                              ? Container(
                            margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                            padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.red),
                            child: const Text("Unsupport type message😰",
                                style: TextStyle(color: Colors.white)),
                          )
                              : Flexible(
                            child: Container(
                              constraints: BoxConstraints(
                                  maxWidth: mediaQuery.size.width * 0.7),
                              margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: isSendbyCurrentUser
                                    ? const Color(0xfff1f1f1)
                                    : Provider
                                    .of<AmityUIConfiguration>(context)
                                    .primaryColor,
                              ),
                              child: Text(
                                (vm.amitymessage[index].data!
                                as MessageTextData)
                                    .text ??
                                    "N/A",
                                style: theme.textTheme.bodyLarge!.copyWith(
                                    fontSize: 14.7,
                                    color: isSendbyCurrentUser
                                        ? Colors.black
                                        : Colors.white),
                              ),
                            ),
                          ),

                          Padding(padding: EdgeInsets.only(
                              left: 10, right: isSendbyCurrentUser ? 0 : 10), child: Text(
                              getTimeStamp(vm.amitymessage[index]),
                              style: TextStyle(color: Colors.grey[500], fontSize: 12))),
                        ]),
                  ],
                ),
                if (index + 1 == vm.amitymessage.length)
                  const SizedBox(
                    height: 90,
                  )
              ],
            );
          },
        ),
      );
    });
  }
}
