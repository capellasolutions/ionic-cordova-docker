import { TestBed } from '@angular/core/testing';
import { AboutPage } from './about.page';

describe('AboutPage', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [AboutPage],
    }).compileComponents();
  });

  it('should create', () => {
    const fixture = TestBed.createComponent(AboutPage);
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('updates the live counter via signals without zone.js', async () => {
    const fixture = TestBed.createComponent(AboutPage);
    const about = fixture.componentInstance;
    await fixture.whenStable();
    const el = fixture.nativeElement as HTMLElement;

    expect(el.querySelector('[data-testid="taps"]')?.textContent).toContain('0');

    about.tap();
    about.tap();
    about.tap();
    await fixture.whenStable();

    expect(el.querySelector('[data-testid="taps"]')?.textContent).toContain('3');
    expect(el.querySelector('[data-testid="doubled"]')?.textContent).toContain('6');
  });
});
