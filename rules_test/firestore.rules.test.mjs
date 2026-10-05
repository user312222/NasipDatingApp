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
  increment,
  limit,
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

// Gives each uid an account document, i.e. makes it a member of the beta
// (what registering with a valid invite code does in the app).
const seedMembers = (uids, accountType = 'single') =>
  seed(async (db) => {
    for (const uid of uids) await setDoc(doc(db, 'users', uid), { accountType });
  });

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

  test('public profiles are readable by members only (FR-1.3)', async () => {
    await seed((db) => setDoc(doc(db, 'publicProfiles', 'alice'), publicProfile()));
    await seedMembers(['bob']);
    await seedMembers(['gina'], 'guardian');
    await assertSucceeds(getDoc(doc(as('bob'), 'publicProfiles', 'alice')));
    await assertSucceeds(getDocs(collection(as('bob'), 'publicProfiles')));
    // A guardian needs them for the candidates their relative shared.
    await assertSucceeds(getDoc(doc(as('gina'), 'publicProfiles', 'alice')));
    // Signed in with a phone number, but never got past the invite gate.
    await assertFails(getDoc(doc(as('carol'), 'publicProfiles', 'alice')));
    await assertFails(getDocs(collection(as('carol'), 'publicProfiles')));
    await assertFails(getDoc(doc(anon(), 'publicProfiles', 'alice')));
  });

  test('only a single account can have a public profile (FR-8.6)', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'users', 'alice'), { accountType: 'single' });
      await setDoc(doc(db, 'users', 'gina'), { accountType: 'guardian' });
    });
    await assertSucceeds(setDoc(doc(as('alice'), 'publicProfiles', 'alice'), publicProfile()));
    await assertFails(setDoc(doc(as('gina'), 'publicProfiles', 'gina'), publicProfile({ userId: 'gina' })));
    // No account document at all: nothing says this is a single account.
    await assertFails(setDoc(doc(as('carol'), 'publicProfiles', 'carol'), publicProfile({ userId: 'carol' })));
  });

  test('public profiles cannot carry sensitive fields', async () => {
    await seed((db) => setDoc(doc(db, 'users', 'alice'), { accountType: 'single' }));
    const ref = doc(as('alice'), 'publicProfiles', 'alice');
    await assertSucceeds(setDoc(ref, publicProfile()));
    await assertFails(setDoc(ref, publicProfile({ madhhab: 'hanefi' })));
    await assertFails(setDoc(ref, publicProfile({ photoRefs: ['a.jpg'] })));
  });

  describe('editing (FR-2.5): everything but the birth date', () => {
    // Still an adult, so only the "may not move" rule can refuse it.
    const otherAdultBirth = () => Timestamp.fromDate(new Date('1990-06-15'));

    beforeEach(() =>
      seed(async (db) => {
        await setDoc(doc(db, 'users', 'alice'), { accountType: 'single' });
        await setDoc(doc(db, 'profiles', 'alice'), profile());
        await setDoc(doc(db, 'publicProfiles', 'alice'), publicProfile());
      }));

    test('the app\'s save - both documents, same birth date - goes through', async () => {
      const db = as('alice');
      const batch = writeBatch(db);
      batch.set(
        doc(db, 'profiles', 'alice'),
        profile({ name: 'Ayşe Nur', city: 'Ankara', intent: 'notSureYet', photoVisibility: 'autoOnMatch', occupation: 'Mimar' }),
      );
      batch.set(
        doc(db, 'publicProfiles', 'alice'),
        publicProfile({ name: 'Ayşe Nur', city: 'Ankara', intent: 'notSureYet', occupation: 'Mimar' }),
      );
      await assertSucceeds(batch.commit());
    });

    test('the private profile\'s birth date cannot be moved', async () => {
      const ref = doc(as('alice'), 'profiles', 'alice');
      await assertFails(setDoc(ref, profile({ birthDate: otherAdultBirth() })));
      await assertFails(updateDoc(ref, { birthDate: otherAdultBirth() }));
      // Not even by a second.
      await assertFails(updateDoc(ref, { birthDate: new Timestamp(adultBirth().seconds + 1, 0) }));
    });

    test('nor can the age other members see', async () => {
      const ref = doc(as('alice'), 'publicProfiles', 'alice');
      await assertFails(setDoc(ref, publicProfile({ birthDate: otherAdultBirth() })));
      await assertFails(updateDoc(ref, { birthDate: otherAdultBirth() }));
    });

    test('a save that moves it is refused as a whole', async () => {
      const db = as('alice');
      const batch = writeBatch(db);
      batch.set(doc(db, 'profiles', 'alice'), profile({ city: 'Ankara', birthDate: otherAdultBirth() }));
      batch.set(doc(db, 'publicProfiles', 'alice'), publicProfile({ city: 'Ankara', birthDate: otherAdultBirth() }));
      await assertFails(batch.commit());

      const stored = await getDoc(doc(db, 'profiles', 'alice'));
      if (stored.data().city !== 'İzmir') throw new Error('the profile changed');
    });

    test('a first profile can still be created with any adult birth date', async () => {
      await seedMembers(['bob']);
      const db = as('bob');
      const batch = writeBatch(db);
      batch.set(doc(db, 'profiles', 'bob'), profile({ userId: 'bob', birthDate: otherAdultBirth() }));
      batch.set(doc(db, 'publicProfiles', 'bob'), publicProfile({ userId: 'bob', birthDate: otherAdultBirth() }));
      await assertSucceeds(batch.commit());
    });
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

  // alice, the one liking, has finished her profile unless a test says not.
  const seedProfiles = (...uids) =>
    seed(async (db) => {
      for (const uid of uids) await setDoc(doc(db, 'publicProfiles', uid), { userId: uid });
    });

  test('a first like with a counter of 1 works', async () => {
    await seedProfiles('alice', 'bob');
    await assertSucceeds(likeBatch(as('alice'), 1));
  });

  test('a like without bumping the counter by one is rejected', async () => {
    await seedProfiles('alice', 'bob');
    await assertFails(likeBatch(as('alice'), 2));
  });

  test('cannot like someone without a public profile', async () => {
    await seedProfiles('alice');
    await assertFails(likeBatch(as('alice'), 1));
  });

  test('cannot like without a public profile of your own', async () => {
    await seedProfiles('bob');
    await assertFails(likeBatch(as('alice'), 1));
  });

  test('cannot like yourself', async () => {
    await seed((db) => setDoc(doc(db, 'publicProfiles', 'alice'), { userId: 'alice' }));
    await assertFails(likeBatch(as('alice'), 1, 'alice'));
  });

  test('the cap stops at 12', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'publicProfiles', 'alice'), { userId: 'alice' });
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

  test('the single user can ask whether one match is shared (chat switch)', async () => {
    await seed((db) => setDoc(doc(db, 'familyVisible', `${MATCH}_alice`), visible));
    const one = (db, uid, matchId) => query(
      collection(db, 'familyVisible'),
      where('singleUserId', '==', uid),
      where('matchId', '==', matchId),
      limit(1),
    );
    await assertSucceeds(getDocs(one(as('alice'), 'alice', MATCH)));
    // "Off" is an empty result, not a denial - which is why the app queries
    // instead of fetching `{matchId}_{uid}` directly.
    await assertSucceeds(getDocs(one(as('alice'), 'alice', 'some_other_match')));
    await assertFails(getDoc(doc(as('alice'), 'familyVisible', 'some_other_match_alice')));
    await assertFails(getDocs(one(as('carol'), 'alice', MATCH)));
  });

  test('only the single user, in their own match, can mark it shared', async () => {
    await seedMatch();
    const data = { singleUserId: 'alice', matchId: MATCH, otherUserId: 'bob', matchedAt: Timestamp.now(), markedAt: serverTimestamp() };
    await assertFails(setDoc(doc(as('carol'), 'familyVisible', `${MATCH}_carol`), { ...data, singleUserId: 'carol' }));
    await assertFails(setDoc(doc(as('bob'), 'familyVisible', `${MATCH}_alice`), data));
    await assertSucceeds(setDoc(doc(as('alice'), 'familyVisible', `${MATCH}_alice`), data));
  });

  describe('linking a guardian (FR-8.3)', () => {
    const link = (over = {}) => ({
      singleUserId: 'alice',
      guardianName: 'Gina',
      relationship: 'anne',
      linkedAt: serverTimestamp(),
      familyCode: 'ABCD1234',
      ...over,
    });
    // alice and zoe each have a family code; gina is a guardian account.
    const seedCodes = () =>
      seed(async (db) => {
        await setDoc(doc(db, 'users', 'gina'), { accountType: 'guardian' });
        await setDoc(doc(db, 'users', 'alice'), { accountType: 'single' });
        await setDoc(doc(db, 'users', 'bob'), { accountType: 'single' });
        await setDoc(doc(db, 'familyInviteCodeLookup', 'ABCD1234'), { singleUserId: 'alice' });
        await setDoc(doc(db, 'familyInviteCodeLookup', 'ZZZZ9999'), { singleUserId: 'zoe' });
      });

    test('works with the code of the account being linked', async () => {
      await seedCodes();
      await assertSucceeds(setDoc(doc(as('gina'), 'guardianOf', 'gina'), link()));
    });

    test('knowing the uid is not enough: no code, no link', async () => {
      await seedCodes();
      const { familyCode, ...withoutCode } = link();
      await assertFails(setDoc(doc(as('gina'), 'guardianOf', 'gina'), withoutCode));
      await assertFails(setDoc(doc(as('gina'), 'guardianOf', 'gina'), link({ familyCode: 'NOPE0000' })));
    });

    test('a code only links to its own owner', async () => {
      await seedCodes();
      // zoe's code cannot be used to attach to alice.
      await assertFails(setDoc(doc(as('gina'), 'guardianOf', 'gina'), link({ familyCode: 'ZZZZ9999' })));
      await assertSucceeds(setDoc(doc(as('gina'), 'guardianOf', 'gina'), link({ singleUserId: 'zoe', familyCode: 'ZZZZ9999' })));
    });

    test('only a guardian account, and only for itself', async () => {
      await seedCodes();
      // bob is a single account: it cannot become anyone's guardian.
      await assertFails(setDoc(doc(as('bob'), 'guardianOf', 'bob'), link()));
      // carol has no account at all.
      await assertFails(setDoc(doc(as('carol'), 'guardianOf', 'carol'), link()));
      await assertFails(setDoc(doc(as('gina'), 'guardianOf', 'someone_else'), link()));
    });

    test('other fields are still validated', async () => {
      await seedCodes();
      await assertFails(setDoc(doc(as('gina'), 'guardianOf', 'gina'), link({ relationship: 'kuzen' })));
      await assertFails(setDoc(doc(as('gina'), 'guardianOf', 'gina'), link({ guardianName: '' })));
    });
  });
});

