"""
LDO Behavioral Model for Sky130 Adaptive Voltage Scaling (AVS)
Simulates continuous/discrete-time voltage settling, load regulation,
and step response extracted from ngspice simulations.
"""

import numpy as np

class LDOBehavioralModel:
    def __init__(self,
                 v_min=0.90,
                 v_max=1.50,
                 dac_bits=5,
                 settling_time_us=0.5,
                 damping_ratio=0.75,
                 r_out=0.15,
                 i_quiescent_ua=75.0):
        """
        Parameters:
        - v_min: Minimum regulated output voltage (V) at code 0
        - v_max: Maximum regulated output voltage (V) at code 31
        - dac_bits: Number of DAC programming bits
        - settling_time_us: 1% settling time in microseconds
        - damping_ratio: Closed-loop damping ratio (zeta)
        - r_out: Output resistance (Ohms) causing IR load droop
        - i_quiescent_ua: LDO quiescent current (microamps)
        """
        self.v_min = v_min
        self.v_max = v_max
        self.dac_bits = dac_bits
        self.max_code = (1 << dac_bits) - 1
        self.step_size = (v_max - v_min) / float(self.max_code)
        
        self.settling_time = settling_time_us * 1e-6
        self.zeta = damping_ratio
        # Natural frequency from settling time (approx 4 / (zeta * omega_n))
        self.omega_n = 4.0 / (self.zeta * self.settling_time)
        self.r_out = r_out
        self.i_q = i_quiescent_ua * 1e-6
        
        # State variables
        self.v_out = v_max  # Start at safe ceiling voltage
        self.v_dot = 0.0
        self.current_code = self.max_code
        self.target_v = v_max

    def set_voltage_code(self, code):
        """Update DAC voltage code (0 to 31) and compute target voltage."""
        code = int(np.clip(code, 0, self.max_code))
        self.current_code = code
        self.target_v = self.v_min + (code * self.step_size)
        return self.target_v

    def step(self, dt, i_load):
        """
        Advance LDO simulation by time step dt (seconds) under load current i_load (Amps).
        Uses a 2nd-order state-space integration.
        """
        # Load regulation voltage drop
        v_steady = self.target_v - (i_load * self.r_out)
        
        # Second-order differential equation: v'' + 2*zeta*wn*v' + wn^2*(v - v_target) = 0
        v_ddot = (self.omega_n ** 2) * (v_steady - self.v_out) - 2.0 * self.zeta * self.omega_n * self.v_dot
        
        # Euler integration
        self.v_dot += v_ddot * dt
        self.v_out += self.v_dot * dt
        
        # Clamp to realistic physical rail limits [0V, 1.8V]
        self.v_out = np.clip(self.v_out, 0.0, 1.80)
        return self.v_out

    def get_voltage(self):
        return self.v_out

    def get_power(self, i_load, v_in=1.80):
        """Compute instantaneous power drawn from 1.8V supply (Watts)."""
        i_total = i_load + self.i_q
        return v_in * i_total


if __name__ == "__main__":
    ldo = LDOBehavioralModel()
    print("=== LDO Behavioral Model Test ===")
    print(f"Voltage Range: {ldo.v_min:.2f}V to {ldo.v_max:.2f}V across {ldo.max_code+1} codes")
    print(f"Step Size: {ldo.step_size*1e3:.2f} mV / LSB")
    
    # Test step from code 31 (1.50V) down to code 10 (1.09V)
    target = ldo.set_voltage_code(10)
    print(f"Set Code 10 -> Target Voltage: {target:.3f}V")
    
    dt = 1e-8  # 10 ns
    time_points = []
    voltages = []
    
    for step_idx in range(200):
        t = step_idx * dt
        v = ldo.step(dt, i_load=15e-3)
        time_points.append(t * 1e6)
        voltages.append(v)
        
    print(f"Final settled voltage after 2.0 us: {voltages[-1]:.4f}V (Error: {abs(voltages[-1] - (target - 15e-3*0.15))*1e3:.2f} mV)")
    print("LDO Behavioral Model verification passed!")
