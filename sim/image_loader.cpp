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

#include "image_loader.hpp"

#include "color.hpp"

#include <iostream>

ImageLoader::ImageLoader(const std::string& path, Config config)
    : config_(config)
{
    image_.loadFromFile(path); 
}

ImageLoader::Frame ImageLoader::get_frame(int number) const
{
    Frame frame(config_.height);
    // int x_offset = (frames_in_row % number) * ;
    // int y_offset = frames_in_row / number;

    for (int y = 0; y < config_.height; ++y)
    {
        frame[y].resize(config_.width);
        for (int x = 0; x < config_.width; ++x)
        {
            frame[y][x] = Color::make_from_sfml(image_.getPixel(x, y)).to_rgb444();
        }
    }
    return frame;
}

