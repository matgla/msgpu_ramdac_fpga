#include "Vmsgpu.h"
#include "verilated.h"

#include <memory>
#include <thread>
#include <chrono>
#include <iostream>

#include "window.hpp"

int main(int argc, char *argv[])
{
    Verilated::commandArgs(argc, argv);
    Vmsgpu* top = new Vmsgpu();
    /*while (!Verilated::gotFinish())
    {
        top->eval();
    }*/

    Window window;
    window.run();

    for (int x = 0; x < 640; ++x)
    {
        for (int y = 0; y < 480; ++y)
        {
            if (x < 210) 
            {
                window.set_pixel(y, x, sf::Color::Red);
            }
            else if (x < 420) 
            {
                window.set_pixel(y, x, sf::Color::Green);
            }
            else 
            {
                window.set_pixel(y, x, sf::Color::Blue);
            }
        }
    }

    window.join();

    return 0;
}
