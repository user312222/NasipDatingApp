// Run with `npm test` inside rules_test/ (needs Java + the Firebase CLI).
// Targets the local Firestore emulator only - project id "demo-binasip".
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  setLogLevel,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

let env;

// Denied writes are the point of these tests; keep the SDK's error logs out.
setLogLevel('silent');

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-binasip',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();
const seed = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

const adultBirth = () => Timestamp.fromDate(new Date('1995-01-01'));
const minorBirth = () => {
  const d = new Date();
  d.setFullYear(d.getFullYear() - 10);
  return Timestamp.fromDate(d);
};

const MATCH = 'alice_bob';
const seedMatch = () =>
  seed((db) => setDoc(doc(db, 'matches', MATCH), { users: ['alice', 'bob'], createdAt: Timestamp.now() }));

describe('chat messages', () => {
  const msg = (over = {}) => ({ text: 'merhaba', senderId: 'alice', sentAt: serverTimestamp(), ...over });
  const messages = (db) => collection(db, 'matches', MATCH, 'messages');

  test('a participant can send as themselves', async () => {
    await seedMatch();
    await assertSucceeds(addDoc(messages(as('alice')), msg()));
  });

  test('cannot send in someone else\'s name', async () => {
    await seedMatch();
    await assertFails(addDoc(messages(as('alice')), msg({ senderId: 'bob' })));
  });

  test('cannot backdate sentAt', async () => {
    await seedMatch();
    await assertFails(addDoc(messages(as('alice')), msg({ sentAt: Timestamp.fromDate(new Date('2020-01-01')) })));
  });

  test('rejects empty and oversized text', async () => {
    await seedMatch();
    await assertFails(addDoc(messages(as('alice')), msg({ text: '' })));
    await assertFails(addDoc(messages(as('alice')), msg({ text: 'x'.repeat(4001) })));
  });

  test('rejects extra fields', async () => {
    await seedMatch();
    await assertFails(addDoc(messages(as('alice')), msg({ role: 'admin' })));
  });

  test('an outsider can neither send nor read', async () => {
    await seedMatch();
    await assertFails(addDoc(messages(as('carol')), msg({ senderId: 'carol' })));
    await assertFails(getDocs(messages(as('carol'))));
    await assertFails(getDocs(messages(anon())));
  });

  test('both participants can read', async () => {
    await seedMatch();
    await assertSucceeds(getDocs(messages(as('alice'))));
    await assertSucceeds(getDocs(messages(as('bob'))));
  });

  test('messages are immutable', async () => {
    await seedMatch();
    await seed((db) => setDoc(doc(db, 'matches', MATCH, 'messages', 'm1'), { text: 'a', senderId: 'alice', sentAt: Timestamp.now() }));
    const ref = doc(as('alice'), 'matches', MATCH, 'messages', 'm1');
    await assertFails(updateDoc(ref, { text: 'edited' }));
    await assertFails(deleteDoc(ref));
  });
});

describe('matches', () => {
  test('only participants can read', async () => {
    await seedMatch();
    await assertSucceeds(getDoc(doc(as('alice'), 'matches', MATCH)));
    await assertFails(getDoc(doc(as('carol'), 'matches', MATCH)));
    await assertFails(getDoc(doc(anon(), 'matches', MATCH)));
  });

  test('a participant can set the family nudge flag to true', async () => {
    await seedMatch();
    await assertSucceeds(updateDoc(doc(as('bob'), 'matches', MATCH), { familyNudgeShown: true }));
  });

  test('the nudge flag cannot be set to false or mixed with other fields', async () => {
    await seedMatch();
    const ref = doc(as('alice'), 'matches', MATCH);
    await assertFails(updateDoc(ref, { familyNudgeShown: false }));
    await assertFails(updateDoc(ref, { familyNudgeShown: true, users: ['alice', 'carol'] }));
  });

  test('an outsider cannot touch the match', async () => {
    await seedMatch();
    await assertFails(updateDoc(doc(as('carol'), 'matches', MATCH), { familyNudgeShown: true }));
  });

  describe('creation', () => {
    const create = (db) => setDoc(doc(db, 'matches', MATCH), { users: ['alice', 'bob'], createdAt: serverTimestamp() });
    const like = (from, to) => seed((db) => setDoc(doc(db, 'likes', `${from}_${to}`), { from, to, createdAt: Timestamp.now() }));

    test('needs both likes', async () => {
      await like('alice', 'bob');
      await assertFails(create(as('alice')));
    });

    test('works once both likes exist', async () => {
      await like('alice', 'bob');
      await like('bob', 'alice');
      await assertSucceeds(create(as('alice')));
    });

    test('a third party cannot create a match between two others', async () => {
      await like('alice', 'bob');
      await like('bob', 'alice');
      await assertFails(create(as('carol')));
    });
  });
});

