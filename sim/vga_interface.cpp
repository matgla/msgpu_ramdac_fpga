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

#include "vga_interface.hpp"

#include <iostream>

VgaInterface::VgaInterface(const hsync_type& hsync, const vsync_type& vsync,
    const vga_red_type& red, 
    const vga_green_type& green, 
    const vga_blue_type& blue)
    : hsync_(hsync)
    , vsync_(vsync)
    , red_(red) 
    , green_(green)
    , blue_(blue)
    , hsync_stamp_(0)
    , vsync_stamp_(0)
    , line_(0)
    , previous_hsync_state_(false)
    , previous_vsync_state_(false)
    , clocks_offset_(0)
    , vga_ticks_(0)
    , state_(State::Initialization)
{

}

void VgaInterface::process(uint64_t tick)
{
    // firstly we need to synchronize vga and core clocks
    // easiest way is to omit first line (wait for hsync)
    
    if (tick % 8 == 7)
    {
        process_vga_tick();
    }

    previous_hsync_state_ = hsync_;
    previous_vsync_state_ = vsync_;
}

void VgaInterface::on_hsync(const on_hsync_type& on_hsync)
{
    on_hsync_ = on_hsync;
}

void VgaInterface::on_vsync(const on_vsync_type& on_vsync)
{
    on_vsync_ = on_vsync;
}

void VgaInterface::process_vga_tick()
{
    constexpr uint64_t hsync_front_porch = 16;
    constexpr uint64_t hsync_sync_pulse = 96;
    constexpr uint64_t hsync_back_porch = 48;
    constexpr uint64_t hsync_visible_area = 640;
    ++vga_ticks_;
    switch (state_)
    {
        case State::Initialization:
        {
            if (is_hsync_posedge())
            {
                state_ = State::Hsync;
                vga_ticks_ = 0;
            }
        } break;
        case State::Hsync: 
        {
            if (vga_ticks_ >= hsync_back_porch) 
            {
                state_ = State::Display;
                vga_ticks_ = 0;
                ++line_;
                if (on_hsync_) 
                {
                    on_hsync_();
                }
            }
        } break;
        case State::Vsync: 
        {
            if (is_hsync_posedge())
            {
                ++vsync_stamp_; 
            
            if (vsync_stamp_ >= 33) 
            {
                static int frame = 0;
                if (on_vsync_) 
                {
                    on_vsync_();
                }
                state_ = State::Hsync;
                vga_ticks_ = -1;
                line_ = 0;
            }
            }

        } break;
        case State::Display: 
        {
            if (on_pixel_) 
            {
                on_pixel_(red_, green_, blue_);
            }

            if (vga_ticks_ >= hsync_visible_area)
            {
                if (line_ < 480)
                {
                    state_ = State::WaitForHsync;
                    vga_ticks_ = 0;
                }
                else 
                {
                    state_ = State::WaitForVsync;
                }
            }
        } break;
        case State::WaitForHsync: 
        {
            if (is_hsync_posedge()) 
            {
                state_ = State::Hsync;
                vga_ticks_ = 0;
            }
        } break;
        case State::WaitForVsync: 
        {
            if (is_vsync_posedge())
            {
                state_ = State::Vsync;
                vga_ticks_ = 0;
                vsync_stamp_ = 0;
            }
        } break;
    }
}

void VgaInterface::on_pixel(const on_pixel_type& on_pixel)
{
    on_pixel_ = on_pixel;
}

bool VgaInterface::is_hsync_posedge() const 
{
    return (!previous_hsync_state_ && hsync_);
}

bool VgaInterface::is_hsync_negedge() const 
{
    return previous_vsync_state_ && !hsync_;
}

bool VgaInterface::is_vsync_posedge() const 
{
    return (!previous_vsync_state_ && vsync_);
}

bool VgaInterface::is_vsync_negedge() const 
{
    return previous_vsync_state_ && !vsync_;
}


