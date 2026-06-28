#ifndef SOUND_H
#define SOUND_H

#include <string>
#include <queue>
#include <ao/ao.h> // Biblioteca libao para áudio nativo

#define FREQUENCY 44100
#define AMPLITUDE 1638 // Volume seguro (~5% do máximo)

struct BeepObject {
    double freq;
    std::string wave_type;
    int samplesLeft;
};

class Beeper {
private:
    ao_device *device; 
    std::queue<BeepObject> beeps;
    double v; // Acumulador de fase em radianos

    // AGORA SIM: Declarados formalmente como métodos privados da classe Beeper
    double sineWave(double amplitude, double v);
    double squareWave(double amplitude, double v);
    double triangleWave(double amplitude, double v);
    double sawtoothWave(double amplitude, double v);

public:
    Beeper();
    ~Beeper();
    void beep(std::string wave, double freq, int duration);
    void wait(int time);
    double chooseWave(std::string wave, double freq, double amplitude, double v);
};

// Função global chamada pelo Model.cpp
void play_note(int rx, int ry, int rz);

#endif // SOUND_H