describe('matchReads (unread markers)', () => {
  const read = (over = {}) => ({ matchId: MATCH, userId: 'alice', readAt: serverTimestamp(), ...over });

  test('a participant can write their own marker', async () => {
    await seedMatch();
    await assertSucceeds(setDoc(doc(as('alice'), 'matchReads', `${MATCH}_alice`), read()));
  });

  test('the marker can be refreshed', async () => {
    await seedMatch();
    const ref = doc(as('alice'), 'matchReads', `${MATCH}_alice`);
    await assertSucceeds(setDoc(ref, read()));
    await assertSucceeds(setDoc(ref, read()));
  });

  test('cannot write a marker for another user', async () => {
    await seedMatch();
    await assertFails(setDoc(doc(as('alice'), 'matchReads', `${MATCH}_bob`), read({ userId: 'bob' })));
  });

  test('doc id must be matchId_uid', async () => {
    await seedMatch();
    await assertFails(setDoc(doc(as('alice'), 'matchReads', 'whatever'), read()));
  });

  test('readAt must be the server time', async () => {
    await seedMatch();
    await assertFails(setDoc(doc(as('alice'), 'matchReads', `${MATCH}_alice`), read({ readAt: Timestamp.fromDate(new Date('2030-01-01')) })));
  });

  test('an outsider cannot mark a match they are not in', async () => {
    await seedMatch();
    await assertFails(setDoc(doc(as('carol'), 'matchReads', `${MATCH}_carol`), read({ userId: 'carol' })));
  });

  test('only the owner can read it', async () => {
    await seedMatch();
    await seed((db) => setDoc(doc(db, 'matchReads', `${MATCH}_alice`), { matchId: MATCH, userId: 'alice', readAt: Timestamp.now() }));
    await assertSucceeds(getDoc(doc(as('alice'), 'matchReads', `${MATCH}_alice`)));
    await assertFails(getDoc(doc(as('bob'), 'matchReads', `${MATCH}_alice`)));
  });

  test('a list query works only when filtered to your own uid', async () => {
    await seedMatch();
    const q = (db, uid) => query(collection(db, 'matchReads'), where('userId', '==', uid));
    await assertSucceeds(getDocs(q(as('alice'), 'alice')));
    await assertFails(getDocs(q(as('bob'), 'alice')));
  });

  test('the owner can delete their marker, others cannot', async () => {
    await seedMatch();
    await seed((db) => setDoc(doc(db, 'matchReads', `${MATCH}_alice`), { matchId: MATCH, userId: 'alice', readAt: Timestamp.now() }));
    await assertFails(deleteDoc(doc(as('bob'), 'matchReads', `${MATCH}_alice`)));
    await assertSucceeds(deleteDoc(doc(as('alice'), 'matchReads', `${MATCH}_alice`)));
  });
});

describe('waitlist', () => {
  const entry = (over = {}) => ({ name: 'Ayşe', contact: 'ayse@example.com', createdAt: serverTimestamp(), ...over });
  const list = (db) => collection(db, 'waitlist');

  test('anyone, even signed out, can join', async () => {
    await assertSucceeds(addDoc(list(anon()), entry()));
    await assertSucceeds(addDoc(list(anon()), entry({ city: 'Ankara' })));
  });

  test('nobody can read, edit or delete entries', async () => {
    await seed((db) => setDoc(doc(db, 'waitlist', 'w1'), { name: 'a', contact: 'b', createdAt: Timestamp.now() }));
    await assertFails(getDocs(list(as('alice'))));
    await assertFails(getDoc(doc(as('alice'), 'waitlist', 'w1')));
    await assertFails(updateDoc(doc(as('alice'), 'waitlist', 'w1'), { name: 'x' }));
    await assertFails(deleteDoc(doc(as('alice'), 'waitlist', 'w1')));
  });

  test('validates fields', async () => {
    await assertFails(addDoc(list(anon()), entry({ name: '' })));
    await assertFails(addDoc(list(anon()), entry({ name: 'x'.repeat(101) })));
    await assertFails(addDoc(list(anon()), entry({ contact: '' })));
    await assertFails(addDoc(list(anon()), entry({ contact: 'x'.repeat(201) })));
    await assertFails(addDoc(list(anon()), entry({ city: 'x'.repeat(101) })));
    await assertFails(addDoc(list(anon()), entry({ role: 'admin' })));
    await assertFails(addDoc(list(anon()), entry({ createdAt: Timestamp.fromDate(new Date('2000-01-01')) })));
  });

  test('required fields cannot be omitted', async () => {
    await assertFails(addDoc(list(anon()), { name: 'a', createdAt: serverTimestamp() }));
    await assertFails(addDoc(list(anon()), { contact: 'a', createdAt: serverTimestamp() }));
  });
});

