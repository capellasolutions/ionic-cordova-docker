import { TestBed } from '@angular/core/testing';
import { HomePage } from './home.page';

describe('HomePage', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HomePage],
    }).compileComponents();
  });

  it('should create', () => {
    const fixture = TestBed.createComponent(HomePage);
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('updates the signal and computed value without zone.js', async () => {
    const fixture = TestBed.createComponent(HomePage);
    await fixture.whenStable();
    const el = fixture.nativeElement as HTMLElement;
    expect(el.querySelector('[data-testid="count"]')?.textContent).toContain('0');
    expect(el.querySelector('[data-testid="doubled"]')?.textContent).toContain('0');

    fixture.componentInstance.increment();
    fixture.componentInstance.increment();
    await fixture.whenStable();

    expect(el.querySelector('[data-testid="count"]')?.textContent).toContain('2');
    expect(el.querySelector('[data-testid="doubled"]')?.textContent).toContain('4');
  });
});
