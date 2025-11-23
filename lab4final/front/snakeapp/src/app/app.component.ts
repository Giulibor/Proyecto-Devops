import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { SnakeGameComponent } from './snake/snake-game.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, SnakeGameComponent],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css'],
})
export class AppComponent {}