// FR-8.5: a linked guardian learns *that* a shared match exists (see
// 'family sharing' above) and nothing about what is said in it.
describe('guardian privacy (FR-8.5)', () => {
  const messages = (db) => collection(db, 'matches', MATCH, 'messages');

  // gina is linked to alice, and alice shares her match with bob.
  const seedSharedMatch = () =>
    seed(async (db) => {
      await setDoc(doc(db, 'matches', MATCH), { users: ['alice', 'bob'], createdAt: Timestamp.now() });
      await setDoc(doc(db, 'matches', MATCH, 'messages', 'm1'), { text: 'özel', senderId: 'alice', sentAt: Timestamp.now() });
      await setDoc(doc(db, 'matchReads', `${MATCH}_alice`), { matchId: MATCH, userId: 'alice', readAt: Timestamp.now() });
      await setDoc(doc(db, 'familyVisible', `${MATCH}_alice`), { singleUserId: 'alice', matchId: MATCH, otherUserId: 'bob', matchedAt: Timestamp.now(), markedAt: Timestamp.now() });
      await setDoc(doc(db, 'guardianOf', 'gina'), { singleUserId: 'alice', guardianName: 'Gina', relationship: 'anne', linkedAt: Timestamp.now() });
      await setDoc(doc(db, 'users', 'gina'), { accountType: 'guardian' });
    });

  test('cannot read the messages of a match shared with them', async () => {
    await seedSharedMatch();
    await assertFails(getDocs(messages(as('gina'))));
    await assertFails(getDoc(doc(as('gina'), 'matches', MATCH, 'messages', 'm1')));
  });

  test('cannot write into the conversation', async () => {
    await seedSharedMatch();
    await assertFails(addDoc(messages(as('gina')), { text: 'selam', senderId: 'gina', sentAt: serverTimestamp() }));
    await assertFails(addDoc(messages(as('gina')), { text: 'selam', senderId: 'alice', sentAt: serverTimestamp() }));
  });

  test('cannot read the match document or any read markers', async () => {
    await seedSharedMatch();
    await assertFails(getDoc(doc(as('gina'), 'matches', MATCH)));
    await assertFails(getDoc(doc(as('gina'), 'matchReads', `${MATCH}_alice`)));
    await assertFails(getDocs(query(collection(as('gina'), 'matchReads'), where('userId', '==', 'alice'))));
  });

  test('cannot read the private profile of the single user', async () => {
    await seedSharedMatch();
    await seed((db) => setDoc(doc(db, 'profiles', 'alice'), { name: 'Alice' }));
    await assertFails(getDoc(doc(as('gina'), 'profiles', 'alice')));
  });

  test('cannot switch the sharing on or off themselves', async () => {
    await seedSharedMatch();
    await assertFails(deleteDoc(doc(as('gina'), 'familyVisible', `${MATCH}_alice`)));
    await assertFails(setDoc(doc(as('gina'), 'familyVisible', `${MATCH}_alice`), { singleUserId: 'alice', matchId: MATCH, otherUserId: 'bob', matchedAt: Timestamp.now(), markedAt: serverTimestamp() }));
  });
});

