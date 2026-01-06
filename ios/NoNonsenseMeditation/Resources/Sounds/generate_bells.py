#!/usr/bin/env python3
"""
Generate meditation bell sounds using audio synthesis.
Requires: numpy, scipy

Install with: pip install numpy scipy
"""

import numpy as np
from scipy.io import wavfile
import os

def generate_bell_tone(duration_sec, frequency, sample_rate=44100):
    """
    Generate a bell-like tone with harmonic overtones and decay.

    Args:
        duration_sec: Duration in seconds
        frequency: Fundamental frequency in Hz
        sample_rate: Audio sample rate (default: 44100 Hz)

    Returns:
        numpy array of audio samples
    """
    # Time array
    t = np.linspace(0, duration_sec, int(sample_rate * duration_sec))

    # Fundamental frequency
    signal = np.sin(2 * np.pi * frequency * t)

    # Add harmonics (overtones) for bell-like quality
    signal += 0.5 * np.sin(2 * np.pi * (frequency * 2.0) * t)  # Octave
    signal += 0.3 * np.sin(2 * np.pi * (frequency * 3.0) * t)  # Perfect fifth above octave
    signal += 0.2 * np.sin(2 * np.pi * (frequency * 4.5) * t)  # Inharmonic overtone
    signal += 0.15 * np.sin(2 * np.pi * (frequency * 5.4) * t) # Inharmonic overtone

    # Exponential decay envelope for bell-like decay
    decay = np.exp(-3.0 * t / duration_sec)
    signal *= decay

    # Add slight attack (fade in) to avoid clicks
    attack_samples = int(0.01 * sample_rate)  # 10ms attack
    attack_envelope = np.linspace(0, 1, attack_samples)
    signal[:attack_samples] *= attack_envelope

    # Normalize to prevent clipping
    signal = signal / np.max(np.abs(signal)) * 0.8

    return signal

def save_bell_sound(filename, signal, sample_rate=44100):
    """
    Save audio signal as WAV file.

    Args:
        filename: Output filename
        signal: Audio signal (numpy array)
        sample_rate: Sample rate in Hz
    """
    # Convert to 16-bit PCM
    audio_int16 = np.int16(signal * 32767)
    wavfile.write(filename, sample_rate, audio_int16)
    print(f"✓ Generated: {filename}")

def main():
    """Generate all meditation bell sounds."""

    print("Generating meditation bell sounds...")
    print()

    # Get script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Sample rate
    sample_rate = 44100

    # 1. Start bell - Higher pitch, longer duration, welcoming
    print("1. meditation_start.wav - Starting meditation (528 Hz, 2.5s)")
    start_bell = generate_bell_tone(duration_sec=2.5, frequency=528, sample_rate=sample_rate)
    save_bell_sound(os.path.join(script_dir, "meditation_start.wav"), start_bell, sample_rate)

    # 2. Pause bell - Medium pitch, shorter duration
    print("2. meditation_pause.wav - Pausing (440 Hz, 1.5s)")
    pause_bell = generate_bell_tone(duration_sec=1.5, frequency=440, sample_rate=sample_rate)
    save_bell_sound(os.path.join(script_dir, "meditation_pause.wav"), pause_bell, sample_rate)

    # 3. Resume bell - Similar to start but slightly different
    print("3. meditation_resume.wav - Resuming (480 Hz, 2.0s)")
    resume_bell = generate_bell_tone(duration_sec=2.0, frequency=480, sample_rate=sample_rate)
    save_bell_sound(os.path.join(script_dir, "meditation_resume.wav"), resume_bell, sample_rate)

    # 4. Completion bell - Lower pitch, rich harmonics, celebratory
    print("4. meditation_completion.wav - Meditation complete (396 Hz, 3.0s)")
    completion_bell = generate_bell_tone(duration_sec=3.0, frequency=396, sample_rate=sample_rate)
    save_bell_sound(os.path.join(script_dir, "meditation_completion.wav"), completion_bell, sample_rate)

    print()
    print("✨ All meditation bells generated successfully!")
    print()
    print("Note: Frequencies chosen from Solfeggio healing frequencies:")
    print("  • 528 Hz (Start) - Transformation and DNA repair")
    print("  • 440 Hz (Pause) - Standard concert pitch")
    print("  • 480 Hz (Resume) - Intermediate frequency")
    print("  • 396 Hz (Complete) - Liberation from fear and guilt")

if __name__ == "__main__":
    main()
