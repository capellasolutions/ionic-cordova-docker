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

  it('tracks tasks via signals and computed values without zone.js', async () => {
    const fixture = TestBed.createComponent(HomePage);
    const home = fixture.componentInstance;
    await fixture.whenStable();
    const el = fixture.nativeElement as HTMLElement;

    // Seed: 3 tasks, 2 done / 1 open.
    expect(el.querySelector('[data-testid="remaining"]')?.textContent).toContain('1');
    expect(el.querySelector('[data-testid="completed"]')?.textContent).toContain('2');

    home.draft.set('Write the README');
    home.addTodo();
    await fixture.whenStable();
    expect(home.todos().length).toBe(4);
    expect(el.querySelector('[data-testid="remaining"]')?.textContent).toContain('2');

    // Complete the remaining seed task, then drop everything that is done.
    home.toggleTodo(3);
    await fixture.whenStable();
    expect(home.remaining()).toBe(1);

    home.clearCompleted();
    await fixture.whenStable();
    expect(home.completed()).toBe(0);
    expect(home.todos().length).toBe(1);
  });
});
