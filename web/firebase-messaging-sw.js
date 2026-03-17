// Firebase Cloud Messaging Service Worker
// This file is required for web push notifications

importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize Firebase (values will be injected by Flutter)
// The actual config will come from firebase_options.dart
firebase.initializeApp({
  apiKey: "AIzaSyDhDEeMPbKf1UJ2TL2V-WnXpgL3BAGRC9E",
  authDomain: "kf-product.firebaseapp.com",
  projectId: "kf-product",
  storageBucket: "kf-product.firebasestorage.app",
  messagingSenderId: "594189782744",
  appId: "1:594189782744:web:8ef02f55a5581b902951ad"
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'New Notification';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.messageId,
    requireInteraction: false,
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

