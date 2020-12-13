#include "Vmsgpu.h"
#include "verilated.h"

#include <memory>
#include <thread>
#include <chrono>
#include <iostream>

#include "window.hpp"

#include "msgpu_simulation.hpp"

#include "image_loader.hpp"
#include "color.hpp"

int main(int argc, char *argv[])
{
    Window window;
    window.run();
    MsgpuSimulation simulation(argc, argv);
    simulation.run();
    simulation.on_pixel([&window](uint8_t r, uint8_t g, uint8_t b) {
        static int x = 0;
        static int y = 0;
        //std::cerr << "pixel: " << static_cast<int>(r) << ", " << static_cast<int>(g) << ", " << static_cast<int>(b) << std::endl;
        if ( x < 640) 
        {
            ++x;
        }
        else 
        {
            x = 0;
            ++y;
        }
        if (y >= 480 - 1)
        {
            y = 0;
        }
        if (r || g || b) 
        {
//            std::cerr << "R " << static_cast<int>(r)
//                << ", g " << static_cast<int>(g)
//                << ", b" << static_cast<int>(b) << std::endl;
            window.set_pixel(2, x, Color::make_from_rgb444(r, g, b).to_sfml());
        }
    });

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
    ImageLoader::Config config{
        .width = 640,
        .height = 480,
        .frames_in_row = 5,
        .frames_in_column = 4
    };
    
    ImageLoader loader("test.png", config);
//    std::this_thread::sleep_for(std::chrono::milliseconds(1));

//    auto frame = loader.get_frame(0);
//    simulation.send_frame(frame);
    std::vector<uint16_t> line;
    for (int i = 0; i < 5; ++i)
    {
        line.push_back(i);
    }
    simulation.send_line(line);
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    simulation.send_command(0x02); // enable vga output 

    window.join();

    return 0;
}
