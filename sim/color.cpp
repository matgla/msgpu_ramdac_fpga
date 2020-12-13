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

Color Color::make_from_rgb444(uint8_t r, uint8_t g, uint8_t b)
{
    return Color(r * 2, g * 2, b * 2);
}

uint16_t Color::to_rgb444() const 
{
    return (static_cast<uint16_t>(r_ / uint16_t(2)) << 8)
        | (static_cast<uint16_t>(g_ / 2u) << 4)
        | static_cast<uint16_t>(b_ / 2u);
}

sf::Color Color::to_sfml() const 
{
    return sf::Color(r_, g_, b_);
}
