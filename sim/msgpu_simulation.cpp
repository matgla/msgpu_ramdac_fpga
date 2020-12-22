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
    , mcu_interface_{}
    , vga_interface_(circuit_->hsync, circuit_->vsync, circuit_->vga_red, circuit_->vga_green, circuit_->vga_blue)
{
    circuit_->hsync = 1;
    circuit_->vsync = 1;
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
    circuit_->clock = 1; 
    circuit_->eval();

    circuit_->clock = 0; 
    circuit_->eval();
  
    mcu_interface_.process(tick_counter_, circuit_->mcu_bus, circuit_->mcu_bus_clock, circuit_->mcu_bus_command_data);
    vga_interface_.process(tick_counter_);
  
    ++tick_counter_;
}

void MsgpuSimulation::on_pixel(const on_pixel_callback_type& callback)
{
    vga_interface_.on_pixel(callback);
}

void MsgpuSimulation::on_hsync(const hsync_callback_type& callback)
{
    vga_interface_.on_hsync(callback);
}

void MsgpuSimulation::on_vsync(const vsync_callback_type& callback)
{
    vga_interface_.on_vsync(callback);
}

void MsgpuSimulation::send_u16(uint16_t data)
{
    send_u8(data & 0xff);
    send_u8((data >> 8) & 0xff);
}

void MsgpuSimulation::send_u8(uint8_t byte) 
{
    mcu_interface_.send_data(byte);
}

void MsgpuSimulation::send_command(uint8_t command) 
{
    mcu_interface_.send_command(command);
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

void MsgpuSimulation::send_pixel(uint16_t color)
{
    send_u16(color);
}
