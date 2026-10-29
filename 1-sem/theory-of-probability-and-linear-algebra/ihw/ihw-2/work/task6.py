import numpy as np

np.random.seed(16)


def simulate_markov_chain(transition_matrix, initial_state, steps):
    states = [initial_state]
    current_state = initial_state

    for _ in range(steps):
        current_state = np.random.choice(
            a=len(transition_matrix),
            p=transition_matrix[current_state]
        )
        states.append(current_state)

    return states


transition_matrix = np.array([
    [2, 2, 4, 0, 0, 2, 0, 0],
    [3, 2, 0, 0, 0, 3, 2, 0],
    [1, 0, 1, 0, 0, 3, 5, 0],
    [0, 0, 0, 3, 0, 0, 0, 7],
    [0, 1, 0, 4, 2, 0, 2, 1],
    [2, 3, 2, 0, 0, 3, 0, 0],
    [0, 4, 1, 0, 0, 3, 2, 0],
    [0, 0, 0, 4, 0, 0, 0, 6]
]) / 10

runs = [(1, 10), (5, 50), (3, 100), (6, 1000), (4, 100), (8, 1000)]

for initial_state, steps in runs:
    trajectory = simulate_markov_chain(transition_matrix, initial_state - 1, steps)
    trajectory = [int(state) + 1 for state in trajectory]
    print(f'Initial State: {initial_state}, Steps: {steps}, Trajectory: {trajectory}')
