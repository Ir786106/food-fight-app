// Firebase Messaging Service Worker for Food Fight Web
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyDummyKeyReplaceInProd",
  authDomain: "food-fight-424a1.firebaseapp.com",
  projectId: "food-fight-424a1",
  storageBucket: "food-fight-424a1.appspot.com",
  messagingSenderId: "585587375994",
  appId: "1:585587375994:web:644a860ebc2fcce86835a2"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification?.title || 'Food Fight 🥊';
  const notificationOptions = {
    body: payload.notification?.body || 'You have an update on your order.',
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
