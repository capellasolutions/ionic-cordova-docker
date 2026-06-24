import { ChangeDetectionStrategy, Component, computed, signal } from '@angular/core';
import {
  IonButton,
  IonContent,
  IonHeader,
  IonItem,
  IonLabel,
  IonList,
  IonNote,
  IonText,
  IonTitle,
  IonToolbar,
} from '@ionic/angular/standalone';

import { environment, firebaseConfig } from '../../environments/environment';

interface StackItem {
  label: string;
  value: string;
}

@Component({
  selector: 'app-about',
  imports: [
    IonHeader,
    IonToolbar,
    IonTitle,
    IonContent,
    IonList,
    IonItem,
    IonLabel,
    IonNote,
    IonText,
    IonButton,
  ],
  templateUrl: './about.page.html',
  styleUrl: './about.page.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AboutPage {
  readonly stack: readonly StackItem[] = [
    { label: 'Angular', value: '22 · zoneless' },
    { label: 'Ionic', value: 'v9 pre-release' },
    { label: 'Build', value: 'esbuild application builder' },
    { label: 'Tests', value: 'Vitest + jsdom' },
    { label: 'Native', value: 'Cordova (Android / iOS)' },
    { label: 'Toolchain', value: 'Ubuntu 26.04 Docker image' },
  ];

  readonly buildMode = environment.production ? 'production' : 'development';
  readonly firebaseProjectId = firebaseConfig.projectId;

  readonly taps = signal(0);
  readonly doubled = computed(() => this.taps() * 2);

  tap(): void {
    this.taps.update((value) => value + 1);
  }

  reset(): void {
    this.taps.set(0);
  }
}
