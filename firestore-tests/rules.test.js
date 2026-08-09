const assert = require('assert');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'zeus-rules-test',
    firestore: {
      rules: fs.readFileSync('../firestore.rules', 'utf8'),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

describe('Firestore security rules', () => {
  it('a user can read and write their own user doc', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const db = alice.firestore();

    await assertSucceeds(db.doc('users/alice').set({ name: 'Alice' }));
    await assertSucceeds(db.doc('users/alice').get());
  });

  it('a user cannot read or write another user\'s doc', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const db = alice.firestore();

    await assertFails(db.doc('users/bob').set({ name: 'Bob' }));
    await assertFails(db.doc('users/bob').get());
  });

  it('a user cannot write another user\'s checkIns subcollection', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const db = alice.firestore();

    await assertFails(db.doc('users/bob/checkIns/2026-08-02').set({ type: 'checked_in' }));
  });

  it('a user cannot write another user\'s foodLogs subcollection', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const db = alice.firestore();

    await assertFails(db.doc('users/bob/foodLogs/2026-08-02').set({ meals: {} }));
  });

  it('a user can write their own checkIns, splitDays, workoutLogs, and foodLogs subcollections', async () => {
    const alice = testEnv.authenticatedContext('alice');
    const db = alice.firestore();

    await assertSucceeds(db.doc('users/alice/checkIns/2026-08-02').set({ type: 'checked_in' }));
    await assertSucceeds(db.doc('users/alice/splitDays/monday').set({ label: 'Chest' }));
    await assertSucceeds(db.doc('users/alice/workoutLogs/log1').set({ date: '2026-08-02' }));
    await assertSucceeds(db.doc('users/alice/foodLogs/2026-08-02').set({ meals: {} }));
  });

  it('an unauthenticated request is denied entirely', async () => {
    const anon = testEnv.unauthenticatedContext();
    const db = anon.firestore();

    await assertFails(db.doc('users/alice').get());
  });
});