describe('inviteCodes', () => {
  test('a single valid-format code can be fetched, even signed out', async () => {
    await seed((db) => setDoc(doc(db, 'inviteCodes', 'NASIP2026'), { active: true }));
    const snap = await assertSucceeds(getDoc(doc(anon(), 'inviteCodes', 'NASIP2026')));
    if (!snap.exists() || snap.data().active !== true) throw new Error('expected the active code');
  });

  test('an unknown code just comes back missing', async () => {
    const snap = await assertSucceeds(getDoc(doc(anon(), 'inviteCodes', 'NOPE1234')));
    if (snap.exists()) throw new Error('did not expect a doc');
  });

  test('ids outside the allowed format are refused', async () => {
    await assertFails(getDoc(doc(anon(), 'inviteCodes', 'nasip2026')));
    await assertFails(getDoc(doc(anon(), 'inviteCodes', 'ABC')));
  });

  test('codes cannot be listed or written by clients', async () => {
    await assertFails(getDocs(collection(anon(), 'inviteCodes')));
    await assertFails(getDocs(collection(as('alice'), 'inviteCodes')));
    await assertFails(setDoc(doc(as('alice'), 'inviteCodes', 'HACKME1'), { active: true }));
    await assertFails(setDoc(doc(anon(), 'inviteCodes', 'HACKME1'), { active: true }));
  });
});

describe('profiles', () => {
  const profile = (over = {}) => ({
    userId: 'alice',
    name: 'Ayşe',
    birthDate: adultBirth(),
    city: 'İzmir',
    intent: 'marriage',
    photoRefs: ['a.jpg'],
    photoVisibility: 'hiddenUntilIUnlock',
    familyInvolvementOptIn: false,
    ...over,
  });
  const publicProfile = (over = {}) => ({ userId: 'alice', name: 'Ayşe', birthDate: adultBirth(), city: 'İzmir', intent: 'marriage', ...over });

  test('an owner can save a valid private profile', async () => {
    await assertSucceeds(setDoc(doc(as('alice'), 'profiles', 'alice'), profile()));
  });

  test('under-18 and malformed profiles are rejected', async () => {
    const ref = doc(as('alice'), 'profiles', 'alice');
    await assertFails(setDoc(ref, profile({ birthDate: minorBirth() })));
    await assertFails(setDoc(ref, profile({ photoRefs: [] })));
    await assertFails(setDoc(ref, profile({ intent: 'fun' })));
    await assertFails(setDoc(ref, profile({ madhhabSecret: 'x' })));
  });

  test('nobody else can read or write someone\'s private profile', async () => {
    await seed((db) => setDoc(doc(db, 'profiles', 'alice'), profile()));
    await assertFails(getDoc(doc(as('bob'), 'profiles', 'alice')));
    await assertFails(setDoc(doc(as('bob'), 'profiles', 'alice'), profile()));
  });

  test('public profiles are readable by any signed-in user but not signed out', async () => {
    await seed((db) => setDoc(doc(db, 'publicProfiles', 'alice'), publicProfile()));
    await assertSucceeds(getDoc(doc(as('bob'), 'publicProfiles', 'alice')));
    await assertFails(getDoc(doc(anon(), 'publicProfiles', 'alice')));
  });

  test('public profiles cannot carry sensitive fields', async () => {
    const ref = doc(as('alice'), 'publicProfiles', 'alice');
    await assertSucceeds(setDoc(ref, publicProfile()));
    await assertFails(setDoc(ref, publicProfile({ madhhab: 'hanefi' })));
    await assertFails(setDoc(ref, publicProfile({ photoRefs: ['a.jpg'] })));
  });
});

