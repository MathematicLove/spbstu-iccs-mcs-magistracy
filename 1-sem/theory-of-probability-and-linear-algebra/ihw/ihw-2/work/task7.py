import numpy as np

np.random.seed(16)
np.set_printoptions(precision=4, suppress=True)

transition_matrix1 = np.array([
    [2, 2, 4, 2, 0],
    [3, 2, 0, 3, 2],
    [1, 0, 1, 3, 5],
    [2, 3, 2, 3, 0],
    [0, 4, 1, 3, 2]
]) / 10
transition_matrix2 = np.array([
    [3, 7],
    [4, 6]
]) / 10

labels1 = [1, 2, 3, 6, 7]
labels2 = [4, 8]


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


def calculate_state_percentages(states, num_states):
    counts = np.bincount(states, minlength=num_states)
    percentages = counts / len(states)
    return percentages


def stationary_distribution(transition_matrix):
    eigenvalues, eigenvectors = np.linalg.eig(transition_matrix.T)
    stationary_vector = eigenvectors[:, np.isclose(eigenvalues, 1)]
    stationary_vector = stationary_vector / np.sum(stationary_vector)
    return stationary_vector.real.flatten()


def simulation(steps, initial_state, transition_matrix, labels):
    print(f"Initial state: {labels[initial_state]}, steps: {steps}")

    trajectory = simulate_markov_chain(transition_matrix, initial_state, steps)

    percentages = calculate_state_percentages(trajectory, len(transition_matrix))
    print(f"Percentages: {percentages}")
    stationary_vector = stationary_distribution(transition_matrix)
    print(f"Final distribution: {stationary_vector}")

    difference = np.abs(percentages - stationary_vector)
    print(f"Difference: {difference}\n")


print("Class 1: states (1, 2, 3, 6, 7)\n")
simulation(10, 0, transition_matrix1, labels1)
simulation(50, 1, transition_matrix1, labels1)
simulation(100, 2, transition_matrix1, labels1)
simulation(1000, 3, transition_matrix1, labels1)

print("Class 2: states (4, 8)\n")
simulation(10, 0, transition_matrix2, labels2)
simulation(50, 1, transition_matrix2, labels2)
simulation(100, 0, transition_matrix2, labels2)
simulation(1000, 1, transition_matrix2, labels2)
