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

#include "color.hpp"

#include <iostream>

Color::Color(uint8_t r, uint8_t g, uint8_t b) 
    : r_(r) 
    , g_(g) 
    , b_(b)
{
}

Color Color::make_from_sfml(const sf::Color& color)
{
    return Color(color.r, color.g, color.b);
}

Color Color::make_from_rgb444(uint16_t pixel)
{
    return make_from_rgb444((pixel >> 8) & 0xf, (pixel >> 4) & 0xf, pixel & 0xf);
}

Color Color::make_from_rgb444(uint8_t r, uint8_t g, uint8_t b)
{
    uint8_t rr = normalize_to_8bit(r);
    uint8_t gg = normalize_to_8bit(g);
    uint8_t bb = normalize_to_8bit(b);
    return Color(rr, gg, bb);
}

uint16_t Color::to_rgb444() const 
{
    uint8_t r = normalize_to_4bit(r_);
    uint8_t g = normalize_to_4bit(g_);
    uint8_t b = normalize_to_4bit(b_);
    const uint16_t pixel = r << 8 | g << 4 | b;
    return pixel;
}

uint8_t Color::normalize_to_8bit(uint8_t color) 
{
    return (255.0/15.0) * color;
}

uint8_t Color::normalize_to_4bit(uint8_t color) 
{
    return static_cast<uint8_t>(static_cast<float>(color) * 15.0 / 255.0);
}

sf::Color Color::to_sfml() const 
{
    return sf::Color(r_, g_, b_);
}