describe('likes and the daily cap', () => {
  const now = new Date();
  const counterId = (uid) => `${uid}_${now.getUTCFullYear()}-${now.getUTCMonth() + 1}-${now.getUTCDate()}`;
  const likeBatch = (db, count, to = 'bob') => {
    const batch = writeBatch(db);
    batch.set(doc(db, 'likeCounters', counterId('alice')), { uid: 'alice', count });
    batch.set(doc(db, 'likes', `alice_${to}`), { from: 'alice', to, createdAt: serverTimestamp() });
    return batch.commit();
  };

  test('a first like with a counter of 1 works', async () => {
    await seed((db) => setDoc(doc(db, 'publicProfiles', 'bob'), { userId: 'bob' }));
    await assertSucceeds(likeBatch(as('alice'), 1));
  });

  test('a like without bumping the counter by one is rejected', async () => {
    await seed((db) => setDoc(doc(db, 'publicProfiles', 'bob'), { userId: 'bob' }));
    await assertFails(likeBatch(as('alice'), 2));
  });

  test('cannot like someone without a public profile', async () => {
    await assertFails(likeBatch(as('alice'), 1));
  });

  test('cannot like yourself', async () => {
    await seed((db) => setDoc(doc(db, 'publicProfiles', 'alice'), { userId: 'alice' }));
    await assertFails(likeBatch(as('alice'), 1, 'alice'));
  });

  test('the cap stops at 12', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'publicProfiles', 'bob'), { userId: 'bob' });
      await setDoc(doc(db, 'likeCounters', counterId('alice')), { uid: 'alice', count: 12 });
    });
    await assertFails(likeBatch(as('alice'), 13));
  });

  test('likes are never editable or deletable', async () => {
    await seed((db) => setDoc(doc(db, 'likes', 'alice_bob'), { from: 'alice', to: 'bob', createdAt: Timestamp.now() }));
    await assertFails(updateDoc(doc(as('alice'), 'likes', 'alice_bob'), { to: 'carol' }));
    await assertFails(deleteDoc(doc(as('alice'), 'likes', 'alice_bob')));
  });
});

describe('family sharing', () => {
  const visible = { singleUserId: 'alice', matchId: MATCH, otherUserId: 'bob', matchedAt: Timestamp.now(), markedAt: Timestamp.now() };
  const byOwner = (db, uid) => query(collection(db, 'familyVisible'), where('singleUserId', '==', uid));

  test('a linked guardian sees the single user\'s shared matches', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'familyVisible', `${MATCH}_alice`), visible);
      await setDoc(doc(db, 'guardianOf', 'gina'), { singleUserId: 'alice', guardianName: 'Gina', relationship: 'anne', linkedAt: Timestamp.now() });
    });
    await assertSucceeds(getDocs(byOwner(as('gina'), 'alice')));
    await assertSucceeds(getDocs(byOwner(as('alice'), 'alice')));
  });

  test('an unlinked user cannot', async () => {
    await seed((db) => setDoc(doc(db, 'familyVisible', `${MATCH}_alice`), visible));
    await assertFails(getDocs(byOwner(as('carol'), 'alice')));
  });

  test('a guardian linked to someone else cannot', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'familyVisible', `${MATCH}_alice`), visible);
      await setDoc(doc(db, 'guardianOf', 'gina'), { singleUserId: 'zoe', guardianName: 'Gina', relationship: 'anne', linkedAt: Timestamp.now() });
    });
    await assertFails(getDocs(byOwner(as('gina'), 'alice')));
  });

  test('only the single user, in their own match, can mark it shared', async () => {
    await seedMatch();
    const data = { singleUserId: 'alice', matchId: MATCH, otherUserId: 'bob', matchedAt: Timestamp.now(), markedAt: serverTimestamp() };
    await assertFails(setDoc(doc(as('carol'), 'familyVisible', `${MATCH}_carol`), { ...data, singleUserId: 'carol' }));
    await assertFails(setDoc(doc(as('bob'), 'familyVisible', `${MATCH}_alice`), data));
    await assertSucceeds(setDoc(doc(as('alice'), 'familyVisible', `${MATCH}_alice`), data));
  });

  test('a guardian cannot link as someone else', async () => {
    const link = { singleUserId: 'alice', guardianName: 'Gina', relationship: 'anne', linkedAt: serverTimestamp() };
    await assertFails(setDoc(doc(as('carol'), 'guardianOf', 'gina'), link));
    await assertSucceeds(setDoc(doc(as('gina'), 'guardianOf', 'gina'), link));
    await assertFails(setDoc(doc(as('gina'), 'guardianOf', 'gina'), { ...link, relationship: 'kuzen' }));
  });
});

