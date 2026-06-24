// Default (development) environment.
//
// For a production build Angular replaces this file with environment.prod.ts
// via the `fileReplacements` in angular.json. The Docker build first copies
// environment.<ENV_NAME>.ts over environment.prod.ts, so one production build
// can be pointed at the dev or prod backend (see the example-app Dockerfile).

export const environment = {
  production: false,
  APIEndpoints: '',
};

export const firebaseConfig = {
  apiKey: 'API_KEY',
  authDomain: 'AUTH_DOMAIN',
  databaseURL: 'DATABASE_URL',
  projectId: 'example-app-dev',
  storageBucket: 'example-app-dev.appspot.com',
  messagingSenderId: 'SENDER_ID',
  appId: 'APP_ID',
  measurementId: 'MEASUREMENT_ID',
};
