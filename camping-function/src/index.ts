import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

initializeApp();

export const sendCommentNotification = onDocumentCreated(
  "sites/{siteId}/comments/{commentId}",
  async (event) => {
    const commentData = event.data?.data();
    if (!commentData) return;

    const siteId = event.params.siteId;
    const commenterId = commentData.userId;

    const siteDoc = await getFirestore().collection("sites").doc(siteId).get();
    if (!siteDoc.exists) return;

    const siteOwnerId = siteDoc.data()?.userId;
    if (!siteOwnerId || siteOwnerId === commenterId) return;

    const userDoc = await getFirestore()
      .collection("users")
      .doc(siteOwnerId)
      .get();
    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return;

    await getMessaging().send({
      token: fcmToken,
      notification: {
        title: "New Comment on Your Site",
        body: "Someone commented on your site: " + siteDoc.data()?.siteName,
      },
      data: {
        siteId,
      },
    });
  },
);
