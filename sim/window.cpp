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

#include "window.hpp"

#include <SFML/Graphics.hpp>
#include <SFML/Window.hpp>


Window::Window() 
{
    screen_.create(640, 480);
}


void Window::join()
{
    if (window_thread_) 
    {
        window_thread_->join();
    }
}

void Window::set_pixel(int y, int x, sf::Color color)
{
    screen_.setPixel(x, y, color);
}

void Window::clear() 
{
    screen_.create(640, 480);
}

void Window::run()
{
    window_thread_ = std::make_unique<std::thread>([this] {
        sf::RenderWindow window(sf::VideoMode(640, 480), "MSGPU Simulator");
        while (window.isOpen())
        {
            sf::Event ev; 
            while (window.pollEvent(ev))
            {
                if (ev.type == sf::Event::Closed)
                {
                    window.close();
                }
            }
            
            window.clear();
            sf::Texture tex;
            tex.loadFromImage(screen_);
            sf::Sprite sprite;
            sprite.setPosition(0, 0);
            sprite.setTexture(tex);
            window.draw(sprite);
            window.display();
        }
    });
}

