const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();
const storage = admin.storage();

// Dummy user data
const dummyUsers = [
  {
    name: "Alice Johnson",
    username: "alice_j",
    email: "alice@example.com",
    bio: "Fitness enthusiast 💪 | Runner | Healthy living",
    password: "password123"
  },
  {
    name: "Bob Smith",
    username: "bob_smith",
    email: "bob@example.com",
    bio: "Food lover 🍕 | Chef | Trying new recipes every day",
    password: "password123"
  },
  {
    name: "Carol Davis",
    username: "carol_d",
    email: "carol@example.com",
    bio: "Yoga instructor 🧘‍♀️ | Wellness coach | Living mindfully",
    password: "password123"
  },
  {
    name: "David Wilson",
    username: "david_wilson",
    email: "david@example.com",
    bio: "Outdoor adventurer 🏔️ | Hiking | Photography",
    password: "password123"
  },
  {
    name: "Emma Brown",
    username: "emma_b",
    email: "emma@example.com",
    bio: "Nutritionist 🥗 | Meal prep queen | Healthy recipes",
    password: "password123"
  },
  {
    name: "Frank Miller",
    username: "frank_m",
    email: "frank@example.com",
    bio: "Gym rat 💪 | Personal trainer | No pain no gain",
    password: "password123"
  },
  {
    name: "Grace Lee",
    username: "grace_lee",
    email: "grace@example.com",
    bio: "Plant-based lifestyle 🌱 | Vegan recipes | Sustainability",
    password: "password123"
  },
  {
    name: "Henry Taylor",
    username: "henry_t",
    email: "henry@example.com",
    bio: "Marathon runner 🏃 | Training for my next race",
    password: "password123"
  }
];

// Dummy post data (captions and types)
const dummyPosts = [
  { caption: "Morning run complete! 5 miles done 🏃‍♀️", type: "activity" },
  { caption: "Healthy breakfast bowl to start the day right 🥗", type: "meal" },
  { caption: "Sunset vibes after a great workout", type: "freeform" },
  { caption: "Meal prep Sunday! Ready for the week 💪", type: "meal" },
  { caption: "New PR on deadlifts today! 💪", type: "activity" },
  { caption: "Homemade pizza night 🍕", type: "meal" },
  { caption: "Yoga session by the beach 🧘‍♀️", type: "activity" },
  { caption: "Trying out this new smoothie recipe", type: "meal" },
  { caption: "Hiking with the best views 🏔️", type: "activity" },
  { caption: "Post-workout glow ✨", type: "freeform" },
  { caption: "Healthy lunch prep for the week", type: "meal" },
  { caption: "Morning meditation complete 🧘", type: "activity" },
  { caption: "Dinner date night at home", type: "meal" },
  { caption: "Trail run in the mountains", type: "activity" },
  { caption: "Fresh salad for lunch 🥗", type: "meal" },
];

// Placeholder image URLs (using Lorem Picsum for random images)
const getRandomImageUrl = (seed) => {
  return `https://picsum.photos/seed/${seed}/1080/1080`;
};

