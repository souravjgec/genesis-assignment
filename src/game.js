export const GRID_SIZE = 16;
export const TICK_MS = 140;

export const DIRECTIONS = {
  up: { x: 0, y: -1 },
  down: { x: 0, y: 1 },
  left: { x: -1, y: 0 },
  right: { x: 1, y: 0 },
};

const INITIAL_SNAKE = [
  { x: 7, y: 8 },
  { x: 6, y: 8 },
  { x: 5, y: 8 },
];

export function createInitialState(random = Math.random) {
  const snake = INITIAL_SNAKE.map((segment) => ({ ...segment }));

  return {
    gridSize: GRID_SIZE,
    snake,
    direction: "right",
    pendingDirection: "right",
    food: spawnFood(snake, GRID_SIZE, random),
    score: 0,
    status: "ready",
  };
}

export function setDirection(state, direction) {
  if (!DIRECTIONS[direction]) {
    return state;
  }

  if (isOppositeDirection(state.direction, direction) && state.snake.length > 1) {
    return state;
  }

  return {
    ...state,
    pendingDirection: direction,
  };
}

export function togglePause(state) {
  if (state.status === "game-over") {
    return state;
  }

  if (state.status === "ready") {
    return {
      ...state,
      status: "running",
    };
  }

  return {
    ...state,
    status: state.status === "paused" ? "running" : "paused",
  };
}

export function advanceState(state, random = Math.random) {
  if (state.status === "game-over" || state.status === "paused") {
    return state;
  }

  const direction = getResolvedDirection(state.direction, state.pendingDirection, state.snake.length);
  const movement = DIRECTIONS[direction];
  const head = state.snake[0];
  const nextHead = { x: head.x + movement.x, y: head.y + movement.y };
  const grows = positionsMatch(nextHead, state.food);
  const nextSnake = [nextHead, ...state.snake];

  if (!grows) {
    nextSnake.pop();
  }

  const hitWall =
    nextHead.x < 0 ||
    nextHead.y < 0 ||
    nextHead.x >= state.gridSize ||
    nextHead.y >= state.gridSize;
  const hitSelf = nextSnake.slice(1).some((segment) => positionsMatch(segment, nextHead));

  if (hitWall || hitSelf) {
    return {
      ...state,
      direction,
      pendingDirection: direction,
      status: "game-over",
    };
  }

  return {
    ...state,
    snake: nextSnake,
    direction,
    pendingDirection: direction,
    food: grows ? spawnFood(nextSnake, state.gridSize, random) : state.food,
    score: grows ? state.score + 1 : state.score,
    status: "running",
  };
}

export function spawnFood(snake, gridSize, random = Math.random) {
  const occupied = new Set(snake.map((segment) => `${segment.x},${segment.y}`));
  const available = [];

  for (let y = 0; y < gridSize; y += 1) {
    for (let x = 0; x < gridSize; x += 1) {
      const key = `${x},${y}`;
      if (!occupied.has(key)) {
        available.push({ x, y });
      }
    }
  }

  if (available.length === 0) {
    return null;
  }

  const index = Math.floor(random() * available.length);
  return available[index];
}

function getResolvedDirection(current, pending, snakeLength) {
  if (snakeLength > 1 && isOppositeDirection(current, pending)) {
    return current;
  }

  return pending;
}

function isOppositeDirection(current, next) {
  return (
    (current === "up" && next === "down") ||
    (current === "down" && next === "up") ||
    (current === "left" && next === "right") ||
    (current === "right" && next === "left")
  );
}

function positionsMatch(a, b) {
  return Boolean(a && b && a.x === b.x && a.y === b.y);
}
