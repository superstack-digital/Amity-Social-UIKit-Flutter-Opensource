import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/native_social_override.dart';
import 'package:amity_uikit_beta_service/v4/core/toast/bloc/amity_uikit_toast_bloc.dart';
import 'package:amity_uikit_beta_service/v4/utils/error_util.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'comment_creator_events.dart';
part 'comment_creator_state.dart';

class CommentCreatorBloc
    extends Bloc<CommentCreatorEvent, CommentCreatorState> {
  static const double defaultHeight = 45;
  static const double lineHeight = 25;
  static const double maxHeight = 200;

  final AmityComment? replyTo;

  CommentCreatorBloc({
    required this.replyTo,
  }) : super(CommentCreatorState(
            text: "", currentHeight: defaultHeight, replyTo: replyTo)) {
    on<CommentCreatorTextChage>((event, emit) {
      // Approximate height of one line of text
      final numLines = '\n'.allMatches(event.text).length + 1;
      double currentHeight = (numLines * lineHeight) +
          20; // Calculate height based on number of lines includes padding
      if (currentHeight > maxHeight) {
        currentHeight = maxHeight;
      }
      emit(state.copyWith(text: event.text, currentHeight: currentHeight));
    });

    on<CommentCreatorCreated>((event, emit) async {
      // A natively-created post lives only in Postgres, so createComment()
      // would target an id Amity has never seen. Comments are not wired to
      // Postgres yet — that needs a native seam replacing CommentLiveCollection
      // on the read side too — so say so rather than dropping the text into a
      // call that silently fails.
      if (event.referenceType == AmityCommentReferenceType.POST &&
          NativeSocialOverride.isNativePost(event.referenceId)) {
        event.toastBloc.add(const AmityToastShort(
            message: "Commenting isn't available on this post yet."));
        return;
      }

      final replyTo = state.replyTo?.commentId;
      emit(const CommentCreatorState(
          text: "", currentHeight: defaultHeight, replyTo: null));
      if (replyTo != null) {
        try {
          if (event.referenceType == AmityCommentReferenceType.POST) {
            AmitySocialClient.newCommentRepository()
                .createComment()
                .post(event.referenceId)
                .parentId(replyTo)
                .create()
                .text(event.text)
                .send();
          } else if (event.referenceType == AmityCommentReferenceType.STORY) {
            await AmitySocialClient.newCommentRepository()
                .createComment()
                .story(event.referenceId)
                .parentId(replyTo)
                .create()
                .text(event.text)
                .send();
          }
        } catch (error) {
          if (error != null && error is AmityException) {
            if (error.code ==
                error.getErrorCode(AmityErrorCode.BAN_WORD_FOUND)) {
              event.toastBloc.add(const AmityToastShort(
                  message:
                      "Your comment contains inappropriate word. Please review and delete it."));
            }
            if (error.code ==
                error.getErrorCode(AmityErrorCode.TARGET_NOT_FOUND)) {
              if (error.message.contains("Story")) {
                event.toastBloc.add(const AmityToastShort(
                    message: "This story is no longer available"));
              }
            }
          }
        }
      } else {
        try {
          if (event.referenceType == AmityCommentReferenceType.POST) {
            await AmitySocialClient.newCommentRepository()
                .createComment()
                .post(event.referenceId)
                .create()
                .text(event.text)
                .send();
          } else if (event.referenceType == AmityCommentReferenceType.STORY) {
            await AmitySocialClient.newCommentRepository()
                .createComment()
                .story(event.referenceId)
                .create()
                .text(event.text)
                .send();
          }
        } catch (error) {
          if (error != null && error is AmityException) {
            if (error.code ==
                error.getErrorCode(AmityErrorCode.BAN_WORD_FOUND)) {
              event.toastBloc.add(const AmityToastShort(
                  message:
                      "Your comment contains inappropriate word. Please review and delete it."));
            }
            if (error.code ==
                error.getErrorCode(AmityErrorCode.TARGET_NOT_FOUND)) {
              if (error.message.contains("Story")) {
                event.toastBloc.add(const AmityToastShort(
                    message: "This story is no longer available"));
              }
            }
          }
        }
      }
    });
  }
}
