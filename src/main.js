import {
  GRID_SIZE,
  TICK_MS,
  advanceState,
  createInitialState,
  setDirection,
  togglePause,
} from "./game.js";

const boardElement = document.querySelector("#board");
const scoreElement = document.querySelector("#score");
const statusElement = document.querySelector("#status");
const startButton = document.querySelector("#start-button");
const pauseButton = document.querySelector("#pause-button");
const restartButton = document.querySelector("#restart-button");
const controlButtons = document.querySelectorAll("[data-direction]");

let state = createInitialState();
let tickHandle = null;

buildBoard();
render();

document.addEventListener("keydown", handleKeydown);
startButton.addEventListener("click", startGame);
pauseButton.addEventListener("click", pauseOrResumeGame);
restartButton.addEventListener("click", restartGame);

controlButtons.forEach((button) => {
  button.addEventListener("click", () => {
    state = setDirection(state, button.dataset.direction);
    if (state.status === "ready") {
      startGame();
    }
    render();
  });
});

function buildBoard() {
  const cells = [];

  for (let index = 0; index < GRID_SIZE * GRID_SIZE; index += 1) {
    const cell = document.createElement("div");
    cell.className = "cell";
    cell.setAttribute("role", "gridcell");
    cells.push(cell);
  }

  boardElement.replaceChildren(...cells);
}

function render() {
  const cells = boardElement.children;

  for (const cell of cells) {
    cell.className = "cell";
  }

  state.snake.forEach((segment, index) => {
    const cell = cells[getCellIndex(segment.x, segment.y)];
    if (!cell) {
      return;
    }

    cell.classList.add("snake");
    if (index === 0) {
      cell.classList.add("head");
    }
  });

  if (state.food) {
    const foodCell = cells[getCellIndex(state.food.x, state.food.y)];
    if (foodCell) {
      foodCell.classList.add("food");
    }
  }

  scoreElement.textContent = String(state.score);
  statusElement.textContent = formatStatus(state.status);
  pauseButton.textContent = state.status === "paused" ? "Resume" : "Pause";
}

function handleKeydown(event) {
  const direction = getDirectionForKey(event.key);

  if (event.key === " ") {
    event.preventDefault();
    pauseOrResumeGame();
    return;
  }

  if (!direction) {
    return;
  }

  event.preventDefault();
  state = setDirection(state, direction);

  if (state.status === "ready") {
    startGame();
  }

  render();
}

function startGame() {
  if (state.status === "game-over" || state.status === "running") {
    return;
  }

  if (!tickHandle) {
    tickHandle = window.setInterval(runTick, TICK_MS);
  }

  state = togglePause(state);
  render();
}

function pauseOrResumeGame() {
  if (state.status === "ready" || state.status === "game-over") {
    return;
  }

  state = togglePause(state);
  render();
}

function restartGame() {
  if (tickHandle) {
    window.clearInterval(tickHandle);
    tickHandle = null;
  }

  state = createInitialState();
  render();
}

function runTick() {
  state = advanceState(state);
  render();

  if (state.status === "game-over" && tickHandle) {
    window.clearInterval(tickHandle);
    tickHandle = null;
  }
}

function getCellIndex(x, y) {
  return y * GRID_SIZE + x;
}

function getDirectionForKey(key) {
  switch (key.toLowerCase()) {
    case "arrowup":
    case "w":
      return "up";
    case "arrowdown":
    case "s":
      return "down";
    case "arrowleft":
    case "a":
      return "left";
    case "arrowright":
    case "d":
      return "right";
    default:
      return null;
  }
}

function formatStatus(status) {
  switch (status) {
    case "ready":
      return "Ready";
    case "running":
      return "Running";
    case "paused":
      return "Paused";
    case "game-over":
      return "Game over";
    default:
      return status;
  }
}
