import numpy as np
import matplotlib.pyplot as plt
from dataclasses import dataclass
from typing import Dict, List, Tuple, Optional, Callable
import time
import threading
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[logging.StreamHandler()]
)

@dataclass
class QDTConstants:
    """Core QDT constants"""
    LAMBDA: float = 0.867     # Coupling constant
    GAMMA: float = 0.4497     # Damping coefficient
    BETA: float = 0.310       # Fractal recursion
    ETA: float = 0.520        # Stabilizing term

class BetaMonitor:
    """Monitor and flag negative beta values in QDT systems"""
    
    def __init__(self, 
                 reference_beta: float = 0.310, 
                 alert_threshold: float = 0.05,
                 critical_threshold: float = -0.05,
                 emergency_threshold: float = -0.15):
        """Initialize the beta monitor with thresholds.
        
        Args:
            reference_beta: The standard beta value (typically 0.310)
            alert_threshold: Threshold for alert level (yellow)
            critical_threshold: Threshold for critical level (orange)
            emergency_threshold: Threshold for emergency level (red)
        """
        self.reference_beta = reference_beta
        self.alert_threshold = alert_threshold
        self.critical_threshold = critical_threshold
        self.emergency_threshold = emergency_threshold
        
        self.current_beta = reference_beta
        self.beta_history = []
        self.alert_status = "NORMAL"
        self.alert_callbacks = []
        
        self.monitor_active = False
        self.monitor_thread = None
        
    def register_alert_callback(self, callback: Callable[[str, float], None]):
        """Register a callback function to be called when alert status changes.
        
        Args:
            callback: Function taking alert_status and current_beta as parameters
        """
        self.alert_callbacks.append(callback)
        
    def calculate_effective_beta(self, 
                                system_state: Dict[str, float], 
                                time_factor: float) -> float:
        """Calculate effective beta value from system state.
        
        Args:
            system_state: Dictionary with void_energy, filament_energy, etc.
            time_factor: Current time factor
            
        Returns:
            Effective beta value
        """
        # Extract key metrics from system state
        void_energy = system_state.get('void_energy', 0.5)
        filament_energy = system_state.get('filament_energy', 0.5)
        temperature = system_state.get('temperature', 0)
        coupling = system_state.get('coupling', QDTConstants.LAMBDA)
        
        # Calculate base beta using the standard QDT relationship
        base_beta = self.reference_beta * (void_energy / filament_energy) * coupling
        
        # Apply time mediation
        time_mediation = np.exp(-QDTConstants.GAMMA * time_factor) * \
                         np.sin(2 * np.pi * time_factor * QDTConstants.ETA)
        
        # Calculate effective beta with time mediation
        effective_beta = base_beta * (1 + 0.2 * time_mediation)
        
        # Apply temperature effects (if relevant to the system)
        if abs(temperature) > 0.1:
            temp_factor = 1 - 0.05 * abs(temperature)
            effective_beta *= temp_factor
            
        return effective_beta
        
    def update_beta(self, new_beta: float):
        """Update current beta value and check for triggers.
        
        Args:
            new_beta: New beta value to evaluate
        """
        self.current_beta = new_beta
        self.beta_history.append(new_beta)
        
        # Trim history if too long
        if len(self.beta_history) > 1000:
            self.beta_history = self.beta_history[-1000:]
            
        # Check for triggers
        previous_status = self.alert_status
        
        if new_beta <= self.emergency_threshold:
            self.alert_status = "EMERGENCY"
        elif new_beta <= self.critical_threshold:
            self.alert_status = "CRITICAL"
        elif new_beta <= self.alert_threshold:
            self.alert_status = "ALERT"
        else:
            self.alert_status = "NORMAL"
            
        # If status changed, notify callbacks
        if previous_status != self.alert_status:
            self._notify_callbacks()
    
    def _notify_callbacks(self):
        """Notify all registered callbacks about status change"""
        for callback in self.alert_callbacks:
            try:
                callback(self.alert_status, self.current_beta)
            except Exception as e:
                logging.error(f"Error in callback: {e}")
    
    def start_monitoring(self, 
                        state_provider: Callable[[], Dict[str, float]], 
                        interval: float = 1.0):
        """Start continuous monitoring thread.
        
        Args:
            state_provider: Function that returns current system state
            interval: Monitoring interval in seconds
        """
        if self.monitor_active:
            return
            
        self.monitor_active = True
        
        def monitor_loop():
            time_factor = 0
            while self.monitor_active:
                try:
                    system_state = state_provider()
                    effective_beta = self.calculate_effective_beta(system_state, time_factor)
                    self.update_beta(effective_beta)
                    
                    # Log if not normal
                    if self.alert_status != "NORMAL":
                        logging.warning(
                            f"Beta alert: {self.alert_status}, β={self.current_beta:.4f}"
                        )
                    
                    time.sleep(interval)
                    time_factor += interval
                except Exception as e:
                    logging.error(f"Error in monitoring loop: {e}")
                    time.sleep(interval)
        
        self.monitor_thread = threading.Thread(target=monitor_loop)
        self.monitor_thread.daemon = True
        self.monitor_thread.start()
        logging.info("Beta monitoring started")
    
    def stop_monitoring(self):
        """Stop the monitoring thread"""
        self.monitor_active = False
        if self.monitor_thread:
            self.monitor_thread.join(timeout=1.0)
        logging.info("Beta monitoring stopped")
    
    def get_status_color(self) -> str:
        """Get color code for current status"""
        if self.alert_status == "EMERGENCY":
            return "#FF0000"  # Red
        elif self.alert_status == "CRITICAL":
            return "#FF7700"  # Orange
        elif self.alert_status == "ALERT":
            return "#FFFF00"  # Yellow
        else:
            return "#00FF00"  # Green
    
    def visualize_beta_history(self, window_size: int = 100):
        """Visualize beta history with alert thresholds.
        
        Args:
            window_size: Number of recent points to display
        """
        history = self.beta_history[-window_size:] if len(self.beta_history) > window_size else self.beta_history
        
        plt.figure(figsize=(12, 6))
        
        # Plot beta history
        plt.plot(history, 'b-', label='Effective β Value')
        
        # Plot thresholds
        plt.axhline(y=0, color='gray', linestyle='--', alpha=0.5)
        plt.axhline(y=self.alert_threshold, color='yellow', linestyle='--', label='Alert Threshold')
        plt.axhline(y=self.critical_threshold, color='orange', linestyle='--', label='Critical Threshold')
        plt.axhline(y=self.emergency_threshold, color='red', linestyle='--', label='Emergency Threshold')
        plt.axhline(y=self.reference_beta, color='green', linestyle='--', label='Reference β')
        
        # Highlight current status
        plt.scatter([len(history)-1], [history[-1]], 
                   color=self.get_status_color(), s=100, zorder=5)
        
        # Add title and labels
        plt.title(f'QDT β Value Monitoring - Status: {self.alert_status}', fontweight='bold')
        plt.xlabel('Time Steps')
        plt.ylabel('β Value')
        plt.grid(True, alpha=0.3)
        plt.legend()
        
        plt.tight_layout()
        plt.show()


