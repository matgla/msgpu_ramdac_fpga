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

#ifndef COLOR_H
#define COLOR_H

#include <cstdint>

#include <SFML/Graphics.hpp>

class Color
{
public:
    Color(uint8_t r, uint8_t g, uint8_t b);
    static Color make_from_rgb444(uint8_t r, uint8_t g, uint8_t b);
    static Color make_from_sfml(const sf::Color& color);

    uint16_t to_rgb444() const;
    sf::Color to_sfml() const;
private:
    uint8_t r_; 
    uint8_t g_;
    uint8_t b_;
};

#endif /* COLOR_H */
