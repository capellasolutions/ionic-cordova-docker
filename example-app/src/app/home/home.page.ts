import { ChangeDetectionStrategy, Component, computed, signal } from '@angular/core';
import {
  IonBadge,
  IonButton,
  IonButtons,
  IonCheckbox,
  IonContent,
  IonHeader,
  IonInput,
  IonItem,
  IonLabel,
  IonList,
  IonNote,
  IonTitle,
  IonToolbar,
} from '@ionic/angular/standalone';

interface Todo {
  id: number;
  title: string;
  done: boolean;
}

@Component({
  selector: 'app-home',
  imports: [
    IonHeader,
    IonToolbar,
    IonTitle,
    IonButtons,
    IonButton,
    IonContent,
    IonList,
    IonItem,
    IonLabel,
    IonInput,
    IonCheckbox,
    IonBadge,
    IonNote,
  ],
  templateUrl: './home.page.html',
  styleUrl: './home.page.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class HomePage {
  private nextId = 4;

  readonly draft = signal('');
  readonly todos = signal<Todo[]>([
    { id: 1, title: 'Scaffold on Angular 22', done: true },
    { id: 2, title: 'Wire Ionic v9 (zoneless)', done: true },
    { id: 3, title: 'Ship the Cordova build', done: false },
  ]);

  readonly remaining = computed(() => this.todos().filter((todo) => !todo.done).length);
  readonly completed = computed(() => this.todos().filter((todo) => todo.done).length);

  onDraftInput(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.draft.set(target.value ?? '');
  }

  addTodo(): void {
    const title = this.draft().trim();
    if (!title) {
      return;
    }
    this.todos.update((list) => [...list, { id: this.nextId++, title, done: false }]);
    this.draft.set('');
  }

  toggleTodo(id: number): void {
    this.todos.update((list) =>
      list.map((todo) => (todo.id === id ? { ...todo, done: !todo.done } : todo)),
    );
  }

  removeTodo(id: number): void {
    this.todos.update((list) => list.filter((todo) => todo.id !== id));
  }

  clearCompleted(): void {
    this.todos.update((list) => list.filter((todo) => !todo.done));
  }
}
