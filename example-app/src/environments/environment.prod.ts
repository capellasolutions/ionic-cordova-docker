// Prod-backend environment. This is the file Angular swaps in for a production
// build (see angular.json fileReplacements). The Docker build overwrites it with
// environment.<ENV_NAME>.ts for non-prod targets before building.

export const environment = {
  production: true,
  APIEndpoints: '',
};

export const firebaseConfig = {
  apiKey: 'API_KEY',
  authDomain: 'AUTH_DOMAIN',
  databaseURL: 'DATABASE_URL',
  projectId: 'example-app-prod',
  storageBucket: 'example-app-prod.appspot.com',
  messagingSenderId: 'SENDER_ID',
  appId: 'APP_ID',
  measurementId: 'MEASUREMENT_ID',
};
