import { ChangeDetectionStrategy, Component } from '@angular/core';
import { addIcons } from 'ionicons';
import { homeOutline, informationCircleOutline } from 'ionicons/icons';
import {
  IonIcon,
  IonLabel,
  IonTabBar,
  IonTabButton,
  IonTabs,
} from '@ionic/angular/standalone';

@Component({
  selector: 'app-tabs',
  imports: [IonTabs, IonTabBar, IonTabButton, IonIcon, IonLabel],
  templateUrl: './tabs.page.html',
  styleUrl: './tabs.page.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TabsPage {
  constructor() {
    addIcons({
      'home-outline': homeOutline,
      'information-circle-outline': informationCircleOutline,
    });
  }
}
