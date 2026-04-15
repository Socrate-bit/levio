import {onCall, HttpsError} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();

/**
 * Atomically redeems a referral code:
 * 1. Validates code exists with required fields (type, num_use, max_use)
 * 2. Checks code is not exhausted (num_use < max_use)
 * 3. Checks caller hasn't already used this code
 * 4. Increments num_use, appends UID to usedBy
 * 5. Sets user_type on the user document
 */
export const redeemReferralCode = onCall(async (request) => {
  // Require authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  const uid = request.auth.uid;
  const code = request.data?.code;
  if (typeof code !== "string" || code.trim().length === 0) {
    throw new HttpsError("invalid-argument", "A referral code is required.");
  }

  const codeRef = db.collection("referralCodes").doc(code.trim());
  const userRef = db.collection("users").doc(uid);

  const userType = await db.runTransaction(async (tx) => {
    const codeSnap = await tx.get(codeRef);
    if (!codeSnap.exists) {
      throw new HttpsError("not-found", "Referral code does not exist.");
    }
    const data = codeSnap.data()!;
    const type = data.type as string | undefined;
    const numUse = data.num_use as number | undefined;
    const maxUse = data.max_use as number | undefined;

    if (type === undefined || numUse === undefined || maxUse === undefined) {
      throw new HttpsError("failed-precondition", "Invalid referral code.");
    }
    if (numUse >= maxUse) {
      throw new HttpsError(
        "resource-exhausted",
        "This code has reached its usage limit."
      );
    }
    const usedBy = (data.usedBy as string[]) || [];
    if (usedBy.includes(uid)) {
      throw new HttpsError(
        "already-exists",
        "You have already used this code."
      );
    }

    // Atomic updates
    tx.update(codeRef, {
      num_use: FieldValue.increment(1),
      usedBy: FieldValue.arrayUnion([uid]),
    });
    tx.set(userRef, {user_type: type}, {merge: true});

    return type;
  });

  return {user_type: userType};
});
