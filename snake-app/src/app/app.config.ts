import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter([
      { path: '', loadComponent: () => import('./snake/snake-game.component').then(m => m.SnakeGameComponent) },
      { path: '**', redirectTo: '' }
    ])
  ]
};