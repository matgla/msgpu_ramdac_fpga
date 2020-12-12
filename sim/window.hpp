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

#ifndef WINDOW_H
#define WINDOW_H

#include <memory>
#include <thread>

#include <SFML/Graphics.hpp>

class Window
{
public:
    Window();

    void join();
    void run();

    void set_pixel(int y, int x, sf::Color color);
    void clear();

private: 
    std::unique_ptr<std::thread> window_thread_;
    sf::Image screen_;
};

#endif /* WINDOW_H */