class QDTSystemCorrector:
    """System to correct negative beta values and restore stability"""
    
    def __init__(self, beta_monitor: BetaMonitor, qdt_constants: QDTConstants = QDTConstants()):
        self.beta_monitor = beta_monitor
        self.constants = qdt_constants
        self.corrective_actions_history = []
        
        # Register for alert callbacks
        self.beta_monitor.register_alert_callback(self.alert_handler)
    
    def alert_handler(self, alert_status: str, current_beta: float):
        """Handle alerts from beta monitor"""
        logging.info(f"Alert received: {alert_status}, β={current_beta:.4f}")
        
        if alert_status in ["ALERT", "CRITICAL", "EMERGENCY"]:
            self.apply_corrective_action(alert_status, current_beta)
    
    def apply_corrective_action(self, alert_status: str, current_beta: float):
        """Apply corrective action based on alert status"""
        
        # Calculate correction strength based on how negative beta is
        correction_needed = self.beta_monitor.reference_beta - current_beta
        
        if alert_status == "EMERGENCY":
            # Emergency correction - strong and immediate
            correction_factor = min(1.0, correction_needed / 0.5)
            action = "EMERGENCY_RESET"
            message = f"EMERGENCY RESET applied: β correction of {correction_factor:.2f}"
            
        elif alert_status == "CRITICAL":
            # Strong correction with damping
            correction_factor = min(0.7, correction_needed / 0.6)
            action = "STRONG_CORRECTION"
            message = f"Strong correction applied: β correction of {correction_factor:.2f}"
            
        else:  # ALERT
            # Gentle correction
            correction_factor = min(0.3, correction_needed / 0.8)
            action = "GENTLE_CORRECTION"
            message = f"Gentle correction applied: β correction of {correction_factor:.2f}"
        
        # Log the corrective action
        logging.warning(message)
        
        # Record the action
        self.corrective_actions_history.append({
            'timestamp': time.time(),
            'alert_status': alert_status,
            'beta_value': current_beta,
            'action': action,
            'correction_factor': correction_factor
        })
        
        return correction_factor
    
    def get_correction_parameters(self) -> Dict[str, float]:
        """Get correction parameters for a QDT system"""
        # If no corrections have been applied, return default values
        if not self.corrective_actions_history:
            return {
                'void_energy_boost': 0.0,
                'lambda_adjustment': 0.0,
                'gamma_increase': 0.0,
                'stabilization_factor': 1.0
            }
        
        # Get the most recent correction
        last_correction = self.corrective_actions_history[-1]
        correction_factor = last_correction['correction_factor']
        
        # Create corrective parameters
        if last_correction['action'] == "EMERGENCY_RESET":
            return {
                'void_energy_boost': 0.5 * correction_factor,  # Strong boost to void energy
                'lambda_adjustment': 0.1 * correction_factor,  # Increase coupling
                'gamma_increase': 0.2 * correction_factor,     # Increase damping
                'stabilization_factor': 1 + correction_factor  # Overall stabilization
            }
        elif last_correction['action'] == "STRONG_CORRECTION":
            return {
                'void_energy_boost': 0.3 * correction_factor,
                'lambda_adjustment': 0.05 * correction_factor,
                'gamma_increase': 0.1 * correction_factor,
                'stabilization_factor': 1 + 0.7 * correction_factor
            }
        else:  # GENTLE_CORRECTION
            return {
                'void_energy_boost': 0.1 * correction_factor,
                'lambda_adjustment': 0.02 * correction_factor,
                'gamma_increase': 0.05 * correction_factor,
                'stabilization_factor': 1 + 0.3 * correction_factor
            }