describe('safety', () => {
  const report = (over = {}) => ({ reporterId: 'alice', targetUserId: 'bob', reason: 'scam', createdAt: serverTimestamp(), ...over });

  test('a report can be filed but never read back, not even by the reporter', async () => {
    await assertSucceeds(addDoc(collection(as('alice'), 'reports'), report()));
    await seed((db) => setDoc(doc(db, 'reports', 'r1'), { reporterId: 'alice', targetUserId: 'bob', reason: 'scam', createdAt: Timestamp.now() }));
    await assertFails(getDoc(doc(as('alice'), 'reports', 'r1')));
    await assertFails(getDocs(collection(as('alice'), 'reports')));
  });

  test('invalid reports are rejected', async () => {
    const col = collection(as('alice'), 'reports');
    await assertFails(addDoc(col, report({ reporterId: 'bob' })));
    await assertFails(addDoc(col, report({ targetUserId: 'alice' })));
    await assertFails(addDoc(col, report({ reason: 'dislike' })));
    await assertFails(addDoc(collection(anon(), 'reports'), report()));
  });

  test('blocking: create and read your own, nobody else\'s', async () => {
    await assertSucceeds(setDoc(doc(as('alice'), 'blockedUsers', 'alice_bob'), { blockerId: 'alice', blockedId: 'bob', createdAt: serverTimestamp() }));
    await assertSucceeds(getDoc(doc(as('alice'), 'blockedUsers', 'alice_bob')));
    await assertFails(getDoc(doc(as('bob'), 'blockedUsers', 'alice_bob')));
    await assertFails(setDoc(doc(as('bob'), 'blockedUsers', 'alice_carol'), { blockerId: 'alice', blockedId: 'carol', createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(as('alice'), 'blockedUsers', 'alice_alice'), { blockerId: 'alice', blockedId: 'alice', createdAt: serverTimestamp() }));
  });
});

describe('account docs', () => {
  test('users: only the owner, only valid account types', async () => {
    await assertSucceeds(setDoc(doc(as('alice'), 'users', 'alice'), { accountType: 'single' }));
    await assertFails(setDoc(doc(as('alice'), 'users', 'alice'), { accountType: 'admin' }));
    await assertFails(setDoc(doc(as('alice'), 'users', 'alice'), { accountType: 'single', isAdmin: true }));
    await assertFails(setDoc(doc(as('bob'), 'users', 'alice'), { accountType: 'single' }));
    await assertFails(getDoc(doc(as('bob'), 'users', 'alice')));
  });

  test('consents: only the owner', async () => {
    const data = { consentVersion: 'v1', lastAcceptedAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(as('alice'), 'consents', 'alice'), data));
    await assertFails(setDoc(doc(as('bob'), 'consents', 'alice'), data));
    await assertFails(getDoc(doc(as('bob'), 'consents', 'alice')));
  });

  test('family invite codes: private to the owner, lookup is create-once', async () => {
    await assertSucceeds(setDoc(doc(as('alice'), 'familyInviteCodes', 'alice'), { code: 'ABCD1234' }));
    await assertFails(getDoc(doc(as('bob'), 'familyInviteCodes', 'alice')));
    await assertFails(setDoc(doc(as('alice'), 'familyInviteCodes', 'alice'), { code: 'ZZZZ9999' }));
    await assertSucceeds(setDoc(doc(as('alice'), 'familyInviteCodeLookup', 'ABCD1234'), { singleUserId: 'alice' }));
    await assertSucceeds(getDoc(doc(as('bob'), 'familyInviteCodeLookup', 'ABCD1234')));
    await assertFails(setDoc(doc(as('bob'), 'familyInviteCodeLookup', 'ZZZZ9999'), { singleUserId: 'alice' }));
  });

  test('anything not listed is closed', async () => {
    await assertFails(setDoc(doc(as('alice'), 'surprise', 'x'), { a: 1 }));
    await assertFails(getDoc(doc(as('alice'), 'surprise', 'x')));
  });
});
