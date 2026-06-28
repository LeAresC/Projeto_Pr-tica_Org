#include "Sound.h"
#include <ao/ao.h>
#include <cmath>
#include <algorithm>
#include <cstdlib>

Beeper::Beeper() {
    ao_initialize();

    ao_sample_format formato;
    formato.bits = 16;
    formato.channels = 1;
    formato.rate = FREQUENCY; 
    formato.byte_format = AO_FMT_NATIVE;
    formato.matrix = 0;

    int driver_padrao = ao_default_driver_id();
    device = ao_open_live(driver_padrao, &formato, NULL);

    v = 0.0; 
}

Beeper::~Beeper() {
    if (device != NULL) {
        ao_close(device);
    }
    ao_shutdown();
}

// CORREÇÃO AQUI: Adicionado o prefixo Beeper:: para dizer ao C++ que estes métodos pertencem à classe!
double Beeper::sineWave(double amplitude, double v) {
    return amplitude * std::sin(v);
}

double Beeper::squareWave(double amplitude, double v) {
    return (std::sin(v) >= 0.0 ? amplitude : -amplitude);
}

double Beeper::triangleWave(double amplitude, double v) {
    return (2.0 / M_PI) * std::asin(std::sin(v)) * amplitude;
}

double Beeper::sawtoothWave(double amplitude, double v) {
    double phase = v / (2 * M_PI);
    double wave = 2.0 * (phase - std::floor(0.5 + phase));
    return wave * amplitude;
}

// Vinculado corretamente ao escopo da classe
double Beeper::chooseWave(std::string wave, double freq, double amplitude, double v) {
    if (wave == "sine")     return sineWave(amplitude, v);
    if (wave == "square")   return squareWave(amplitude, v);
    if (wave == "triangle") return triangleWave(amplitude, v);
    if (wave == "sawtooth") return sawtoothWave(amplitude, v);
    return sineWave(amplitude, v);
}

void Beeper::beep(std::string wave, double freq, int duration) {
    BeepObject bo;
    bo.freq = freq;
    bo.wave_type = wave;
    bo.samplesLeft = duration * FREQUENCY / 1000;
    beeps.push(bo);
}

void Beeper::wait(int time) {
    while (!beeps.empty()) {
        BeepObject& bo = beeps.front();
        int length = bo.samplesLeft;

        int16_t *stream = (int16_t*) calloc(length, sizeof(int16_t));
        
        if (stream != NULL) {
            for (int i = 0; i < length; i++) {
                stream[i] = (int16_t)chooseWave(bo.wave_type, bo.freq, AMPLITUDE, v);
                
                v += 2.0 * M_PI * bo.freq / FREQUENCY;
                if (v > 2.0 * M_PI) {
                    v -= 2.0 * M_PI;
                }
            }

            ao_play(device, (char *)stream, length * sizeof(int16_t));
            free(stream);
        }
        
        beeps.pop();
    }
}

void play_note(int rx, int ry, int rz) {
    static Beeper beeper;
    std::string type;

    switch (rz) {
        case 0:  type = "sine";     break;
        case 1:  type = "square";   break;
        case 2:  type = "triangle"; break;
        case 3:  type = "sawtooth"; break;    
        default: type = "sine";     break;
    }
    
    beeper.beep(type, rx, ry);
    beeper.wait(30);
}
