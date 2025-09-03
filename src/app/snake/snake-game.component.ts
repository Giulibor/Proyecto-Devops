import { Component, ViewChild, ElementRef, AfterViewInit, HostListener, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';

type Pos = { x: number; y: number };
type Dir = { x: number; y: number };

@Component({
  selector: 'app-snake-game',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './snake-game.component.html',
  styleUrls: ['./snake-game.component.css']
})
export class SnakeGameComponent implements AfterViewInit {
  @ViewChild('gameCanvas', { static: true }) canvasRef!: ElementRef<HTMLCanvasElement>;
  private ctx!: CanvasRenderingContext2D;

  // Configuración del tablero y juego
  readonly cellSize = 20;         // tamaño de cada celda (px)
  readonly cols = 24;             // ancho en celdas
  readonly rows = 18;             // alto en celdas
  readonly initialSpeedMs = 140;  // menor = más rápido
  readonly minSpeedMs = 60;
  readonly speedStepMs = 8;       // cuánto acelera por comida
  readonly wallMode = true;       // true: colisión con pared; false: atraviesa bordes (wrap)

  // Estado reactivo básico con signals (Angular 16+)
  score = signal(0);
  highScore = signal<number>(Number(localStorage.getItem('snake_high_score') || 0));
  speedMs = signal(this.initialSpeedMs);
  isRunning = signal(false);
  isGameOver = signal(false);
  isPaused = signal(false);

  // Snake y comida
  private snake: Pos[] = [];
  private direction: Dir = { x: 1, y: 0 };     // hacia la derecha
  private nextDirection: Dir = { x: 1, y: 0 };
  private food!: Pos;

  // Loop
  private lastFrameTs = 0;
  private accMs = 0;
  private rafId: number | null = null;

  // Canvas size (en px)
  canvasW = this.cols * this.cellSize;
  canvasH = this.rows * this.cellSize;

  ngAfterViewInit(): void {
    const ctx = this.canvasRef.nativeElement.getContext('2d');
    if (!ctx) throw new Error('No se pudo obtener el contexto 2D del canvas');
    this.ctx = ctx;
    this.resetGame();
    this.draw(); // dibujo inicial (grid + snake + food)
  }

  /** Reinicia el estado del juego a valores por defecto */
  resetGame(): void {
    this.isGameOver.set(false);
    this.isPaused.set(false);
    this.score.set(0);
    this.speedMs.set(this.initialSpeedMs);
    // Snake inicial en el centro
    const startX = Math.floor(this.cols / 2);
    const startY = Math.floor(this.rows / 2);
    this.snake = [
      { x: startX - 2, y: startY },
      { x: startX - 1, y: startY },
      { x: startX,     y: startY }
    ];
    this.direction = { x: 1, y: 0 };
    this.nextDirection = { x: 1, y: 0 };
    this.spawnFood();
    this.lastFrameTs = 0;
    this.accMs = 0;
    this.stopLoop();
  }

  /** Inicia el juego (o reanuda si estaba en pausa) */
  start(): void {
    if (this.isGameOver()) this.resetGame();
    this.isRunning.set(true);
    this.isPaused.set(false);
    this.lastFrameTs = performance.now();
    this.loop(this.lastFrameTs);
  }

  /** Pausa/continúa */
  togglePause(): void {
    if (!this.isRunning() || this.isGameOver()) return;
    const pause = !this.isPaused();
    this.isPaused.set(pause);
    if (!pause) {
      // reanudar
      this.lastFrameTs = performance.now();
      this.loop(this.lastFrameTs);
    } else {
      this.stopLoop();
    }
  }

  /** Loop principal con requestAnimationFrame */
  private loop = (ts: number) => {
    if (!this.isRunning() || this.isPaused() || this.isGameOver()) return;

    const dt = ts - this.lastFrameTs;
    this.lastFrameTs = ts;
    this.accMs += dt;

    // Avanzar una "tick" cuando acumulamos más que la velocidad actual
    if (this.accMs >= this.speedMs()) {
      this.accMs = 0;
      this.tick();
      this.draw();
    }
    this.rafId = requestAnimationFrame(this.loop);
  };

  private stopLoop(): void {
    if (this.rafId != null) {
      cancelAnimationFrame(this.rafId);
      this.rafId = null;
    }
  }

  /** Un "paso" de la simulación: mueve snake, detecta colisiones, come, acelera. */
  private tick(): void {
    // Actualizar dirección (evita girar 180° instantáneo)
    this.direction = this.nextDirection;

    // Calcular nueva cabeza
    let head = this.snake[this.snake.length - 1];
    let newHead: Pos = { x: head.x + this.direction.x, y: head.y + this.direction.y };

    // Paredes o wrap
    if (this.wallMode) {
      if (newHead.x < 0 || newHead.x >= this.cols || newHead.y < 0 || newHead.y >= this.rows) {
        this.gameOver();
        return;
      }
    } else {
      // Wrap-around
      if (newHead.x < 0) newHead.x = this.cols - 1;
      if (newHead.x >= this.cols) newHead.x = 0;
      if (newHead.y < 0) newHead.y = this.rows - 1;
      if (newHead.y >= this.rows) newHead.y = 0;
    }

    // Colisión consigo misma
    if (this.snake.some(seg => seg.x === newHead.x && seg.y === newHead.y)) {
      this.gameOver();
      return;
    }

    // Avanza la snake
    this.snake.push(newHead);

    // Comer comida o mover cola
    if (newHead.x === this.food.x && newHead.y === this.food.y) {
      this.score.set(this.score() + 1);
      // Acelerar levemente por cada comida
      const newSpeed = Math.max(this.minSpeedMs, this.speedMs() - this.speedStepMs);
      this.speedMs.set(newSpeed);
      this.spawnFood();
    } else {
      // no comió: quitar cola
      this.snake.shift();
    }
  }

  private gameOver(): void {
    this.isGameOver.set(true);
    this.isRunning.set(false);
    this.stopLoop();
    if (this.score() > this.highScore()) {
      this.highScore.set(this.score());
      localStorage.setItem('snake_high_score', String(this.score()));
    }
  }

  /** Genera comida en una celda libre aleatoria */
  private spawnFood(): void {
    let p: Pos;
    do {
      p = {
        x: Math.floor(Math.random() * this.cols),
        y: Math.floor(Math.random() * this.rows)
      };
    } while (this.snake.some(seg => seg.x === p.x && seg.y === p.y));
    this.food = p;
  }

  // === Dibujo (Canvas) ===

  private clear(): void {
    this.ctx.fillStyle = '#111';
    this.ctx.fillRect(0, 0, this.canvasW, this.canvasH);
  }

  private drawGrid(): void {
    this.ctx.strokeStyle = '#222';
    this.ctx.lineWidth = 1;
    for (let x = 0; x <= this.cols; x++) {
      this.ctx.beginPath();
      this.ctx.moveTo(x * this.cellSize + 0.5, 0);
      this.ctx.lineTo(x * this.cellSize + 0.5, this.canvasH);
      this.ctx.stroke();
    }
    for (let y = 0; y <= this.rows; y++) {
      this.ctx.beginPath();
      this.ctx.moveTo(0, y * this.cellSize + 0.5);
      this.ctx.lineTo(this.canvasW, y * this.cellSize + 0.5);
      this.ctx.stroke();
    }
  }

  private drawSnake(): void {
    this.ctx.fillStyle = '#4CAF50';
    for (const seg of this.snake) {
      this.ctx.fillRect(seg.x * this.cellSize, seg.y * this.cellSize, this.cellSize - 1, this.cellSize - 1);
    }
    // cabeza destacada
    const head = this.snake[this.snake.length - 1];
    this.ctx.fillStyle = '#7CFC00';
    this.ctx.fillRect(head.x * this.cellSize, head.y * this.cellSize, this.cellSize - 1, this.cellSize - 1);
  }

  private drawFood(): void {
    this.ctx.fillStyle = '#FF5252';
    this.ctx.fillRect(this.food.x * this.cellSize, this.food.y * this.cellSize, this.cellSize - 1, this.cellSize - 1);
  }

  private drawHud(): void {
    this.ctx.fillStyle = '#fff';
    this.ctx.font = '14px system-ui, -apple-system, Segoe UI, Roboto, Arial';
    this.ctx.fillText(`Score: ${this.score()}  High: ${this.highScore()}  Speed: ${this.speedMs()}ms`, 10, 18);
  }

  private draw(): void {
    this.clear();
    this.drawGrid();
    this.drawSnake();
    this.drawFood();
    this.drawHud();
    if (this.isGameOver()) this.overlay('GAME OVER - Press Start to retry');
    else if (this.isPaused()) this.overlay('PAUSED');
    else if (!this.isRunning()) this.overlay('Press Start to play');
  }

  private overlay(text: string): void {
    this.ctx.fillStyle = 'rgba(0,0,0,0.4)';
    this.ctx.fillRect(0, 0, this.canvasW, this.canvasH);
    this.ctx.fillStyle = '#fff';
    this.ctx.font = 'bold 20px system-ui, -apple-system, Segoe UI, Roboto, Arial';
    this.ctx.textAlign = 'center';
    this.ctx.fillText(text, this.canvasW / 2, this.canvasH / 2);
    this.ctx.textAlign = 'left';
  }

  // === Input ===

  @HostListener('window:keydown', ['$event'])
  onKeydown(e: KeyboardEvent) {
    const k = e.key.toLowerCase();
    let desired: Dir | null = null;
    if (k === 'arrowup' || k === 'w') desired = { x: 0, y: -1 };
    if (k === 'arrowdown' || k === 's') desired = { x: 0, y: 1 };
    if (k === 'arrowleft' || k === 'a') desired = { x: -1, y: 0 };
    if (k === 'arrowright' || k === 'd') desired = { x: 1, y: 0 };
    if (k === ' ' || k === 'enter') { this.togglePause(); return; }

    if (desired) {
      // Evitar giro de 180°
      if (this.direction.x + desired.x === 0 && this.direction.y + desired.y === 0) return;
      this.nextDirection = desired;
      e.preventDefault();
    }
  }
}