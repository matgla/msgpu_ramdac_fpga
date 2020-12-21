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

#ifndef VGA_INTERFACE_H
#define VGA_INTERFACE_H

#include <functional>
#include <utility>

#include "Vmsgpu.h"

class VgaInterface 
{
public:
    using hsync_type = decltype(std::declval<Vmsgpu>().hsync);
    using vsync_type = decltype(std::declval<Vmsgpu>().vsync);
    using vga_red_type = decltype(std::declval<Vmsgpu>().vga_red);
    using vga_green_type = decltype(std::declval<Vmsgpu>().vga_green);
    using vga_blue_type = decltype(std::declval<Vmsgpu>().vga_blue);
    VgaInterface(const hsync_type& hsync, const vsync_type& vsync,
        const vga_red_type& red, 
        const vga_green_type& green, 
        const vga_blue_type& blue);

    void process(uint64_t tick);

    using on_pixel_type = std::function<void(uint8_t r, uint8_t g, uint8_t b)>;
    using on_hsync_type = std::function<void()>;
    using on_vsync_type = std::function<void()>; 

    void on_pixel(const on_pixel_type& on_pixel);
    void on_hsync(const on_hsync_type& on_hsync);
    void on_vsync(const on_vsync_type& on_vsync);
private:
    void process_vga_tick();
    bool is_hsync_posedge() const;
    bool is_hsync_negedge() const;
    bool is_vsync_posedge() const;
    bool is_vsync_negedge() const;

    const hsync_type& hsync_;
    const vsync_type& vsync_;
    const vga_red_type& red_;
    const vga_green_type& green_;
    const vga_blue_type& blue_;

    enum class State 
    {
        Initialization, 
        Hsync,
        Vsync,
        Display,
        WaitForHsync,
        WaitForVsync
    };

    uint64_t hsync_stamp_;
    uint64_t vsync_stamp_;
    uint32_t line_; 
    bool previous_hsync_state_;
    bool previous_vsync_state_;

    uint64_t clocks_offset_;
    uint64_t vga_ticks_;
    State state_;
    on_pixel_type on_pixel_;
    on_vsync_type on_vsync_;
    on_hsync_type on_hsync_;
};

#endif // VGA_INTERFACE_H

