// Dev-backend environment. The Docker build copies this over
// environment.prod.ts when ENV_NAME=dev, so a production build points at the
// dev Firebase project while staying fully optimized.

export const environment = {
  production: true,
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