describe('safety', () => {
  const report = (over = {}) => ({ reporterId: 'alice', targetUserId: 'bob', reason: 'scam', createdAt: serverTimestamp(), ...over });

  test('a report can be filed but never read back, not even by the reporter', async () => {
    await seedMembers(['alice']);
    await assertSucceeds(addDoc(collection(as('alice'), 'reports'), report()));
    await seed((db) => setDoc(doc(db, 'reports', 'r1'), { reporterId: 'alice', targetUserId: 'bob', reason: 'scam', createdAt: Timestamp.now() }));
    await assertFails(getDoc(doc(as('alice'), 'reports', 'r1')));
    await assertFails(getDocs(collection(as('alice'), 'reports')));
  });

  test('invalid reports are rejected', async () => {
    await seedMembers(['alice']);
    const col = collection(as('alice'), 'reports');
    await assertFails(addDoc(col, report({ reporterId: 'bob' })));
    await assertFails(addDoc(col, report({ targetUserId: 'alice' })));
    await assertFails(addDoc(col, report({ reason: 'dislike' })));
    await assertFails(addDoc(collection(anon(), 'reports'), report()));
  });

  test('reporting and blocking are for members only', async () => {
    // carol signed in with a phone number but never registered.
    await assertFails(addDoc(collection(as('carol'), 'reports'), report({ reporterId: 'carol' })));
    await assertFails(setDoc(doc(as('carol'), 'blockedUsers', 'carol_bob'), { blockerId: 'carol', blockedId: 'bob', createdAt: serverTimestamp() }));
  });

  test('blocking: create and read your own, nobody else\'s', async () => {
    await seedMembers(['alice', 'bob']);
    await assertSucceeds(setDoc(doc(as('alice'), 'blockedUsers', 'alice_bob'), { blockerId: 'alice', blockedId: 'bob', createdAt: serverTimestamp() }));
    await assertSucceeds(getDoc(doc(as('alice'), 'blockedUsers', 'alice_bob')));
    await assertFails(getDoc(doc(as('bob'), 'blockedUsers', 'alice_bob')));
    await assertFails(setDoc(doc(as('bob'), 'blockedUsers', 'alice_carol'), { blockerId: 'alice', blockedId: 'carol', createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(as('alice'), 'blockedUsers', 'alice_alice'), { blockerId: 'alice', blockedId: 'alice', createdAt: serverTimestamp() }));
  });
});

describe('account docs', () => {
  describe('users: the account is the invite gate (FR-1.3)', () => {
    const seedCodes = () =>
      seed(async (db) => {
        await setDoc(doc(db, 'inviteCodes', 'NASIP2026'), { active: true });
        await setDoc(doc(db, 'inviteCodes', 'OTHER2026'), { active: true });
        await setDoc(doc(db, 'inviteCodes', 'KAPALI01'), { active: false });
      });
    const account = (over = {}) => ({ accountType: 'single', inviteCode: 'NASIP2026', ...over });

    test('can be created with an active invite code', async () => {
      await seedCodes();
      await assertSucceeds(setDoc(doc(as('alice'), 'users', 'alice'), account()));
      await assertSucceeds(setDoc(doc(as('gina'), 'users', 'gina'), account({ accountType: 'guardian' })));
    });

    test('cannot be created without one', async () => {
      await seedCodes();
      await assertFails(setDoc(doc(as('alice'), 'users', 'alice'), { accountType: 'single' }));
    });

    test('cannot be created with an unknown, revoked or malformed code', async () => {
      await seedCodes();
      await assertFails(setDoc(doc(as('alice'), 'users', 'alice'), account({ inviteCode: 'YOKBOYLE' })));
      await assertFails(setDoc(doc(as('alice'), 'users', 'alice'), account({ inviteCode: 'KAPALI01' })));
      await assertFails(setDoc(doc(as('alice'), 'users', 'alice'), account({ inviteCode: 'nasip2026' })));
      await assertFails(setDoc(doc(as('alice'), 'users', 'alice'), account({ inviteCode: 42 })));
    });

    test('only the owner, only valid fields', async () => {
      await seedCodes();
      await assertFails(setDoc(doc(as('bob'), 'users', 'alice'), account()));
      await assertFails(setDoc(doc(as('alice'), 'users', 'alice'), account({ accountType: 'admin' })));
      await assertFails(setDoc(doc(as('alice'), 'users', 'alice'), account({ isAdmin: true })));
      await assertSucceeds(setDoc(doc(as('alice'), 'users', 'alice'), account()));
      await assertFails(getDoc(doc(as('bob'), 'users', 'alice')));
    });

    test('later steps can add to the account but not change its code', async () => {
      await seedCodes();
      const ref = doc(as('alice'), 'users', 'alice');
      await assertSucceeds(setDoc(ref, account()));
      // The liveness step: merge in `verifiedAt`, code untouched.
      await assertSucceeds(setDoc(ref, { accountType: 'single', verifiedAt: Timestamp.now() }, { merge: true }));
      await assertFails(setDoc(ref, { inviteCode: 'OTHER2026' }, { merge: true }));
      await assertFails(setDoc(ref, { accountType: 'single' }));
    });

    test('an account from before the rule keeps working, without a code', async () => {
      await seedCodes();
      await seed((db) => setDoc(doc(db, 'users', 'alice'), { accountType: 'single' }));
      const ref = doc(as('alice'), 'users', 'alice');
      await assertSucceeds(setDoc(ref, { accountType: 'single', verifiedAt: Timestamp.now() }, { merge: true }));
      await assertFails(setDoc(ref, { inviteCode: 'NASIP2026' }, { merge: true }));
    });

    test('a revoked code does not lock out the accounts made with it', async () => {
      await seedCodes();
      const ref = doc(as('alice'), 'users', 'alice');
      await assertSucceeds(setDoc(ref, account()));
      await seed((db) => setDoc(doc(db, 'inviteCodes', 'NASIP2026'), { active: false }));
      await assertSucceeds(setDoc(ref, { accountType: 'single', verifiedAt: Timestamp.now() }, { merge: true }));
      await assertSucceeds(getDoc(ref));
    });
  });

  test('users: the sign-in door can look up its own account, present or not', async () => {
    await assertSucceeds(getDoc(doc(as('alice'), 'users', 'alice')));
    await seed((db) => setDoc(doc(db, 'users', 'alice'), { accountType: 'single' }));
    await assertSucceeds(getDoc(doc(as('alice'), 'users', 'alice')));
    await assertFails(getDoc(doc(anon(), 'users', 'alice')));
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
    await assertFails(setDoc(doc(as('bob'), 'familyInviteCodeLookup', 'ZZZZ9999'), { singleUserId: 'alice' }));
  });

  test('a family code can be looked up when known, never listed', async () => {
    await seedMembers(['gina'], 'guardian');
    await seed((db) => setDoc(doc(db, 'familyInviteCodeLookup', 'ABCD1234'), { singleUserId: 'alice' }));
    await assertSucceeds(getDoc(doc(as('gina'), 'familyInviteCodeLookup', 'ABCD1234')));
    // A list would hand out every code together with whose it is.
    await assertFails(getDocs(collection(as('gina'), 'familyInviteCodeLookup')));
    await assertFails(getDocs(query(collection(as('gina'), 'familyInviteCodeLookup'), where('singleUserId', '==', 'alice'))));
    // Not a member: not even a known code.
    await assertFails(getDoc(doc(as('carol'), 'familyInviteCodeLookup', 'ABCD1234')));
  });

  test('anything not listed is closed', async () => {
    await assertFails(setDoc(doc(as('alice'), 'surprise', 'x'), { a: 1 }));
    await assertFails(getDoc(doc(as('alice'), 'surprise', 'x')));
  });
});

describe('feed (günün sorusu)', () => {
  const now = new Date();
  const dayKey = `${now.getUTCFullYear()}-${now.getUTCMonth() + 1}-${now.getUTCDate()}`;
  const postId = (uid) => `${uid}_${dayKey}`;
  const answer = (uid, over = {}) => ({
    authorId: uid,
    dayKey,
    text: 'Kahvaltı ve uzun bir yürüyüş.',
    createdAt: serverTimestamp(),
    likeCount: 0,
    ...over,
  });

  const seedMembers = () =>
    seed(async (db) => {
      for (const uid of ['alice', 'bob', 'carol']) {
        await setDoc(doc(db, 'users', uid), { accountType: 'single' });
        await setDoc(doc(db, 'publicProfiles', uid), { userId: uid });
      }
      await setDoc(doc(db, 'users', 'gina'), { accountType: 'guardian' });
    });
  const seedPost = (uid, likeCount = 0) =>
    seed((db) =>
      setDoc(doc(db, 'feedPosts', postId(uid)), {
        authorId: uid,
        dayKey,
        text: 'cevap',
        createdAt: Timestamp.now(),
        likeCount,
      }),
    );

  const like = (db, uid, target, delta = 1) => {
    const batch = writeBatch(db);
    batch.set(doc(db, 'feedLikes', `${postId(target)}_${uid}`), {
      postId: postId(target),
      userId: uid,
      dayKey,
      createdAt: serverTimestamp(),
    });
    batch.update(doc(db, 'feedPosts', postId(target)), { likeCount: increment(delta) });
    return batch.commit();
  };
  const unlike = (db, uid, target, delta = -1) => {
    const batch = writeBatch(db);
    batch.delete(doc(db, 'feedLikes', `${postId(target)}_${uid}`));
    batch.update(doc(db, 'feedPosts', postId(target)), { likeCount: increment(delta) });
    return batch.commit();
  };

  describe('answers', () => {
    test('a member can check for their own answer before writing one (tab dot)', async () => {
      await seedMembers();
      await assertSucceeds(getDoc(doc(as('alice'), 'feedPosts', postId('alice'))));
      await assertFails(getDoc(doc(as('gina'), 'feedPosts', postId('gina'))));
      await assertFails(getDoc(doc(anon(), 'feedPosts', postId('alice'))));
    });

    test('a member can answer the question of the day once', async () => {
      await seedMembers();
      await assertSucceeds(setDoc(doc(as('alice'), 'feedPosts', postId('alice')), answer('alice')));
    });

    test('the doc id pins it to the author and to today', async () => {
      await seedMembers();
      await assertFails(setDoc(doc(as('alice'), 'feedPosts', postId('bob')), answer('alice')));
      await assertFails(setDoc(doc(as('alice'), 'feedPosts', 'alice_2020-1-1'), answer('alice', { dayKey: '2020-1-1' })));
      await assertFails(setDoc(doc(as('alice'), 'feedPosts', 'alice_extra'), answer('alice')));
    });

    test('cannot answer as someone else', async () => {
      await seedMembers();
      await assertFails(setDoc(doc(as('alice'), 'feedPosts', postId('alice')), answer('bob')));
    });

    test('validates text, counter, timestamp and fields', async () => {
      await seedMembers();
      const ref = doc(as('alice'), 'feedPosts', postId('alice'));
      await assertFails(setDoc(ref, answer('alice', { text: '' })));
      await assertFails(setDoc(ref, answer('alice', { text: 'x'.repeat(281) })));
      await assertFails(setDoc(ref, answer('alice', { likeCount: 99 })));
      await assertFails(setDoc(ref, answer('alice', { createdAt: Timestamp.fromDate(new Date('2020-01-01')) })));
      await assertFails(setDoc(ref, answer('alice', { pinned: true })));
    });

    test('needs a public profile', async () => {
      await seed((db) => setDoc(doc(db, 'users', 'dave'), { accountType: 'single' }));
      await assertFails(setDoc(doc(as('dave'), 'feedPosts', postId('dave')), answer('dave')));
    });

    test('an answer cannot be edited, by its author or anyone else', async () => {
      await seedMembers();
      await seedPost('alice');
      await assertFails(updateDoc(doc(as('alice'), 'feedPosts', postId('alice')), { text: 'changed' }));
      await assertFails(updateDoc(doc(as('bob'), 'feedPosts', postId('alice')), { text: 'changed' }));
    });

    test('only the author can delete it', async () => {
      await seedMembers();
      await seedPost('alice');
      await assertFails(deleteDoc(doc(as('bob'), 'feedPosts', postId('alice'))));
      await assertSucceeds(deleteDoc(doc(as('alice'), 'feedPosts', postId('alice'))));
    });

    test('members can read the feed; guardians and signed-out visitors cannot', async () => {
      await seedMembers();
      await seedPost('alice');
      const today = (db) => query(collection(db, 'feedPosts'), where('dayKey', '==', dayKey));
      await assertSucceeds(getDocs(today(as('bob'))));
      await assertFails(getDocs(today(as('gina'))));
      await assertFails(getDocs(today(anon())));
    });

    test('a guardian cannot answer', async () => {
      await seedMembers();
      await seed((db) => setDoc(doc(db, 'publicProfiles', 'gina'), { userId: 'gina' }));
      await assertFails(setDoc(doc(as('gina'), 'feedPosts', postId('gina')), answer('gina')));
    });
  });

  describe('likes', () => {
    test('liking adds the like doc and bumps the counter by one', async () => {
      await seedMembers();
      await seedPost('alice');
      await assertSucceeds(like(as('bob'), 'bob', 'alice'));
    });

    test('the counter cannot be bumped without a like, or by more than one', async () => {
      await seedMembers();
      await seedPost('alice');
      await assertFails(updateDoc(doc(as('bob'), 'feedPosts', postId('alice')), { likeCount: increment(1) }));
      await assertFails(like(as('bob'), 'bob', 'alice', 5));
    });

    test('a like doc cannot be created without bumping the counter', async () => {
      await seedMembers();
      await seedPost('alice');
      await assertFails(
        setDoc(doc(as('bob'), 'feedLikes', `${postId('alice')}_bob`), {
          postId: postId('alice'),
          userId: 'bob',
          dayKey,
          createdAt: serverTimestamp(),
        }),
      );
    });

    test('cannot like twice', async () => {
      await seedMembers();
      await seedPost('alice');
      await assertSucceeds(like(as('bob'), 'bob', 'alice'));
      await assertFails(like(as('bob'), 'bob', 'alice'));
    });

    test('cannot like your own answer', async () => {
      await seedMembers();
      await seedPost('alice');
      await assertFails(like(as('alice'), 'alice', 'alice'));
    });

    test('cannot like in the name of someone else', async () => {
      await seedMembers();
      await seedPost('alice');
      const db = as('bob');
      const batch = writeBatch(db);
      batch.set(doc(db, 'feedLikes', `${postId('alice')}_carol`), {
        postId: postId('alice'),
        userId: 'carol',
        dayKey,
        createdAt: serverTimestamp(),
      });
      batch.update(doc(db, 'feedPosts', postId('alice')), { likeCount: increment(1) });
      await assertFails(batch.commit());
    });

    test('un-liking removes the like and decrements by one', async () => {
      await seedMembers();
      await seedPost('alice');
      await assertSucceeds(like(as('bob'), 'bob', 'alice'));
      await assertSucceeds(unlike(as('bob'), 'bob', 'alice'));
    });

    test('the counter cannot be decremented without having liked', async () => {
      await seedMembers();
      await seedPost('alice', 3);
      await assertFails(updateDoc(doc(as('bob'), 'feedPosts', postId('alice')), { likeCount: increment(-1) }));
      await assertFails(unlike(as('bob'), 'bob', 'alice'));
    });

    test('likes are private to whoever gave them', async () => {
      await seedMembers();
      await seedPost('alice');
      await like(as('bob'), 'bob', 'alice');
      const mine = (db, uid) => query(collection(db, 'feedLikes'), where('userId', '==', uid), where('dayKey', '==', dayKey));
      await assertSucceeds(getDocs(mine(as('bob'), 'bob')));
      await assertFails(getDocs(mine(as('alice'), 'bob')));
      await assertFails(getDoc(doc(as('alice'), 'feedLikes', `${postId('alice')}_bob`)));
    });

    test('a like left behind by a deleted answer can be removed', async () => {
      await seedMembers();
      await seed((db) =>
        setDoc(doc(db, 'feedLikes', `${postId('alice')}_bob`), {
          postId: postId('alice'),
          userId: 'bob',
          dayKey,
          createdAt: Timestamp.now(),
        }),
      );
      await assertSucceeds(deleteDoc(doc(as('bob'), 'feedLikes', `${postId('alice')}_bob`)));
    });

    test('a guardian cannot like', async () => {
      await seedMembers();
      await seedPost('alice');
      await assertFails(like(as('gina'), 'gina', 'alice'));
    });

    test('a member who has not finished their profile cannot like', async () => {
      await seedMembers();
      await seed((db) => setDoc(doc(db, 'users', 'dave'), { accountType: 'single' }));
      await seedPost('alice');
      await assertFails(like(as('dave'), 'dave', 'alice'));
    });
  });
});