async function createUsers() {
  console.log('Creating users...');
  const userIds = [];

  for (const userData of dummyUsers) {
    try {
      // Create user in Firebase Auth
      const userRecord = await auth.createUser({
        email: userData.email,
        password: userData.password,
        displayName: userData.name,
      });

      console.log(`Created user: ${userData.name} (${userRecord.uid})`);

      // Create user document in Firestore
      await db.collection('users').doc(userRecord.uid).set({
        name: userData.name,
        username: userData.username,
        email: userData.email.toLowerCase(),
        bio: userData.bio,
        photoUrl: '',
        followerCount: 0,
        followingCount: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      userIds.push(userRecord.uid);
    } catch (error) {
      console.error(`Error creating user ${userData.name}:`, error.message);
    }
  }

  return userIds;
}

async function createPosts(userIds) {
  console.log('Creating posts...');
  let postCount = 0;

  for (const userId of userIds) {
    // Each user creates 2-4 posts
    const numPosts = Math.floor(Math.random() * 3) + 2;

    for (let i = 0; i < numPosts; i++) {
      const postData = dummyPosts[Math.floor(Math.random() * dummyPosts.length)];
      const seed = `${userId}-${i}-${Date.now()}`;

      try {
        await db.collection('posts').add({
          userId: userId,
          imageUrl: getRandomImageUrl(seed),
          caption: postData.caption,
          type: postData.type,
          likeCount: Math.floor(Math.random() * 50),
          commentCount: Math.floor(Math.random() * 20),
          isArchived: false,
          createdAt: admin.firestore.Timestamp.fromDate(
            new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000) // Random date within last 30 days
          ),
        });

        postCount++;
        console.log(`Created post ${postCount} for user ${userId}`);
      } catch (error) {
        console.error(`Error creating post:`, error.message);
      }
    }
  }

  console.log(`Total posts created: ${postCount}`);
}

async function createFollows(userIds) {
  console.log('Creating follow relationships...');
  let followCount = 0;

  for (let i = 0; i < userIds.length; i++) {
    const followerId = userIds[i];

    // Each user follows 2-4 random other users
    const numFollows = Math.floor(Math.random() * 3) + 2;
    const followedUsers = new Set();

    for (let j = 0; j < numFollows; j++) {
      let followingId;
      do {
        followingId = userIds[Math.floor(Math.random() * userIds.length)];
      } while (followingId === followerId || followedUsers.has(followingId));

      followedUsers.add(followingId);

      try {
        // Create follow relationship
        await db.collection('follows').add({
          followerId: followerId,
          followingId: followingId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update follower count
        await db.collection('users').doc(followingId).update({
          followerCount: admin.firestore.FieldValue.increment(1),
        });

        // Update following count
        await db.collection('users').doc(followerId).update({
          followingCount: admin.firestore.FieldValue.increment(1),
        });

        followCount++;
        console.log(`Created follow: ${followerId} -> ${followingId}`);
      } catch (error) {
        console.error(`Error creating follow:`, error.message);
      }
    }
  }

  console.log(`Total follows created: ${followCount}`);
}

async function createLikes(userIds) {
  console.log('Creating likes...');

  // Get all posts
  const postsSnapshot = await db.collection('posts').get();
  const posts = postsSnapshot.docs;

  let likeCount = 0;

  for (const post of posts) {
    // 3-8 random users like each post
    const numLikes = Math.floor(Math.random() * 6) + 3;
    const likedUsers = new Set();

    for (let i = 0; i < Math.min(numLikes, userIds.length); i++) {
      let userId;
      do {
        userId = userIds[Math.floor(Math.random() * userIds.length)];
      } while (likedUsers.has(userId));

      likedUsers.add(userId);

      try {
        await db.collection('likes').add({
          postId: post.id,
          userId: userId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        likeCount++;
      } catch (error) {
        console.error(`Error creating like:`, error.message);
      }
    }

    // Update like count on post
    await post.ref.update({
      likeCount: likedUsers.size,
    });

    console.log(`Created ${likedUsers.size} likes for post ${post.id}`);
  }

  console.log(`Total likes created: ${likeCount}`);
}

async function createComments(userIds) {
  console.log('Creating comments...');

  const commentTexts = [
    "Amazing! 😍",
    "Love this!",
    "Great job! 💪",
    "This is awesome!",
    "Keep it up! 🔥",
    "Inspiring! ✨",
    "Looking good!",
    "Nice work! 👏",
    "Goals! 🙌",
    "This is great!",
  ];

  // Get all posts
  const postsSnapshot = await db.collection('posts').get();
  const posts = postsSnapshot.docs;

  let commentCount = 0;

  for (const post of posts) {
    // 2-5 random comments per post
    const numComments = Math.floor(Math.random() * 4) + 2;

    for (let i = 0; i < numComments; i++) {
      const userId = userIds[Math.floor(Math.random() * userIds.length)];
      const text = commentTexts[Math.floor(Math.random() * commentTexts.length)];

      try {
        await db.collection('comments').add({
          postId: post.id,
          userId: userId,
          text: text,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        commentCount++;
      } catch (error) {
        console.error(`Error creating comment:`, error.message);
      }
    }

    // Update comment count on post
    await post.ref.update({
      commentCount: numComments,
    });

    console.log(`Created ${numComments} comments for post ${post.id}`);
  }

  console.log(`Total comments created: ${commentCount}`);
}

async function main() {
  try {
    console.log('Starting data upload...\n');

    // Create users
    const userIds = await createUsers();
    console.log(`\nCreated ${userIds.length} users\n`);

    // Create posts
    await createPosts(userIds);
    console.log('\nPosts created\n');

    // Create follows
    await createFollows(userIds);
    console.log('\nFollow relationships created\n');

    // Create likes
    await createLikes(userIds);
    console.log('\nLikes created\n');

    // Create comments
    await createComments(userIds);
    console.log('\nComments created\n');

    console.log('✅ All dummy data uploaded successfully!');
    console.log('\nYou can now log in with any of these accounts:');
    console.log('Email: alice@example.com (or any other user email)');
    console.log('Password: password123');

    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

main();
