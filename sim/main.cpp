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
    int x = 0; 
    int y = 0;
    simulation.on_hsync([&x, &y]() {
        x = 0;
        ++y;
    });

    simulation.on_vsync([&x, &y]() {
        y = -1; 
        x = 0;
    });
    
    simulation.on_pixel([&window, &x, &y](uint8_t r, uint8_t g, uint8_t b) {
        window.set_pixel(y, x, Color::make_from_rgb444(r, g, b).to_sfml());
        ++x;
    });

    simulation.run();
    ImageLoader::Config config{
        .width = 640,
        .height = 480,
        .frames_in_row = 5,
        .frames_in_column = 4
    };
    
    ImageLoader loader("test.png", config);
//    std::this_thread::sleep_for(std::chrono::milliseconds(1));
    
    auto frame = loader.get_frame(0);
    auto thread = std::thread([&frame, &simulation](){
//        simulation.send_frame(frame);
        for (int y = 0; y < 480; ++y) 
        {
            for (int x = 0; x < 640; ++x) 
            {
                //simulation.send_pixel(x);
                if (x == 0) simulation.send_pixel(0xfff);
                //if (x == 2) simulation.send_pixel(0xfff);
                else if (x == 639) simulation.send_pixel(0xff0);
                else if (y == 0) simulation.send_pixel(0xf00);
                else if (y == 479) simulation.send_pixel(0x00f);
                else simulation.send_pixel(0x000);
            }
        }
    });

    std::this_thread::sleep_for(std::chrono::milliseconds(2000));
    simulation.send_command(0x02); // enable vga output 

    auto frame2 = loader.get_frame(1);
    bool second = true;
    decltype(frame)* f;
//    while (true) 
//    {
//        if (second) 
//        {
//            f = &frame; 
//            second = false;
//        }
//        else 
//        {
//            f = &frame2;
//            second = true;
//        }
//        simulation.send_frame(*f); 
//        std::this_thread::sleep_for(std::chrono::milliseconds(2000));
//    }
   

    window.join();

    return 0;
}
