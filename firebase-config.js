// Firebase Client Configuration
// REPLACE these values with your actual Firebase project settings from the Firebase Console!
export const firebaseConfig = {
  apiKey: "AIzaSyB8JT7__rwaWRzyEzIJEeUSwCT05VLCljc",
  authDomain: "selvi-s-beauty-parlour.firebaseapp.com",
  projectId: "selvi-s-beauty-parlour",
  storageBucket: "selvi-s-beauty-parlour.firebasestorage.app",
  messagingSenderId: "1054885257137",
  appId: "1:1054885257137:android:210b3a260c0bb39911a790"
};

// Check if the developer has configured Firebase yet
export const isFirebaseConfigured = () => {
  return firebaseConfig.apiKey && firebaseConfig.apiKey !== "YOUR_API_KEY";
};