# Example usage with simulation
def run_beta_monitoring_demo():
    """Run a demonstration of the beta monitoring system"""
    print("\n=== QDT Beta Value Monitor Demonstration ===\n")
    
    # Create the beta monitor
    monitor = BetaMonitor(
        reference_beta=0.310,
        alert_threshold=0.05,      # Yellow alert below 0.05
        critical_threshold=-0.05,  # Orange alert below -0.05
        emergency_threshold=-0.15  # Red alert below -0.15
    )
    
    # Create system corrector
    corrector = QDTSystemCorrector(monitor)
    
    # Simulated system state
    system_state = {
        'void_energy': 0.5,
        'filament_energy': 0.5,
        'temperature': 0.0,
        'coupling': QDTConstants.LAMBDA
    }
    
    # Define a callback for status changes
    def status_change_callback(status, beta):
        print(f"\n[{time.strftime('%H:%M:%S')}] ALERT STATUS CHANGE: {status}, β={beta:.4f}")
        
        # Suggest corrective actions
        if status == "EMERGENCY":
            print("  RECOMMENDED ACTION: Immediate void energy injection and system reset")
        elif status == "CRITICAL":
            print("  RECOMMENDED ACTION: Increase lambda coupling and apply damping")
        elif status == "ALERT":
            print("  RECOMMENDED ACTION: Gentle void energy increase")
    
    # Register the callback
    monitor.register_alert_callback(status_change_callback)
    
    # Simulation parameters
    simulation_steps = 100
    
    # Collection for plotting
    time_steps = np.arange(simulation_steps)
    beta_values = []
    
    # Start with normal beta values
    beta = monitor.reference_beta
    
    print("\nRunning simulation with gradually decreasing beta...\n")
    
    # Run simulation
    for step in range(simulation_steps):
        # In first half, gradually decrease beta
        if step < simulation_steps // 2:
            # Gradual decrease with some noise
            decrease_rate = 0.01 * (step / (simulation_steps // 4))
            beta = monitor.reference_beta - decrease_rate + 0.01 * np.sin(step/5)
        else:
            # In second half, recover with corrective actions
            if monitor.alert_status != "NORMAL":
                correction = corrector.apply_corrective_action(
                    monitor.alert_status, beta)
                beta += correction * 0.1
            
            # Add some noise
            beta += 0.01 * np.sin(step/3)
        
        # Update the monitor
        monitor.update_beta(beta)
        beta_values.append(beta)
        
        # Print status periodically
        if step % 10 == 0:
            print(f"Step {step}: β={beta:.4f}, Status: {monitor.alert_status}")
    
    # Visualize results
    plt.figure(figsize=(15, 8))
    
    # Plot beta values
    plt.plot(time_steps, beta_values, 'b-', linewidth=2, label='β Value')
    
    # Add thresholds
    plt.axhline(y=monitor.reference_beta, color='green', linestyle='--', 
               label=f'Reference β={monitor.reference_beta}')
    plt.axhline(y=monitor.alert_threshold, color='yellow', linestyle='--', 
               label=f'Alert ({monitor.alert_threshold})')
    plt.axhline(y=monitor.critical_threshold, color='orange', linestyle='--', 
               label=f'Critical ({monitor.critical_threshold})')
    plt.axhline(y=monitor.emergency_threshold, color='red', linestyle='--', 
               label=f'Emergency ({monitor.emergency_threshold})')
    plt.axhline(y=0, color='black', linestyle=':', alpha=0.5, label='Zero Line')
    
    # Highlight alert regions
    alert_mask = np.array([v <= monitor.alert_threshold and v > monitor.critical_threshold 
                         for v in beta_values])
    critical_mask = np.array([v <= monitor.critical_threshold and v > monitor.emergency_threshold 
                            for v in beta_values])
    emergency_mask = np.array([v <= monitor.emergency_threshold for v in beta_values])
    
    if np.any(alert_mask):
        plt.fill_between(time_steps, monitor.alert_threshold, monitor.critical_threshold,
                        where=alert_mask, color='yellow', alpha=0.3, label='Alert Zone')
    
    if np.any(critical_mask):
        plt.fill_between(time_steps, monitor.critical_threshold, monitor.emergency_threshold,
                        where=critical_mask, color='orange', alpha=0.3, label='Critical Zone')
    
    if np.any(emergency_mask):
        plt.fill_between(time_steps, monitor.emergency_threshold, min(beta_values),
                        where=emergency_mask, color='red', alpha=0.3, label='Emergency Zone')
    
    # Add markers for corrective actions
    correction_steps = []
    correction_values = []
    correction_colors = []
    correction_sizes = []
    
    for i, action in enumerate(corrector.corrective_actions_history):
        for step, beta in enumerate(beta_values):
            if abs(beta - action['beta_value']) < 0.001:
                correction_steps.append(step)
                correction_values.append(beta)
                
                if action['action'] == 'EMERGENCY_RESET':
                    correction_colors.append('red')
                    correction_sizes.append(150)
                elif action['action'] == 'STRONG_CORRECTION':
                    correction_colors.append('orange')
                    correction_sizes.append(100)
                else:
                    correction_colors.append('yellow')
                    correction_sizes.append(80)
                
                break
    
    if correction_steps:
        plt.scatter(correction_steps, correction_values, c=correction_colors, s=correction_sizes,
                   marker='*', edgecolor='black', linewidth=1, zorder=10, label='Corrective Action')
    
    # Add title and labels
    plt.title('QDT Beta Value Monitoring and Correction Simulation', fontsize=16, fontweight='bold')
    plt.xlabel('Simulation Step', fontsize=12)
    plt.ylabel('Beta Value', fontsize=12)
    plt.grid(True, alpha=0.3)
    plt.legend(loc='upper right')
    
    # Add annotation explaining the simulation
    plt.figtext(0.5, 0.01, 
               "Simulation shows beta value decreasing into negative territory (alert zones) and recovery with corrective actions.\n"
               "Yellow, orange and red zones represent increasing alert levels requiring intervention.",
               ha='center', fontsize=10, bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
    
    plt.tight_layout(rect=[0, 0.03, 1, 1])
    plt.show()
    
    print("\n=== Simulation Complete ===\n")
    print(f"Total corrective actions: {len(corrector.corrective_actions_history)}")
    print(f"Final beta value: {beta_values[-1]:.4f}")
    print(f"Final alert status: {monitor.alert_status}")
    
    return monitor, corrector

# Run the demonstration
if __name__ == "__main__":
    monitor, corrector = run_beta_monitoring_demo()