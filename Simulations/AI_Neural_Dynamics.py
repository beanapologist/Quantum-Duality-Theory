import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
import matplotlib.pyplot as plt


# Define QDT constants
class QDTConstants:
    GAMMA = 0.4497  # Damping coefficient
    ALPHA = 0.520   # Prime recursion
    BETA = 0.310    # Fractal recursion
    LAMBDA = 0.867  # Coupling constant
    PHI = 1.618033  # Golden ratio
    KAPPA_0 = 1.0   # Base time mediation


# Define QDT-inspired activation
def qdt_activation(x, t, constants):
    damping = torch.exp(-constants.GAMMA * t)
    oscillation = torch.sin(2 * np.pi * t * constants.ALPHA)
    modulation = 1 + constants.BETA * torch.cos(constants.PHI * t)
    kappa = constants.KAPPA_0 * damping * oscillation * modulation
    return torch.tanh(kappa * x)


# Define dynamic QDT-inspired neural network
class DynamicQDTNN(nn.Module):
    def __init__(self, input_size, hidden_size, output_size, time_steps=100):
        super(DynamicQDTNN, self).__init__()
        self.constants = QDTConstants()
        self.time_steps = time_steps
        self.time = torch.arange(0, time_steps).float()

        self.hidden_layer = nn.Linear(input_size, hidden_size)
        self.output_layer = nn.Linear(hidden_size, output_size)

    def forward(self, x, step):
        t = self.time[step % self.time_steps]
        x = self.hidden_layer(x)
        x = qdt_activation(x, t, self.constants)
        x = self.output_layer(x)
        return x


# Generate synthetic data for training
def generate_synthetic_data(num_samples=1000, input_size=1):
    x = np.linspace(-10, 10, num_samples)
    y = np.sin(x) + np.cos(0.5 * x) + 0.1 * np.random.randn(num_samples)
    return torch.tensor(x).float().view(-1, input_size), torch.tensor(y).float()


# Train the dynamic QDT network
def train_qdt_network(model, dataloader, num_epochs=50, learning_rate=0.01):
    criterion = nn.MSELoss()
    optimizer = optim.Adam(model.parameters(), lr=learning_rate)

    loss_history = []
    for epoch in range(num_epochs):
        for step, (x_batch, y_batch) in enumerate(dataloader):
            model.train()
            optimizer.zero_grad()
            y_pred = model(x_batch, step)
            loss = criterion(y_pred.squeeze(), y_batch)
            loss.backward()
            optimizer.step()

        loss_history.append(loss.item())
        print(f"Epoch {epoch + 1}/{num_epochs}, Loss: {loss.item():.4f}")

    return loss_history


# Visualize results
def visualize_results(model, x, y, time_steps):
    model.eval()
    with torch.no_grad():
        y_pred = [model(x, t) for t in range(time_steps)]
    y_pred = torch.stack(y_pred).mean(dim=0).squeeze()

    plt.figure(figsize=(10, 6))
    plt.plot(x.numpy(), y.numpy(), label="True Data", alpha=0.7)
    plt.plot(x.numpy(), y_pred.numpy(), label="QDT Model Prediction", alpha=0.7)
    plt.legend()
    plt.xlabel("Input")
    plt.ylabel("Output")
    plt.title("QDT Neural Network Prediction")
    plt.grid(True)
    plt.show()


# Main pipeline
def main():
    # Hyperparameters
    input_size = 1
    hidden_size = 32
    output_size = 1
    num_samples = 1000
    batch_size = 32
    num_epochs = 50
    learning_rate = 0.01

    # Generate data
    x, y = generate_synthetic_data(num_samples, input_size)
    dataset = TensorDataset(x, y)
    dataloader = DataLoader(dataset, batch_size=batch_size, shuffle=True)

    # Initialize model
    model = DynamicQDTNN(input_size, hidden_size, output_size)

    # Train model
    print("Training QDT Neural Network...")
    loss_history = train_qdt_network(model, dataloader, num_epochs, learning_rate)

    # Visualize loss
    plt.plot(loss_history, label="Training Loss")
    plt.xlabel("Epochs")
    plt.ylabel("Loss")
    plt.title("Training Loss Over Time")
    plt.legend()
    plt.show()

    # Visualize results
    visualize_results(model, x, y, model.time_steps)


if __name__ == "__main__":
    main()