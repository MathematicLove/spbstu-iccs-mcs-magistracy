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
    [2, 3, 0, 0, 1, 0, 2, 2],
    [1, 2, 0, 0, 3, 0, 4, 0],
    [0, 0, 2, 4, 0, 4, 0, 0],
    [0, 0, 1, 2, 6, 1, 0, 0],
    [1, 0, 0, 0, 5, 0, 0, 4],
    [0, 0, 2, 4, 4, 0, 0, 0],
    [2, 3, 0, 0, 0, 0, 4, 1],
    [3, 0, 0, 0, 2, 0, 2, 3]
]) / 10

runs = [(1, 10), (3, 50), (5, 100), (7, 1000), (6, 100), (8, 1000)]

for initial_state, steps in runs:
    trajectory = simulate_markov_chain(transition_matrix, initial_state - 1, steps)
    trajectory = [int(state) + 1 for state in trajectory]
    print(f'Initial State: {initial_state}, Steps: {steps}, Trajectory: {trajectory}')
