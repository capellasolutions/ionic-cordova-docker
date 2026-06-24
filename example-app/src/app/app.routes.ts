import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: 'tabs',
    loadComponent: () => import('./tabs/tabs.page').then((m) => m.TabsPage),
    children: [
      {
        path: 'home',
        loadComponent: () => import('./home/home.page').then((m) => m.HomePage),
      },
      {
        path: 'about',
        loadComponent: () => import('./about/about.page').then((m) => m.AboutPage),
      },
      {
        path: '',
        redirectTo: 'home',
        pathMatch: 'full',
      },
    ],
  },
  {
    path: '',
    redirectTo: 'tabs/home',
    pathMatch: 'full',
  },
];
