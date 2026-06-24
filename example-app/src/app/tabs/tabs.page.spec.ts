import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { provideIonicAngular } from '@ionic/angular/standalone';

import { TabsPage } from './tabs.page';

describe('TabsPage', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TabsPage],
      providers: [provideIonicAngular(), provideRouter([])],
    }).compileComponents();
  });

  it('should create the tab shell', () => {
    const fixture = TestBed.createComponent(TabsPage);
    expect(fixture.componentInstance).toBeTruthy();
  });
});
