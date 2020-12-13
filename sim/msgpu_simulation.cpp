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

#include "msgpu_simulation.hpp"

#include <iostream>

MsgpuSimulation::MsgpuSimulation(int argc, char *argv[])
    : tick_counter_(0)
    , circuit_(std::make_unique<Vmsgpu>())
{
    Verilated::commandArgs(argc, argv);
}

void MsgpuSimulation::run() 
{
    thread_ = std::thread([this] {
        while (!Verilated::gotFinish())
        {
            do_tick();
        }
    });
}

void MsgpuSimulation::do_tick()
{
    circuit_->clock = 0; 
    circuit_->eval();

    if (sclk_counter_ == 0 && !sclk_down_)
    {
        data_mutex_.lock();
        if (fifo_.size())
        {
            sclk_counter_ = 2;
            circuit_->mcu_bus = fifo_.front();
            sclk_down_ = false;
            fifo_.pop();
        }
        data_mutex_.unlock();
    }
    else if (sclk_counter_) 
    {
        --sclk_counter_;
    } 
    else if ((sclk_down_ == false) && sclk_counter_ == 0) 
    {
        sclk_counter = 2; 
        sclk_down_ = true;
    }

    circuit_->clock = 1; 
    circuit_->eval();
   

    ++tick_counter_;
    if (previous_hsync_state_ == 1 && circuit_->hsync == 0)
    {
        ticks_for_vga_tick_ =  (tick_counter_ - hsync_tick_stamp_) / 800;
        hsync_tick_stamp_ = tick_counter_;
    }
    uint64_t hsync_delta = tick_counter_ - hsync_tick_stamp_;
    if (hsync_delta >= 144)
    {
        // now we are receiving pixels, but only in mod 8 
        if (hsync_delta % ticks_for_vga_tick_) 
        {
            if (on_pixel_) 
            {
                on_pixel_(circuit_->vga_red, circuit_->vga_green, circuit_->vga_blue);
            }
        }
    }
    previous_hsync_state_ = circuit_->hsync;
    previous_vsync_state_ = circuit_->vsync;
}

void MsgpuSimulation::on_pixel(const on_pixel_callback_type& callback)
{
    on_pixel_ = callback;
}

void MsgpuSimulation::send_u16(uint16_t data)
{
    send_u8((data >> 8) & 0xff);
    send_u8(data & 0xff);
}

void MsgpuSimulation::send_u8(uint8_t byte) 
{
    data_mutex_.lock();
    bus_ = byte;
    circuit_->mcu_bus_command_data = 1;
    generate_sclk();
    data_mutex_.unlock();
}

void MsgpuSimulation::send_command(uint8_t command) 
{
    data_mutex_.lock();
    bus_ = command; 
    circuit_->mcu_bus_command_data = 0;
    generate_sclk();
    data_mutex_.unlock();
}

void MsgpuSimulation::generate_sclk() 
{
    while (circuit_->mcu_bus_clock || sclk_counter_) 
    {
    }
    sclk_counter_ = 2;
    circuit_->mcu_bus_clock = 1;
}

void MsgpuSimulation::send_line(const line_type& line)
{
    for (uint16_t pixel : line)
    {
        send_u16(pixel);
    }
}

void MsgpuSimulation::send_frame(const frame_type& frame)
{
    for (const auto& line : frame)
    {
        send_line(line);
    }
}

