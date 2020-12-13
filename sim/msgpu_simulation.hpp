// This file is part of MSGPU project.
// Copyright (C) 2020 Mateusz Stadnik
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#ifndef MSGPU_SIMULATION_H
#define MSGPU_SIMULATION_H

#include <atomic>
#include <cstdint>
#include <memory>
#include <mutex>

#include <functional>

#include <Vmsgpu.h>
#include <verilated.h>

#include <thread>
#include <vector>
#include <queue>

class McuInterface
{
public:
    enum class State 
    {
        Idle,
        BusHigh,
        BusLow
    };

private:
    
};

class MsgpuSimulation
{
public:
    using hsync_callback_type = std::function<void()>;
    using vsync_callback_type = std::function<void()>;
    using on_pixel_callback_type = std::function<void(uint8_t r, uint8_t g, uint8_t n)>;

    MsgpuSimulation(int argc, char *argv[]);
    
    void run();
    void on_hsync(const hsync_callback_type& callback);
    void on_vsync(const vsync_callback_type& callback);
    void on_pixel(const on_pixel_callback_type& callback);

    void send_u8(uint8_t byte);
    void send_u16(uint16_t data);
    void send_pixel(uint16_t color);
    void send_command(uint8_t command);

    using line_type = std::vector<uint16_t>;
    using frame_type = std::vector<line_type>;

    void send_line(const line_type& line);
    void send_frame(const frame_type& frame);

private:
    void generate_sclk();
    void do_tick();

    uint8_t bus_;
    uint64_t tick_counter_;

    std::unique_ptr<Vmsgpu> circuit_;

    hsync_callback_type on_hsync_;
    vsync_callback_type on_vsync_;
    on_pixel_callback_type on_pixel_;

    bool previous_hsync_state_;
    bool previous_vsync_state_;
    std::atomic<uint8_t> sclk_counter_;
    std::thread thread_;

    uint64_t hsync_tick_stamp_;
    uint64_t ticks_for_vga_tick_;
    std::mutex data_mutex_;
    bool sclk_down_;
    std::queue<std::pair<uint8_t, bool>> fifo_;
};

#endif /* MSGPU_SIMULATION_H */

